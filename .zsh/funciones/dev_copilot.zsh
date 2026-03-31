#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: dev_copilot.zsh
# PROPÓSITO: Asistente de Desarrollo impulsado por IA Local en Español
# MOTOR: MLX (Nativo para Apple Silicon)
# ==============================================================================

export MLX_COPILOT_MODEL="mlx-community/Qwen3-4B-4bit"
export MLX_PYTHON="$HOME/.local/bin/mlx_python"

function git-ia() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Error: No estás dentro de un repositorio de Git."
        return 1
    fi

    local DIFF=$(git diff HEAD)
    if [[ -z "$DIFF" ]]; then
        echo "📭 No hay cambios detectados. Haz 'git add' primero."
        return 1
    fi

    echo "⚡ Analizando código con MLX y generando mensajes..."

    local TMP_DIFF=$(mktemp /tmp/mlx_diff_XXXXXX.txt)
    echo "$DIFF" | head -c 3000 > "$TMP_DIFF"

    local TMP_SCRIPT=$(mktemp /tmp/mlx_git_XXXXXX.py)

    cat > "$TMP_SCRIPT" << 'PYEOF'
import sys, io, re, json, contextlib
from mlx_lm import load, generate
from mlx_lm.sample_utils import make_sampler

model_name = sys.argv[1]
diff_path = sys.argv[2]

with open(diff_path, 'r', errors='replace') as f:
    diff_text = f.read()

prompt_text = (
    "Eres un desarrollador senior. Analiza este git diff y genera 3 opciones "
    "de mensajes de commit (feat, fix, chore, etc). "
    'RESPONDE ÚNICAMENTE CON UN JSON VÁLIDO CON ESTA ESTRUCTURA EXACTA: '
    '{"commits": ["mensaje 1", "mensaje 2", "mensaje 3"]}. DIFF:\n' + diff_text
)

try:
    model, tokenizer = load(model_name)
    messages = [{"role": "user", "content": prompt_text}]
    formatted_prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)

    sampler = make_sampler(temp=0.1)
    buffer = io.StringIO()

    with contextlib.redirect_stdout(buffer):
        generate(model, tokenizer, prompt=formatted_prompt, max_tokens=800, sampler=sampler, verbose=True)

    raw = buffer.getvalue()
    stats_pat = re.compile(r'\n={5,}\s*\nPrompt:', re.DOTALL)
    m = stats_pat.search(raw)
    text = raw[:m.start()].strip() if m else raw.strip()

    if "</think>" in text: text = text.split("</think>")[-1].strip()
    else: text = text.replace("<think>", "").strip()

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
        if isinstance(obj, list): return obj
        if isinstance(obj, dict):
            for v in obj.values():
                res = extract_list(v)
                if res: return res
        return None

    parsed = find_first_json(text)
    if parsed:
        commits = extract_list(parsed)
        if commits:
            for i, commit in enumerate(commits[:3], 1):
                if isinstance(commit, str):
                    print(f"{i}. {commit.replace('`','').strip()}")
                elif isinstance(commit, dict):
                    print(f"{i}. {str(next(iter(commit.values()), '')).replace('`','').strip()}")
        else:
            print("1. chore: actualizar archivos")
    else:
        lines = [l.strip() for l in text.split('\n') if any(p in l for p in ('feat:', 'fix:', 'chore:', 'docs:'))]
        if lines:
            for i, line in enumerate(lines[:3], 1): print(f"{i}. {line}")
        else:
            print("1. chore: actualizar archivos")

except Exception as e:
    print(f"❌ Error MLX: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF

    local RESPUESTA=$("$MLX_PYTHON" "$TMP_SCRIPT" "$MLX_COPILOT_MODEL" "$TMP_DIFF" 2>/tmp/mlx_error.log)
    rm -f "$TMP_SCRIPT" "$TMP_DIFF"

    echo "\n💡 SUGERENCIAS DE AUTO-COMMIT:"
    if command -v bat &>/dev/null; then echo "$RESPUESTA" | bat --style=plain --language=markdown --paging=never; else echo "$RESPUESTA"; fi
}

