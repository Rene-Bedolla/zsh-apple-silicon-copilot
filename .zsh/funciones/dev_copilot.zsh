#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: dev_copilot.zsh
# PROPÓSITO: Asistente de IA local para explicar comandos de terminal en español
# MOTOR: MLX (Apple Silicon Nativo)
# ==============================================================================

# -------------------------------------------------------------------
# explicar
# Toma un comando o error de consola, consulta a MLX local y 
# devuelve una explicación limpia en español, destruyendo el <think>.
# -------------------------------------------------------------------
function explicar() {
    if [[ -z "$1" ]]; then
        echo "❌ Uso: explicar 'comando o error'"
        echo "💡 Ejemplo: explicar 'tar -xzvf archivo.tar.gz'"
        return 1
    fi

    local CONSULTA="$1"
    # Usaremos el modelo más rápido y ligero que ya tienes en caché para esto
    local MODELO="mlx-community/Qwen3-4B-4bit"

    echo "⚡ Analizando con Apple Silicon (MLX)..."

    # 1. Definimos el prompt estricto en una variable
    local PROMPT="Actúa como un manual de Linux/macOS. Explica el siguiente comando: '$CONSULTA'. FORMATO OBLIGATORIO: 1) Una línea de resumen general. 2) Una lista de viñetas explicando cada parte o argumento del comando. REGLAS: Sólo responde en Español, sé conciso y no uses saludos."

    # 2. Creamos un script temporal en Python. 
    # Esto nos permite: 
    # a) Capturar la salida silenciosamente.
    # b) Usar Regex (re.sub) para borrar el bloque <think> antes de imprimirlo.
    local TMP_SCRIPT=$(mktemp /tmp/mlx_explicar_XXXXXX.py)

    cat > "$TMP_SCRIPT" << EOF
import sys
import re
from mlx_lm import load, generate

model_name = "$MODELO"
prompt_text = "$PROMPT"

try:
    # Carga silenciosa
    model, tokenizer = load(model_name)
    
    # Formateo del mensaje para el modelo (ChatML format)
    messages = [{"role": "user", "content": prompt_text}]
    formatted_prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    
    # Generación
    response = generate(model, tokenizer, prompt=formatted_prompt, max_tokens=1000, verbose=False)
    
    # Limpieza: Eliminamos todo lo que esté entre <think> y </think> (incluyendo saltos de línea)
    clean_response = re.sub(r'<think>.*?</think>', '', response, flags=re.DOTALL)
    
    # Limpieza extra: Eliminamos posibles saltos de línea vacíos al inicio
    print(clean_response.strip())

except Exception as e:
    print(f"❌ Error interno de MLX: {e}")
EOF

    # 3. Ejecutamos el script y guardamos la respuesta limpia
    local RESPUESTA=$(python3 "$TMP_SCRIPT" 2>/dev/null)
    
    # Borramos el script temporal
    rm -f "$TMP_SCRIPT"

    # 4. Imprimimos el resultado con formato
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
# Analiza los cambios en el repositorio git actual y usa MLX local
# para sugerir 3 opciones de mensajes de commit profesionales.
# -------------------------------------------------------------------
function git-ia() {
    # 1. Verificación de seguridad: ¿Estamos en un repo Git?
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Error: No estás dentro de un repositorio de Git."
        return 1
    fi

    # 2. Capturar los cambios (staged y un-staged combinados)
    echo "🔍 Leyendo cambios del código..."
    local DIFF=$(git diff HEAD)
    
    if [[ -z "$DIFF" ]]; then
        echo "📭 No hay cambios detectados para analizar. Guarda o haz 'git add' primero."
        return 1
    fi

    # Si el diff es muy grande, lo truncamos para no sobrecargar la memoria de la IA
    local DIFF_TRUNCADO=$(echo "$DIFF" | head -c 3000)

    echo "⚡ Analizando código con MLX y generando mensajes..."

    local MODELO="mlx-community/Qwen3-4B-4bit"
    local PROMPT="Actúa como un desarrollador de software experto. Analiza el siguiente 'git diff' y genera exactamente 3 opciones de mensajes de commit usando el estándar Conventional Commits (feat:, fix:, chore:, docs: etc). REGLAS: 1) Responde ÚNICAMENTE en Español. 2) No expliques nada, solo da la lista numerada. 3) Sé muy descriptivo con lo que cambió. DIFF: $DIFF_TRUNCADO"

    local TMP_SCRIPT=$(mktemp /tmp/mlx_git_XXXXXX.py)

    cat > "$TMP_SCRIPT" << EOF
import sys
import re
from mlx_lm import load, generate

model_name = "$MODELO"
prompt_text = """$PROMPT"""

try:
    model, tokenizer = load(model_name)
    messages = [{"role": "user", "content": prompt_text}]
    formatted_prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    
    response = generate(model, tokenizer, prompt=formatted_prompt, max_tokens=300, verbose=False)
    clean_response = re.sub(r'<think>.*?</think>', '', response, flags=re.DOTALL)
    print(clean_response.strip())

except Exception as e:
    print(f"❌ Error interno de MLX: {e}")
EOF

    local RESPUESTA=$(python3 "$TMP_SCRIPT" 2>/dev/null)
    rm -f "$TMP_SCRIPT"

    echo "\n=========================================================="
    echo "💡 SUGERENCIAS DE AUTO-COMMIT:"
    echo "=========================================================="
    # Si tenemos bat, le damos sintaxis Markdown para que se vea elegante
    if command -v bat &> /dev/null; then
        echo "$RESPUESTA" | bat --style=plain --language=markdown --paging=never
    else
        echo "$RESPUESTA"
    fi
    echo "=========================================================="
    echo "👉 Puedes usar una copiándola y pegándola con: git commit -m 'mensaje'"
    echo "==========================================================\n"
}
