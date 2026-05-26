#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: hermes_model.zsh
# PROPÓSITO: Switch zero-fricción entre modelo local MLX y nube (OpenRouter)
# INTEGRA CON: hermes_router.zsh (_hermes_mlx_activo), mlx-server-start.sh
# CONVENCIÓN: extiende la familia hermes-* de 02-aliases.zsh
# ==============================================================================

_HERMES_CONFIG="$HOME/.hermes/config.yaml"
_MLX_START="$HOME/Documents/dotfiles/hermes/scripts/mlx-server-start.sh"

# ------------------------------------------------------------------------------
# hermes-local — activa Qwen3-8B local como provider de Hermes CLI
# Levanta mlx_lm.server si no está corriendo (reutiliza mlx-server-start.sh)
# ------------------------------------------------------------------------------
function hermes-local() {
    echo "⚙  Configurando HERMES → LOCAL (Qwen3-8B-4bit)"

    # 1. Levantar servidor MLX si no responde
    if ! _hermes_mlx_activo; then
        echo "   Servidor MLX inactivo — arrancando en :8000..."
        export MLX_ACTIVE_MODEL="mlx-community/Qwen3-8B-4bit"
        # mlx-server-start.sh lee MLX_ACTIVE_MODEL y hace exec (no regresa)
        # lo lanzamos en background para no bloquear el shell
        bash "$_MLX_START" &
        local _wait=0
        # Esperar máximo 12s a que el puerto responda
        while ! _hermes_mlx_activo && (( _wait < 12 )); do
            sleep 2; (( _wait += 2 ))
            echo "   ...esperando servidor MLX (${_wait}s)"
        done
        if ! _hermes_mlx_activo; then
            echo "❌  Servidor MLX no respondió en 12s. Revisa: tail -40 ~/.hermes-mlx.log"
            return 1
        fi
    else
        echo "   Servidor MLX ya activo en :8000 ✅"
    fi

    # 2. Apuntar Hermes CLI al endpoint local (OpenAI-compatible)
    hermes config set model.default   "mlx-community/Qwen3-8B-4bit"
    hermes config set model.provider  "custom"
    hermes config set model.base_url  "http://localhost:8000/v1"
    hermes config set model.api_key   "local-mlx"
    hermes config set model.api_mode  "chat_completions"

    echo "🤖  HERMES → LOCAL  │ Qwen3-8B-4bit @ :8000"
    echo "    Usa 'hermes chat' para abrir sesión."
}

# ------------------------------------------------------------------------------
# hermes-cloud — restaura Nemotron free via OpenRouter
# No apaga el servidor MLX (puede seguir siendo usado por hermes-ask)
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# hermes-mlx-stop — apaga el servidor MLX y libera RAM (~5-6 GB)
# Separado de hermes-cloud para no obligar a apagar MLX al cambiar a nube
# (hermes-ask rapido/codigo sigue funcionando si MLX está activo)
# ------------------------------------------------------------------------------
function hermes-mlx-stop() {
    local pid
    pid=$(lsof -i :8000 -sTCP:LISTEN -t 2>/dev/null)
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null && echo "🛑  mlx_lm.server detenido (PID $pid) — RAM liberada"
    else
        echo "ℹ️   No hay servidor MLX activo en :8000"
    fi
}

# ------------------------------------------------------------------------------
# hermes-model-status — muestra provider/modelo activo en Hermes config
# Complementa hermes-router-status de hermes_router.zsh
# ------------------------------------------------------------------------------
function hermes-model-status() {
    echo ""
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║   🤖  HERMES Model — Configuración activa           ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    # Extraer provider y modelo del config sin abrir el wizard
    local _model _provider _base
    _model=$(grep -A1 'model:' "$_HERMES_CONFIG" 2>/dev/null \
             | grep 'default:' | awk '{print $2}')
    _provider=$(grep 'provider:' "$_HERMES_CONFIG" 2>/dev/null \
                | head -1 | awk '{print $2}')
    _base=$(grep 'base_url:' "$_HERMES_CONFIG" 2>/dev/null \
            | head -1 | awk '{print $2}')
    echo ""
    echo "  Modelo   : ${_model:-desconocido}"
    echo "  Provider : ${_provider:-desconocido}"
    echo "  Base URL : ${_base:-desconocido}"
    echo ""
    # Estado del servidor MLX
    if _hermes_mlx_activo; then
        echo "  🟢 Servidor MLX activo en :8000"
    else
        echo "  🔴 Servidor MLX inactivo"
    fi
    echo ""
}
