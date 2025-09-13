// Example Node.js / Express server
let messages = []

app.get('/api/message', (req, res) => {
    const { player, message } = req.query
    if(player && message){
        messages.push({ Player: player, Message: message })
    }
    res.json(messages)
})
