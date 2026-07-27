// spam them all you want it has no affect on me
//        feels the aura
const webhooks = {
    // lucky block
    "662417684": "https://discord.com/api/webhooks/1531439138597900509/8AoCPcECLJ82oQ22logS72TtqWZWjK34hsrcAjELHlAZx8l1j1B2egdscXFd0w8Mx0Se",
    // prospecting
    "129827112113663": "https://discord.com/api/webhooks/1531439267665154088/G0XGiQCMXF_DDii0iXUzaD1xvI6QGUZIoV9KS-2oFQzqHtjnOogNFWOpjDg5ALKRNRkF",
    // answer or die
    "11966456877": "https://discord.com/api/webhooks/1531439690480091177/j1AY2pwGRo_doV7gnKsUtlS9L7ymddV8lhRYGn29lM4_PzFrxtu7961UydJ7H9nhcLts",
    // Guess the Country Flag or Die
    "88817068170433": "https://discord.com/api/webhooks/1531439764245581834/bJsqvOIscNk-CAazZ6JD2V_9KwUBoxiY0l49nwH2RwMHD2UByr5xe9bUaRevf-ClfW1f",
    // Idle Blocks
    "101759436219635": "https://discord.com/api/webhooks/1502821413390913666/F7pOBvhXavuv8SHBlRY5bUtVcStj5aJZt12nJzFx3ijD1X5wAayD7TcLa1ezH3BovGTF",
    // teen titan
    "3082002798": "https://discord.com/api/webhooks/1531438831587561624/bt7gssxuo48ZSs5bw7G-8V_V27W2I_Aiq6qPZYQkD3YpVF4hWBfnAYF_GK1I3F4pZuWJ"
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
