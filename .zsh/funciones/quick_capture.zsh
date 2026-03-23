#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: quick_capture.zsh
# PROPÓSITO: Sistema universal y agnóstico de captura rápida de notas (Markdown).
# ==============================================================================

# Definimos el directorio universal de captura (agnóstico a Obsidian/Notion)
export UNIVERSAL_INBOX="$HOME/.notas_inbox"

# -------------------------------------------------------------------
# nota
# Permite escribir una nota rápida directamente desde la terminal.
# Si la carpeta no existe, la crea. Guarda todo en un archivo diario.
# -------------------------------------------------------------------
function nota() {
    # 1. Verificar si el usuario mandó un mensaje
    if [[ -z "$1" ]]; then
        echo "❌ Uso: nota 'Texto de tu idea o recordatorio'"
        echo "💡 Ejemplo: nota 'Investigar sobre Zoxide para el repo de GitHub'"
        return 1
    fi

    # 2. Crear la bóveda universal si es la primera vez que se usa
    if [[ ! -d "$UNIVERSAL_INBOX" ]]; then
        mkdir -p "$UNIVERSAL_INBOX"
        echo "🌱 Se ha creado tu bandeja de entrada en: $UNIVERSAL_INBOX"
    fi

    # 3. Preparar variables de tiempo y archivo
    local FECHA=$(date +"%Y-%m-%d")
    local HORA=$(date +"%H:%M:%S")
    local ARCHIVO="$UNIVERSAL_INBOX/Inbox_$FECHA.md"

    # 4. Inyectar Frontmatter si el archivo es nuevo hoy
    if [[ ! -f "$ARCHIVO" ]]; then
        echo "---" > "$ARCHIVO"
        echo "title: Bandeja de entrada - $FECHA" >> "$ARCHIVO"
        echo "tags: [inbox, terminal]" >> "$ARCHIVO"
        echo "---" >> "$ARCHIVO"
        echo "\n# Notas del $FECHA\n" >> "$ARCHIVO"
    fi

    # 5. Escribir la nota con formato de viñeta (bullet) y hora
    echo "- **[$HORA]**: $1" >> "$ARCHIVO"

    # 6. Feedback silencioso y elegante
    echo "✅ Nota guardada en Inbox_$FECHA.md"
}

# -------------------------------------------------------------------
# leer-notas
# Muestra rápidamente las notas capturadas el día de hoy usando bat (cat).
# -------------------------------------------------------------------
function leer-notas() {
    local FECHA=$(date +"%Y-%m-%d")
    local ARCHIVO="$UNIVERSAL_INBOX/Inbox_$FECHA.md"
    
    if [[ -f "$ARCHIVO" ]]; then
        bat --paging=never --style=plain "$ARCHIVO"
    else
        echo "📭 Tu bandeja de entrada de hoy está vacía."
    fi
}
