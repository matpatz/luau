import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://mantynmtsppznocdfrvd.supabase.co',
  process.env.SUPABASE_KEY // use anon or service key
)

export default async function handler(req, res) {
  const { hwid, action } = req.query
  if (!hwid) return res.status(400).json({ error: 'HWID required' })

  // ensure user row exists
  let { data: user, error } = await supabase
    .from('users')
    .select('*')
    .eq('hwid', hwid)
    .single()

  if (!user) {
    await supabase.from('users').insert({ hwid, cash: 0, last_spin: 0 })
    user = { hwid, cash: 0, last_spin: 0 }
  }

  if (action === 'spin') {
    const now = Date.now()
    if (now - user.last_spin < 24 * 60 * 60 * 1000) {
      return res.json({ error: 'Already spun today' })
    }

    // banana stats
    const banana = {
      rarity: Math.random() < 0.05 ? 'Legendary' : 'Common',
      curveyness: Math.random(),
      length: 10 + Math.random() * 10,
      patches: Math.floor(Math.random() * 10),
      weight: 0.2 + Math.random() * 0.5,
      color_r: 1,
      color_g: 1 - Math.random() * 0.3,
      color_b: 0,
      value: 100 + Math.floor(Math.random() * 400)
    }

    // save banana
    await supabase.from('bananas').insert({ user_hwid: hwid, ...banana })
    await supabase.from('users').update({ last_spin: now }).eq('hwid', hwid)

    return res.json({ banana })
  }

  if (action === 'sell') {
    // sell first banana
    let { data: bananas } = await supabase
      .from('bananas')
      .select('*')
      .eq('user_hwid', hwid)
      .limit(1)

    if (!bananas || bananas.length === 0) {
      return res.json({ error: 'No bananas to sell' })
    }

    const banana = bananas[0]
    await supabase.from('bananas').delete().eq('id', banana.id)
    await supabase
      .from('users')
      .update({ cash: user.cash + banana.value })
      .eq('hwid', hwid)

    return res.json({ sold: banana.value })
  }

  // default: return user data + bananas
  let { data: bananas } = await supabase
    .from('bananas')
    .select('*')
    .eq('user_hwid', hwid)

  return res.json({ user, bananas })
}
