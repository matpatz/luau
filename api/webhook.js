// spam them all you want it has no affect on me
//        feels the aura
const webhooks = {
    // lucky block
    "662417684": "https://discord.com/api/webhooks/1538378199866540082/LQysSXzp1xxmt4SuH4X-pbUffH6l-EqKgxYPe4uUi89DTVFMeMk3Q3DTxSKV2KJpjrAo",
    // prospecting
    "129827112113663": "https://discord.com/api/webhooks/1538378617937989684/gu-a6ThfumuGQS5PSOiWHhJGjTOcJZsOnbXP8al0102INHDLq1blutObdOfn02vsjH6c",
    // answer or die
    "11966456877": "https://discord.com/api/webhooks/1538378532575641701/Zm2Hi0-Ppe90CMlllOjJBC6Tch1UCCJr2vWlxbS2vSfFy9jql5VaWIVRPKU900HEajBT",
    // Guess the Country Flag or Die
    "88817068170433": "https://discord.com/api/webhooks/1538378447989248030/KVqnM3B4bl_v1Q-lSiaBMGxcK4NMQ0r_qxIs0-RCXVE4zabXjKJGAVWeYCugQFEIY7mE",
    // Idle Blocks
    "101759436219635": "https://discord.com/api/webhooks/1538378365512454224/KEX1XjAaGLT3_ag7EKbxBInLSGmjhiDmL-0ThgEWTQikYL4Q0XWJHPv0iyJumSX1_qEm",
    // teen titan
    "3082002798": "https://discord.com/api/webhooks/1538377761046012005/gr1t-tHdm8lf9c8jHzyiaW4uWqKSmyeOQMD4YZFvoD0XAM-cfPwJdVLj7zNBGVC3ZNdu"
};

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).end();
  }

  try {
    // Force parse if it's a string
    let body = req.body;
    if (typeof body === "string") {
      body = JSON.parse(body);
    }

    const { username, executor, gname, placeid } = body;
    const webhookUrl = webhooks[String(placeid)];

    if (!webhookUrl) {
      return res.status(400).json({ ok: false });
    }

    await fetch(webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        content: `Username: ${username} | Executor: ${executor} | Game: ${gname} | PlaceId: ${placeid}`
      })
    });

    return res.status(200).json({ ok: true });
  } catch (e) {
    console.error("Error:", e);
    return res.status(500).json({ ok: false, error: e.message });
  }
}
