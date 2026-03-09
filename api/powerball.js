import { createClient } from "@supabase/supabase-js"

const SHARED = process.env.sSecret
const SUPABASE_URL = process.env.supabaseurl
const SUPABASE_SERVICE = process.env.supabaseService
const supabase = createClient(SUPABASE_URL,SUPABASE_SERVICE)
const BASE_JACKPOT=1000
const FAIL_INCREASE=50

function generateCode(){
    const nums=Array.from({length:5},()=>Math.floor(Math.random()*69)+1)
    const power=Math.floor(Math.random()*26)+1
    return `${nums.join("-")}|${power}`
}

async function getUser(username){
    let {data}=await supabase.from("users").select("*").eq("username",username).single()
    if(!data){await supabase.from("users").insert({username,balance:0,wins:0,wrong:0,cooldown:0});return {balance:0,wins:0,wrong:0,cooldown:0}}
    return data
}

async function setUser(username,obj){
    await supabase.from("users").update({...obj,updated_at:new Date()}).eq("username",username)
}

export default async function handler(req,res){
    const json=(obj)=>res.status(200).json(obj)
    if(req.method!=="POST") return res.status(405).json({error:"method not allowed"})
    if(req.headers["x-secret"]!==SHARED) return res.status(401).json({error:"unauthorized"})
    let {username,guess,action,amount}=req.body
    if(!username) return res.status(400).json({error:"invalid request"})
    let {data:state}=await supabase.from("powerball").select("*").eq("id",1).single()
    if(!state){const code=generateCode();await supabase.from("powerball").insert({id:1,code,jackpot:BASE_JACKPOT,updated_at:new Date()});state={code,jackpot:BASE_JACKPOT}}
    if(Date.now()-new Date(state.updated_at).getTime()>3600000){const code=generateCode();await supabase.from("powerball").update({code,jackpot:BASE_JACKPOT,updated_at:new Date()}).eq("id",1);state.code=code;state.jackpot=BASE_JACKPOT}
    let user=await getUser(username)
    if(action==="buyCooldown"){
        if(user.balance>=100){user.balance-=100;user.cooldown=Math.max(0,user.cooldown-1);await setUser(username,user);return json({success:true,balance:user.balance,cooldown:user.cooldown})}
        return json({success:false,error:"not enough balance"})
    }
    if(action==="setBalance"){
        const val=Number(amount)
        if(isNaN(val)) return json({success:false,error:"invalid amount"})
        user.balance=val
        await setUser(username,user)
        return json({success:true,balance:user.balance})
    }
    if(!guess) return json({balance:user.balance,wins:user.wins,wrong:user.wrong,jackpot:state.jackpot})
    if(guess===state.code){
        const payout=state.jackpot
        user.balance+=payout
        user.wins+=1
        await setUser(username,user)
        const code=generateCode()
        await supabase.from("powerball").update({code,jackpot:BASE_JACKPOT,updated_at:new Date()}).eq("id",1)
        return json({valid:true,payout,balance:user.balance,wins:user.wins,wrong:user.wrong})
    }
    const newJackpot=state.jackpot+FAIL_INCREASE
    user.wrong+=1
    await setUser(username,user)
    await supabase.from("powerball").update({jackpot:newJackpot}).eq("id",1)
    return json({valid:false,jackpot:newJackpot,balance:user.balance,wins:user.wins,wrong:user.wrong})
}
