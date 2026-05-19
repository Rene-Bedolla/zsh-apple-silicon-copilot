#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: 02-aliases.zsh
# PROPÓSITO: Atajos de teclado y comandos de uso frecuente (VERSIÓN PÚBLICA)
# ÚLTIMA REVISIÓN: 2026-05-05
# ==============================================================================

# ─── Sistema y Homebrew ───────────────────────────────────────────────────────
alias actualizar='brew update && brew upgrade'
alias instalar='brew install'
alias limpiar='brew cleanup && brew autoremove && brew cleanup'
alias refresco='source ~/.zshrc'
alias pingoogle='ping 8.8.8.8'

# ─── Herramientas del Entorno Zero-Friction ───────────────────────────────────
alias respaldo-cold='generar_cold_backup'
alias macos-tweaks='~/Documents/dotfiles/scripts/macos_tweaks.sh'

# ─── Navegación y CLI Visual (eza + bat) ──────────────────────────────────────
alias cat='bat --paging=never'
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first --git'
alias tree='eza --tree --icons'
alias treef='eza --tree --icons'

# ─── Editor de Texto ──────────────────────────────────────────────────────────
# neovim: sucesor moderno de vim, config en dotfiles/config/nvim/
alias vim='nvim'
alias vi='nvim'

# ─── Python (Homebrew 3.11 — intérprete único activo) ─────────────────────────
alias python=/opt/homebrew/opt/python@3.11/libexec/bin/python3
alias python3=/opt/homebrew/opt/python@3.11/libexec/bin/python3
alias pip=/opt/homebrew/opt/python@3.11/libexec/bin/pip3

# ─── IA y Automatización Pública (MLX) ────────────────────────────────────────
alias traducir-srt='python3 ~/Documents/dotfiles/scripts/translate_srt.py'
alias transcribir-video='extraerSubs'
alias transcribir-rápido='extraerSubs $1 tiny'
alias procesar-minuta='mlx_lm.generate --model mlx-community/Qwen3-8B-4bit --max-tokens 2000 --temp 0.1 --prompt "Actúa como un analista experto. Lee la siguiente transcripción y extrae de forma estructurada: 1) Resumen (3 viñetas), 2) Tareas asignadas, 3) Puntos críticos. Mantén la objetividad estricta sin inventar datos: "'

# ─── Calendario (carl) ────────────────────────────────────────────────────────
alias cal='carl'
alias calagenda='carl -n 3 --agenda'

# ─── Xcode / Desarrollo iOS ───────────────────────────────────────────────────
alias xdev="cd /Volumes/T7/Developer/Xcode"
alias xproj="cd /Volumes/T7/Developer/Xcode/Proyectos"
alias xdemos="cd /Volumes/T7/Developer/Xcode/Demos"
alias xsand="cd /Volumes/T7/Developer/Xcode/Sandbox"


# ─── HERMES Harness ───────────────────────────────────────────────────────────
# Orquestador IA personal — Mac Mini M4, Python 3.11, MLX
# Dashboard: http://192.168.1.243:8421  |  Proxy NAS: https://renbedolla.synology.me/hermes
# Docs: ~/Documents/dotfiles/hermes/README.md

# ── Ciclo de vida del harness ─────────────────────────────────────────────────
alias hermes-init='bash ~/Documents/dotfiles/hermes/init.sh'
alias hermes-tareas='python3 ~/Documents/dotfiles/hermes/agents/orchestrator.py --listar'
alias hermes-run='python3 ~/Documents/dotfiles/hermes/agents/orchestrator.py'
alias hermes-status='hermes-init && mlx-status && hermes-router-status'

# ── Dashboard web — puerto 8421 ───────────────────────────────────────────────
alias hermes-dashboard-on='() {
  local PREV_PID
  PREV_PID=$(lsof -ti tcp:8421 2>/dev/null)
  if [[ -n "$PREV_PID" ]]; then
    kill -9 $PREV_PID 2>/dev/null
    sleep 1
  fi

  python3 ~/Documents/dotfiles/hermes/dashboard.py &>/tmp/hermes-dashboard.log &
  sleep 2

  if lsof -ti tcp:8421 >/dev/null 2>&1; then
    echo "✅ HERMES Dashboard activo en :8421"
  else
    echo "❌ Dashboard no levantó — revisa: hermes-dashboard-log"
  fi
}'

alias hermes-dashboard-off='() {
  local PIDS
  PIDS=$(lsof -ti tcp:8421 2>/dev/null)
  if [[ -n "$PIDS" ]]; then
    kill -9 $PIDS 2>/dev/null
    sleep 1
  fi
  if lsof -ti tcp:8421 >/dev/null 2>&1; then
    echo "❌ No se pudo liberar :8421"
  else
    echo "🔴 HERMES Dashboard detenido"
  fi
}'
alias hermes-dashboard-status='lsof -ti tcp:8421 &>/dev/null && echo "✅ Dashboard activo en :8421" || echo "🔴 Dashboard inactivo"'
alias hermes-dashboard-log='tail -40 /tmp/hermes-dashboard.log'

