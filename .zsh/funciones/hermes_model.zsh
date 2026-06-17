#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: hermes_model.zsh
# PROPÓSITO: Switch zero-fricción entre modelo local MLX y nube (OpenRouter)
# PERFIL LOCAL POR DEFECTO: Qwen3-4B-4bit (rápido, menos RAM)
# ==============================================================================

_HERMES_CONFIG="$HOME/.hermes/config.yaml"
_MLX_START="$HOME/Documents/dotfiles/hermes/scripts/mlx-server-start.sh"
_HERMES_LOCAL_MODEL="mlx-community/Qwen3-4B-4bit"

function hermes-local() {
    echo "⚙  Configurando HERMES → LOCAL (${_HERMES_LOCAL_MODEL})"

    if ! _hermes_mlx_activo; then
        echo "   Servidor MLX inactivo — arrancando en :8000..."
        export MLX_ACTIVE_MODEL="$_HERMES_LOCAL_MODEL"
        bash "$_MLX_START" &
        local _wait=0
        while ! _hermes_mlx_activo && (( _wait < 12 )); do
            sleep 2
            (( _wait += 2 ))
            echo "   ...esperando servidor MLX (${_wait}s)"
        done
        if ! _hermes_mlx_activo; then
            echo "❌  Servidor MLX no respondió en 12s. Revisa: tail -40 ~/.hermes-mlx.log"
            return 1
        fi
    else
        echo "   Servidor MLX ya activo en :8000 ✅"
    fi

    hermes config set model.default   "$_HERMES_LOCAL_MODEL"
    hermes config set model.provider  "custom"
    hermes config set model.base_url  "http://localhost:8000/v1"
    hermes config set model.api_key   "local-mlx"
    hermes config set model.api_mode  "chat_completions"

    echo "🤖  HERMES → LOCAL  │ ${_HERMES_LOCAL_MODEL} @ :8000"
    echo "    Usa 'hermes chat' para abrir sesión."
}

function hermes-cloud() {
    echo "☁️  Configurando HERMES → CLOUD (Nemotron-3 Super 120B free)"

    hermes config set model.default   "nvidia/nemotron-3-super-120b-a12b:free"
    hermes config set model.provider  "openrouter"
    hermes config set model.base_url  "https://openrouter.ai/api/v1"
    hermes config set model.api_key   ""
    hermes config set model.api_mode  "chat_completions"

    echo "☁️  HERMES → CLOUD  │ Nemotron-3 Super 120B free @ OpenRouter"
    echo "    Usa 'hermes chat' para abrir sesión."
}

function hermes-mlx-stop() {
    local pid
    pid=$(lsof -i :8000 -sTCP:LISTEN -t 2>/dev/null)
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null && echo "🛑  mlx_lm.server detenido (PID $pid) — RAM liberada"
    else
        echo "ℹ️   No hay servidor MLX activo en :8000"
    fi
}

function hermes-model-status() {
    echo ""
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║   🤖  HERMES Model — Configuración activa           ║"
    echo "  ╚══════════════════════════════════════════════════════╝"

    local _model _provider _base
    _model=$(grep -A1 '^model:' "$_HERMES_CONFIG" 2>/dev/null | grep 'default:' | awk '{print $2}')
    _provider=$(grep -A4 '^model:' "$_HERMES_CONFIG" 2>/dev/null | grep 'provider:' | head -1 | awk '{print $2}')
    _base=$(grep -A6 '^model:' "$_HERMES_CONFIG" 2>/dev/null | grep 'base_url:' | head -1 | awk '{print $2}')

    echo ""
    echo "  Modelo   : ${_model:-desconocido}"
    echo "  Provider : ${_provider:-desconocido}"
    echo "  Base URL : ${_base:-desconocido}"
    echo ""

    if _hermes_mlx_activo; then
        echo "  🟢 Servidor MLX activo en :8000"
    else
        echo "  🔴 Servidor MLX inactivo"
    fi
    echo ""
}
