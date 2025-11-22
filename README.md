# Native-Smart-Contract-NSC-Pi
---

📌 Visi Proyek

Menyediakan toolchain end-to-end untuk NSC Pi, meliputi:

Bahasa khusus Pi (PiLang) — resource-oriented, modular, aman.

Compiler lengkap: PiLang → IR → WASM → Metadata.

PiVM — runtime deterministik untuk menjalankan bytecode.

SDK JS & Python untuk integrasi dengan aplikasi.

Contoh kontrak on-chain (Token, NFT, DEX, Lending, DAO).

Test-suite, fuzzer, dan static-analyzer.

Dokumentasi lengkap dan developer onboarding.



---

🧬 5️⃣ Kompilasi Kontrak

Contoh untuk kontrak PiToken:

./build/pilangc contracts/PiToken.pi -o out/PiToken.wasm

Output:

out/
 ├─ PiToken.wasm   → bytecode siap eksekusi
 └─ PiToken.json   → ABI (Application Binary Interface)


---

💻 6️⃣ Jalankan PiVM Lokal

python vm/pivm.py --load out/PiToken.wasm

VM akan menjalankan kontrak secara lokal di sandbox environment.

Kamu bisa menambahkan flag opsional:

python vm/pivm.py --load out/PiToken.wasm --debug --trace


---

🧪 7️⃣ Jalankan Test Suite

pytest tests

Atau jalankan semua test secara paralel:

pytest -n auto


---

🔍 8️⃣ Verifikasi Hasil Build

Gunakan perintah di bawah untuk memastikan semua file berhasil dibuat dengan benar:

tree -L 2 build/ out/

Atau gunakan tools bawaan:

python tools/check_build.py


---

🧠 9️⃣ Developer Shortcuts

Untuk mempercepat workflow, gunakan alias berikut di terminal:

alias pi-build='python compiler/build.py && ./build/pilangc contracts/PiToken.pi -o out/PiToken.wasm'
alias pi-run='python vm/pivm.py --load out/PiToken.wasm'
alias pi-test='pytest tests'

Dengan begitu, kamu hanya perlu menjalankan:

pi-build && pi-run && pi-test


---

✅ 10️⃣ TL;DR (Ringkasan Cepat)

git clone https://github.com/yourname/pi-nsc-project.git
cd pi-nsc-project
pip install -r requirements.txt
npm install
python compiler/build.py
./build/pilangc contracts/PiToken.pi -o out/PiToken.wasm
python vm/pivm.py --load out/PiToken.wasm
pytest tests

📦 Hasil akhir: Kontrak PiToken berhasil dikompilasi, dieksekusi di PiVM, dan seluruh test lulus ✅


---

Selanjutnya kamu bisa lanjut ke:

📘 docs/getting_started.md untuk belajar struktur kode PiLang.

🧩 contracts/examples/ untuk melihat kontrak lain seperti NFT, DAO, dan DEX.

🧰 tools/ untuk debugging, inspeksi bytecode, dan analisis gas.


> 💡 Tip: Jalankan python tools/devmenu.py untuk menggunakan interactive developer console — mode cepat bagi developer untuk kompilasi & deploy kontrak langsung dari terminal.



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
🏗️ Arsitektur Utama

┌───────────────────────────────────────────────┐
│                 Application Layer              │
│  (dApps, Wallets, Marketplaces, Merchant API)  │
└───────────────────────────────────────────────┘
                 ▼
┌───────────────────────────────────────────────┐
│                Pi SDK (JS / Py)               │
│      - Contract interaction                   │
│      - WASM loader                            │
│      - Signing & transaction builder          │
└───────────────────────────────────────────────┘
                 ▼
┌───────────────────────────────────────────────┐
│              PiVM (Runtime Engine)            │
│  - WASM Execution                             │
│  - Host API (ledger, storage, events)         │
│  - Deterministic compute                      │
└───────────────────────────────────────────────┘
                 ▼
┌───────────────────────────────────────────────┐
│                  Smart Contracts              │
│          (PiToken, NFT, DEX, DAO)             │
└───────────────────────────────────────────────┘
                 ▼
┌───────────────────────────────────────────────┐
│                   Blockchain Layer            │
│      - Nodes, Consensus, Ledger State         │
└───────────────────────────────────────────────┘


---

🔧 Struktur Repo

