/// Client-side manager gate for a small internal team app.
/// Not bank-grade security — keeps employees from accidentally opening the dashboard.
const kManagerPassword = 'iggy';

/// Saved on manager profiles — managers don't enter a personal name.
const kManagerDisplayName = 'Manager';

bool verifyManagerPassword(String input) =>
    input.trim().toLowerCase() == kManagerPassword;
