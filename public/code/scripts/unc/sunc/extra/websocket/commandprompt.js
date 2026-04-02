const WebSocket = require("ws");
const { exec } = require("child_process");

const wss = new WebSocket.Server({ port: 8081 });

wss.on("connection", (ws) => {
    console.log("Luau client connected");

    ws.on("message", (message) => {
        console.log("Received request:", message);

        // command prompt execution
        exec(`cmd /c "${message}"`, (err, stdout, stderr) => {
            if (err) {
                ws.send(`[ERROR] ${stderr || err.message}`);
                return;
            }
            ws.send(stdout || "[OK]");
        });
    });

    ws.on("close", () => {
        console.log("Client disconnected");
    });

    ws.send("We are now interlinked");
});

console.log("command prompt is running on : ws://localhost:8081");
