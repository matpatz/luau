module.exports = async (req, res) => {
    let body = req.body;

    if (typeof body === "string") {
        try { body = JSON.parse(body); } catch { return res.status(400).send("-- invalid json"); }
    }

    if (!body) return res.status(400).send("-- missing body");

    const { text, model = "openai-fast" } = body;
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
