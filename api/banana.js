export default async function handler(req, res) {
  try {
    const { hwid, action } = req.query
    if (!hwid) return res.status(400).json({ error: 'hwid required' })

    // ensure user row exists
    let { data: user, error: fetchUserErr } = await supabase
      .from('users')
      .select('hwid,cash,last_spin')
      .eq('hwid', hwid)
      .limit(1)
      .single()

    if (fetchUserErr && fetchUserErr.code !== 'PGRST116') { // "No rows found" code
      return res.status(500).json({ error: fetchUserErr.message })
    }

    if (!user) {
      const { error: insertErr } = await supabase
        .from('users')
        .insert({ hwid, cash: 0, last_spin: 0 })
      if (insertErr) return res.status(500).json({ error: insertErr.message })

      // fetch again
      const { data: newUser } = await supabase
        .from('users')
        .select('hwid,cash,last_spin')
        .eq('hwid', hwid)
        .single()
      user = newUser
    }

    const now = Date.now()

    if (action === 'spin') {
      if (user.last_spin && (now - Number(user.last_spin) < 24 * 60 * 60 * 1000)) {
        return res.json({ error: 'Already spun today' })
      }

      const rarRoll = Math.random()
      const rarity = rarRoll < 0.02 ? 'Sigma'
        : rarRoll < 0.08 ? 'Epic'
        : rarRoll < 0.22 ? 'Rare'
        : rarRoll < 0.5 ? 'Uncommon'
        : 'Common'

      const curveyness = +(Math.random() * 10).toFixed(2)
      const length = +(15 + Math.random() * 15).toFixed(2)
      const patches = Math.floor(Math.random() * 11)
      const weight = +(0.5 + Math.random() * 0.8).toFixed(2)
      const color = randomYellow()
      const value = computeValue({ length, curveyness, weight, patches, rarity })

      const { data: inserted, error: insErr } = await supabase
        .from('bananas')
        .insert([{
          user_hwid: hwid,
          rarity,
          value,
          curveyness,
          length,
          patches,
          weight,
          color_r: color.r,
          color_g: color.g,
          color_b: color.b
        }])
        .select()
        .single()

      if (insErr) return res.status(500).json({ error: insErr.message })

      await supabase.from('users').update({ last_spin: now }).eq('hwid', hwid)

      return res.json({ banana: inserted })
    }

    if (action === 'sell') {
      const { data: bananas, error: bananaErr } = await supabase
        .from('bananas')
        .select('*')
        .eq('user_hwid', hwid)
        .order('value', { ascending: false })
        .limit(1)

      if (bananaErr) return res.status(500).json({ error: bananaErr.message })
      if (!bananas || bananas.length === 0) return res.json({ error: 'No bananas to sell' })

      const toSell = bananas[0]

      const { error: delErr } = await supabase.from('bananas').delete().eq('id', toSell.id)
      if (delErr) return res.status(500).json({ error: delErr.message })

      const { error: updErr } = await supabase
        .from('users')
        .update({ cash: (user.cash || 0) + toSell.value })
        .eq('hwid', hwid)
      if (updErr) return res.status(500).json({ error: updErr.message })

      return res.json({ sold: toSell.value })
    }

    const { data: bananasList, error: banErr } = await supabase
      .from('bananas')
      .select('*')
      .eq('user_hwid', hwid)
      .order('inserted_at', { ascending: false })

    if (banErr) return res.status(500).json({ error: banErr.message })
    return res.json({ user, bananas: bananasList || [] })
  } catch (e) {
    console.error(e)
    return res.status(500).json({ error: e.message })
  }
}
