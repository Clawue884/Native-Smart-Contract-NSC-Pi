---

🌐 Pi Native Smart Contract (NSC) — Predictive Development Suite

Complete, Advanced, Modular, & Fully Developer-Ready

Selamat datang di Pi NSC Predictive Development Suite, sebuah proyek komprehensif yang memodelkan, memprediksi, dan mensimulasikan bagaimana Native Smart Contract (NSC) Pi Network kemungkinan bekerja—berdasarkan:

Pola kontrak PiChain V1/V2

Struktur ledger híbrida Pi

Model consensus SCP-modified

Pola desain Resource Oriented ala Move

Arsitektur WASM yang diduga digunakan Pi VM


Repository ini menyediakan kompiler, VM, bahasa prediksi (PiLang), contoh kontrak, SDK, pipeline, dan local testnet.


---

🏷️ Badges

![Status](https://img.shields.io/badge/status-active-green)
![Compiler](https://img.shields.io/badge/compiler-WASM-blue)
![Language](https://img.shields.io/badge/PiLang-resource--oriented-orange)
![VM](https://img.shields.io/badge/PiVM-sandbox-lightgrey)
![License](https://img.shields.io/badge/license-MIT-yellow)


---

🚀 Quickstart Instalasi

1️⃣ Clone Repository

git clone https://github.com/yourname/pi-nsc-project.git
cd pi-nsc-project

2️⃣ Instal Dependensi

Python – Compiler & PiVM

pip install -r requirements.txt

NodeJS – SDK & Tools

npm install


---

3️⃣ Build Compiler

python compiler/build.py

Output:

build/pilangc        # PiLang Compiler
build/pilang-ir      # Intermediate Representation Generator


---

4️⃣ Compile Kontrak

./build/pilangc contracts/PiToken.pi -o out/PiToken.wasm

Output:

out/PiToken.wasm
out/PiToken.json (ABI)


---

5️⃣ Jalankan PiVM

python vm/pivm.py --load out/PiToken.wasm --debug


---

6️⃣ Jalankan Test Suite

pytest tests


---

🧪 Menjalankan Kontrak di PiVM Lokal

Deploy module

python vm/pivm.py --deploy out/PiToken.wasm

Panggil fungsi

python vm/pivm.py --call PiToken::transfer --args "alice,bob,100"

Trace eksekusi

python vm/pivm.py --load out/PiToken.wasm --trace

Akan menampilkan:

Instruksi WASM

State perubahan storage

Event yang dikeluarkan

Gas usage



---

🛠 Deploy ke Testnet Lokal

Jalankan testnet 3-node

python tools/localnet.py --nodes 3

Node tersedia pada:

localhost:4301
localhost:4302
localhost:4303

Deploy kontrak ke node

python tools/deploy.py --node 4301 --wasm out/PiToken.wasm

Cek status kontrak

curl localhost:4301/contract/PiToken


---

🧬 Struktur Proyek

/
├─ compiler/            → Parser, AST, IR, WASM backend
├─ vm/                  → PiVM runtime
├─ contracts/           → Token, DEX, DAO, Lending, NFT
├─ sdk-js/              → JavaScript SDK
├─ sdk-py/              → Python SDK
├─ tools/               → Debugger, deployer, localnet
├─ tests/               → Unit, integration, fuzzing
├─ docs/                → Language spec & architecture
└─ out/                 → Compiled WASM + ABI


---

📘 Sintaks Bahasa NSC — PiLang

PiLang adalah bahasa smart contract prediktif untuk Pi Native Smart Contract.

Fitur:

Resource-Oriented (Move-like)

Safety-first borrow model

No global mutable state

Event-driven

Deterministic WASM output


Contoh fungsi transfer

public transfer(from: address, to: address, value: u64) {
  let b_from = ledger::borrow<Balance>(from);
  let b_to   = ledger::borrow<Balance>(to);

  assert(b_from.amount >= value, "Insufficient");

  b_from.amount -= value;
  b_to.amount   += value;

  event::emit("Transfer", from, to, value);
}


---

⚙️ Compiler Pipeline

PiLang (.pi)
    ↓
Parser → AST → Resource Checker → Type Checker
    ↓
Pi-IR (Intermediate Representation)
    ↓
WASM Generator
    ↓
module.wasm + metadata.json


---

🖥 PiVM — Virtual Machine

Fitur PiVM:

WASM sandbox engine

Deterministic compute model

Snapshot & rollback

Gas metering

Secure host API


Host API:

ledger::read / write
storage::read / write
event::emit
auth::verify
crypto::hash


---

🧪 Testing & Fuzzing

Menjalankan semua test:

pytest -n auto

Fuzz kontrak:

python tools/fuzzer.py contracts/PiDEX.pi


---

🛠 Integrasi SDK

JavaScript

import { PiContract } from "../sdk-js";

const token = new PiContract("out/PiToken.wasm");
await token.load();
await token.call("transfer", [alice, bob, 50]);

Python

from sdk_py import PiContract

c = PiContract("out/PiToken.wasm")
c.load()
c.call("transfer", ["alice", "bob", 50])


---

🧭 Workflow Developer Lengkap

1. Tulis kontrak di contracts/


2. Compile → WASM


3. Jalankan di PiVM


4. Unit testing


5. Fuzzing & audit


6. Debug dengan --trace


7. Integrasi via SDK


8. Deploy ke testnet lokal




---

🏛 Governance Model Prediktif

Developer submit module

Node menjalankan sandbox test

Komunitas voting (DAO-like)

Aktivasi kontrak on-chain



---

🔐 Best Practices & Keamanan

Hindari global mutable state

Pakai borrow-pattern resource

Gunakan safe-u64

No recursion

Emit event untuk trace



---

🗺 Roadmap

WASM backend optimization

PiVM JIT improvements

SDK v2

Testnet cluster v2

GUI Debugger



---

📄 Lisensi

MIT License


---

📬 Kontak

Diskusi & kolaborasi dapat dilakukan melalui GitHub Issues.


---
