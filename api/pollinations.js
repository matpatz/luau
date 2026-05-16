let rpm = 0;
let lreset = Math.floor(Date.now() / 1000);

/**
 * @param {string} text
 * @param {Object} options
 * @param {string} [options.model]
 * @param {number} [options.temperature]
 * @param {boolean|Object} [options.thinking]
 */
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
    
    const {
        model = "qwen-coder",
        temperature,
        thinking
    } = options;
    
    const body = {
        model,
        messages: [
            {
                role: "user",
                content: text
            }
        ],
        stream: false // Explicitly disable streaming for faster response
    };
    
    if (temperature !== undefined) {
        body.temperature = temperature;
    }
    if (thinking !== undefined) {
        body.thinking =
            typeof thinking === "boolean"
                ? {
                    type: thinking ? "enabled" : "disabled"
                }
                : thinking;
    }
    
    try {
        // Add timeout wrapper
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 8000); // 8 second timeout
        
        const response = await fetch(
            "https://gen.pollinations.ai/v1/chat/completions",
            {
                method: "POST",
                headers: {
                    Authorization: `Bearer ${process.env.pollinations}`,
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(body),
                signal: controller.signal
            }
        );
        
        clearTimeout(timeoutId);
        
        if (!response.ok) {
            return "-- api error";
        }
        
        const data = await response.json();
        return (
            data?.choices?.[0]?.message?.content ||
            "-- no content returned"
        );
    } catch (err) {
        if (err.name === 'AbortError') {
            console.error('Request timeout');
            return "-- timeout";
        }
        console.error(err);
        return "-- request failed";
    }
}

module.exports = prompt;
