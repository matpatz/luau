// who cares ig
const webhooks = {
    // lucky block
    "106931261124996": "https://discord.com/api/webhooks/1422373646013431828/HyqRzqTB787PqUj64ZYrOj7I17F-rJsIklH5AirX3-NHdayZK4b8p5d8Dx3i9K8YNzs-",
    // prospecting
    "129827112113663": "https://discord.com/api/webhooks/1422374009600741430/NFfvcty5NZPHOH4_sUZCJkOjz7n_99W3FMqlvSZkNout4Rb1Yb-n2WDYmRZllJMpfFPi",
    // answer or die
    "11966456877": "https://discord.com/api/webhooks/1422790373016735745/SLR6ujXdmNqNjtjeDTcm6Fsq2cP41jY20VFPd5Ol0n96ksHcta30etmzTDi7Spuqb968",
    // Guess the Country Flag or Die
    "88817068170433": "https://discord.com/api/webhooks/1422774328100913272/EY0fzME1MD1mhBH4TrPxm5fWjkkbNCLnPn_FQLcJ5lhlVSG-s7y1pwy4uAsoXm45Bg_K"
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
