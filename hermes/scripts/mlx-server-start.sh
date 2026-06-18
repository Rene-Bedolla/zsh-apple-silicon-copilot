#!/usr/bin/env bash
# ==============================================================================
# ARCHIVO: mlx-server-start.sh
# PROPÓSITO: Arrancar el servidor MLX REST en puerto 8000
# PROTOCOLO: OpenAI-compatible API (mlx_lm.server)
# MODELO: Qwen3.5-4B-OptiQ-4bit por defecto (rápido, ~2.5GB RAM)
# CAMBIA DE MODELO: edita MLX_DEFAULT_MODEL o usa mlx-update
# ==============================================================================

MLX_PYTHON="/opt/homebrew/opt/python@3.11/libexec/bin/python3"
MLX_DEFAULT_MODEL="${MLX_ACTIVE_MODEL:-mlx-community/Qwen3.5-4B-OptiQ-4bit}"
MLX_PORT=8000
LOG_FILE="$HOME/.hermes-mlx.log"

# Verificar que no hay otro servidor activo en el puerto
if lsof -i ":$MLX_PORT" -sTCP:LISTEN &>/dev/null; then
    echo "⚠️  Puerto $MLX_PORT ya ocupado. Servidor MLX ya activo." >&2
    exit 0
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') — Iniciando MLX REST con $MLX_DEFAULT_MODEL" >> "$LOG_FILE"

exec "$MLX_PYTHON" -m mlx_lm.server \
    --model "$MLX_DEFAULT_MODEL" \
    --port "$MLX_PORT" \
    --host 127.0.0.1 \
    >> "$LOG_FILE" 2>&1
