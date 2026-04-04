// who cares ig
const webhooks = {
    // lucky block
    106931261124996: "https://discord.com/api/webhooks/1422373646013431828/HyqRzqTB787PqUj64ZYrOj7I17F-rJsIklH5AirX3-NHdayZK4b8p5d8Dx3i9K8YNzs-",
    // prospecting
    129827112113663: "https://discord.com/api/webhooks/1422374009600741430/NFfvcty5NZPHOH4_sUZCJkOjz7n_99W3FMqlvSZkNout4Rb1Yb-n2WDYmRZllJMpfFPi",
    // answer or die
    11966456877: "https://discord.com/api/webhooks/1422790373016735745/SLR6ujXdmNqNjtjeDTcm6Fsq2cP41jY20VFPd5Ol0n96ksHcta30etmzTDi7Spuqb968",
    // Guess the Country Flag or Die
    88817068170433: "https://discord.com/api/webhooks/1422774328100913272/EY0fzME1MD1mhBH4TrPxm5fWjkkbNCLnPn_FQLcJ5lhlVSG-s7y1pwy4uAsoXm45Bg_K"
};

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  try {
    const { username, executor, placeId, game } = req.body || {};

    const webhookUrl = webhooks[placeId];
    if (!webhookUrl) {
      return res.status(400).json({ error: "No webhook for this placeId" });
    }

    const payload = {
      content: `Username: ${username} | Executor: ${executor} | Game: ${game} | PlaceId: ${placeId}`
    };

    const response = await fetch(webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });

    return res.status(200).json({ status: "success", discordStatus: response.status });
  } catch (err) {
    console.error("Webhook failed:", err);
    return res.status(500).json({ error: "Failed to send webhook" });
  }
}
