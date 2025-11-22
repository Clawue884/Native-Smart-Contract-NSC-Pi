# Native-Smart-Contract-NSC-Pi
Dokumen ini merupakan rekonstruksi teknis dan prediksi komprehensif untuk Native Smart Contract (NSC) Pi Network berdasarkan pola SC V1/V2 Testnet, arsitektur Pi (FBA), dan praktik desain bahasa kontrak modern (Move, Soroban, WASM-DSL). Ini bukan dokumentasi resmi Core Team — melainkan hasil analisis, asumsi teknis yang konsisten, dan contoh implementasi hipotetis untuk tujuan studi, pengujian, dan persiapan developer.


---

Ringkasan singkat

Tipe bahasa: WASM-based DSL / Resource-oriented DSL (mirip Move + Soroban)

Address format: pi:<bech32-like> atau account:xxxx (bukan 0x)

Tipe numerik: u64, u128 untuk token/amount

Model akuntansi: resource-safe (resource tidak bisa disalin), storage terstruktur (map/list)

Transaksi: tx.sender, tx.amount, tx.nonce, ledger::timestamp()

Eksekusi: tidak memakai gas tradisional; memakai execution budget / compute units

Keamanan: require/abort, no reentrancy by design, integer overflow safe



---

1. Prediksi Sintaks Bahasa NSC Pi (Spesimen)

> Catatan: sintaks ini bersifat prediktif; gunakan untuk eksperimen pseudocode dan desain kontrak.



1.1 Struktur modul/contract

module MyModule {
    // resource & types
    resource TokenBalance {
        owner: address;
        amount: u128;
    }

    // storage declarations
    storage balances: map<address, TokenBalance>;

    // initializer
    init() {
        balances = {};
    }

    // public entrypoint
    public fn mint(to: address, amount: u128) {
        require(tx.sender == admin, "unauthorized");
        ledger::credit(to, amount);
        event::emit("Mint", to, amount);
    }
}

1.2 Tipe data & deklarasi

u8, u16, u32, u64, u128

bool, string, address

map<K, V>, list<T>

resource Name { ... } — resource tidak boleh disalin; hanya dipindahkan


1.3 Function / Entrypoint

public fn transfer(to: address, amount: u128) {
    let from = tx.sender;
    ledger::debit(from, amount);
    ledger::credit(to, amount);
    event::emit("Transfer", from, to, amount);
}

1.4 Error handling & require

require(cond, "msg") — revert/abort transaksi

abort("msg") — hentikan eksekusi


1.5 Event

event::emit("Purchase", buyer, seller, id, price);

1.6 Storage access

storage name: map<...> global

akses storageName[key]

resource diambil / dikembalikan lewat operasi move semantics



---

2. Contoh Kontrak Lengkap (Prediksi)

2.1 Token (native token wrapper)

module PiToken {
    resource Balance { amount: u128 }
    storage balances: map<address, Balance>
    storage total_supply: u128

    init() { balances = {}; total_supply = 0; }

    public fn mint(to: address, amount: u128) {
        require(tx.sender == token_admin, "unauthorized");
        ledger::credit(to, amount);
        total_supply = total_supply + amount;
        event::emit("Mint", to, amount);
    }

    public fn transfer(to: address, amount: u128) {
        let from = tx.sender;
        ledger::debit(from, amount);
        ledger::credit(to, amount);
        event::emit("Transfer", from, to, amount);
    }
}

2.2 NFT (non-fungible resource)

module PiNFT {
    resource NFT { id: u64; owner: address; metadata: string }
    storage nfts: map<u64, NFT>
    storage next_id: u64

    init() { nfts = {}; next_id = 1; }

    public fn mint(to: address, metadata: string) -> u64 {
        let id = next_id;
        next_id = next_id + 1;
        nfts[id] = NFT { id: id, owner: to, metadata: metadata };
        event::emit("MintNFT", id, to);
        return id;
    }

    public fn transfer(id: u64, to: address) {
        let nft = nfts[id];
        require(nft.owner == tx.sender, "not owner");
        nft.owner = to;
        nfts[id] = nft;
        event::emit("TransferNFT", id, tx.sender, to);
    }
}

2.3 Marketplace

module Marketplace {
    resource Listing { id: u64; seller: address; price: u128; nft_id: u64; active: bool }
    storage listings: map<u64, Listing>
    storage next_listing: u64

    init() { listings = {}; next_listing = 1; }

    public fn create_listing(nft_id: u64, price: u128) -> u64 {
        let id = next_listing; next_listing = next_listing + 1;
        listings[id] = Listing { id: id, seller: tx.sender, price: price, nft_id: nft_id, active: true };
        event::emit("Created", id, tx.sender, price);
        return id;
    }