function explicar() {
    if [[ -z "$1" ]]; then return 1; fi

    local PROMPT="Eres un manual de macOS. Analiza el comando '${1}' y responde SOLO con este JSON EXACTO: {\"resumen\": \"una línea corta\", \"sintaxis\": \"ejemplo de uso\", \"opciones\": [\"opción 1\", \"opción 2\"], \"ejemplo\": \"bat archivo.txt\"}."
    local TMP_SCRIPT=$(mktemp /tmp/mlx_explicar_XXXXXX.py)

    cat > "$TMP_SCRIPT" << 'PYEOF'
import sys, io, re, json, contextlib
from mlx_lm import load, generate
from mlx_lm.sample_utils import make_sampler

try:
    model, tokenizer = load(sys.argv[1])
    messages = [{"role": "user", "content": sys.argv[2]}]
    formatted_prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)

    sampler = make_sampler(temp=0.1)
    buffer = io.StringIO()

    with contextlib.redirect_stdout(buffer):
        generate(model, tokenizer, prompt=formatted_prompt, max_tokens=600, sampler=sampler, verbose=True)

    raw = buffer.getvalue()
    stats_pat = re.compile(r'\n={5,}\s*\nPrompt:', re.DOTALL)
    m = stats_pat.search(raw)
    text = raw[:m.start()].strip() if m else raw.strip()
    if "</think>" in text: text = text.split("</think>")[-1].strip()

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
        print(f"**Resumen general:**\n{data.get('resumen', 'No disponible')}\n\n**Sintaxis:**\n{data.get('sintaxis', 'No disponible')}\n\n**Opciones principales:**")
        for opt in data.get('opciones', [])[:10]: print(f"- {opt}")
        print(f"\n**Ejemplo:**\n{data.get('ejemplo', 'No disponible')}")
    else:
        print(text if text else "Error de formato")

except Exception as e:
    sys.exit(1)
PYEOF

    echo "⚡ Analizando comando con Apple Silicon (MLX)..."
    local RESPUESTA=$("$MLX_PYTHON" "$TMP_SCRIPT" "$MLX_COPILOT_MODEL" "$PROMPT" 2>/tmp/mlx_error.log)
    rm -f "$TMP_SCRIPT"

    echo "\n💡 EXPLICACIÓN DEL COMANDO:"
    if command -v bat &>/dev/null; then echo "$RESPUESTA" | bat --style=plain --language=markdown --paging=never; else echo "$RESPUESTA"; fi
}

# -------------------------------------------------------------------
# conversar-mantener
# Panel de mantenimiento para MLX: actualiza paquetes y lista modelos.
# -------------------------------------------------------------------
function conversar-mantener() {
    echo "\n🔧 Mantenimiento IA Local MLX"
    echo "=========================================================="

    # 1. Actualizar paquetes Python
    echo "\n📦 1/3 Actualizando mlx-lm..."
    pip install --upgrade mlx-lm --quiet \
        && echo "   ✅ mlx-lm actualizado" \
        || echo "   ❌ Error al actualizar mlx-lm"

    echo "📦     Actualizando mlx-vlm..."
    pip install --upgrade mlx-vlm --quiet \
        && echo "   ✅ mlx-vlm actualizado" \
        || echo "   ❌ Error al actualizar mlx-vlm"

    # 2. Versiones instaladas
    echo "\n📋 2/3 Versiones activas:"
    echo "   mlx-lm  → $(pip show mlx-lm 2>/dev/null | grep Version | awk '{print $2}')"
    echo "   mlx-vlm → $(pip show mlx-vlm 2>/dev/null | grep Version | awk '{print $2}')"

    # 3. Modelos en caché local con su tamaño en disco
    echo "\n🗂️  3/3 Modelos descargados en caché local:"
    local cachedir="$HOME/.cache/huggingface/hub"
    if [[ -d "$cachedir" ]]; then
        for modelo in "$cachedir"/models--mlx-community--*/; do
            local nombre=$(basename "$modelo" | sed 's/models--mlx-community--//')
            local tamano=$(du -sh "$modelo" 2>/dev/null | awk '{print $1}')
            echo "   📁 $nombre ($tamano)"
        done
    else
        echo "   ⚠️  No se encontró el directorio de caché."
    fi

    echo "\n=========================================================="
    echo "💡 Para reemplazar un modelo descarga el nuevo con:"
    echo "   mlx_lm.generate --model mlx-community/NUEVO-MODELO --prompt 'Hola'"
    echo "   y actualiza MLX_COPILOT_MODEL en dev_copilot.zsh"
    echo "==========================================================\n"
}
