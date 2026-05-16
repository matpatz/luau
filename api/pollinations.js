let rpm = 0;
let lreset = Math.floor(Date.now() / 1000);

module.exports = async (req, res) => {
    const now = Math.floor(Date.now() / 1000);
    if (now - lreset >= 60) {
        rpm = 0;
        lreset = now;
    }
    if (rpm >= 4) {
        return res.status(429).send("-- ratelimited");
    }
    rpm++;

    const { text, model = "openai-fast", temperature, thinking } = req.body;

    if (!text) return res.status(400).send("-- missing text");

    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 8000);

        const response = await fetch(
            `https://text.pollinations.ai/${encodeURIComponent(text)}?model=${model}&seed=${Math.floor(Math.random() * 9999)}&json=false`,
            { method: "GET", signal: controller.signal }
        );

        clearTimeout(timeoutId);

        if (!response.ok) return res.status(500).send("-- api error");

        const content = await response.text();
        res.send(content?.trim() || "-- no content returned");

    } catch (err) {
        if (err.name === "AbortError") return res.status(504).send("-- timeout");
        console.error(err);
        res.status(500).send("-- request failed");
    }
};
