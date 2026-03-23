#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: dev_copilot.zsh
# PROPÓSITO: Asistente de Desarrollo impulsado por IA Local en Español
# MOTOR: MLX (Nativo para Apple Silicon)
# AUTOR: René López Bedolla
# VERSIÓN: 2.2 — Fixes: verbose=False bug, diff injection, JSON regex, sampler
# ==============================================================================

export MLX_COPILOT_MODEL="mlx-community/Qwen3-4B-4bit"

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
    local DIFF
    DIFF=$(git diff HEAD)

    if [[ -z "$DIFF" ]]; then
        echo "📭 No hay cambios detectados. Guarda archivos o haz 'git add' primero."
        return 1
    fi

    echo "⚡ Analizando código con MLX y generando mensajes..."

    # DIFF a archivo temporal para evitar inyección que rompa sys.argv
    local TMP_DIFF
    TMP_DIFF=$(mktemp /tmp/mlx_diff_XXXXXX.txt)
    echo "$DIFF" | head -c 3000 > "$TMP_DIFF"

    local TMP_SCRIPT
    TMP_SCRIPT=$(mktemp /tmp/mlx_git_XXXXXX.py)

    cat > "$TMP_SCRIPT" << 'EOF'
import sys
import io
import re
import json
import contextlib
from mlx_lm import load, generate
from mlx_lm.sample_utils import make_sampler

model_name = sys.argv[1]
diff_path  = sys.argv[2]

with open(diff_path, 'r', errors='replace') as f:
    diff_text = f.read()

prompt_text = (
    "Eres un desarrollador senior. Analiza este git diff y genera 3 opciones "
    "de mensajes de commit (feat, fix, chore, etc). "
    'RESPONDE ÚNICAMENTE CON UN JSON VÁLIDO CON ESTA ESTRUCTURA EXACTA: '
    '{"commits": ["mensaje 1", "mensaje 2", "mensaje 3"]}. '
    "NO agregues texto ni explicaciones fuera del JSON. "
    f"DIFF:\n{diff_text}"
)

try:
    model, tokenizer = load(model_name)
    messages = [{"role": "user", "content": prompt_text}]
    formatted_prompt = tokenizer.apply_chat_template(
        messages, tokenize=False, add_generation_prompt=True
    )

    sampler = make_sampler(temp=0.1)
    buffer = io.StringIO()
    
    with contextlib.redirect_stdout(buffer):
        generate(
            model, tokenizer,
            prompt=formatted_prompt,
            max_tokens=800,
            sampler=sampler,
            verbose=True
        )
    raw = buffer.getvalue()

    stats_pat = re.compile(r'\n={5,}\s*\nPrompt:', re.DOTALL)
    m = stats_pat.search(raw)
    text = raw[:m.start()].strip() if m else raw.strip()

    if "</think>" in text:
        text = text.split("</think>")[-1].strip()
    else:
        text = text.replace("<think>", "").strip()

    def find_first_json(s):
        decoder = json.JSONDecoder()
        for start_char in ('{', '['):
            idx = s.find(start_char)
            while idx != -1:
                try:
                    obj, _ = decoder.raw_decode(s, idx)
                    return obj
                except json.JSONDecodeError:
                    idx = s.find(start_char, idx + 1)
        return None

    def extract_list(obj):
        if isinstance(obj, list):
            return obj
        if isinstance(obj, dict):
            for v in obj.values():
                result = extract_list(v)
                if result:
                    return result
        return None

    parsed = find_first_json(text)

    if parsed:
        commits = extract_list(parsed)
        if commits:
            for i, commit in enumerate(commits[:3], 1):
                if isinstance(commit, str):
                    print(f"{i}. {commit.replace('`','').strip()}")
                elif isinstance(commit, dict):
                    first_val = next(iter(commit.values()), "")
                    print(f"{i}. {str(first_val).replace('`','').strip()}")
        else:
            print("1. chore: actualizar archivos (JSON sin lista de commits)")
    else:
        lines = [
            l.strip() for l in text.split('\n')
            if any(p in l for p in ('feat:', 'fix:', 'chore:', 'docs:', 'refactor:', 'style:'))
        ]
        if lines:
            for i, line in enumerate(lines[:3], 1):
                print(f"{i}. {line}")
        else:
            print("1. chore: actualizar archivos (modelo no siguió instrucciones)")

