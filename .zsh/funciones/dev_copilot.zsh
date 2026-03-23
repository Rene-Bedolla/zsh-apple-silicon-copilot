# -------------------------------------------------------------------
# git-ia
# Analiza 'git diff' y sugiere 3 mensajes de commit profesionales.
# -------------------------------------------------------------------
function git-ia() {
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

    local DIFF_TRUNCADO=$(echo "$DIFF" | head -c 3000)

    echo "⚡ Analizando código con MLX y generando mensajes..."

    local PROMPT="Eres un desarrollador senior. Analiza este git diff y genera 3 opciones de mensajes de commit (feat, fix, chore, etc). RESPONDE ÚNICAMENTE CON UN JSON VÁLIDO CON ESTA ESTRUCTURA EXACTA: {\"commits\": [\"mensaje 1\", \"mensaje 2\", \"mensaje 3\"]}. NO agregues texto ni explicaciones fuera del JSON. DIFF: $DIFF_TRUNCADO"

    local TMP_SCRIPT=$(mktemp /tmp/mlx_git_XXXXXX.py)

    cat > "$TMP_SCRIPT" << 'EOF'
import sys
import json
import re
from mlx_lm import load, generate

model_name = sys.argv[1]
prompt_text = sys.argv[2]

try:
    model, tokenizer = load(model_name)
    messages = [{"role": "user", "content": prompt_text}]
    formatted_prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    
    # Dejamos que el modelo hable libremente (sin inyectar caracteres)
    response = generate(model, tokenizer, prompt=formatted_prompt, max_tokens=800, verbose=False)
    
    # Limpiamos las etiquetas <think> (si las hubiera)
    clean_text = re.sub(r'<think>.*?</think>', '', response, flags=re.DOTALL).strip()
    
    # Expresión regular para capturar tanto un diccionario JSON como una lista JSON
    json_match = re.search(r'(\{.*\}|\[.*\])', clean_text, re.DOTALL)
    
    def extract_list(obj):
        """Función recursiva para buscar una lista dentro de cualquier estructura JSON"""
        if isinstance(obj, list):
            return obj
        elif isinstance(obj, dict):
            for value in obj.values():
                result = extract_list(value)
                if result:
                    return result
        return None

    if json_match:
        try:
            parsed_data = json.loads(json_match.group(0))
            commits = extract_list(parsed_data)

            if commits and isinstance(commits, list):
                for i, commit in enumerate(commits[:3], 1):
                    # Limpiamos comillas o formatos extraños dentro del mensaje
                    if isinstance(commit, str):
                        clean_msg = commit.replace('`', '').strip()
                        print(f"{i}. {clean_msg}")
                    elif isinstance(commit, dict):
                        # A veces el modelo anida diccionarios dentro de la lista
                        first_val = next(iter(commit.values()))
                        clean_msg = str(first_val).replace('`', '').strip()
                        print(f"{i}. {clean_msg}")
            else:
                print("1. chore: actualizar archivos (No se encontró lista en el JSON)")
        except json.JSONDecodeError:
            print("1. chore: actualizar archivos (Error al decodificar JSON)")
    else:
        # Fallback de emergencia si el modelo ignoró hacer un JSON
        lines = [line.strip() for line in clean_text.split('\n') if 'feat:' in line or 'fix:' in line or 'chore:' in line]
        if lines:
            for i, line in enumerate(lines[:3], 1):
                print(f"{i}. {line}")
        else:
            print("1. chore: actualizar archivos (El modelo no siguió las instrucciones)")

except Exception as e:
    print(f"❌ Error interno de MLX: {e}")
EOF

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
