#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: media.zsh
# PROPÓSITO: Flujo local de transcripción, traducción e incrustación de video
# DEPENDENCIAS: ffmpeg, mlx-whisper (Python)
# ==============================================================================

# -------------------------------------------------------------------
# incrustarSubs
# Incrusta subtítulos de un archivo .srt en un video .mp4 usando ffmpeg
# -------------------------------------------------------------------
incrustarSubs() {
  if [[ -z "$1" ]]; then
    echo "Uso: incrustarSubs archivo_video.mp4"
    return 1
  fi
  local input="$1"
  local base="${input%.*}"
  local srt_file="${base}.srt"
  local output="${base}_sub.mp4"

  if [[ ! -f "$input" ]]; then
    echo "Error: No se encontró el video '$input'"
    return 1
  fi
  if [[ ! -f "$srt_file" ]]; then
    echo "Error: No se encontró el archivo de subtítulos '$srt_file'"
    return 1
  fi
  
  echo "Incrustando subtítulos de '$srt_file' en '$input'..."
  ffmpeg -i "$input" -vf subtitles=$srt_file "$output" -y

  if [[ $? -eq 0 ]]; then
    echo "✅ Completado: '$output' creado exitosamente."
  else
    echo "❌ Ocurrió un error al procesar el archivo con ffmpeg."
    return 1
  fi
}

# -------------------------------------------------------------------
# extraerSubs
# Transcribe un video/audio a subtítulos usando MLX-Whisper
# -------------------------------------------------------------------
extraerSubs() {
  if [[ -z "$1" ]]; then
    echo "❌ Error: Falta el archivo de entrada"
    echo "Uso: extraerSubs <video_o_audio> [modelo] [opciones]"
    return 1
  fi
  
  local input="$1"
  if [[ ! -f "$input" ]]; then
    echo "❌ Error: Archivo no encontrado '$input'"
    return 1
  fi
  
  local base="${input%.*}"
  local model_short="${2:-small}"
  local model_name
  
  case "$model_short" in
    tiny)   model_name="mlx-community/whisper-tiny-mlx" ;;
    base)   model_name="mlx-community/whisper-base-mlx" ;;
    small)  model_name="mlx-community/whisper-small-mlx" ;;
    medium) model_name="mlx-community/whisper-medium-mlx" ;;
    *)
      echo "❌ Error: Modelo desconocido '$model_short'."
      return 1
      ;;
  esac
  
  local generate_srt=true
  local generate_vtt=true
  local generate_txt=true
  
  for arg in "${@:3}"; do
    case "$arg" in
      --srt-only) generate_vtt=false; generate_txt=false ;;
      --vtt-only) generate_srt=false; generate_txt=false ;;
      --txt-only) generate_srt=false; generate_vtt=false ;;
    esac
  done
  
  echo "🎬 Transcribiendo: $input con $model_short"
  local script_tmp=$(mktemp)
  
  cat > "$script_tmp" << 'PYTHON_SCRIPT'
import mlx_whisper
import sys

input_file = sys.argv[1]
model_name = sys.argv[2]
base_name = sys.argv[3]
gen_srt = sys.argv[4] == "true"
gen_vtt = sys.argv[5] == "true"
gen_txt = sys.argv[6] == "true"

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
    
    def fmt_vtt(sec):
        h = int(sec // 3600)
        m = int((sec % 3600) // 60)
        s = int(sec % 60)
        ms = int((sec % 1) * 1000)
        return f"{h:02d}:{m:02d}:{s:02d}.{ms:03d}"
    
    if gen_srt:
        with open(f"{base_name}.srt", 'w', encoding='utf-8') as f:
            for idx, seg in enumerate(result['segments'], 1):
                f.write(f"{idx}\n{fmt_srt(seg['start'])} --> {fmt_srt(seg['end'])}\n{seg['text'].strip()}\n\n")
    if gen_vtt:
        with open(f"{base_name}.vtt", 'w', encoding='utf-8') as f:
            f.write("WEBVTT\n\n")
            for seg in result['segments']:
                f.write(f"{fmt_vtt(seg['start'])} --> {fmt_vtt(seg['end'])}\n{seg['text'].strip()}\n\n")
    if gen_txt:
        with open(f"{base_name}.txt", 'w', encoding='utf-8') as f:
            f.write(result['text'])
    
    print("\n✨ ¡Transcripción completada!")
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
PYTHON_SCRIPT
  
  python3 "$script_tmp" "$input" "$model_name" "$base" "$generate_srt" "$generate_vtt" "$generate_txt"
  local exit_code=$?
  rm -f "$script_tmp"
  
  if [[ $exit_code -ne 0 ]]; then return 1; fi
}

