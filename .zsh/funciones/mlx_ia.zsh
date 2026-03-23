#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: mlx_ia.zsh
# PROPÓSITO: Interfaz interactiva de IA Local (MLX) usando Qwen3
# ==============================================================================

# Elimina alias previo si existe para permitir la función
unalias conversar 2>/dev/null

# -------------------------------------------------------------------
# conversar()
# Menú interactivo para iniciar chats con IA usando diferentes parámetros
# -------------------------------------------------------------------
conversar() {
  echo ""
  echo "  ╔══════════════════════════════════════════════════════════╗"
  echo "  ║          🤖  IA LOCAL · MLX · Qwen3                      ║"
  echo "  ╠══════════════════════════════════════════════════════════╣"
  echo "  ║  1) rápido    Consultas cortas y definiciones  [4B]      ║"
  echo "  ║  2) código    Debug, scripts, arquitectura     [8B·T0.4] ║"
  echo "  ║  3) max       Análisis profundo, sin límite    [8B]      ║"
  echo "  ║  4) creativo  Brainstorming e ideas            [8B·T0.8] ║"
  echo "  ║  5) preciso   Datos exactos, traducción, SQL   [8B·T0.3] ║"
  echo "  ║  6) visión    Análisis de imágenes             [VL·4B]   ║"
  echo "  ╚══════════════════════════════════════════════════════════╝"
  echo ""
  echo -n "  Modo [1-6]: "
  read modo
  echo ""

  case $modo in
    1)
      echo "  ⚡ Iniciando modo rápido — Qwen3 4B\n"
      mlx_lm.chat --model mlx-community/Qwen3-4B-4bit --max-tokens 1000 --temp 0.6 --top-p 0.9
      ;;
    2)
      echo "  💻 Iniciando modo código — Qwen3 8B (temp 0.4)\n"
      mlx_lm.chat --model mlx-community/Qwen3-8B-4bit --max-tokens 2000 --temp 0.4 --top-p 0.85
      ;;
    3)
      echo "  🔍 Iniciando modo max — Qwen3 8B (sin límite de tokens)\n"
      mlx_lm.chat --model mlx-community/Qwen3-8B-4bit --max-tokens -1 --temp 0.6 --top-p 0.9
      ;;
    4)
      echo "  ✨ Iniciando modo creativo — Qwen3 8B (temp 0.8)\n"
      mlx_lm.chat --model mlx-community/Qwen3-8B-4bit --max-tokens 2000 --temp 0.8 --top-p 0.95
      ;;
    5)
      echo "  🎯 Iniciando modo preciso — Qwen3 8B (temp 0.3)\n"
      mlx_lm.chat --model mlx-community/Qwen3-8B-4bit --max-tokens 2000 --temp 0.3 --top-p 0.7
      ;;
    6)
      echo "  🖼️  Iniciando modo visión — Qwen3 VL 4B\n"
      echo -n "  Ruta de imagen (Enter para omitir): "
      read imagen
      echo ""
      if [[ -n "$imagen" ]]; then
        python -m mlx_vlm.generate --model mlx-community/Qwen3-VL-4B-Instruct-4bit --image "$imagen" --prompt "Describe y analiza esta imagen en español con detalle." --max-tokens 1500 --temp 0.6
      else
        python -m mlx_vlm.generate --model mlx-community/Qwen3-VL-4B-Instruct-4bit --max-tokens 1500 --temp 0.6
      fi
      ;;
    *)
      echo "  ❌ Opción no válida. Elige un número entre 1 y 6."
      conversar
      ;;
  esac
}

# -------------------------------------------------------------------
# conversar-mantener()
# Utilidad de diagnóstico y actualización de dependencias MLX
# -------------------------------------------------------------------
conversar-mantener() {
  echo "\n  ╔══════════════════════════════════════════════════════════╗"
  echo "  ║       🔧  Mantenimiento IA Local · MLX                   ║"
  echo "  ╚══════════════════════════════════════════════════════════╝\n"

  echo "  📦 Actualizando mlx-lm..."
  pip install --upgrade mlx-lm --quiet && echo "  ✅ mlx-lm actualizado" || echo "  ❌ Error al actualizar mlx-lm"

  echo "  📦 Actualizando mlx-vlm..."
  pip install --upgrade mlx-vlm --quiet && echo "  ✅ mlx-vlm actualizado" || echo "  ❌ Error al actualizar mlx-vlm"

  echo "\n  📋 Versiones activas:"
  echo "     mlx-lm  : $(pip show mlx-lm 2>/dev/null | grep Version | awk '{print $2}')"
  echo "     mlx-vlm : $(pip show mlx-vlm 2>/dev/null | grep Version | awk '{print $2}')"

  echo "\n  🗂️  Modelos descargados en caché:"
  local cache_dir="$HOME/.cache/huggingface/hub"
  if [[ -d "$cache_dir" ]]; then
    for modelo in "$cache_dir"/models--mlx-community--*/; do
      local nombre=$(basename "$modelo" | sed 's/models--mlx-community--//')
      local tamaño=$(du -sh "$modelo" 2>/dev/null | awk '{print $1}')
      echo "     • $nombre  ($tamaño)"
    done
  else
    echo "     (No se encontró el directorio de caché)"
  fi

  echo "\n  ⚠️  Los modelos MLX no se actualizan automáticamente."
  echo "     Los nuevos releases aparecen en: https://huggingface.co/mlx-community\n"
}

# Utilidades no interactivas
alias conversar-generar='mlx_lm.generate --model mlx-community/Qwen3-8B-4bit --max-tokens 3000 --temp 0.6 --top-p 0.9'
alias conversar-medidor='mlx_lm.generate --model mlx-community/Qwen3-8B-4bit --max-tokens 2000 --temp 0.6 --top-p 0.9 --verbose'

