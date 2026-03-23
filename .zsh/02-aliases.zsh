#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: 02-aliases.zsh
# PROPÓSITO: Atajos de teclado y comandos de uso frecuente
# ==============================================================================

# ─── Sistema y Homebrew ───────────────────────────────────────────
alias actualizar='brew update && brew upgrade'
alias instalar='brew install'
alias limpiar='brew cleanup && brew autoremove && brew cleanup'
alias refresco='source ~/.zshrc' # Unificado (elimina tu alias 'updatezsh')
alias pingoogle='ping 8.8.8.8'
alias respaldo-cold='generar_cold_backup'

# ─── Navegación y CLI Visual (eza + bat) ──────────────────────────
alias cat='bat --paging=never'
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first --git'
alias tree='eza --tree --icons'
alias treef='eza --tree --icons'

# ─── Conexiones INPI y NAS ────────────────────────────────────────
alias conectaKoha='ssh acervos@200.57.183.23'
alias respaldaKoha='cd /Volumes/EXT/Respaldos/Incrementales/ && sh RespaldosCatalogosINPI.sh'
alias conectaNAS='ssh ren@renbedolla.synology.me -p 2008'

# ─── Python (Homebrew) ────────────────────────────────────────────
alias python=/opt/homebrew/opt/python@3.11/libexec/bin/python3
alias python3=/opt/homebrew/opt/python@3.11/libexec/bin/python3
alias pip=/opt/homebrew/opt/python@3.11/libexec/bin/pip3

# ─── Cerebro e IA (Scripts externos) ──────────────────────────────
alias pull-notas="python3 ~/scripts/cerebro/notes_to_obsidian.py"
alias push-notas="python3 ~/scripts/cerebro/obsidian_to_notes.py"
alias sync-cerebro="pull-notas && push-notas"
alias log-cerebro="tail -50 ~/scripts/cerebro/sync.log"
alias traducir-srt='python3 ~/scripts/translate_srt.py'
alias traducir-srt-rápido='python3 ~/scripts/translate_srt.py --batch-size 15 --temp 0.5'
alias traducir-srt-preciso='python3 ~/scripts/translate_srt.py --batch-size 4 --temp 0.1'

# ─── MLX-Whisper Automáticos ──────────────────────────────────────
alias transcribir-video='extraerSubs'           
alias transcribir-rápido='extraerSubs $1 tiny'  
alias transcribir-preciso='extraerSubs $1 medium' 
alias transcribir-srt-only='extraerSubs $1 small --srt-only' 

alias procesar-minuta='mlx_lm.generate --model mlx-community/Qwen3-8B-4bit --max-tokens 2000 --temp 0.1 --prompt "Actúa como un analista experto. Lee la siguiente transcripción y extrae: 1) Resumen ejecutivo (3 viñetas), 2) Tareas asignadas (con responsable), 3) Puntos críticos mencionados. Mantén la objetividad estricta sin inventar datos: "'
