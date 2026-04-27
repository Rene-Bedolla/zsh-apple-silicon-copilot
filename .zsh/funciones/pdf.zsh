# -------------------------------------------------------------------
# quitapass_pdf
# Descripción: Elimina la contraseña de usuario de un PDF con qpdf.
#              Sobreescribe el archivo original de forma segura
#              (qpdf usa un temporal interno, operación atómica).
# Uso:         quitapass_pdf archivo.pdf
# Dependencia: brew install qpdf
# -------------------------------------------------------------------
function quitapass_pdf() {

  # — Validar argumento —
  if [[ -z "$1" ]]; then
    echo "❌ Uso: quitapass_pdf archivo.pdf"
    return 1
  fi

  local pdf_input="$1"

  # — Verificar existencia del archivo —
  if [[ ! -f "$pdf_input" ]]; then
    echo "❌ Archivo no encontrado: $pdf_input"
    return 1
  fi

  # — Auto-instalar qpdf si no existe (una sola vez) —
  if ! command -v qpdf &>/dev/null; then
    echo "⚠️  qpdf no está instalado. Instalando con Homebrew..."
    brew install qpdf || { echo "❌ No se pudo instalar qpdf."; return 1 }
  fi

  # — Leer contraseña sin mostrarla en pantalla —
  read -s "pdf_pass?🔑 Contraseña del PDF: "
  echo ""

  echo "🧠 Descifrando PDF... (operación atómica vía temporal interno)"

  # — Descifrar y sobreescribir el original —
  # --replace-input: qpdf escribe en un .tmp y reemplaza al terminar,
  #                  garantizando que el original no se corrompe si falla.
  if qpdf --password="$pdf_pass" --decrypt --replace-input "$pdf_input" 2>/dev/null; then
    echo "✅ PDF desbloqueado: ${pdf_input:t}"
  else
    echo "❌ Error: contraseña incorrecta o el PDF no tiene cifrado de apertura."
    echo "   💡 Si solo tiene restricciones de impresión/edición (owner password),"
    echo "      prueba: qpdf --decrypt --replace-input \"$pdf_input\""
    return 1
  fi
}