    public fn purchase(listing_id: u64) {
        let l = listings[listing_id];
        require(l.active, "not active");
        ledger::debit(tx.sender, l.price);
        ledger::credit(l.seller, l.price);
        // transfer NFT ownership (calls PiNFT.transfer) - cross-module call
        PiNFT::transfer(l.nft_id, tx.sender);
        l.active = false; listings[listing_id] = l;
        event::emit("Purchased", listing_id, tx.sender, l.seller);
    }
}

2.4 Lending (simplified)

module Lending {
    resource Loan { id: u64; borrower: address; amount: u128; collateral_nft: u64; due: u64 }
    storage loans: map<u64, Loan>
    storage next_loan: u64

    public fn borrow(collateral_nft: u64, amount: u128, duration_secs: u64) -> u64 {
        // transfer NFT to escrow
        PiNFT::transfer(collateral_nft, escrow_address);
        let id = next_loan; next_loan = next_loan + 1;
        loans[id] = Loan { id: id, borrower: tx.sender, amount: amount, collateral_nft: collateral_nft, due: ledger::timestamp() + duration_secs };
        ledger::credit(tx.sender, amount);
        event::emit("Borrow", id, tx.sender, amount);
        return id;
    }

    public fn repay(id: u64) {
        let loan = loans[id];
        require(loan.borrower == tx.sender, "not borrower");
        ledger::debit(tx.sender, loan.amount);
        // return collateral
        PiNFT::transfer(loan.collateral_nft, tx.sender);
        delete loans[id];
        event::emit("Repay", id);
    }
}

2.5 DAO governance (simplified)

module DAO {
    resource Proposal { id: u64; proposer: address; description: string; votes_for: u128; votes_against: u128; open: bool }
    storage proposals: map<u64, Proposal>
    storage next_proposal: u64

    public fn propose(description: string) -> u64 {
        let id = next_proposal; next_proposal = next_proposal + 1;
        proposals[id] = Proposal { id: id, proposer: tx.sender, description: description, votes_for: 0, votes_against: 0, open: true };
        event::emit("Proposed", id, tx.sender);
        return id;
    }

    public fn vote(id: u64, support: bool, weight: u128) {
        let p = proposals[id];
        require(p.open, "closed");
        if (support) { p.votes_for = p.votes_for + weight; } else { p.votes_against = p.votes_against + weight; }
        proposals[id] = p;
    }

    public fn finalize(id: u64) {
        let p = proposals[id]; require(p.proposer == tx.sender || tx.sender == dao_admin, "unauthorized");
        p.open = false; proposals[id] = p;
        event::emit("Finalized", id, p.votes_for, p.votes_against);
    }
}


---

3. Struktur Proyek & Tooling (Prediksi)

pi-nsc-project/
├─ contracts/                # source contracts (.pi or .nsc)
│  ├─ PiToken.pi
│  ├─ PiNFT.pi
│  └─ Marketplace.pi
├─ scripts/
│  ├─ deploy.js             # deployment scripts (CLI wrappers)
├─ tests/
│  ├─ token_tests.py
│  └─ marketplace_tests.py
├─ build/
│  └─ artifacts/            # compiled wasm, abi, metadata
├─ compiler/                # reference compiler front-end (optional)
│  └─ pi-compiler
├─ vm/                      # local VM runner for testing
├─ cli/                     # pi-cli tool
└─ README.md

3.1 Format file sumber

ekstensi .pi atau .nsc

compiler meng-output: module.wasm + metadata.json (ABI-like)


3.2 Artifacts

module.wasm — WASM binary

metadata.json — fungsi public, types, events

bytecode_hash — fingerprint



---

4. Compiler & Toolchain (Prediksi)

4.1 Arsitektur compiler

Front-end: parser -> AST -> type checker (resource checks, lifetime)

Middle: borrow checker/resource analyzer -> IR

Back-end: IR -> WASM (target WASM 1.0 with constrained imports)

Optimizer: remove dead code, gas/compute budget estimation

Metadata generator: function signatures, event schemas


4.2 Fitur compiler

Static analysis: deteksi resource leak, ownership violations

Security checks: integer overflow, uninitialized storage

Deterministic output for bytecode verification


4.3 CLI

pi-compile contract.pi -o build/module.wasm --metadata build/metadata.json

pi-deploy build/module.wasm --network testnet --from <account>

pi-call <module> <fn> --args ...



---

5. Virtual Machine (VM) Design — Runtime Pi NSC (Prediksi)

5.1 Tujuan VM

Eksekusi WASM-secure module

Enforcement resource semantics

Deterministic state transition

Compute budgeting (no gas market but limit per txn/block)


5.2 Komponen VM

Loader: verifikasi signature & fingerprint

Sandbox: pembatasan akses host (ledger, event, cross-module)

Resource Manager: track ownership & movement

Budget Meter: hitung compute units dan hentikan jika melebihi

Host functions: ledger::debit, ledger::credit, event::emit, storage::read, storage::write, timestamp


5.3 Security model

Memory safety via WASM

No arbitrary syscalls; hanya host APIs

