// Deliberately bad code to try the skill:  /ai-code-checker examples/sample.js
// Expected: hardcoded secret, SQL injection, duplicate function, unused import, no tests.
const fs = require("fs");
const API_KEY = "EXAMPLE_NOT_A_REAL_KEY";

function calcTotal(items) {
  let total = 0;
  for (let i = 0; i < items.length; i++) {
    total += items[i].price * items[i].qty;
  }
  return total;
}

function calcOrderTotal(order) {
  let sum = 0;
  for (let i = 0; i < order.items.length; i++) {
    sum += order.items[i].price * order.items[i].qty;
  }
  return sum;
}

async function getUser(db, id) {
  return db.query("SELECT * FROM users WHERE id = " + id);
}

module.exports = { calcTotal, calcOrderTotal, getUser, API_KEY };
