// api/banana.js
import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = process.env.SUPABASE_URL
const SUPABASE_KEY = process.env.SUPABASE_KEY
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)

function randomYellow() {
  const r = 200 + Math.floor(Math.random()*55)
  const g = 180 + Math.floor(Math.random()*75)
  const b = Math.floor(Math.random()*40)
  return { r: r/255, g: g/255, b: b/255 }
}

function computeValue({ length, curveyness, weight, patches, rarity }) {
  const rarityMul = rarity === 'Sigma' ? 5 : rarity === 'Epic' ? 3 : rarity === 'Rare' ? 2 : rarity === 'Uncommon' ? 1.5 : 1
  // tuned formula: length, curve, weight increase price, patches reduce
  const base = length * 2 + curveyness * 10 + weight * 50 - patches * 5
  return Math.max(1, Math.floor(base * rarityMul))
}

export default async function handler(req, res) {
  try {
    const { hwid, action } = req.query
    if (!hwid) return res.status(400).json({ error: 'hwid required' })

    // ensure user row exists
    const { data: user, error: fetchUserErr } = await supabase
      .from('users')
      .select('hwid,cash,last_spin')
      .eq('hwid', hwid)
      .maybeSingle()

    if (fetchUserErr) return res.status(500).json({ error: fetchUserErr.message })

    if (!user) {
      // upsert a user
      const { error: insertErr } = await supabase
        .from('users')
        .insert({ hwid, cash: 0, last_spin: 0 })
      if (insertErr) return res.status(500).json({ error: insertErr.message })
    }

    // Refresh user now
    const { data: currentUser } = await supabase
      .from('users')
      .select('hwid,cash,last_spin')
      .eq('hwid', hwid)
      .single()

    const now = Date.now()

    if (action === 'spin') {
      // cooldown 24h
      if (currentUser.last_spin && (now - Number(currentUser.last_spin) < 24*60*60*1000)) {
        return res.json({ error: 'Already spun today' })
      }

      // create banana stats
      const rarRoll = Math.random()
      const rarities = ['Common','Uncommon','Rare','Epic','Sigma']
      const rarity = rarRoll < 0.02 ? 'Sigma' : rarRoll < 0.08 ? 'Epic' : rarRoll < 0.22 ? 'Rare' : rarRoll < 0.5 ? 'Uncommon' : 'Common'
      const curveyness = +(Math.random() * 10).toFixed(2)
      const length = +(15 + Math.random() * 15).toFixed(2)
      const patches = Math.floor(Math.random() * 11)
      const weight = +(0.5 + Math.random() * 0.8).toFixed(2)
      const color = randomYellow()
      const value = computeValue({ length, curveyness, weight, patches, rarity })

      // insert banana into DB
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

      // update last_spin
      await supabase.from('users').update({ last_spin: now }).eq('hwid', hwid)

      return res.json({ banana: inserted })
    }

    if (action === 'sell') {
      // find highest-value banana and sell it
      const { data: bananas, error: bananaErr } = await supabase
        .from('bananas')
        .select('*')
        .eq('user_hwid', hwid)
        .order('value', { ascending: false })
        .limit(1)

      if (bananaErr) return res.status(500).json({ error: bananaErr.message })
      if (!bananas || bananas.length === 0) return res.json({ error: 'No bananas to sell' })

      const toSell = bananas[0]

      // delete banana and add cash
      const { error: delErr } = await supabase.from('bananas').delete().eq('id', toSell.id)
      if (delErr) return res.status(500).json({ error: delErr.message })

      const { error: updErr } = await supabase.from('users').update({ cash: (currentUser.cash||0) + toSell.value }).eq('hwid', hwid)
      if (updErr) return res.status(500).json({ error: updErr.message })

      return res.json({ sold: toSell.value })
    }

    // default: return user and bananas
    const { data: bananasList, error: banErr } = await supabase
      .from('bananas')
      .select('*')
      .eq('user_hwid', hwid)
      .order('inserted_at', { ascending: false })

    if (banErr) return res.status(500).json({ error: banErr.message })
    return res.json({ user: currentUser, bananas: bananasList })
  } catch (e) {
    console.error(e)
    return res.status(500).json({ error: e.message })
  }
}
