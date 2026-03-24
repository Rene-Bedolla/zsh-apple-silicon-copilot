#!/bin/zsh
# extraer-subs-batch.sh
# Extrae subtítulos de videos .mp4 que no tienen .srt, agregando sufijo "- jp"

# ═══════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════
MODELO="${1:-small}"
CONTADOR_PROCESADOS=0
CONTADOR_OMITIDOS=0
ERRORES=()

# Ruta de Python Homebrew 3.11 (CRÍTICO para mlx_whisper)
PYTHON="/opt/homebrew/opt/python@3.11/libexec/bin/python3"

# Mapeo de modelos
case "$MODELO" in
    tiny)
        MODEL_NAME="mlx-community/whisper-tiny-mlx"
        MODEL_DESC="tiny-mlx (3.5GB | 45 tok/s | 97%)"
        ;;
    base)
        MODEL_NAME="mlx-community/whisper-base-mlx"
        MODEL_DESC="base-mlx (5.2GB | 35 tok/s | 98%)"
        ;;
    small)
        MODEL_NAME="mlx-community/whisper-small-mlx"
        MODEL_DESC="small-mlx (8.1GB | 25 tok/s | 99%) ⭐"
        ;;
    medium)
        MODEL_NAME="mlx-community/whisper-medium-mlx"
        MODEL_DESC="medium-mlx (14GB | 12 tok/s | 99.5%)"
        ;;
    *)
        echo "❌ Error: Modelo desconocido '$MODELO'"
        echo "Válidos: tiny, base, small, medium"
        exit 1
        ;;
esac

# ═══════════════════════════════════════════════════════════
# FUNCIÓN DE EXTRACCIÓN (Copia de extraerSubs)
# ═══════════════════════════════════════════════════════════
extraer_subtitulo() {
    local input="$1"
    local base="${input%.mp4}"
    
    echo "📦 Modelo: $MODEL_DESC"
    echo "🎬 Transcribiendo: $input"
    echo "⏳ Procesando..."
    
    # Crea script Python temporal
    local script_tmp=$(mktemp)
    
    cat > "$script_tmp" << 'PYTHON_SCRIPT'
import mlx_whisper
import sys

input_file = sys.argv[1]
model_name = sys.argv[2]
base_name = sys.argv[3]

try:
    result = mlx_whisper.transcribe(
        input_file,
        path_or_hf_repo=model_name,
        word_timestamps=True
    )
    
    def fmt_srt(sec):
        h = int(sec // 3600)
        m = int((sec % 3600) // 60)
        s = int(sec % 60)
        ms = int((sec % 1) * 1000)
        return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"
    
    with open(f"{base_name}.srt", 'w', encoding='utf-8') as f:
        for idx, seg in enumerate(result['segments'], 1):
            f.write(f"{idx}\n{fmt_srt(seg['start'])} --> {fmt_srt(seg['end'])}\n{seg['text'].strip()}\n\n")
    
    print(f"✓ Generado: {base_name}.srt")
    
except Exception as e:
    print(f"✗ Error: {e}")
    sys.exit(1)
PYTHON_SCRIPT
    
    # LÍNEA CRÍTICA: Usa la ruta completa de Python Homebrew
    "$PYTHON" "$script_tmp" "$input" "$MODEL_NAME" "$base"
    local exit_code=$?
    
    rm -f "$script_tmp"
    
    return $exit_code
}

# ═══════════════════════════════════════════════════════════
# PROCESO PRINCIPAL
# ═══════════════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════════"
echo "  Extracción masiva de subtítulos con mlx-whisper"
echo "═══════════════════════════════════════════════════════"
echo "Modelo: $MODELO"
echo "Python: $PYTHON"
echo "Directorio: $(pwd)"
echo ""

# Itera sobre todos los archivos .mp4
for video in *.mp4; do
    # Verifica que realmente existan archivos .mp4
    [[ ! -f "$video" ]] && continue
    
    # Obtiene el nombre base sin extensión
    base="${video%.mp4}"
    
    # Verifica si ya existe un archivo .srt (con cualquier sufijo)
    if [[ -f "${base}.srt" ]] || [[ -f "${base} - jp.srt" ]]; then
        echo "⊘ OMITIDO: $video (ya tiene subtítulos)"
        ((CONTADOR_OMITIDOS++))
        continue
    fi
    
    echo ""
    echo "▶ PROCESANDO: $video"
    echo "────────────────────────────────────────────────────"
    
    # Extrae los subtítulos
    if extraer_subtitulo "$video"; then
        # Renombra el archivo agregando "- jp"
        if [[ -f "${base}.srt" ]]; then
            mv "${base}.srt" "${base} - jp.srt"
            echo "✓ COMPLETADO: ${base} - jp.srt"
            ((CONTADOR_PROCESADOS++))
        fi
    else
        echo "✗ ERROR: Falló la transcripción"
        ERRORES+=("$video")
    fi
done

# Resumen final
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  RESUMEN DE EJECUCIÓN"
echo "═══════════════════════════════════════════════════════"
echo "Videos procesados:    $CONTADOR_PROCESADOS"
echo "Videos omitidos:      $CONTADOR_OMITIDOS"
echo "Errores encontrados:  ${#ERRORES[@]}"

if [[ ${#ERRORES[@]} -gt 0 ]]; then
    echo ""
    echo "Videos con error:"
    for err in "${ERRORES[@]}"; do
        echo "  • $err"
    done
fi

echo ""
echo "✨ Proceso finalizado."
