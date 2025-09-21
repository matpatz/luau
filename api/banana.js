// api/banana.js
import { createClient } from '@supabase/supabase-js'

// **Make sure you set these in Vercel env variables**
const SUPABASE_URL = process.env.SUPABASE_URL
const SUPABASE_KEY = process.env.SUPABASE_KEY
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)

// Random yellow banana color
function randomYellow() {
  const r = 200 + Math.floor(Math.random()*55)
  const g = 180 + Math.floor(Math.random()*75)
  const b = Math.floor(Math.random()*40)
  return { r: r/255, g: g/255, b: b/255 }
}

// Compute banana value
function computeValue({ length, curveyness, weight, patches, rarity }) {
  const rarityMul = rarity === 'Sigma' ? 5 : rarity === 'Epic' ? 3 : rarity === 'Rare' ? 2 : rarity === 'Uncommon' ? 1.5 : 1
  const base = length * 2 + curveyness * 10 + weight * 50 - patches * 5
  return Math.max(1, Math.floor(base * rarityMul))
}

export default async function handler(req, res) {
  try {
    const { hwid, action } = req.query
    if (!hwid) return res.status(400).json({ error: 'hwid required' })

    // Ensure user exists
    let { data: user } = await supabase
      .from('users')
      .select('*')
      .eq('hwid', hwid)
      .maybeSingle()

    if (!user) {
      const { data: newUser, error: insertErr } = await supabase
        .from('users')
        .insert({ hwid, cash: 0, last_spin: 0 })
        .select()
        .single()
      if (insertErr) return res.status(500).json({ error: insertErr.message })
      user = newUser
    }

    const now = Date.now()

    if (action === 'spin') {
      if (user.last_spin && now - user.last_spin < 24*60*60*1000) {
        return res.json({ error: 'Already spun today' })
      }

      // Banana stats
      const rarRoll = Math.random()
      const rarities = ['Common','Uncommon','Rare','Epic','Sigma']
      const rarity = rarRoll < 0.02 ? 'Sigma' : rarRoll < 0.08 ? 'Epic' : rarRoll < 0.22 ? 'Rare' : rarRoll < 0.5 ? 'Uncommon' : 'Common'
      const curveyness = +(Math.random()*10).toFixed(2)
      const length = +(15 + Math.random()*15).toFixed(2)
      const patches = Math.floor(Math.random()*11)
      const weight = +(0.5 + Math.random()*0.8).toFixed(2)
      const color = randomYellow()
      const value = computeValue({ length, curveyness, weight, patches, rarity })

      const { data: banana, error: banErr } = await supabase
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
      if (banErr) return res.status(500).json({ error: banErr.message })

      await supabase.from('users').update({ last_spin: now }).eq('hwid', hwid)

      return res.json({ banana })
    }

    if (action === 'sell') {
      const { data: bananas } = await supabase
        .from('bananas')
        .select('*')
        .eq('user_hwid', hwid)
        .order('value', { ascending: false })
        .limit(1)

      if (!bananas || bananas.length === 0) return res.json({ error: 'No bananas to sell' })

      const toSell = bananas[0]

      await supabase.from('bananas').delete().eq('id', toSell.id)
      await supabase.from('users').update({ cash: (user.cash||0)+toSell.value }).eq('hwid', hwid)

      return res.json({ sold: toSell.value })
    }

    // Default: return user + bananas
    const { data: bananasList } = await supabase
      .from('bananas')
      .select('*')
      .eq('user_hwid', hwid)
      .order('inserted_at', { ascending: false })

    return res.json({ user, bananas: bananasList })
  } catch(e) {
    console.error(e)
    return res.status(500).json({ error: e.message })
  }
}
