resource Proposal { id: u64; proposer: address; description: string; start_ts: u64; end_ts: u64; for_votes: u128; against_votes: u128; executed: bool }
    storage proposals: map<u64, Proposal>
    storage next_proposal_id: u64

    // Voting token/address weight is abstracted; assume token balances determine voting power via Host API
    storage voting_token: address
    storage min_quorum: u128    // minimal votes required

    init(token_addr: address, min_q: u128) {
        proposals = {};
        next_proposal_id = 1;
        voting_token = token_addr;
        min_quorum = min_q;
    }

    public fn propose(description: string, duration_secs: u64) -> u64 {
        let id = next_proposal_id; next_proposal_id = next_proposal_id + 1;
        let now = ledger::timestamp();
        proposals[id] = Proposal { id: id, proposer: tx.sender, description: description, start_ts: now, end_ts: now + duration_secs, for_votes: 0, against_votes: 0, executed: false };
        event::emit("Proposed", id, tx.sender, description);
        return id;
    }

    // Vote: weight determined by ledger::balance_of(voting_token, voter)
    public fn vote(proposal_id: u64, support: bool) {
        let p = proposals[proposal_id];
        require(p.id != 0, "proposal_not_found");
        let now = ledger::timestamp();
        require(now >= p.start_ts && now <= p.end_ts, "voting_closed");

        let weight = ledger::balance_of(voting_token, tx.sender); // host API provides token balance
        require(weight > 0, "no_voting_power");

        if (support) { p.for_votes = p.for_votes + weight; } else { p.against_votes = p.against_votes + weight; }
        proposals[proposal_id] = p;
        event::emit("Voted", proposal_id, tx.sender, support, weight);
    }

    // Tally and execute: only callable after end_ts; execution is abstracted via proposer or governance executor
    public fn execute(proposal_id: u64) {
        let p = proposals[proposal_id];
        require(p.id != 0, "proposal_not_found");
        require(!p.executed, "already_executed");
        let now = ledger::timestamp();
        require(now > p.end_ts, "voting_still_open");

        let total_votes = p.for_votes + p.against_votes;
        require(total_votes >= min_quorum, "quorum_not_met");
        require(p.for_votes > p.against_votes, "proposal_failed");

        // In a full implementation, execute on-chain changes via governance registry;
        // Here we simply mark executed and emit event. Actual action must be enforced by a governance relay.
        p.executed = true;
        proposals[proposal_id] = p;
        event::emit("Executed", proposal_id, p.proposer);
    }

}
