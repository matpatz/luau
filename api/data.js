export default function handler(req, res) {
  res.status(200).json([
    {
      player: "TestPlayer",
      userid: 123456,
      killcode: "KS001",
      timestamp: Date.now()
    },
    {
      player: "AnotherPlayer",
      userid: 654321,
      killcode: "KS002",
      timestamp: Date.now()
    }
  ]);
}
