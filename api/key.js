function generateKey() {
    return Math.random().toString(36).slice(2,12).toUpperCase();
}

app.get('/getkey', (req, res) => {
    const userId = req.query.userid;
    if (!userId) return res.status(400).send("No userId");

    if (!keys[userId]) keys[userId] = generateKey();
    res.send(keys[userId]);
});
