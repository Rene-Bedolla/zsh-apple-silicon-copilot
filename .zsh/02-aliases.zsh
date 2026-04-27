#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: 02-aliases.zsh
# PROPÓSITO: Atajos de teclado y comandos de uso frecuente (VERSIÓN PÚBLICA)
# ==============================================================================

# ─── Sistema y Homebrew ───────────────────────────────────────────
alias actualizar='brew update && brew upgrade'
alias instalar='brew install'
alias limpiar='brew cleanup && brew autoremove && brew cleanup'
alias refresco='source ~/.zshrc'
alias pingoogle='ping 8.8.8.8'

# ─── Herramientas del Entorno Zero-Friction ───────────────────────
alias respaldo-cold='generar_cold_backup'
alias macos-tweaks='~/Documents/dotfiles/scripts/macos_tweaks.sh'

# ─── Navegación y CLI Visual (eza + bat) ──────────────────────────
alias cat='bat --paging=never'
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first --git'
alias tree='eza --tree --icons'
alias treef='eza --tree --icons'

# ─── Python (Homebrew) ────────────────────────────────────────────
alias python=/opt/homebrew/opt/python@3.11/libexec/bin/python3
alias python3=/opt/homebrew/opt/python@3.11/libexec/bin/python3
alias pip=/opt/homebrew/opt/python@3.11/libexec/bin/pip3

# ─── IA y Automatización Pública (MLX) ────────────────────────────
# FIX: Nueva ruta al script de traducción en dotfiles
alias traducir-srt='python3 ~/Documents/dotfiles/scripts/translate_srt.py'
alias transcribir-video='extraerSubs'
alias transcribir-rápido='extraerSubs $1 tiny'

alias procesar-minuta='mlx_lm.generate --model mlx-community/Qwen3-8B-4bit --max-tokens 2000 --temp 0.1 --prompt "Actúa como un analista experto. Lee la siguiente transcripción y extrae de forma estructurada: 1) Resumen (3 viñetas), 2) Tareas asignadas, 3) Puntos críticos. Mantén la objetividad estricta sin inventar datos: "'


# -------------------------------------------------------------------
# cal → carl
# Descripción: Sustituye cal por carl con colores y soporte iCal.
#              calagenda muestra los eventos de los próximos 30 días.
# Uso: cal [args] | calagenda
# -------------------------------------------------------------------
alias cal='carl'
alias calagenda='carl -n 3 --agenda'

# ── Xcode / Desarrollo iOS ──────────────────────────────────────────
alias xdev="cd /Volumes/T7/Developer/Xcode"
alias xproj="cd /Volumes/T7/Developer/Xcode/Proyectos"
alias xdemos="cd /Volumes/T7/Developer/Xcode/Demos"
alias xsand="cd /Volumes/T7/Developer/Xcode/Sandbox"
