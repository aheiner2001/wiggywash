/// Client-side manager gate for a small internal team app.
/// Not bank-grade security — keeps employees from accidentally opening the dashboard.
const kManagerPassword = 'iggy';

bool verifyManagerPassword(String input) =>
    input.trim().toLowerCase() == kManagerPassword;
