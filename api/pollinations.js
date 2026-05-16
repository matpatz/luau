let rpm = 0;
let lreset = Math.floor(Date.now() / 1000);

async function prompt(text) {
    const now = Math.floor(Date.now() / 1000);

    if (now - lreset >= 60) {
        rpm = 0;
        lreset = now;
    }

    if (rpm >= 4) {
        return "-- ratelimited";
    }

    rpm++;

    try {
        const response = await fetch("https://gen.pollinations.ai/v1/chat/completions", {
            method: "POST",
            headers: {
                Authorization: `Bearer ${process.env.pollinations}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                model: "qwen-coder",
                messages: [
                    {
                        role: "user",
                        content: text
                    }
                ]
            })
        });

        const data = await response.json();

        return (
            data?.choices?.[0]?.message?.content ||
            "-- no content returned"
        );
    } catch (err) {
        console.error(err);
        return "-- request failed";
    }
}

module.exports = prompt;
