// Function to generate unique random numbers in a range
function generateNumbers(count, min, max) {
    const numbers = new Set();
    while (numbers.size < count) {
        const num = Math.floor(Math.random() * (max - min + 1)) + min;
        numbers.add(num);
    }
    return Array.from(numbers).sort((a, b) => a - b);
}

// Generate initial winning numbers
let winningNumbers = {
    main: generateNumbers(5, 1, 69), // 5 numbers from 1-69
    powerball: generateNumbers(1, 1, 26)[0] // Powerball number 1-26
};

console.log("Initial Winning Numbers:", winningNumbers);

// Function to check a ticket
function checkTicket(ticket) {
    const mainMatches = ticket.main.filter(n => winningNumbers.main.includes(n)).length;
    const powerballMatch = ticket.powerball === winningNumbers.powerball;

    console.log(`Your ticket: ${ticket.main} + ${ticket.powerball}`);
    console.log(`Matched ${mainMatches} numbers and Powerball match: ${powerballMatch}`);

    // If full match, generate new winning numbers
    if (mainMatches === 5 && powerballMatch) {
        console.log("🎉 Jackpot! Generating new winning numbers...");
        winningNumbers.main = generateNumbers(5, 1, 69);
        winningNumbers.powerball = generateNumbers(1, 1, 26)[0];
        console.log("New Winning Numbers:", winningNumbers);
    }
}

// Example ticket
const myTicket = { main: [3, 7, 47, 67, 68], powerball: 2 };
checkTicket(myTicket);
