const WebSocket = require("ws");
const { exec } = require("child_process");

// powerhsell
const psServer = new WebSocket.Server({ port: 8080 });
psServer.on("connection", (ws) => {
    console.log("[PS] Client connected");
    ws.on("message", (message) => {
        exec(`powershell -Command "${message}"`, (err, stdout, stderr) => {
            ws.send(err ? `[ERROR] ${stderr || err.message}` : stdout || "[OK]");
        });
    });
    ws.send("[Server] PowerShell Connected");
});

// command prompt
const cmdServer = new WebSocket.Server({ port: 8081 });
cmdServer.on("connection", (ws) => {
    console.log("[CMD] Client connected");
    ws.on("message", (message) => {
        exec(`cmd /c "${message}"`, (err, stdout, stderr) => {
            ws.send(err ? `[ERROR] ${stderr || err.message}` : stdout || "[OK]");
        });
    });
    ws.send("[Server] CMD Connected");
});

console.log("powershell is running on : ws://localhost:8080");
console.log("cmd is running on : ws://localhost:8081");
