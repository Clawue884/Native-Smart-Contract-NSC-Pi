
<!-- Banner -->
<p align="center">
  <img src="./assets/banner.png" alt="Pi NSC Banner" width="100%" />
</p>

<h1 align="center">🌐 Pi Native Smart Contract (NSC) — Predictive Development Suite</h1>
<p align="center">Modular • Advanced • Developer-Ready • Fully Predictive</p>

---

## 🚀 Deskripsi

Pi NSC Predictive Development Suite adalah kerangka kerja komprehensif untuk memodelkan, memprediksi, dan mensimulasikan bagaimana Native Smart Contract (NSC) Pi Network kemungkinan bekerja.

Toolkit ini dibangun berdasarkan:

- Pola kontrak PiChain V1/V2  
- Struktur ledger hybrid Pi  
- Konsensus modifikasi SCP  
- Resource-Oriented Programming (Move-like)  
- Backend WASM untuk PiVM  

Suite ini menyediakan:
Compiler, VM, Bahasa PiLang, SDK, Debugger, Local Testnet, Fuzzing Engine, dan contoh kontrak lengkap.

---

![Roadmap](https://img.shields.io/badge/Roadmap-Active-brightgreen?style=for-the-badge)
![Status](https://img.shields.io/badge/Development-In%20Progress-blue?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-0.1.0-orange?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-lightgrey?style=for-the-badge)

---


## 🚀 Instalasi & Quickstart

### 1️⃣ Clone Repository
```sh
git clone https://github.com/yourname/pi-nsc-project.git
cd pi-nsc-project

2️⃣ Instal Dependensi

Python

pip install -r requirements.txt

NodeJS

npm install

3️⃣ Build Compiler

python compiler/build.py

Output:

build/pilangc — PiLang Compiler

build/pilang-ir — IR Generator


4️⃣ Compile Kontrak

./build/pilangc contracts/PiToken.pi -o out/PiToken.wasm

5️⃣ Jalankan PiVM

python vm/pivm.py --load out/PiToken.wasm --debug

6️⃣ Jalankan Test Suite

pytest tests


---

🧪 Menjalankan Kontrak di PiVM Lokal

Deploy

python vm/pivm.py --deploy out/PiToken.wasm

Call

python vm/pivm.py --call PiToken::transfer --args "alice,bob,100"

Trace

python vm/pivm.py --load out/PiToken.wasm --trace


---

🛠 Deploy ke Local Testnet

Menjalankan 3 node

python tools/localnet.py --nodes 3

Node:

localhost:4301

localhost:4302

localhost:4303


Deploy kontrak

python tools/deploy.py --node 4301 --wasm out/PiToken.wasm


---

🧬 Struktur Proyek

/
├─ compiler/      # Parser, AST, IR, WASM backend
├─ vm/            # PiVM runtime
├─ contracts/     # Token, DEX, DAO, Lending, NFT
├─ sdk-js/        # JavaScript SDK
├─ sdk-py/        # Python SDK
├─ tools/         # Debugger, deployer, localnet
├─ tests/         # Unit, integration, fuzzing
├─ docs/          # Spec & architecture
└─ out/           # WASM output + ABI


---

📘 PiLang — Bahasa Smart Contract

Contoh fungsi transfer:

public transfer(from: address, to: address, value: u64) {
    let b_from = ledger::borrow(from);
    let b_to = ledger::borrow(to);

    assert(b_from.amount >= value, "Insufficient");

    b_from.amount -= value;
    b_to.amount += value;

    event::emit("Transfer", from, to, value);
}


---

⚙️ Compiler Pipeline

PiLang (.pi)
 ↓ Parser
 ↓ AST
 ↓ Resource Checker
 ↓ Type Checker
 ↓ Pi-IR
 ↓ WASM Generator
 → Output: module.wasm + metadata.json


---

🖥 PiVM — Virtual Machine

Fitur:

WASM Sandbox

Deterministic Execution

Gas Metering

State Snapshot & Rollback

Secure Host API


Host API:

ledger::read, write
storage::read, write
event::emit
auth::verify
crypto::hash


---

🧪 Testing & Fuzzing

pytest -n auto
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
