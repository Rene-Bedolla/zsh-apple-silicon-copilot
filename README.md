<div align="center">
  <h1>🚀 Zsh Apple Silicon Copilot</h1>
  <p><b>A zero-friction, modular Zsh environment supercharged with Local Offline AI for Mac.</b></p>
  <a href="README_es.md">🇲🇽/🇪🇸 Leer en Español</a>
  <br><br>
</div>

![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Zsh](https://img.shields.io/badge/Zsh-111?style=for-the-badge&logo=gnubash&logoColor=white)
![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M1%2FM2%2FM3%2FM4-blue?style=for-the-badge)

Unlike traditional dotfiles, this repository is designed exclusively for **Apple Silicon Macs**. It leverages the [Apple MLX framework](https://github.com/ml-explore/mlx) to run a Local AI Developer Copilot directly on your machine—no API keys, no subscriptions, 100% offline and blazingly fast.

## 📦 One-Click Installation

Open your Mac terminal and paste this command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Rene-Bedolla/zsh-apple-silicon-copilot/main/install.sh)"
```

*This script is safe. It will install Homebrew (if missing), required tools (`eza`, `bat`, `zoxide`), and securely back up your existing `.zshrc` before applying the new configuration.*

---

## 🛠️ Complete Command Reference

*Note: This project was born in the LATAM tech community. Some core commands are in Spanish, but they are intuitive and fully explained below. AI outputs default to Spanish, but you can easily translate the prompts in `~/.zsh/funciones/dev_copilot.zsh` to output in English.*

### 🧠 1. Local AI Developer Copilot (Powered by MLX)
These commands use local LLMs (like Qwen3) to assist your development workflow offline.

| Command | Meaning | Description |
| :--- | :--- | :--- |
| `explicar "<cmd>"` | Explain | Breaks down complex shell commands or errors. E.g., `explicar "tar -xzvf file.tar.gz"` |
| `git-ia` | Git AI | Reads your `git diff` and generates 3 professional Conventional Commit message options. |
| `procesar-minuta` | Process Minutes | AI tool to extract action items, summaries, and critical points from transcription texts. |

### 📝 2. Universal Quick Capture (Markdown Notes)
A frictionless system to save ideas directly from the terminal to a daily markdown inbox (`~/.notas_inbox`).

| Command | Meaning | Description |
| :--- | :--- | :--- |
| `nota "<text>"` | Note | Saves a timestamped bullet point to today's inbox. E.g., `nota "Fix the CSS bug"` |
| `leer-notas` | Read Notes | Renders today's captured notes in the terminal using `bat`. |

### 🍏 3. macOS Optimization & Maintenance
Commands to speed up your operating system and maintain your dev environment.

| Command | Meaning | Description |
| :--- | :--- | :--- |
| `macos-tweaks` | macOS Tweaks | Interactive menu to apply "Hacker Defaults" (faster keyboard, instant dock, show hidden files). Includes a revert option. |
| `actualizar` | Update | One-shot command to run `brew update && brew upgrade`. |
| `limpiar` | Clean | Deep cleans Homebrew cache and removes orphaned packages. |
| `refresco` | Refresh | Instantly reloads the `.zshrc` configuration without closing the terminal. |
| `respaldo-cold`| Cold Backup | Generates a portable `.zip` backup of your entire configuration on your Desktop. |

### 🎙️ 4. Media & Transcription (MLX-Whisper)
Built-in aliases for processing audio/video using Apple Silicon's unified memory.

| Command | Description |
| :--- | :--- |
| `transcribir-video <file>` | Extracts audio and generates an `.srt` subtitle file using Whisper base model. |
| `transcribir-rápido <file>`| Same as above but uses the ultra-fast `tiny` model. |
| `traducir-srt` | Translates `.srt` files locally keeping timestamps intact. |

### 🚀 5. Modern CLI Replacements
The environment replaces legacy Unix commands with modern, Rust-based alternatives automatically:
- `ls` / `ll` / `la` → Aliased to **`eza`** (Includes icons, git status, and colors).
- `cat` → Aliased to **`bat`** (Syntax highlighting and line numbers).
- `cd` → Enhanced by **`zoxide`** (Type `z folder_name` to jump instantly).

---

## 🏗️ Modular Architecture
This setup uses a dynamic modular architecture. Drop any `.zsh` script inside the `~/.zsh/funciones/` folder, and it will be auto-loaded upon opening the terminal. Private configurations can be placed in `~/Documents/dotfiles/privado/` (which is git-ignored by default).

*Crafted with ❤️ by [René Bedolla](https://github.com/Rene-Bedolla).*
