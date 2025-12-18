// ===================================================== // MODULE: Liquidation – Lending Position Liquidation // Target: Pi Network Native Smart Contract (NSC) // =====================================================

address 0xPI {

module Liquidation { use 0xPI::LendingPool; use 0xPI::PriceOracle; use 0xPI::PiToken;

/// Liquidation threshold (120%)
const LIQ_THRESHOLD: u64 = 120;
/// Liquidation bonus for liquidator (5%)
const LIQ_BONUS: u64 = 5;

struct LiquidationEvent has store {
    borrower: address,
    liquidator: address,
    repaid: u64,
    seized_collateral: u64,
}

/// Check whether a position is liquidatable
public fun is_liquidatable(borrower: address): bool {
    let pos = borrow_global<LendingPool::Position>(borrower);
    let price = PriceOracle::read();
    let collateral_value = pos.collateral * price;
    let required = pos.debt * LIQ_THRESHOLD / 100;
    collateral_value < required
}

/// Perform liquidation
public fun liquidate(liquidator: &signer, borrower: address, repay_amount: u64) {
    assert!(is_liquidatable(borrower), 10);

    let pos = borrow_global_mut<LendingPool::Position>(borrower);
    assert!(repay_amount <= pos.debt, 11);

    // Liquidator pays borrower debt
    PiToken::transfer(liquidator, @0xPI, repay_amount);
    pos.debt = pos.debt - repay_amount;

    // Calculate collateral to seize
    let price = PriceOracle::read();
    let base_collateral = repay_amount / price;
    let bonus = base_collateral * LIQ_BONUS / 100;
    let seize = base_collateral + bonus;

    assert!(seize <= pos.collateral, 12);
    pos.collateral = pos.collateral - seize;

    // Transfer seized collateral to liquidator
    PiToken::transfer(&create_signer(@0xPI), signer::address_of(liquidator), seize);

    // Emit liquidation event (placeholder)
    // event::emit(LiquidationEvent { borrower, liquidator: signer::address_of(liquidator), repaid: repay_amount, seized_collateral: seize });
}

}

} // end address
