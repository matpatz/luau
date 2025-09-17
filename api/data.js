const data = {
  "53453": {
    version: 1,
    updated: "2025-09-01",
    status: "Functional",
    supported: ["Potassium", "Delta", "Xeno", "Solara"],
    devs: {
      matpats: "B86F5628-12B8-4683-93C7-773F70D1A406",
      john: "thisisafakehwid"
    }
  },
  "34535353": {
    version: 2,
    updated: "2025-09-01",
    status: "Functional",
    supported: ["Potassium", "Delta", "Xeno", "Solara"],
    devs: {
      matpats: "B86F5628-12B8-4683-93C7-773F70D1A406",
      tod: "realhwid1234"
    }
  },
  "Owned": {
    devs: {
      matpats: "B86F5628-12B8-4683-93C7-773F70D1A406",
      alt: "B86Fef28-12B8-4683-93C7-773F70D1A406"
    }
  }
};

export default function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.status(200).json(data);
}
