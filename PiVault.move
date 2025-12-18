module PiNSC::PiVault {
    use std::signer;

    struct Treasury has key {
        balance: u64,
        dao: address,
    }

    public entry fun init(admin: &signer, dao: address) {
        move_to(admin, Treasury { balance: 0, dao });
    }

    public entry fun deposit(user: &signer, amount: u64) {
        borrow_global_mut<Treasury>(@0x1).balance += amount;
    }
}
