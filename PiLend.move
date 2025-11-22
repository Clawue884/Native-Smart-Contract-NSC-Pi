// Loan resource
    resource Loan { id: u64; borrower: address; principal: u128; interest_rate_ppm: u32; collateral_token: address; collateral_amount: u128; start_ts: u64; due_ts: u64; repaid: bool }

    storage loans: map<u64, Loan>
    storage next_loan_id: u64

    // Platform parameters
    storage lending_token: address     // token used as quote (e.g., Pi stable/PI)
    storage min_collateral_ratio_ppm: u32  // e.g., 150% -> 1500000 ppm
    storage liquidation_penalty_ppm: u32

    init(quote_token: address, min_collateral_ppm: u32, liquidation_penalty: u32) {
        loans = {};
        next_loan_id = 1;
        lending_token = quote_token;
        min_collateral_ratio_ppm = min_collateral_ppm;
        liquidation_penalty_ppm = liquidation_penalty;
    }

    // Borrower pledges collateral (ERC20-like token) and borrows principal in lending_token
    public fn borrow(collateral_token: address, collateral_amount: u128, borrow_amount: u128, duration_secs: u64) -> u64 {
        require(collateral_amount > 0 && borrow_amount > 0, "invalid_amounts");

        // debit collateral from borrower
        ledger::debit(tx.sender, collateral_token, collateral_amount);

        // compute collateral value via oracle_host (assume host API returns price scaled to 1e6)
        let collateral_price_ppm = oracle::price(collateral_token, lending_token); // returns price * 1e6
        require(collateral_price_ppm > 0, "no_oracle_price");

        // collateral_value_in_quote = collateral_amount * collateral_price
        let collateral_value = (collateral_amount * collateral_price_ppm) / 1_000_000;

        // required collateral >= borrow_amount * min_collateral_ratio
        let required = (borrow_amount * (min_collateral_ratio_ppm as u128)) / 1_000_000u128;
        require(collateral_value >= required, "insufficient_collateral");

        // create loan
        let id = next_loan_id; next_loan_id = next_loan_id + 1;
        let now = ledger::timestamp();
        loans[id] = Loan { id: id, borrower: tx.sender, principal: borrow_amount, interest_rate_ppm: 50_000u32, collateral_token: collateral_token, collateral_amount: collateral_amount, start_ts: now, due_ts: now + duration_secs, repaid: false };

        // credit borrower with principal in lending token
        ledger::credit(tx.sender, lending_token, borrow_amount);

        event::emit("Borrowed", id, tx.sender, borrow_amount, collateral_token, collateral_amount);
        return id;
    }

    // Repay loan (principal only for simplicity; interest accrues separately)
    public fn repay(loan_id: u64) {
        let ln = loans[loan_id];
        require(ln.id != 0, "loan_not_found");
        require(!ln.repaid, "already_repaid");
        require(tx.sender == ln.borrower, "not_borrower");

        // borrower must pay principal + interest (simplified fixed rate)
        let now = ledger::timestamp();
        let duration = if (now > ln.start_ts) { now - ln.start_ts } else { 0 };
        // interest = principal * rate_ppm * duration_days / (365*1e6)
        let duration_days = duration / 86400u64;
        let interest = (ln.principal * (ln.interest_rate_ppm as u128) * (duration_days as u128)) / (365u128 * 1_000_000u128);
        let total_due = ln.principal + interest;

        // debit total due from borrower
        ledger::debit(tx.sender, lending_token, total_due);

        // return collateral
        ledger::credit(tx.sender, ln.collateral_token, ln.collateral_amount);

        // mark repaid
        ln.repaid = true; loans[loan_id] = ln;

        event::emit("Repaid", loan_id, tx.sender, total_due);
    }

    // Liquidation: anyone can liquidate if collateral value < required
    public fn liquidate(loan_id: u64) {
        let ln = loans[loan_id];
        require(ln.id != 0, "loan_not_found");
        require(!ln.repaid, "already_repaid");

        // compute collateral value now
        let collateral_price_ppm = oracle::price(ln.collateral_token, lending_token);
        require(collateral_price_ppm > 0, "no_oracle_price");
        let collateral_value = (ln.collateral_amount * collateral_price_ppm) / 1_000_000;

        let required = (ln.principal * (min_collateral_ratio_ppm as u128)) / 1_000_000u128;
        require(collateral_value < required, "not_liquidatable");

        // apply liquidation penalty and transfer collateral to liquidator (tx.sender)
        let penalty = (ln.collateral_amount * (liquidation_penalty_ppm as u128)) / 1_000_000u128;
        let out_collateral = ln.collateral_amount - penalty;

        // burn/mark loan as repaid via collateral liquidation
        ln.repaid = true; loans[loan_id] = ln;

        // transfer collateral to liquidator
        ledger::credit(tx.sender, ln.collateral_token, out_collateral);

        // platform keeps penalty (credited to platform treasury)
        ledger::credit(platform::treasury_address(), ln.collateral_token, penalty);

        event::emit("Liquidated", loan_id, tx.sender, out_collateral, penalty);
    }

}

