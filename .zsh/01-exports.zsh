#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: 01-exports.zsh
# PROPÓSITO: Definición de variables de entorno y PATH de macOS
# ÚLTIMA REVISIÓN: 2026-05-04
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

# ── 4. Scripts Públicos (Dotfiles) ────────────────────────────────────────────
export PATH="$HOME/Documents/dotfiles/scripts:$PATH"

# ── 5. Node Version Manager (nvm) ─────────────────────────────────────────────
# Gestión de versiones de Node.js — instalado via Homebrew
# Node activo: v24.15.0 LTS (requerido por coc.nvim y herramientas modernas)
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && source "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \
  source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# ── 6. LM Studio CLI ──────────────────────────────────────────────────────────
# CLI de LM Studio — presente en PATH aunque no esté activo actualmente
export PATH="$PATH:$HOME/.lmstudio/bin"

# ── 7. Utilidades Locales ─────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── 8. SDKMAN (Java/Groovy) ───────────────────────────────────────────────────
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# ── 9. Mantener PATH limpio de duplicados ─────────────────────────────────────
typeset -U PATH
