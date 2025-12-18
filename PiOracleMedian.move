module PiNSC::PiOracleMedian {

    use std::signer;
    use std::vector;
    use std::event;

    /// ================================
    ///  STRUCTURES
    /// ================================

    struct OracleSet has key {
        feeders: vector<address>,
        min_feeders: u8,
    }

    struct PriceStore has key {
        prices: vector<u64>,
        last_update: u64,
    }

    struct MedianPrice has key {
        value: u64,
    }

    /// ================================
    ///  EVENTS
    /// ================================

    struct SubmitEvent has drop, store {
        feeder: address,
        price: u64,
    }

    struct MedianUpdateEvent has drop, store {
        median: u64,
    }

    /// ================================
    ///  INIT
    /// ================================

    public entry fun init(
        admin: &signer,
        feeders: vector<address>,
        min_feeders: u8
    ) {
        assert!(vector::length(&feeders) >= min_feeders, 1);

        move_to(
            admin,
            OracleSet { feeders, min_feeders }
        );

        move_to(
            admin,
            PriceStore {
                prices: vector::empty<u64>(),
                last_update: 0,
            }
        );

        move_to(
            admin,
            MedianPrice { value: 0 }
        );
    }

    /// ================================
    ///  FEED PRICE
    /// ================================

    public entry fun submit_price(
        feeder: &signer,
        price: u64,
        now: u64
    ) {
        let sender = signer::address_of(feeder);
        let oracle = borrow_global<OracleSet>(@0x1);

        assert!(is_authorized(sender, &oracle.feeders), 10);
        assert!(price > 0, 11);

        let store = borrow_global_mut<PriceStore>(@0x1);
        vector::push_back(&mut store.prices, price);
        store.last_update = now;

        event::emit(SubmitEvent {
            feeder: sender,
            price
        });

        if (vector::length(&store.prices) >= oracle.min_feeders) {
            let median = compute_median(&mut store.prices);
            borrow_global_mut<MedianPrice>(@0x1).value = median;

            vector::destroy_empty(store.prices);

            event::emit(
                MedianUpdateEvent { median }
            );
        }
    }

    /// ================================
    ///  VIEW
    /// ================================

    public fun get_price(): u64 {
        borrow_global<MedianPrice>(@0x1).value
    }

    /// ================================
    ///  INTERNAL
    /// ================================

    fun is_authorized(addr: address, feeders: &vector<address>): bool {
        let i = 0;
        while (i < vector::length(feeders)) {
            if (*vector::borrow(feeders, i) == addr) return true;
            i = i + 1;
        };
        false
    }

    fun compute_median(prices: &mut vector<u64>): u64 {
        sort(prices);
        let n = vector::length(prices);
        *vector::borrow(prices, n / 2)
    }

    fun sort(v: &mut vector<u64>) {
        let i = 0;
        while (i < vector::length(v)) {
            let j = i + 1;
            while (j < vector::length(v)) {
                let a = *vector::borrow(v, i);
                let b = *vector::borrow(v, j);
                if (a > b) {
                    *vector::borrow_mut(v, i) = b;
                    *vector::borrow_mut(v, j) = a;
                };
                j = j + 1;
            };
            i = i + 1;
        };
    }
}
