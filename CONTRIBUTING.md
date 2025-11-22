
# 🤝 Contributing to Native-Smart-Contract-NSC-Pi

Terima kasih telah tertarik berkontribusi pada **Native Smart Contract (NSC) Pi — Predictive Development Suite**.  
Proyek ini bertujuan membangun model prediktif lengkap untuk Native Smart Contract Pi Network, termasuk compiler, VM, PiLang, toolchain, dan contoh kontrak.

Kontribusi Anda sangat berarti untuk memperkuat ekosistem Pi Developer.

---

## 🧭 Prinsip Umum Kontribusi

Sebelum membuat perubahan, pastikan bahwa kontribusi Anda:

- Sejalan dengan visi proyek  
- Menambah kualitas, stabilitas, keamanan, atau developer-experience  
- Mengikuti standar kode dalam repository  
- Tidak melanggar lisensi, hak cipta, atau regulasi Pi Network  

Jika ragu, silakan buka **Discussion** atau **Issue** sebelum membuat Pull Request.

---

## 📌 Cara Berkontribusi

### 1. Fork Repository
Klik **Fork** untuk membuat salinan repo ke akun Anda.

### 2. Clone Repo Anda
```bash
git clone https://github.com/<username>/Native-Smart-Contract-NSC-Pi
cd Native-Smart-Contract-NSC-Pi

3. Buat Branch Baru

Gunakan nama branch yang jelas:

git checkout -b feature/pilang-optimizer

Contoh lain:

fix/pivm-gas-metering

docs/update-readme

test/add-dex-fuzzer

feature/pylang-compiler-enhancement



---

🛠 Panduan Kontribusi Kode

1. Ikuti Struktur Direktori

compiler/     → Parser, AST, IR, WASM backend
vm/           → PiVM runtime
contracts/    → Smart contract samples
sdk-js/       → JavaScript SDK
sdk-py/       → Python SDK
tools/        → Debugger, deployer, localnet
tests/        → Unit, integration, fuzzing
docs/         → Dokumentasi & spesifikasi

2. Standar Penulisan Kode

PiLang

Resource-oriented approach (Move-like)

Tidak menggunakan global mutable state

Hindari recursion

Emit event untuk setiap perubahan state


Python / Compiler

Ikuti PEP8

Berikan komentar pada logic penting

Minimal satu unit test untuk setiap perubahan modul compiler


JavaScript / SDK

Ikuti ES Modules

Gunakan async/await

Tambahkan JSDoc



---

🔍 Testing

Sebelum membuat Pull Request, jalankan semua test:

pytest -n auto

Untuk test kontrak tertentu:

pytest tests/test_pilang_token.py

Fuzzing:

python tools/fuzzer.py contracts/PiDEX.pi

Pull Request tanpa test akan diminta revisi.


---

🧪 Menjalankan Local Testnet

Jika perubahan Anda terkait VM, storage, ledger, atau host API, jalankan localnet:

python tools/localnet.py --nodes 3

Deploy kontrak untuk pengujian:

python tools/deploy.py --node 4301 --wasm out/PiToken.wasm


---

✔ Checklist Sebelum PR

Pastikan:

[ ] Kode telah diformat sesuai standar

[ ] Tidak ada warning kritis

[ ] Semua test lulus

[ ] Dokumentasi diperbarui (jika perlu)

[ ] Komentar kode sudah jelas

[ ] PR Anda hanya fokus pada satu fitur / fix



---

📬 Membuat Pull Request

1. Push branch Anda:

git push origin feature/nama-fitur


2. Buat Pull Request ke:

main


3. Sertakan:

Deskripsi yang jelas

Screenshot / logs (jika relevan)

Dampak perubahan

Penjelasan technical decision





---

🤝 Aturan Diskusi & Etika

Hargai kontribusi developer lain

Gunakan bahasa yang sopan

Kritik harus bersifat membangun

Jangan memaksa timeline atau keputusan maintainer



---

🔐 Keamanan

Jika Anda menemukan celah keamanan: JANGAN buat issue publik.
Silakan laporkan secara private ke:

📧 security@nsc-pi.dev (placeholder – ganti jika diperlukan)


---

📄 Lisensi

Dengan berkontribusi, Anda menyetujui bahwa kontribusi Anda dirilis di bawah MIT License.


---

⭐ Terima kasih

Kontribusi Anda membantu membangun ekosistem developer Pi Network yang lebih besar, lebih aman, dan lebih inovatif.

Mari kita bangun NSC Pi bersama-sama. 🚀

---
