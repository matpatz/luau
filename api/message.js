export default function handler(req, res) {
  const messages = [
    { Player: "Alice", Message: "Hello everyone!" },
    { Player: "Bob", Message: "Hey Alice!" }
  ];

  res.status(200).json(messages);
}
