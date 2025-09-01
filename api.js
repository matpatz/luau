let versions = {
    "126884695634066": 2,
    "53453465134142342": 8
};

const ADMIN_KEY = "Unknownpassword69";

export default async function handler(req, res) {
    if (req.method === "GET") {
        const { placeid } = req.query;
        if (!placeid) return res.status(400).json({ error: "Missing placeid" });

        const version = versions[placeid];
        if (version === undefined) return res.status(404).json({ error: "PlaceId not found" });

        return res.status(200).json({ placeid, version });
    } 
    else if (req.method === "POST") {
        try {
            const body = await json(req);
            const { key, placeid, version } = body;

            if (key !== ADMIN_KEY) return res.status(403).json({ error: "Unauthorized" });
            if (!placeid || version === undefined) return res.status(400).json({ error: "Missing placeid or version" });

            versions[placeid] = version;
            return res.status(200).json({ message: "Version updated", placeid, version });
        } catch {
            return res.status(400).json({ error: "Invalid JSON" });
        }
    } 
    else {
        return res.status(405).json({ error: "Method not allowed" });
    }
}

async function json(req) {
    return new Promise((resolve, reject) => {
        let body = "";
        req.on("data", chunk => body += chunk);
        req.on("end", () => {
            try { resolve(JSON.parse(body)); } 
            catch (e) { reject(e); }
        });
    });
}
