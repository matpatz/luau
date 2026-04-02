const WebSocket = require("ws");
const { exec } = require("child_process");

const wss = new WebSocket.Server({ port: 8080 });

wss.on("connection", (ws) => {
    console.log("Luau client connected");

    ws.on("message", (message) => {
        console.log("Received request:", message);

        // executes the users command via powershell
        exec(`powershell -Command "${message}"`, (err, stdout, stderr) => {
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

console.log("powershell is running on : ws://localhost:8080");
