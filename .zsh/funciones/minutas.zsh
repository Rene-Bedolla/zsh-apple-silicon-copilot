#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: minutas.zsh
# PROPÓSITO: Generación automatizada de minutas (MLX/Whisper) y volcado a Obsidian
# ==============================================================================

# -------------------------------------------------------------------
# guardar_minuta (gminuta)
# Toma el texto del portapapeles y lo guarda como nota en Obsidian
# -------------------------------------------------------------------
function guardar_minuta() {
    if [ -z "$1" ]; then
        echo "❌ Error: Debes proporcionar un nombre para la reunión."
        echo "👉 Uso: gminuta 'Nombre_Reunion'"
        return 1
    fi
    
    local NOMBRE_REUNION="$1"
    NOMBRE_REUNION="${NOMBRE_REUNION// /_}"
    
    local OBSIDIAN_DIR="$HOME/Notas/Notas"
    
    if [ ! -d "$OBSIDIAN_DIR" ]; then
        echo "❌ Error: No se encuentra la carpeta INBOX en $OBSIDIAN_DIR"
        return 1
    fi

    local FECHA=$(date +"%Y-%m-%d")
    local RUTA_FINAL="$OBSIDIAN_DIR/$FECHA - Minuta - $NOMBRE_REUNION.md"
    local TEXTO_MINUTA=$(pbpaste)

    if [ -z "$TEXTO_MINUTA" ]; then
        echo "❌ Error: El portapapeles está vacío."
        return 1
    fi

    echo "---" > "$RUTA_FINAL"
    echo "fecha: $FECHA" >> "$RUTA_FINAL"
    echo "origen: ia-local" >> "$RUTA_FINAL"
    echo "tags:" >> "$RUTA_FINAL"
    echo "  - inbox" >> "$RUTA_FINAL"
    echo "  - minuta" >> "$RUTA_FINAL"
    echo "---" >> "$RUTA_FINAL"
    echo "" >> "$RUTA_FINAL"
    echo "$TEXTO_MINUTA" >> "$RUTA_FINAL"
    
    echo "✅ Minuta guardada con éxito en INBOX!"
    echo "📄 Ruta: $RUTA_FINAL"
    
    pbcopy < /dev/null
}
alias gminuta="guardar_minuta"

# -------------------------------------------------------------------
# Funciones Helpers y Procesamiento IA (Qwen3)
# -------------------------------------------------------------------
_limpiar_output_qwen() {
    local tmpscript=$(mktemp /tmp/qwen_clean_XXXXXX.py)
    cat > "$tmpscript" << 'PYEOF'
import sys, re
texto = sys.stdin.read()
texto = re.sub(r'<think>.*?</think>', '', texto, flags=re.DOTALL)
texto = re.sub(r'\n?(Prompt:|Generation:|Peak memory:).*', '', texto)
print(texto.strip())
PYEOF
    python3 "$tmpscript"
    rm -f "$tmpscript"
}

function texto-minuta() {
    if [ -z "$1" ]; then
        echo "❌ Uso: texto-minuta 'Nombre de la Reunion'"
        return 1
    fi

    local texto=$(pbpaste)
    if [ -z "$texto" ]; then
        echo "❌ Portapapeles vacío. Copia la transcripción antes (Cmd+C)."
        return 1
    fi

    echo "📋 Procesando texto...🧠 Analizando con Qwen3-8B..."
    local prompt_completo="/no_think Actúa como un analista experto. Lee la siguiente transcripción y extrae estructurado: 1) Resumen (3 viñetas), 2) Tareas, 3) Puntos críticos. Transcripción: $texto"

    local minuta=$(mlx_lm.generate --model mlx-community/Qwen3-8B-4bit --max-tokens 2000 --temp 0.1 --prompt "$prompt_completo" 2>/dev/null | _limpiar_output_qwen)

    if [ -z "$minuta" ]; then
        echo "❌ Error: Qwen3 no generó respuesta."
        return 1
    fi

    echo "$minuta" | pbcopy
    echo "📝 Guardando en Obsidian..."
    gminuta "$1"
}

function audio-minuta() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "❌ Uso: audio-minuta <archivo_audio> 'Nombre de la Reunion'"
        return 1
    fi

    local audio="$1"
    local nombre="$2"
    local base="${audio%.*}"

    if [ ! -f "$audio" ]; then
        echo "❌ Archivo '$audio' no encontrado."
        return 1
    fi

    echo "🎬 1/3 Transcribiendo '$audio'..."
    extraerSubs "$audio" small --txt-only

    local txt_file="${base}.txt"
    if [ ! -f "$txt_file" ]; then
        echo "❌ Transcripción fallida."
        return 1
    fi

    local texto_audio=$(cat "$txt_file")
    echo "🧠 2/3 Analizando con Qwen3-8B..."

    local prompt_completo="/no_think Actúa como analista. Extrae: 1) Resumen, 2) Tareas, 3) Puntos críticos. Transcripción: $texto_audio"
    local minuta=$(mlx_lm.generate --model mlx-community/Qwen3-8B-4bit --max-tokens 2000 --temp 0.1 --prompt "$prompt_completo" 2>/dev/null | _limpiar_output_qwen)

    echo "$minuta" | pbcopy
    echo "📝 3/3 Guardando..."
    gminuta "$nombre"
    echo "✅ ¡Listo!"
}

