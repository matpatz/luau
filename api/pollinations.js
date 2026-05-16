let rpm = 0;
let lreset = Math.floor(Date.now() / 1000);

async function prompt(text, options = {}) {
    const now = Math.floor(Date.now() / 1000);
    if (now - lreset >= 60) {
        rpm = 0;
        lreset = now;
    }
    if (rpm >= 4) {
        return "-- ratelimited";
    }
    rpm++;

    const { model = "openai-fast", temperature, thinking } = options;

    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 8000);

        const encoded = encodeURIComponent(text);
        const modelParam = `model=${model}`;
        const seedParam = `seed=${Math.floor(Math.random() * 9999)}`;

        const response = await fetch(
            `https://text.pollinations.ai/${encoded}?${modelParam}&${seedParam}&json=false`,
            {
                method: "GET",
                signal: controller.signal
            }
        );

        clearTimeout(timeoutId);

        if (!response.ok) {
            return "-- api error";
        }

        const content = await response.text();
        return content?.trim() || "-- no content returned";

    } catch (err) {
        if (err.name === "AbortError") {
            return "-- timeout";
        }
        console.error(err);
        return "-- request failed";
    }
}

module.exports = prompt;
