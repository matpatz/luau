const data = {
  "Catastrophia": {
    version: 1,
    updated: "2025-09-01",
    status: "Functional",
    supported: ["Potassium","Delta","Xeno","Solara"],
    devs: {
      matpats: "B86F5628-12B8-4683-93C7-773F70D1A406",
      john: "thisisafakehwid"
    }
  },
  "game": {
    version: 2,
    updated: "2025-09-01",
    status: "Functional",
    supported: ["Potassium","Delta","Xeno","Solara"],
    devs: {
      matpats: "B86F5628-12B8-4683-93C7-773F70D1A406",
      tod: "realhwid1234"
    }
  }
};

export default function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.status(200).json(data);
}
