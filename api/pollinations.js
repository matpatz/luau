module.exports = async (req, res) => {
    let body = req.body;

    if (typeof body === "string") {
        try {
            body = JSON.parse(body);
        } catch {
            return res.status(400).send("-- invalid json");
        }
    }

    if (!body) {
        return res.status(400).send("-- missing body");
    }

    const {
        text,
        model = "openai-fast",
        temperature,
        thinking
    } = body;

    if (!text) {
        return res.status(400).send("-- missing text");
    }

    try {
        const payload = {
            model,

            messages: [
                {
                    role: "user",
                    content: text
                }
            ]
        };

        if (temperature !== undefined) {
            payload.temperature = temperature;
        }

        if (thinking !== undefined) {
            payload.thinking =
                typeof thinking === "boolean"
                    ? {
                        type: thinking
                            ? "enabled"
                            : "disabled"
                    }
                    : thinking;
        }

        const response = await fetch(
            "https://gen.pollinations.ai/v1/chat/completions",
            {
                method: "POST",
                headers: {
                    Authorization:
                        `Bearer ${process.env.pollinations}`,
        
                    "Content-Type": "application/json"
                },
        
                body: JSON.stringify(payload)
            }
        );

        const data = await response.json();

        if (!response.ok) {
            console.error(data);

            return res
                .status(response.status)
                .send(data?.error?.message || "-- api error");
        }

        return res.send(
            data?.choices?.[0]?.message?.content
                ?.trim() ||

            "-- no content returned"
        );

    } catch (err) {
        console.error(err);

        return res
            .status(500)
            .send("-- request failed");
    }
};
