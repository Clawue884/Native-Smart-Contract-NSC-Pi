module PiNSC::PiLiquidation {

    use std::signer;
    use PiNSC::PiOracleMedian;
    use PiNSC::PiLend;

    /// ================================
    ///  CONSTANTS
    /// ================================

    const MIN_COLLATERAL_RATIO: u64 = 150; // %
    const LIQUIDATION_BONUS: u64 = 10;     // %

    /// ================================
    ///  LIQUIDATION
    /// ================================

    public entry fun liquidate(
        liquidator: &signer,
        borrower: address
    ) {
        let price = PiOracleMedian::get_price();
        assert!(price > 0, 300);

        let pos = borrow_global_mut<PiLend::Position>(borrower);

        let collateral_value = pos.collateral * price;
        let debt_value = pos.debt * price;

        let ratio = collateral_value * 100 / debt_value;
        assert!(ratio < MIN_COLLATERAL_RATIO, 301);

        // Calculate seized collateral
        let bonus = pos.collateral * LIQUIDATION_BONUS / 100;
        let seized = pos.collateral + bonus;

        // Reset borrower position
        pos.collateral = 0;
        pos.debt = 0;

        // Reward liquidator (simplified)
        if (!exists<PiLend::Position>(signer::address_of(liquidator))) {
            move_to(
                liquidator,
                PiLend::Position { collateral: 0, debt: 0 }
            );
        };

        borrow_global_mut<PiLend::Position>(
            signer::address_of(liquidator)
        ).collateral += seized;
    }
}
