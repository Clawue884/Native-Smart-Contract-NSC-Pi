// Resource representing a liquidity position (for LP shares)
    resource LPToken { owner: address; shares: u128 }

    // Pool state
    resource Pool { token_a: address; token_b: address; reserve_a: u128; reserve_b: u128; total_shares: u128; fee_ppm: u32 }

    // Storage
    storage pools: map<u64, Pool>
    storage lp_tokens: map<u64, LPToken>    // lp_id -> LPToken resource
    storage next_pool_id: u64

    // Events
    // "PoolCreated", pool_id, token_a, token_b
    // "AddLiquidity", pool_id, provider, added_a, added_b, minted_shares
    // "RemoveLiquidity", pool_id, provider, out_a, out_b, burned_shares
    // "Swap", pool_id, sender, in_token, in_amount, out_token, out_amount

    init() {
        pools = {};
        lp_tokens = {};
        next_pool_id = 1;
    }

    // Create pool: deployer must be governance or factory admin in practice
    public fn create_pool(token_a: address, token_b: address, fee_ppm: u32) -> u64 {
        require(token_a != token_b, "identical_tokens");
        let id = next_pool_id; next_pool_id = next_pool_id + 1;
        pools[id] = Pool { token_a: token_a, token_b: token_b, reserve_a: 0, reserve_b: 0, total_shares: 0, fee_ppm: fee_ppm };
        event::emit("PoolCreated", id, token_a, token_b);
        return id;
    }

    // Add liquidity: caller must transfer tokens to pool via ledger::debit (host manages balances)
    public fn add_liquidity(pool_id: u64, amount_a: u128, amount_b: u128) -> u128 {
        let p = pools[pool_id];
        require(p.token_a != 0 && p.token_b != 0, "pool_not_exists");
        require(amount_a > 0 && amount_b > 0, "zero_amount");

        // debit funds from provider
        ledger::debit(tx.sender, p.token_a, amount_a);
        ledger::debit(tx.sender, p.token_b, amount_b);

        // Calculate minted shares
        let minted: u128 = 0;
        if (p.total_shares == 0) {
            // First liquidity provider: use geometric mean
            minted = sqrt_u128(amount_a * amount_b);
        } else {
            // proportional to existing reserves
            let share_a = (amount_a * p.total_shares) / p.reserve_a;
            let share_b = (amount_b * p.total_shares) / p.reserve_b;
            require(share_a == share_b, "unequal_value_added");
            minted = share_a;
        }

        require(minted > 0, "insufficient_mint");

        // Update reserves & total shares
        p.reserve_a = p.reserve_a + amount_a;
        p.reserve_b = p.reserve_b + amount_b;
        p.total_shares = p.total_shares + minted;
        pools[pool_id] = p;

        // mint LP token resource
        let lp_id = hash_u64(tx.sender, pool_id, ledger::timestamp());
        lp_tokens[lp_id] = LPToken { owner: tx.sender, shares: minted };

        event::emit("AddLiquidity", pool_id, tx.sender, amount_a, amount_b, minted);
        return minted;
    }

    // Remove liquidity
    public fn remove_liquidity(pool_id: u64, lp_id: u64) {
        let p = pools[pool_id];
        require(p.total_shares > 0, "no_shares");
        let lp = lp_tokens[lp_id];
        require(lp.owner == tx.sender, "not_owner_lp");
        let burned = lp.shares;
        require(burned > 0, "zero_shares");

        // compute amounts out proportional
        let out_a = (burned * p.reserve_a) / p.total_shares;
        let out_b = (burned * p.reserve_b) / p.total_shares;

        // update pool
        p.reserve_a = p.reserve_a - out_a;
        p.reserve_b = p.reserve_b - out_b;
        p.total_shares = p.total_shares - burned;
        pools[pool_id] = p;

        // burn LP
        delete lp_tokens[lp_id];

        // credit user
        ledger::credit(tx.sender, p.token_a, out_a);
        ledger::credit(tx.sender, p.token_b, out_b);

        event::emit("RemoveLiquidity", pool_id, tx.sender, out_a, out_b, burned);
    }

    // Swap: in_token must be token_a or token_b. AMM constant-product x*y=k, fee applied.
    public fn swap(pool_id: u64, in_token: address, in_amount: u128, min_out: u128) -> u128 {
        let p = pools[pool_id];
        require(in_amount > 0, "zero_amount");
        require(in_token == p.token_a || in_token == p.token_b, "invalid_token");

        // Debit input from trader
        ledger::debit(tx.sender, in_token, in_amount);

        // assign variables
        let reserve_in: u128; let reserve_out: u128; let out_token: address;
        if (in_token == p.token_a) {
            reserve_in = p.reserve_a; reserve_out = p.reserve_b; out_token = p.token_b;
        } else {
            reserve_in = p.reserve_b; reserve_out = p.reserve_a; out_token = p.token_a;
        }

        // apply fee
        let fee_ppm = p.fee_ppm; // parts per million
        let amount_in_with_fee = in_amount * (1_000_000 - fee_ppm) / 1_000_000;

        // constant product formula: out = (amount_in_with_fee * reserve_out) / (reserve_in + amount_in_with_fee)
        let numerator = amount_in_with_fee * reserve_out;
        let denominator = reserve_in + amount_in_with_fee;
        let amount_out = numerator / denominator;
        require(amount_out > 0, "insufficient_out");
        require(amount_out >= min_out, "slippage_exceeded");

        // update reserves
        if (in_token == p.token_a) {
            p.reserve_a = p.reserve_a + in_amount;
            p.reserve_b = p.reserve_b - amount_out;
        } else {
            p.reserve_b = p.reserve_b + in_amount;
            p.reserve_a = p.reserve_a - amount_out;
        }
        pools[pool_id] = p;

        // credit output token to trader
        ledger::credit(tx.sender, out_token, amount_out);

        event::emit("Swap", pool_id, tx.sender, in_token, in_amount, out_token, amount_out);
        return amount_out;
    }

    // Helper sqrt for u128 (integer sqrt)
    fn sqrt_u128(x: u128) -> u128 {
        let r: u128 = 1;
        let last: u128 = 0;
        while (r != last) {
            last = r;
            r = (r + (x / r)) / 2;
        }
        return r;
    }
}
