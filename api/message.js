let messages = [];

export default function handler(req, res) {
  const { player, message } = req.query;

  if (player && message) {
    const now = new Date();
    const stamp = now.toLocaleString("en-US", {
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false
    }).replace(",", "");

    messages.push({
      Date: stamp,      // "09/19 21:20"
      Player: player,
      Message: message
    });

    if (messages.length > 50) messages.shift(); // keep last 50
  }

  res.setHeader("Content-Type", "application/json");
  res.status(200).json(messages);
}
