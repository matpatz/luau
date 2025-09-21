function getRandomBananaColor() {
    // Generate a yellow tone with some variance
    const r = Math.floor(200 + Math.random() * 55); // 200-255
    const g = Math.floor(200 + Math.random() * 55); // 200-255
    const b = Math.floor(Math.random() * 50);       // 0-50
    return `rgb(${r},${g},${b})`;
}

function generateBanana() {
    const rarities = ["Common", "Uncommon", "Rare", "Epic", "Sigma"];
    const rarityMultiplier = { "Common": 1, "Uncommon": 1.5, "Rare": 2, "Epic": 3, "Sigma": 5 };

    const Rarity = rarities[Math.floor(Math.random() * rarities.length)];
    const Curveyness = +(Math.random() * 10).toFixed(2); // 0-10
    const Length = Math.floor(Math.random() * 16) + 15;   // 15-30
    const Patches = Math.floor(Math.random() * 11);       // 0-10
    const Weight = +(Math.random() * 0.5 + 0.5).toFixed(2); // 0.5-1kg
    const Color = getRandomBananaColor();

    // Value formula based on stats
    const value = Math.floor(
        (Length * 2 + Curveyness * 10 + Weight * 50 - Patches * 5) * rarityMultiplier[Rarity]
    );

    return {
        id: Math.floor(Math.random() * 1e6),
        Color,
        Patches,
        Rarity,
        Curveyness,
        Length,
        Weight,
        value
    };
}
