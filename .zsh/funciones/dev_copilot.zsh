#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: dev_copilot.zsh
# PROPÓSITO: Asistente de Desarrollo + Mantenimiento IA Local
# MOTOR: MLX — Apple Silicon ARM64 (Mac Mini M4 / MacBook Air M1)
# REVISIÓN: 2026-04-29 — Fix regex/printf/escape + HF API check + MLX_PYTHON
# ==============================================================================

# ── Modelo activo ─────────────────────────────────────────────────────────────
export MLX_COPILOT_MODEL="mlx-community/Qwen3-4B-4bit"

# ── Python con mlx-lm instalado ───────────────────────────────────────────────
# whence -p: Zsh built-in que resuelve ruta física en $PATH, ignorando aliases
if [[ -x "/opt/homebrew/opt/python@3.11/libexec/bin/python3" ]]; then
    export MLX_PYTHON="/opt/homebrew/opt/python@3.11/libexec/bin/python3"
else
    export MLX_PYTHON="$(whence -p python3 2>/dev/null || print python3)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# git-ia
# Descripción: Analiza git diff HEAD y propone 3 mensajes de commit semánticos
#              (feat/fix/chore/docs) usando Qwen3 vía MLX local.
# Uso: git-ia   (requiere haber hecho git add antes)
# ─────────────────────────────────────────────────────────────────────────────
function git-ia() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf "❌ Error: No estás dentro de un repositorio de Git.\n"
        return 1
    fi

    local DIFF
    DIFF=$(git diff HEAD)
    if [[ -z "$DIFF" ]]; then
        printf "📭 No hay cambios detectados. Haz 'git add' primero.\n"
        return 1
    fi

    printf "⚡ Analizando código con MLX y generando mensajes...\n"

    local TMP_DIFF TMP_SCRIPT
    TMP_DIFF=$(mktemp /tmp/mlx_diff_XXXXXX.txt)
    TMP_SCRIPT=$(mktemp /tmp/mlx_git_XXXXXX.py)

    printf '%s' "$DIFF" | head -c 3000 > "$TMP_DIFF"

    # << 'PYEOF': sin expansión shell → \n llega literal al .py
    # r'\n' en raw string Python = regex newline real ✓ (NO r'\\n')
    cat > "$TMP_SCRIPT" << 'PYEOF'
import sys, io, re, json, contextlib
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
    '{"commits": ["mensaje 1", "mensaje 2", "mensaje 3"]}. DIFF:\n' + diff_text
)

try:
    model, tokenizer = load(model_name)
    messages = [{"role": "user", "content": prompt_text}]
    formatted_prompt = tokenizer.apply_chat_template(
        messages, tokenize=False, add_generation_prompt=True
    )

    sampler = make_sampler(temp=0.1)
    buffer  = io.StringIO()

    with contextlib.redirect_stdout(buffer):
        generate(model, tokenizer, prompt=formatted_prompt,
                 max_tokens=800, sampler=sampler, verbose=True)

    raw = buffer.getvalue()

    # FIX: r'\n' → regex newline real (era r'\\n' → matcheaba literal \n)
    stats_pat = re.compile(r'\n={5,}\s*\nPrompt:', re.DOTALL)
    m    = stats_pat.search(raw)
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
        # FIX: split('\n') → newline real (era split('\\n') → split en literal \n)
        lines = [l.strip() for l in text.split('\n')
                 if any(p in l for p in ('feat:', 'fix:', 'chore:', 'docs:'))]
        if lines:
            for i, line in enumerate(lines[:3], 1):
                print(f"{i}. {line}")
        else:
            print("1. chore: actualizar archivos")

