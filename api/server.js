const express = require("express");
const { Pool } = require("pg");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

// 🔑 replace with your real DB URL
const pool = new Pool({
  connectionString: process.env.supabaseUrl
});

// GET all positions
app.get("/pos", async (req, res) => {
  const result = await pool.query("SELECT name, x, y FROM click_positions");

  const formatted = {};
  result.rows.forEach(row => {
    formatted[row.name] = { x: row.x, y: row.y };
  });

  res.json(formatted);
});

// UPDATE position
app.post("/pos/:name", async (req, res) => {
  const { x, y } = req.body;

  await pool.query(
    "UPDATE click_positions SET x=$1, y=$2 WHERE name=$3",
    [x, y, req.params.name]
  );

  res.sendStatus(200);
});

app.listen(3000, () => console.log("API running"));
