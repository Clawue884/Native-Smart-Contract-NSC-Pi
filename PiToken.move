module PiNSC::PiToken {

    use std::signer;
    use std::string;
    use std::event;

    /// ================================
    ///  RESOURCES
    /// ================================

    /// Global token metadata (1x only)
    struct TokenInfo has key {
        name: string::String,
        symbol: string::String,
        decimals: u8,
        total_supply: u64,
        mint_authority: address,
    }

    /// Balance per account
    struct Balance has key {
        amount: u64,
    }

    /// ================================
    ///  EVENTS
    /// ================================

    struct TransferEvent has drop, store {
        from: address,
        to: address,
        amount: u64,
    }

    struct MintEvent has drop, store {
        to: address,
        amount: u64,
    }

    /// ================================
    ///  INITIALIZATION
    /// ================================

    /// Deploy sekali saja
    public entry fun initialize(
        admin: &signer,
        name: string::String,
        symbol: string::String,
        decimals: u8,
        initial_supply: u64
    ) {
        let admin_addr = signer::address_of(admin);

        assert!(
            !exists<TokenInfo>(admin_addr),
            0
        );

        move_to(
            admin,
            TokenInfo {
                name,
                symbol,
                decimals,
                total_supply: initial_supply,
                mint_authority: admin_addr,
            }
        );

        move_to(
            admin,
            Balance {
                amount: initial_supply,
            }
        );

        event::emit(
            MintEvent {
                to: admin_addr,
                amount: initial_supply,
            }
        );
    }

    /// ================================
    ///  CORE FUNCTIONS
    /// ================================

    public entry fun transfer(
        sender: &signer,
        recipient: address,
        amount: u64
    ) {
        let sender_addr = signer::address_of(sender);

        let sender_balance = borrow_global_mut<Balance>(sender_addr);
        assert!(sender_balance.amount >= amount, 1);

        sender_balance.amount = sender_balance.amount - amount;

        if (!exists<Balance>(recipient)) {
            move_to(
                &create_signer(recipient),
                Balance { amount: 0 }
            );
        };

        let recipient_balance = borrow_global_mut<Balance>(recipient);
        recipient_balance.amount = recipient_balance.amount + amount;

        event::emit(
            TransferEvent {
                from: sender_addr,
                to: recipient,
                amount,
            }
        );
    }

    /// ================================
    ///  MINTING (ADMIN ONLY)
    /// ================================

    public entry fun mint(
        admin: &signer,
        to: address,
        amount: u64
    ) {
        let admin_addr = signer::address_of(admin);
        let info = borrow_global_mut<TokenInfo>(admin_addr);

        assert!(info.mint_authority == admin_addr, 2);

        info.total_supply = info.total_supply + amount;

        if (!exists<Balance>(to)) {
            move_to(
                &create_signer(to),
                Balance { amount: 0 }
            );
        };

        let bal = borrow_global_mut<Balance>(to);
        bal.amount = bal.amount + amount;

        event::emit(
            MintEvent {
                to,
                amount,
            }
        );
    }

    /// ================================
    ///  VIEW FUNCTIONS
    /// ================================

    public fun balance_of(owner: address): u64 {
        if (exists<Balance>(owner)) {
            borrow_global<Balance>(owner).amount
        } else {
            0
        }
    }

    public fun total_supply(admin: address): u64 {
        borrow_global<TokenInfo>(admin).total_supply
    }
}