except Exception as e:
    print(f"❌ Error MLX: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF

    local RESPUESTA exit_code
    RESPUESTA=$("$MLX_PYTHON" "$TMP_SCRIPT" "$MLX_COPILOT_MODEL" "$TMP_DIFF" 2>/tmp/mlx_error.log)
    exit_code=$?
    rm -f "$TMP_SCRIPT" "$TMP_DIFF"

    if (( exit_code != 0 )) || [[ -z "$RESPUESTA" ]]; then
        printf "❌ Sin respuesta de MLX. Revisa: cat /tmp/mlx_error.log\n"
        return 1
    fi

    # FIX: printf en lugar de echo (echo no expande \n en Zsh por defecto)
    printf "\n💡 SUGERENCIAS DE AUTO-COMMIT:\n"
    if command -v bat &>/dev/null; then
        printf '%s\n' "$RESPUESTA" | bat --style=plain --language=markdown --paging=never
    else
        printf '%s\n' "$RESPUESTA"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# explicar
# Descripción: Explica cualquier comando macOS/Unix con resumen, sintaxis,
#              opciones y ejemplo. Salida formateada Markdown vía bat.
# Uso: explicar <comando>   Ej: explicar rsync
# ─────────────────────────────────────────────────────────────────────────────
function explicar() {
    if [[ -z "$1" ]]; then
        printf "❌ Uso: explicar <comando>\n"
        return 1
    fi

    local PROMPT="Eres un manual de macOS. Analiza el comando '${1}' y responde SOLO con este JSON EXACTO: {\"resumen\": \"una línea corta\", \"sintaxis\": \"ejemplo de uso\", \"opciones\": [\"opción 1\", \"opción 2\"], \"ejemplo\": \"bat archivo.txt\"}."
    local TMP_SCRIPT
    TMP_SCRIPT=$(mktemp /tmp/mlx_explicar_XXXXXX.py)

    cat > "$TMP_SCRIPT" << 'PYEOF'
import sys, io, re, json, contextlib
from mlx_lm import load, generate
from mlx_lm.sample_utils import make_sampler

try:
    model, tokenizer = load(sys.argv[1])
    messages = [{"role": "user", "content": sys.argv[2]}]
    formatted_prompt = tokenizer.apply_chat_template(
        messages, tokenize=False, add_generation_prompt=True
    )

    sampler = make_sampler(temp=0.1)
    buffer  = io.StringIO()

    with contextlib.redirect_stdout(buffer):
        generate(model, tokenizer, prompt=formatted_prompt,
                 max_tokens=600, sampler=sampler, verbose=True)

    raw = buffer.getvalue()
    # FIX: r'\n' → regex newline real
    stats_pat = re.compile(r'\n={5,}\s*\nPrompt:', re.DOTALL)
    m    = stats_pat.search(raw)
    text = raw[:m.start()].strip() if m else raw.strip()

    if "</think>" in text:
        text = text.split("</think>")[-1].strip()

    decoder = json.JSONDecoder()
    data = None
    idx  = text.find('{')
    while idx != -1:
        try:
            data, _ = decoder.raw_decode(text, idx)
            break
        except json.JSONDecodeError:
            idx = text.find('{', idx + 1)

    if data:
        # FIX: \n en f-string → salto real (era \\n → imprimía literal \n)
        print(f"**Resumen general:**\n{data.get('resumen', 'No disponible')}")
        print(f"\n**Sintaxis:**\n{data.get('sintaxis', 'No disponible')}")
        print("\n**Opciones principales:**")
        for opt in data.get('opciones', [])[:10]:
            print(f"- {opt}")
        print(f"\n**Ejemplo:**\n{data.get('ejemplo', 'No disponible')}")
    else:
        print(text if text else "Error de formato")

except Exception as e:
    print(f"❌ Error MLX: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF

    printf "⚡ Analizando comando con Apple Silicon (MLX)...\n"

    local RESPUESTA exit_code
    RESPUESTA=$("$MLX_PYTHON" "$TMP_SCRIPT" "$MLX_COPILOT_MODEL" "$PROMPT" 2>/tmp/mlx_error.log)
    exit_code=$?
    rm -f "$TMP_SCRIPT"

    if (( exit_code != 0 )) || [[ -z "$RESPUESTA" ]]; then
        printf "❌ Sin respuesta de MLX. Revisa: cat /tmp/mlx_error.log\n"
        return 1
    fi

    printf "\n💡 EXPLICACIÓN DEL COMANDO:\n"
    if command -v bat &>/dev/null; then
        printf '%s\n' "$RESPUESTA" | bat --style=plain --language=markdown --paging=never
    else
        printf '%s\n' "$RESPUESTA"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# conversar-mantener
# Descripción: Panel de mantenimiento MLX. Actualiza paquetes pip, muestra
#              versiones activas y coteja cada modelo local contra la HF API
#              comparando SHA de commit (refs/main) para detectar actualizaciones.
#              Opera de forma completamente aislada — no toca otras funciones.
# Uso: conversar-mantener
# Lógica de detección:
#   ~/.cache/huggingface/hub/models--mlx-community--*/refs/main → SHA local
#   https://huggingface.co/api/models/mlx-community/{modelo}   → SHA remoto
#   Si difieren → hay nueva versión disponible en HF.
# ─────────────────────────────────────────────────────────────────────────────
function conversar-mantener() {
    printf "\n  ╔══════════════════════════════════════════════════════════╗\n"
    printf "  ║       🔧  Mantenimiento IA Local · MLX                   ║\n"
    printf "  ╚══════════════════════════════════════════════════════════╝\n\n"

    # FIX: todos los locales declarados al inicio de la función
    # En Zsh, 'local var=value' dentro de un for loop imprime las asignaciones
    local _pip _net_ok cachedir
    local modelo_dir nombre tamano refs_file local_sha remote_sha api_json

    # ── Resolver pip del entorno correcto (Homebrew Python@3.11) ─────────────
    if [[ -x "/opt/homebrew/opt/python@3.11/libexec/bin/pip3" ]]; then
        _pip="/opt/homebrew/opt/python@3.11/libexec/bin/pip3"
    else
        _pip="$(command -v pip3 2>/dev/null || command -v pip 2>/dev/null)"
    fi

    if [[ -z "$_pip" ]]; then
        printf "  ❌ pip no encontrado. Verifica tu instalación de Homebrew Python.\n\n"
        return 1
    fi

    # ── 1/3 Actualizar paquetes ───────────────────────────────────────────────
    printf "  📦 Actualizando mlx-lm...\n"
    "$_pip" install --upgrade mlx-lm --quiet 2>/dev/null \
        && printf "  ✅ mlx-lm actualizado\n" \
        || printf "  ❌ Error al actualizar mlx-lm\n"

    printf "  📦 Actualizando mlx-vlm...\n"
    "$_pip" install --upgrade mlx-vlm --quiet 2>/dev/null \
        && printf "  ✅ mlx-vlm actualizado\n" \
        || printf "  ❌ Error al actualizar mlx-vlm\n"

    # ── 2/3 Versiones activas ─────────────────────────────────────────────────
    printf "\n  📋 Versiones activas:\n"
    printf "     mlx-lm  : %s\n" "$("$_pip" show mlx-lm  2>/dev/null | awk '/^Version/{print $2}')"
    printf "     mlx-vlm : %s\n" "$("$_pip" show mlx-vlm 2>/dev/null | awk '/^Version/{print $2}')"

    # ── 3/3 Modelos en caché + cotejo SHA remoto via HF API ──────────────────
    cachedir="$HOME/.cache/huggingface/hub"
    if [[ ! -d "$cachedir" ]]; then
        printf "\n  ⚠️  Caché no encontrada: %s\n\n" "$cachedir"
        return 0
    fi

    # Test de conectividad (timeout 2 s — no bloquea si no hay internet)
    _net_ok=0
    curl -s --max-time 2 --head "https://huggingface.co" -o /dev/null 2>/dev/null \
        && _net_ok=1

    printf "\n  🗂️  Modelos en caché"
    (( _net_ok )) \
        && printf " (🌐 cotejando con Hugging Face):\n\n" \
        || printf " (📵 sin red — sólo caché local):\n\n"

    for modelo_dir in "$cachedir"/models--mlx-community--*/; do
        [[ -d "$modelo_dir" ]] || continue

        # Solo asignaciones dentro del loop — sin 'local' (ya declarados arriba)
        nombre=$(basename "$modelo_dir" | sed 's/^models--mlx-community--//')
        tamano=$(du -sh "$modelo_dir" 2>/dev/null | awk '{print $1}')

        refs_file="$modelo_dir/refs/main"
        if [[ -f "$refs_file" ]]; then
            local_sha=$(tr -d '[:space:]' < "$refs_file" | cut -c1-7)
        else
            local_sha="???????"
        fi

        if (( _net_ok )); then
            api_json=$(curl -s --max-time 5 \
                "https://huggingface.co/api/models/mlx-community/${nombre}" 2>/dev/null)
            remote_sha=$(printf '%s' "$api_json" \
                | "$MLX_PYTHON" -c \
                    "import sys,json; d=json.load(sys.stdin); print(d.get('sha','')[:7])" \
                    2>/dev/null)

            if [[ -z "$remote_sha" ]]; then
                printf "     ⚪ %-44s (%s)  [sin datos remotos]\n" "$nombre" "$tamano"
            elif [[ "$local_sha" == "$remote_sha" ]]; then
                printf "     ✅ %-44s (%s)  [%s · al día]\n" "$nombre" "$tamano" "$local_sha"
            else
                printf "     🆕 %-44s (%s)  [local:%s → remoto:%s]\n" \
                    "$nombre" "$tamano" "$local_sha" "$remote_sha"
                printf "        Para actualizar:\n"
                printf "          rm -rf %s\n" "$modelo_dir"
                printf "          mlx_lm.generate --model mlx-community/%s --prompt 'test'\n" \
                    "$nombre"
            fi
        else
            printf "     •  %-44s (%s)  [local:%s]\n" "$nombre" "$tamano" "$local_sha"
        fi
    done

    printf "\n  🤖 MLX_COPILOT_MODEL activo : %s\n" "$MLX_COPILOT_MODEL"
    printf "  📎 Nuevos modelos           : https://huggingface.co/mlx-community\n\n"
}
