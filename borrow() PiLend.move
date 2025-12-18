use PiNSC::PiOracle;

public entry fun borrow(user: &signer, amount: u64) {
    let addr = signer::address_of(user);
    let pos = borrow_global_mut<Position>(addr);

    let price = PiOracle::get_price(@PiToken);
    let collateral_value = pos.collateral * price;
    let debt_value = amount * price;

    // 200% collateral ratio
    assert!(collateral_value >= debt_value * 2, 200);

    pos.debt += amount;
    borrow_global_mut<Vault>(@0x1).total_borrow += amount;
}
