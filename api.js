// api/version.js
let versions = {
    "126884695634066": { version: 2, updated: "2025-08-31" },
    "53453465134142342": { version: 8, updated: "2025-08-31" }
};

const ADMIN_KEY = "Unknownpassword69";

export default async function handler(req, res) {
    res.setHeader("Content-Type", "text/plain"); // Important for loadstring

    if (req.method === "GET") {
        // Return the entire table as Lua code
        let luaString = "return " + JSON.stringify(versions)
            .replace(/"(\w+)":/g, "['$1'] =") // convert keys to Lua format
            .replace(/"version":/g, "version=")
            .replace(/"updated":/g, "updated=")
            .replace(/}/g, "}") // keep closing braces
        res.status(200).send(luaString);
    } 
    else if (req.method === "POST") {
        // Admin updates version
        try {
            const body = await json(req);
            const { key, placeid, version } = body;

            if (key !== ADMIN_KEY) return res.status(403).send("Unauthorized");
            if (!placeid || version === undefined) return res.status(400).send("Missing placeid or version");

            versions[placeid] = { version, updated: new Date().toISOString() };
            return res.status(200).send(`Version updated for placeId ${placeid}`);
        } catch {
            return res.status(400).send("Invalid JSON");
        }
    } 
    else {
        return res.status(405).send("Method not allowed");
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