/
├─ compiler/            → Parser, AST, Type Checker, IR, WASM Backend
├─ vm/                  → PiVM runtime
├─ contracts/           → Sample contracts (Token, NFT, DAO, DEX)
├─ sdk-js/              → Javascript SDK
├─ sdk-py/              → Python SDK
├─ tests/               → Unit, integration, fuzz testing
├─ tools/               → Auditor, bytecode inspector, runtime debugger
├─ explorer/            → Mini block explorer for local testnet
├─ docs/                → Language spec, tutorials, API reference
└─ ROADMAP.md           → Roadmap resmi proyek


---

🧬 Bahasa NSC: PiLang (Prediksi)

PiLang merupakan bahasa kontrak pintar prediktif untuk Pi Network. Karakteristik:

Resource-Oriented (anti-duplicasi seperti Move)

Event-driven

Module-based

WASM-compiled

Deterministic execution


Contoh Sintaks PiLang (Token)

module PiToken {

  resource Balance {
    amount: u64
  }

  public init(owner: address, supply: u64) {
    ledger::create_resource(owner, Balance { amount: supply });
  }

  public transfer(from: address, to: address, value: u64) {
    let b_from = ledger::borrow<Balance>(from);
    let b_to   = ledger::borrow<Balance>(to);

    assert(b_from.amount >= value, "Insufficient balance");

    b_from.amount -= value;
    b_to.amount   += value;

    event::emit("Transfer", from, to, value);
  }
}


---

⚙️ Compiler Pipeline

Pipeline compiler:

PiLang (.pi)
    ▼
Parser → AST
    ▼
Type Checker + Resource Checker
    ▼
IR (Pi-IR)
    ▼
WASM Generator
    ▼
module.wasm + metadata.json

Fitur utama:

Deterministic compilation

Bytecode hashing untuk governance & upgrade

ABI generation untuk SDK



---

🖥️ PiVM — Virtual Machine

PiVM adalah runtime yang mengeksekusi WASM dengan host API:

ledger::read / write

events::emit

storage::set / get

auth::verify

crypto hashing

timestamp


Fitur keamanan:

Sandboxed WASM

Gas/compute model

Deterministic execution

State isolation



---

🧪 Test Suite

Test-suite lengkap mencakup:

Unit test untuk compiler & VM

Integration test untuk contoh kontrak

Fuzzer (mutasi input → cari crash)

Static Analyzer (pi-audit)


Contoh test:

assert_exec("transfer", args=[alice, bob, 100])
assert_balance(bob) == 100


---

🛠️ SDK Integration

JavaScript

Mendukung:

Load WASM

Generate transaction

Sign with Pi Wallet

Submit to local/testnet node


Python

Cocok untuk backend & automation:

Contract call helpers

WASM inspector

Test runner



---

🏛️ Governance & Module Lifecycle

Model governance prediktif:

1. Developer submit module (signed).


2. Nodes menjalankan verifikasi & sandbox test.


3. DAO vote untuk registrasi module.


4. Deployment ke mainnet staging.


5. Final activation.




---

🚀 Contoh Kontrak Produksi

Repositori ini menyediakan contoh lengkap:

PiToken — token standar

PiNFT — non-fungible token

PiDEX — decentralized exchange

PiLend — lending/borrowing

PiDAO — governance

Marketplace — escrow & orderbook


Setiap kontrak memiliki:

Sumber .pi

WASM compile output

metadata.json (ABI)

Unit test

Integration test



---

📡 Node & Consensus (Analisis Prediktif)

Pi Network tampaknya menggunakan:

Federated consensus mirip Stellar

Constraint Ledger (ALGO-like) untuk validasi state

Deterministic transaction ordering

Node sandbox untuk smart contract


Kontrak tidak dijalankan oleh validator penuh → PiVM terpisah sebagai layer execution.


---

🧭 Roadmap

Daftar lengkap roadmap ada di file: ROADMAP.md

Highlight:

✔ Bahasa v1 draft

✔ Compiler front-end

☐ PiVM runtime

☐ WASM backend

☐ SDK JS & Python

☐ Contoh kontrak produksi

☐ Testnet local cluster

☐ Auditor tool

☐ Mainnet-ready release



---

🤝 Kontribusi

Kami mendorong kontribusi komunitas:

Tambah kontrak baru

Audit code

Perbaiki compiler

Buat tutorial

Tambahkan test



---

🔐 Status Keamanan

⚠ Semua komponen masih dalam tahap prediktif dan tidak aman untuk digunakan di jaringan produksi.


---

📄 Lisensi

MIT License — bebas digunakan, diubah, dan dikembangkan oleh komunitas.


---

💬 Kontak & Dukungan

Untuk diskusi, ide, atau kolaborasi:

Issues (GitHub)

Diskusi komunitas Pi