Isolation antar module

Deterministic floating point banned (gunakan integer/math)



---

6. Deployment, Upgrade & Governance

6.1 Deployment flow (prediksi)

1. Dev compile -> produce module.wasm + metadata


2. Developer propose module to testnet deployment contract (signed tx)


3. Validators verify signature, deterministic bytecode


4. Module registered with module_id di ledger


5. Governance vote (untuk mainnet release)



6.2 Upgrade pattern

Immutable modules: versi tertentu immutable

Proxy pattern: module registry menunjuk ke implementasi (mirip upgradeable pattern) — tapi gunakan governance untuk update

Migration tool: state migrator untuk memindahkan storage ke versi baru



---

 Security Best Practices (untuk developer)

Gunakan require() untuk validasi input

Hindari logika yang bergantung pada timestamp untuk ekonomi sensitif

Audit cross-module calls untuk race conditions

Batasi akses storage private dengan modifier only_admin (pattern)

Gunakan testnet dan fuzzer (randomized testing)



---

 Testing & CI

Unit test via local VM runner (pi-vm run --module build/module.wasm --test ...)

Integration test dengan multiple node testnet cluster

Fuzzing untuk fungsi kritikal (transfer, mint, escrow)

Formal verification pada algoritma ekonomi (opsional)



---

9. Contoh Workflow Developer (singkat)

1. Tulis MyContract.pi


2. pi-compile MyContract.pi -o build/ -> artifacts


3. pi-testnet-deploy build/module.wasm --from <account>


4. Run test: pi-cli call MyContract::create --args ...


5. Submit governance proposal untuk mainnet release




---

10. Migration & Interoperability

Jembatan ke EVM via light-client / relayer (optional)

Oracles harus diadaptasi (off-chain aggregator yang feed ke on-chain host API)



---
Prediksi ABI / Metadata JSON (contoh)

{
  "module": "PiMarket",
  "functions": [
    {"name":"create_listing","args":[{"name":"nft_id","type":"u64"},{"name":"price","type":"u128"}],"returns":"u64"}
  ],
  "events": ["Created","Purchased"]
}


---

 Contoh Alat Pendukung (ecosystem)

pi-explorer — untuk melihat module registration, tx

pi-wallet-cli — sign & send tx

pi-sdk-js / pi-sdk-py — integrasi aplikasi

pi-audit — static security analyzer



---

 FAQ singkat

Q: Apakah ini resmi? A: Tidak. Ini prediksi teknis.

Q: Kenapa WASM? A: Portabilitas, keamanan memory, dan ekosistem tooling.

Q: Bagaimana memastikan kontrak asli? A: Lihat repo resmi, release tag, explorer, dan governance notice dari PCT.


---


2.4 Lending (simplified)

module Lending {
    resource Loan { id: u64; borrower: address; amount: u128; collateral_nft: u64; due: u64 }
    storage loans: map<u64, Loan>
    storage next_loan: u64

    public fn borrow(collateral_nft: u64, amount: u128, duration_secs: u64) -> u64 {
        // transfer NFT to escrow
        PiNFT::transfer(collateral_nft, escrow_address);
        let id = next_loan; next_loan = next_loan + 1;
        loans[id] = Loan { id: id, borrower: tx.sender, amount: amount, collateral_nft: collateral_nft, due: ledger::timestamp() + duration_secs };
        ledger::credit(tx.sender, amount);
        event::emit("Borrow", id, tx.sender, amount);
        return id;
    }

    public fn repay(id: u64) {
        let loan = loans[id];
        require(loan.borrower == tx.sender, "not borrower");
        ledger::debit(tx.sender, loan.amount);
        // return collateral
        PiNFT::transfer(loan.collateral_nft, tx.sender);
        delete loans[id];
        event::emit("Repay", id);
    }
}

2.5 DAO governance (simplified)

module DAO {
    resource Proposal { id: u64; proposer: address; description: string; votes_for: u128; votes_against: u128; open: bool }
    storage proposals: map<u64, Proposal>
    storage next_proposal: u64

    public fn propose(description: string) -> u64 {
        let id = next_proposal; next_proposal = next_proposal + 1;
        proposals[id] = Proposal { id: id, proposer: tx.sender, description: description, votes_for: 0, votes_against: 0, open: true };
        event::emit("Proposed", id, tx.sender);
        return id;
    }

    public fn vote(id: u64, support: bool, weight: u128) {
        let p = proposals[id];
        require(p.open, "closed");
        if (support) { p.votes_for = p.votes_for + weight; } else { p.votes_against = p.votes_against + weight; }
        proposals[id] = p;
    }

    public fn finalize(id: u64) {
        let p = proposals[id]; require(p.proposer == tx.sender || tx.sender == dao_admin, "unauthorized");
        p.open = false; proposals[id] = p;
        event::emit("Finalized", id, p.votes_for, p.votes_against);
    }
}

