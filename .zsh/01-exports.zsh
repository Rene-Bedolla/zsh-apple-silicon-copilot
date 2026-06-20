#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: 01-exports.zsh
# PROPÓSITO: Definición de variables de entorno y PATH de macOS
# ÚLTIMA REVISIÓN: 2026-06-09
# ==============================================================================

# ── 1. Idioma y Localización ───────────────────────────────────────────────────
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ── 2. PATH Principal (Homebrew va primero en Apple Silicon) ──────────────────
export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/Library/Apple/usr/bin

# ── 3. Python de Homebrew (3.11 — único intérprete activo) ────────────────────
if [[ -d "/opt/homebrew/opt/python@3.11/libexec/bin" ]]; then
  export PATH="/opt/homebrew/opt/python@3.11/libexec/bin:$PATH"
elif [[ -d "/opt/homebrew/opt/python@3.11/bin" ]]; then
  export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"
fi

# ── 3.1 FFmpeg Full (subtitles/libass) ────────────────────────────────────────
# Keg-only: se prioriza explícitamente para asegurar el filtro subtitles.
if [[ -d "/opt/homebrew/opt/ffmpeg-full/bin" ]]; then
  export PATH="/opt/homebrew/opt/ffmpeg-full/bin:$PATH"
fi

# ── 4. Scripts Públicos (Dotfiles) ────────────────────────────────────────────
export PATH="$HOME/Documents/dotfiles/scripts:$PATH"

# ── 5. Node Version Manager (nvm) ─────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && source "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \
  source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# ── 6. LM Studio CLI ──────────────────────────────────────────────────────────
export PATH="$PATH:$HOME/.lmstudio/bin"

# ── 7. Utilidades Locales ─────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
# ── 8. SDKMAN (Java/Groovy) ───────────────────────────────────────────────────
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# ── 9. Mantener PATH limpio de duplicados ─────────────────────────────────────
typeset -U PATH

# ── 10. HERMES — Modelo MLX activo ────────────────────────────────────────────
# Consumida por mlx-server-start.sh y hermes_model.zsh
# Perfil rápido por defecto: Qwen3.5-4B-OptiQ-4bit
export MLX_ACTIVE_MODEL="mlx-community/Qwen3.5-4B-OptiQ-4bit"
