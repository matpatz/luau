const webhooks = {
  1087852616: "https://discord.com/api/webhooks/1387246480410148978/qD8vaCCGaXF7kxJ8QfmexV9N7Euq4omaaoWRrTlExf8FJQuAuS-hAr80sO92le3Jg8Z7",
  105938112304055: "https://discord.com/api/webhooks/1422373646013431828/HyqRzqTB787PqUj64ZYrOj7I17F-rJsIklH5AirX3-NHdayZK4b8p5d8Dx3i9K8YNzs-",
  13253735473: "https://discord.com/api/webhooks/1422373838729121824/WnlHIXUjazBFoq3LHguNQcxbScCFQNqchev378LaIrlxj0qjWTH2UDkvmxDIYU-M6WnX",
  129827112113663: "https://discord.com/api/webhooks/1422374009600741430/NFfvcty5NZPHOH4_sUZCJkOjz7n_99W3FMqlvSZkNout4Rb1Yb-n2WDYmRZllJMpfFPi",
  88817068170433: "https://discord.com/api/webhooks/1422774328100913272/EY0fzME1MD1mhBH4TrPxm5fWjkkbNCLnPn_FQLcJ5lhlVSG-s7y1pwy4uAsoXm45Bg_K",
  11966456877: "https://discord.com/api/webhooks/1422790373016735745/SLR6ujXdmNqNjtjeDTcm6Fsq2cP41jY20VFPd5Ol0n96ksHcta30etmzTDi7Spuqb968"
};

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  try {
    const secret = req.headers["x-webhook-secret"];
    if (process.env.WH_SECRET && secret !== process.env.WH_SECRET) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const { username, executor, placeId, game } = req.body || {};

    if (!placeId) return res.status(400).json({ error: "Missing placeId" });

    const webhookUrl = webhooks[placeId];
    if (!webhookUrl) return res.status(400).json({ error: "Unsupported PlaceId" });

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
