import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
)

export default async function handler(req, res) {
  const { hwid } = req.query

  // check if user exists
  const { data: user, error } = await supabase
    .from('users')
    .select('*')
    .eq('hwid', hwid)
    .single()

  if (error && error.code !== 'PGRST116') {
    return res.status(500).json({ error: error.message })
  }

  // if no user, create one
  if (!user) {
    const { data: newUser, error: insertError } = await supabase
      .from('users')
      .insert([{ hwid, cash: 0, last_spin: Date.now() }])
      .select()
      .single()

    if (insertError) return res.status(500).json({ error: insertError.message })
    return res.status(200).json(newUser)
  }

  return res.status(200).json(user)
}
