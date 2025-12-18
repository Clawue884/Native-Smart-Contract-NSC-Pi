module PiNSC::PiOracle {

    use std::signer;
    use std::event;

    /// ================================
    ///  RESOURCES
    /// ================================

    /// Harga 1 aset dalam micro-USD (1e6)
    struct PriceFeed has key {
        price: u64,
        last_update: u64,
        feeder: address,
    }

    /// Global oracle config
    struct OracleConfig has key {
        dao: address,
        min_update_interval: u64,
    }

    /// ================================
    ///  EVENTS
    /// ================================

    struct PriceUpdateEvent has drop, store {
        asset: address,
        price: u64,
        feeder: address,
    }

    /// ================================
    ///  INIT
    /// ================================

    public entry fun init(
        admin: &signer,
        dao: address,
        min_update_interval: u64
    ) {
        move_to(
            admin,
            OracleConfig {
                dao,
                min_update_interval,
            }
        );
    }

    /// ================================
    ///  ADMIN / DAO CONTROL
    /// ================================

    /// Set feeder resmi (via DAO nanti)
    public entry fun register_asset(
        admin: &signer,
        asset: address,
        feeder: address
    ) {
        move_to(
            admin,
            PriceFeed {
                price: 0,
                last_update: 0,
                feeder,
            }
        );
    }

    /// ================================
    ///  FEED PRICE
    /// ================================

    public entry fun update_price(
        feeder: &signer,
        asset: address,
        new_price: u64,
        now: u64
    ) {
        let feed = borrow_global_mut<PriceFeed>(asset);
        let sender = signer::address_of(feeder);

        assert!(feed.feeder == sender, 100);
        assert!(new_price > 0, 101);

        feed.price = new_price;
        feed.last_update = now;

        event::emit(
            PriceUpdateEvent {
                asset,
                price: new_price,
                feeder: sender,
            }
        );
    }

    /// ================================
    ///  VIEW
    /// ================================

    public fun get_price(asset: address): u64 {
        borrow_global<PriceFeed>(asset).price
    }

    public fun last_update(asset: address): u64 {
        borrow_global<PriceFeed>(asset).last_update
    }
}
