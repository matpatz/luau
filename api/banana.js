import { MongoClient } from "mongodb";

const client = new MongoClient(process.env.MONGO_URI);

export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).end();

  const { userId } = req.body;
  await client.connect();
  const db = client.db("bananadb");
  const users = db.collection("users");

  // Generate banana
  const banana = {
    color: ["Yellow", "Golden", "Green", "Spotted"][Math.floor(Math.random() * 4)],
    patches: Math.floor(Math.random() * 10),
    rarity: ["Bum", "Sigma"][Math.floor(Math.random() * 2)],
    curveyness: Math.random().toFixed(2),
    length: (Math.random() * 10).toFixed(2),
    weight: (Math.random() * 5).toFixed(2),
    value: Math.floor(Math.random() * 100)
  };

  // Save to user
  await users.updateOne(
    { userId },
    { $push: { bananas: banana }, $setOnInsert: { cash: 0 } },
    { upsert: true }
  );

  res.json({ banana });
}
