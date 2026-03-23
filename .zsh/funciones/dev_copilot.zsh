#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: dev_copilot.zsh
# PROPÓSITO: Asistente de Desarrollo impulsado por IA Local en Español
# MOTOR: MLX (Nativo para Apple Silicon)
# AUTOR: René López Bedolla
# ==============================================================================

# Variable global para el modelo más rápido de tu sistema
export MLX_COPILOT_MODEL="mlx-community/Qwen3-4B-4bit"

# -------------------------------------------------------------------
# explicar <comando>
# Consulta a MLX para desglosar y explicar comandos de consola o errores.
# -------------------------------------------------------------------
function explicar() {
    if [[ -z "$1" ]]; then
        echo "❌ Uso: explicar 'comando o error'"
        echo "💡 Ejemplo: explicar 'tar -xzvf archivo.tar.gz'"
        return 1
    fi

    local CONSULTA="$1"
    echo "⚡ Analizando comando con Apple Silicon (MLX)..."

    # Prompt estricto usando /no_think (específico para arquitectura Qwen3)
    local PROMPT="/no_think Actúa como un manual de Linux/macOS. Explica el siguiente comando: '$CONSULTA'. FORMATO OBLIGATORIO: 1) Una línea de resumen general. 2) Una lista de viñetas explicando cada parte o argumento del comando. REGLAS: Sólo responde en Español, sé conciso y no uses saludos."

    local TMP_SCRIPT=$(mktemp /tmp/mlx_explicar_XXXXXX.py)

    cat > "$TMP_SCRIPT" << 'EOF'
import sys
from mlx_lm import load, generate

model_name = sys.argv[1]
prompt_text = sys.argv[2]

try:
    # Carga silenciosa
    model, tokenizer = load(model_name)
    messages = [{"role": "user", "content": prompt_text}]
    formatted_prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    
    # Generación sin temperatura para respuestas deterministas
    response = generate(model, tokenizer, prompt=formatted_prompt, max_tokens=1000, verbose=False)
    
    # MÉTODO INFALIBLE ANTI-THINKING: Cortar la cadena si el modelo desobedece
    if "</think>" in response:
        clean_response = response.split("</think>")[-1].strip()
    else:
        clean_response = response.replace("<think>", "").strip()
        
    print(clean_response)

except Exception as e:
    print(f"❌ Error interno de MLX: {e}")
EOF

    # Pasamos las variables como argumentos a Python para evitar conflictos de comillas
    local RESPUESTA=$(python3 "$TMP_SCRIPT" "$MLX_COPILOT_MODEL" "$PROMPT" 2>/dev/null)
    rm -f "$TMP_SCRIPT"

    echo "\n=========================================================="
    echo "💡 EXPLICACIÓN DEL COMANDO:"
    echo "=========================================================="
    if command -v bat &> /dev/null; then
        echo "$RESPUESTA" | bat --style=plain --language=markdown --paging=never
    else
        echo "$RESPUESTA"
    fi
    echo "==========================================================\n"
}

# -------------------------------------------------------------------
# git-ia
# Analiza 'git diff' y sugiere mensajes de commit profesionales.
# -------------------------------------------------------------------
function git-ia() {
    # 1. Seguridad: Verificar que estamos en un repositorio
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Error: No estás dentro de un repositorio de Git."
        return 1
    fi

    echo "🔍 Leyendo cambios del código..."
    local DIFF=$(git diff HEAD)
    
    if [[ -z "$DIFF" ]]; then
        echo "📭 No hay cambios detectados. Guarda archivos o haz 'git add' primero."
        return 1
    fi

    # Truncar el diff a 3000 caracteres para no saturar el contexto de la IA
    local DIFF_TRUNCADO=$(echo "$DIFF" | head -c 3000)

    echo "⚡ Analizando código con MLX y generando mensajes..."

    local PROMPT="/no_think Actúa como un desarrollador de software experto. Analiza este git diff y dame exactamente 3 opciones de mensajes de commit usando Conventional Commits (feat:, fix:, docs:, chore:). REGLAS: 1) Responde ÚNICAMENTE con la lista numerada en Español. 2) No expliques nada, no saludes. DIFF: $DIFF_TRUNCADO"

    local TMP_SCRIPT=$(mktemp /tmp/mlx_git_XXXXXX.py)

    cat > "$TMP_SCRIPT" << 'EOF'
import sys
from mlx_lm import load, generate

model_name = sys.argv[1]
prompt_text = sys.argv[2]

try:
    model, tokenizer = load(model_name)
    messages = [{"role": "user", "content": prompt_text}]
    formatted_prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    
    response = generate(model, tokenizer, prompt=formatted_prompt, max_tokens=800, verbose=False)
    
    # MÉTODO INFALIBLE ANTI-THINKING
    if "</think>" in response:
        clean_response = response.split("</think>")[-1].strip()
    else:
        clean_response = response.replace("<think>", "").strip()
        
    if not clean_response:
        print("1. chore: actualizar archivos (el diff era demasiado complejo)")
    else:
        print(clean_response)

except Exception as e:
    print(f"❌ Error interno de MLX: {e}")
EOF

    # Ejecución
    local RESPUESTA=$(python3 "$TMP_SCRIPT" "$MLX_COPILOT_MODEL" "$PROMPT" 2>/dev/null)
    rm -f "$TMP_SCRIPT"

    echo "\n=========================================================="
    echo "💡 SUGERENCIAS DE AUTO-COMMIT:"
    echo "=========================================================="
    if command -v bat &> /dev/null; then
        echo "$RESPUESTA" | bat --style=plain --language=markdown --paging=never
    else
        echo "$RESPUESTA"
    fi
    echo "=========================================================="
    echo "👉 Usa una ejecutando: git commit -m 'mensaje'"
    echo "==========================================================\n"
}
