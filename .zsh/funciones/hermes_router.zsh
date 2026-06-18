#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: hermes_router.zsh
# PROPÓSITO: Router inteligente — local MLX vs OpenRouter nube
# CAMBIAR MODELO: edita OR_MODEL_DEFAULT en hermes/privado/openrouter.env
# ==============================================================================

_MLX_PY="/opt/homebrew/opt/python@3.11/libexec/bin/python3"

# Verifica si el servidor MLX local responde
function _hermes_mlx_activo() {
    curl -s --max-time 2 http://localhost:8000/v1/models &>/dev/null
}

# Elimina bloques <think>, estadísticas y líneas vacías del output MLX
function _limpiar_output_mlx() {
    "$_MLX_PY" -c "
import sys, re
texto = sys.stdin.read()
texto = re.sub(r'<think>.*?</think>', '', texto, flags=re.DOTALL)
texto = re.sub(r'\n?(Generation:|Prompt:|Peak memory:|=====).*', '', texto)
print(texto.strip())
"
}

# Cliente HTTP para OpenRouter — usa OR_MODEL_DEFAULT del entorno
function _hermes_llamar_openrouter() {
    local prompt="$1"
    local max_tokens="${2:-2000}"

    if [[ -z "$OPENROUTER_API_KEY" ]]; then
        echo "❌ OPENROUTER_API_KEY no definida." >&2
        return 1
    fi

    "$_MLX_PY" - << PYEOF
import httpx, sys

payload = {
    "model": "${OR_MODEL_DEFAULT}",
    "messages": [{"role": "user", "content": """${prompt}"""}],
    "max_tokens": ${max_tokens},
    "temperature": 0.3
}
headers = {
    "Authorization": "Bearer ${OPENROUTER_API_KEY}",
    "Content-Type": "application/json",
    "HTTP-Referer": "https://github.com/Rene-Bedolla",
    "X-Title": "HERMES Personal Harness"
}
try:
    with httpx.Client(timeout=120) as client:
        resp = client.post("${OPENROUTER_BASE_URL}/chat/completions",
                          json=payload, headers=headers)
        resp.raise_for_status()
        print(resp.json()["choices"][0]["message"]["content"])
except Exception as e:
    print(f"❌ Error OpenRouter: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
}

# ------------------------------------------------------------------------------
# hermes-ask — interfaz principal del router
# Tipos: rapido · codigo · nube · privado · auto
# Uso:   hermes-ask <tipo> "tu pregunta"
# ------------------------------------------------------------------------------
function hermes-ask() {
    local tipo="${1:-auto}"
    local prompt="$2"

    if [[ -z "$prompt" ]]; then
        echo "\n  Uso: hermes-ask <tipo> \"pregunta\""
        echo "  Tipos: rapido · codigo · nube · privado · auto\n"
        return 1
    fi

    local modelo_usado respuesta

    case "$tipo" in
        rapido|privado)
            ! _hermes_mlx_activo && { echo "⚠️  Iniciando MLX..." >&2; mlx-on; }
            modelo_usado="Qwen3.5-4B-OptiQ-4bit · local"
            respuesta=$(mlx_lm.generate \
                --model mlx-community/Qwen3.5-4B-OptiQ-4bit \
                --prompt "$prompt" \
                --max-tokens 1000 --temp 0.3 2>/dev/null | _limpiar_output_mlx)
            ;;
        codigo)
            ! _hermes_mlx_activo && { echo "⚠️  Iniciando MLX..." >&2; mlx-on; }
            modelo_usado="Qwen3.5-4B-OptiQ-4bit · local"
            respuesta=$(mlx_lm.generate \
                --model mlx-community/Qwen3.5-4B-OptiQ-4bit \
                --prompt "$prompt" \
                --max-tokens 2000 --temp 0.2 2>/dev/null | _limpiar_output_mlx)
            ;;
        nube)
            modelo_usado="$(echo $OR_MODEL_DEFAULT | cut -d'/' -f2) · OpenRouter"
            respuesta=$(_hermes_llamar_openrouter "$prompt" 3000)
            ;;
        auto)
            local longitud=${#prompt}
            if (( longitud < 300 )) && _hermes_mlx_activo; then
                modelo_usado="Qwen3.5-4B-OptiQ-4bit · local (auto)"
                respuesta=$(mlx_lm.generate \
                    --model mlx-community/Qwen3.5-4B-OptiQ-4bit \
                    --prompt "$prompt" \
                    --max-tokens 800 --temp 0.3 2>/dev/null | _limpiar_output_mlx)
            else
                modelo_usado="$(echo $OR_MODEL_DEFAULT | cut -d'/' -f2) · nube (auto)"
                respuesta=$(_hermes_llamar_openrouter "$prompt" 2000)
            fi
            ;;
        *)
            echo "❌ Tipo no reconocido: $tipo"
            return 1 ;;
    esac

    echo "\n  ─── $modelo_usado ───\n"
    if command -v bat &>/dev/null; then
        echo "$respuesta" | bat --style=plain --language=markdown --paging=never
    else
        echo "$respuesta"
    fi
    echo ""
}

# Muestra estado actual de todos los modelos disponibles
function hermes-router-status() {
    echo ""
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║   🔀  HERMES Router — Estado de Modelos             ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo ""
    if _hermes_mlx_activo; then
        echo "  🟢 LOCAL   Qwen3.5-4B-OptiQ-4bit   → hermes-ask rapido"
        echo "  🟢 LOCAL   Qwen3.5-4B-OptiQ-4bit   → hermes-ask codigo"
    else
        echo "  🔴 LOCAL   MLX inactivo → mlx-on para activar"
    fi
    echo ""
    if [[ -n "$OPENROUTER_API_KEY" ]]; then
        echo "  🟢 NUBE    $(echo $OR_MODEL_DEFAULT | cut -d'/' -f2) → hermes-ask nube"
        echo "  📋 Modelo: $OR_MODEL_DEFAULT"
    else
        echo "  🔴 NUBE    OPENROUTER_API_KEY no definida"
    fi
    echo ""
    echo "  🔀 AUTO    hermes-ask auto \"pregunta\""
    echo ""
}
