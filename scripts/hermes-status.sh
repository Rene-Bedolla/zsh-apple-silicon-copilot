#!/usr/bin/env zsh
# hermes-status.sh — Diagnóstico completo del stack HERMES
# Fases: F1 MLX · F5 MCP · F6 Telegram · F7 STT/TTS · F8 Cerebro · Docker (prereq F2,F8,F9)

SEP="──────────────────────────────────────────────────"

check() {
  # check "Descripción" "comando_de_prueba"
  local label="$1"; shift
  if eval "$@" &>/dev/null; then
    printf "  ✅  %-40s\n" "$label"
  else
    printf "  ❌  %-40s\n" "$label"
  fi
}

port_check() {
  # Verifica si un puerto está en uso (servicio activo)
  local label="$1" port="$2"
  if lsof -iTCP:$port -sTCP:LISTEN &>/dev/null; then
    printf "  ✅  %-40s [:%s activo]\n" "$label" "$port"
  else
    printf "  ⏳  %-40s [:%s inactivo]\n" "$label" "$port"
  fi
}

echo ""
echo "  🛰  HERMES — Estado del Sistema · $(date '+%Y-%m-%d %H:%M')"
echo "$SEP"

# ── F1: MLX + Modelos ────────────────────────────────
echo "\n  [F1] MLX + Modelos Locales"
check "Python 3.11 Homebrew" "/opt/homebrew/opt/python@3.11/libexec/bin/python3 --version"
check "mlx instalado"        "python3 -c 'import mlx.core'"
check "mlx-lm instalado"     "python3 -c 'from mlx_lm import load'"
check "mlx-whisper instalado" "python3 -c 'import mlx_whisper'"
check "mlx-vlm instalado"    "python3 -c 'import mlx_vlm'"

# Modelos en caché
echo "\n  [F1] Modelos en caché (~/.cache/huggingface/hub/)"
for model in "Qwen3-8B-4bit" "Qwen3-4B-4bit" "Qwen3-VL-4B-Instruct-4bit" "whisper-small-mlx"; do
  dir=$(ls -d ~/.cache/huggingface/hub/models--mlx-community--${model} 2>/dev/null)
  if [[ -n "$dir" ]]; then
    size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    printf "  ✅  %-44s [%s]\n" "$model" "$size"
  else
    printf "  ❌  %-44s [no encontrado]\n" "$model"
  fi
done

# Servidor MLX REST
echo "\n  [F1] Servidor MLX REST"
port_check "mlx_lm.server" 8000
if curl -s --max-time 2 http://localhost:8000/v1/models &>/dev/null; then
  modelo_activo=$(curl -s http://localhost:8000/v1/models | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data'][0]['id'])" 2>/dev/null)
  printf "       Modelo activo: %s\n" "${modelo_activo:-desconocido}"
fi

# ── F2/F8/F9: Docker (prerequisito) ─────────────────
echo "\n  [F2/F8/F9] Docker Desktop (prerequisito bloqueante)"
check "Docker CLI disponible"   "docker --version"
check "Docker daemon activo"    "docker info"
port_check "Open WebUI"         3000
port_check "n8n"                5678
port_check "ChromaDB / Qdrant"  6333

# ── F5: MCP Servers ──────────────────────────────────
echo "\n  [F5] MCP Servers"
check "mcp-apple-notes clonado" "test -d ~/Documents/dotfiles/.zsh/mcp-apple-notes"
check "Bun instalado (req. MCP)" "command -v bun"
check "Node v24 activo"          "node --version"

# ── F6: Bot Telegram ─────────────────────────────────
echo "\n  [F6] Bot Telegram"
check "python-telegram-bot"     "python3 -c 'import telegram'"
check "aiogram"                 "python3 -c 'import aiogram'"

# ── F7: STT + TTS ────────────────────────────────────
echo "\n  [F7] Voz STT + TTS"
check "mlx-whisper (STT)"       "python3 -c 'import mlx_whisper'"
check "ffmpeg (procesado audio)" "command -v ffmpeg"
check "Piper TTS instalado"     "command -v piper"
check "soundfile"               "python3 -c 'import soundfile'"

# ── F8: Memoria Persistente ──────────────────────────
echo "\n  [F8] Memoria Persistente — Cerebro"
check "Obsidian vault presente" "test -d ~/Notas"
check "sync_maestro.py existe"  "test -f ~/Documents/dotfiles/privado/cerebro/sync_maestro.py"
check "LaunchAgent sync activo" "launchctl list | grep -q com.rene.sync-cerebro"
check "sync.log presente"       "test -f ~/Documents/dotfiles/privado/cerebro/sync.log"
port_check "ChromaDB"           6333

# ── RAM snapshot ────────────────────────────────────
echo "\n  [RAM] Memoria Unificada"
vm_stat | awk '
  /Pages free/       { free=$3 }
  /Pages active/     { active=$3 }
  /Pages wired/      { wired=$4 }
  /Pages occupied/   { compressed=$5 }
  END {
    page=4096
    used_gb=(active+wired+compressed)*page/1024/1024/1024
    free_gb=free*page/1024/1024/1024
    printf "  RAM usada: %.1f GB  |  Disponible: %.1f GB\n", used_gb, free_gb
  }'

# ── Puertos clave HERMES ─────────────────────────────
echo "\n  [RED] Puertos HERMES"
for p in 8000 3000 5678 8080 6333 8888; do
  port_check "Puerto $p" $p
done

echo "\n$SEP"
echo "  Ejecuta 'conversar-mantener' para verificar actualizaciones de modelos MLX."
echo ""
