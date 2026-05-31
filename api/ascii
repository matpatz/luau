const express = require("express")
const axios = require("axios")
const sharp = require("sharp")

const app = express()
app.use(express.json())

const chars = "@%#*+=-:. "

function mapBrightness(v) {
    const index = Math.floor((v / 255) * (chars.length - 1))
    return chars[index]
}

app.get("/ascii", async (req, res) => {
    try {
        const url = req.query.url
        if (!url) return res.json({ error: "no url" })

        const response = await axios.get(url, { responseType: "arraybuffer" })

        const image = sharp(response.data)
        const { data, info } = await image
            .resize(60, 30) // ASCII resolution
            .grayscale()
            .raw()
            .toBuffer({ resolveWithObject: true })

        let ascii = ""
        for (let i = 0; i < data.length; i++) {
            ascii += mapBrightness(data[i])
            if ((i + 1) % info.width === 0) ascii += "\n"
        }

        res.json({ ascii })
    } catch (e) {
        res.json({ error: e.message })
    }
})

app.listen(3000, () => console.log("ASCII API running"))