except Exception as e:
    print(f"❌ Error interno de MLX: {e}", file=sys.stderr)
    sys.exit(1)
EOF

    local RESPUESTA
    RESPUESTA=$(python3 "$TMP_SCRIPT" "$MLX_COPILOT_MODEL" "$TMP_DIFF" 2>/tmp/mlx_error.log)
    local EXIT_CODE=$?
    rm -f "$TMP_SCRIPT" "$TMP_DIFF"

    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "❌ Error de MLX. Revisa con: cat /tmp/mlx_error.log"
        return 1
    fi

    echo "\n=========================================================="
    echo "💡 SUGERENCIAS DE AUTO-COMMIT:"
    echo "=========================================================="
    if command -v bat &>/dev/null; then
        echo "$RESPUESTA" | bat --style=plain --language=markdown --paging=never
    else
        echo "$RESPUESTA"
    fi
    echo "=========================================================="
    echo "👉 Usa una ejecutando: git commit -m 'mensaje'"
    echo "==========================================================\n"
}

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

    local PROMPT="Eres un manual de macOS. Analiza el comando '${CONSULTA}' y responde SOLO con este JSON EXACTO: {\"resumen\": \"una línea corta\", \"sintaxis\": \"ejemplo de uso\", \"opciones\": [\"opción 1\", \"opción 2\", \"opción 3\"], \"ejemplo\": \"bat archivo.txt\"}. NO escribas nada fuera del JSON."

    local TMP_SCRIPT
    TMP_SCRIPT=$(mktemp /tmp/mlx_explicar_XXXXXX.py)

    cat > "$TMP_SCRIPT" << 'EOF'
import sys
import io
import re
import json
import contextlib
from mlx_lm import load, generate
from mlx_lm.sample_utils import make_sampler

model_name  = sys.argv[1]
prompt_text = sys.argv[2]

try:
    model, tokenizer = load(model_name)
    messages = [{"role": "user", "content": prompt_text}]
    formatted_prompt = tokenizer.apply_chat_template(
        messages, tokenize=False, add_generation_prompt=True
    )

    sampler = make_sampler(temp=0.1)
    buffer = io.StringIO()
    
    with contextlib.redirect_stdout(buffer):
        generate(
            model, tokenizer,
            prompt=formatted_prompt,
            max_tokens=600,
            sampler=sampler,
            verbose=True
        )
    raw = buffer.getvalue()

    stats_pat = re.compile(r'\n={5,}\s*\nPrompt:', re.DOTALL)
    m = stats_pat.search(raw)
    text = raw[:m.start()].strip() if m else raw.strip()

    if "</think>" in text:
        text = text.split("</think>")[-1].strip()
    else:
        text = text.replace("<think>", "").strip()

    decoder = json.JSONDecoder()
    data = None
    idx = text.find('{')
    while idx != -1:
        try:
            data, _ = decoder.raw_decode(text, idx)
            break
        except json.JSONDecodeError:
            idx = text.find('{', idx + 1)

    if data:
        output = f"**Resumen general:**\n{data.get('resumen', 'No disponible')}\n\n"
        output += f"**Sintaxis:**\n{data.get('sintaxis', 'No disponible')}\n\n"
        if data.get('opciones'):
            output += "**Opciones principales:**\n"
            for opt in data.get('opciones', [])[:10]:
                output += f"- {opt}\n"
            output += "\n"
        output += f"**Ejemplo:**\n{data.get('ejemplo', 'No disponible')}"
        print(output)
    else:
        print(text if text else "El modelo no generó una respuesta estructurada.")

except Exception as e:
    print(f"❌ Error interno de MLX: {e}", file=sys.stderr)
    sys.exit(1)
EOF

    local RESPUESTA
    RESPUESTA=$(python3 "$TMP_SCRIPT" "$MLX_COPILOT_MODEL" "$PROMPT" 2>/tmp/mlx_error.log)
    local EXIT_CODE=$?
    rm -f "$TMP_SCRIPT"

    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "❌ Error de MLX. Revisa con: cat /tmp/mlx_error.log"
        return 1
    fi

    echo "\n=========================================================="
    echo "💡 EXPLICACIÓN DEL COMANDO:"
    echo "=========================================================="
    if command -v bat &>/dev/null; then
        echo "$RESPUESTA" | bat --style=plain --language=markdown --paging=never
    else
        echo "$RESPUESTA"
    fi
    echo "==========================================================\n"
}
