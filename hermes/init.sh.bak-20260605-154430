#!/usr/bin/env bash
# ==============================================================================
# ARCHIVO: init.sh
# PROPÓSITO: Validar entorno antes de activar agentes HERMES y registrar estado
# PILAR: 1 — El Repositorio como Sistema
# ==============================================================================

HERMES_DIR="$HOME/Documents/dotfiles/hermes"
STATUS_FILE="$HOME/.hermes/status.json"
HISTORY_FILE="$HERMES_DIR/history.md"

PASS=0; FAIL=0; WARN=0

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

check_ok()   { echo -e "  ${GREEN}✅${NC} $1"; ((PASS++)); }
check_fail() { echo -e "  ${RED}❌${NC} $1"; ((FAIL++)); }
check_warn() { echo -e "  ${YELLOW}⚠️${NC}  $1"; ((WARN++)); }

# Variables de estado para status.json
MLX_UP="false"
MLX_MODELS=""
HERMES_INSTALLED="false"
TG_UP="false"

echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   🔍  HERMES — Validación de Entorno             ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo ""

# ── 1. Python 3.11 ────────────────────────────────────────────────
if /opt/homebrew/opt/python@3.11/libexec/bin/python3 -c "import sys; assert sys.version_info[:2] == (3,11)" 2>/dev/null; then
    check_ok "Python 3.11 activo"
else
    check_fail "Python 3.11 no encontrado en Homebrew"
fi

# ── 2. mlx-lm instalado ───────────────────────────────────────────
if /opt/homebrew/opt/python@3.11/libexec/bin/python3 -c "import mlx_lm" 2>/dev/null; then
    check_ok "mlx-lm instalado"
else
    check_fail "mlx-lm no instalado — ejecuta: pip install mlx-lm"
fi

# ── 3. Servidor MLX REST ──────────────────────────────────────────
if curl -s --max-time 3 http://localhost:8000/v1/models &>/dev/null; then
    check_ok "Servidor MLX activo en :8000"
    MLX_UP="true"
    # Intentar listar modelos activos para status.json (no es crítico si falla)
    MLX_MODELS=$(/opt/homebrew/opt/python@3.11/libexec/bin/python3 - << 'PYEOF' 2>/dev/null
import sys, json
try:
    data = json.load(sys.stdin)
    ids = [m.get("id","") for m in data.get("data", [])]
    print(",".join([i for i in ids if i]))
except Exception:
    pass
PYEOF
    < <(curl -s --max-time 3 http://localhost:8000/v1/models))
else
    check_warn "Servidor MLX inactivo — ejecuta: mlx-on"
    MLX_UP="false"
fi

# ── 4. Hermes Agent instalado ─────────────────────────────────────
if command -v hermes &>/dev/null; then
    check_ok "Hermes Agent instalado ($(hermes --version 2>/dev/null | head -1))"
    HERMES_INSTALLED="true"
else
    check_fail "Hermes Agent no encontrado"
    HERMES_INSTALLED="false"
fi

# ── 5. OpenRouter API key ─────────────────────────────────────────
if grep -q "^OPENROUTER_API_KEY=sk-or" "$HOME/.hermes/.env" 2>/dev/null; then
    check_ok "OpenRouter API key configurada"
else
    check_fail "OpenRouter API key no configurada en ~/.hermes/.env"
fi

# ── 6. Gateway Telegram ───────────────────────────────────────────
if launchctl list 2>/dev/null | grep -q "ai.hermes.gateway"; then
    check_ok "Gateway Telegram activo"
    TG_UP="true"
else
    check_warn "Gateway Telegram inactivo — ejecuta: hermes gateway start"
    TG_UP="false"
fi

# ── 7. Archivos raíz del harness ──────────────────────────────────
for archivo in agents.md Nexus.md features.json; do
    if [[ -f "$HERMES_DIR/$archivo" ]]; then
        check_ok "$archivo presente"
    else
        check_warn "$archivo no encontrado en hermes/"
    fi
done

# ── 8. Directorios de progreso ────────────────────────────────────
mkdir -p "$HERMES_DIR/progress/"{orchestrator,explorer,implementer,reviewer}
check_ok "Directorios progress/ verificados"

# ── 9. Sincronizar mlx-server-start.sh → /usr/local/bin ───────────
SRC="$HERMES_DIR/scripts/mlx-server-start.sh"
DST="/usr/local/bin/hermes-mlx-server"
if [[ -f "$SRC" && -f "$DST" ]]; then
    if ! diff -q "$SRC" "$DST" &>/dev/null; then
        if sudo cp "$SRC" "$DST" 2>/dev/null; then
            check_ok "hermes-mlx-server sincronizado"
        else
            check_warn "No se pudo sincronizar hermes-mlx-server"
        fi
    else
        check_ok "hermes-mlx-server al día"
    fi
fi

# ── Resumen por consola ───────────────────────────────────────────
echo ""
echo "  Resultado: ${PASS} ✅  ${WARN} ⚠️   ${FAIL} ❌"
echo ""

# ── 10. Escribir ~/.hermes/status.json ────────────────────────────
mkdir -p "$HOME/.hermes"

TIMESTAMP=$(date --iso-8601=seconds 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$STATUS_FILE" << JSONEOF
{
  "timestamp": "${TIMESTAMP}",
  "mlx": {
    "up": ${MLX_UP},
    "endpoint": "http://localhost:8000/v1",
    "models": "${MLX_MODELS}"
  },
  "hermes_agent": {
    "installed": ${HERMES_INSTALLED}
  },
  "telegram_gateway": {
    "up": ${TG_UP}
  },
  "summary": {
    "pass": ${PASS},
    "warn": ${WARN},
    "fail": ${FAIL}
  }
}
JSONEOF

# ── 11. Registrar entrada en history.md ───────────────────────────
if [[ ! -f "$HISTORY_FILE" ]]; then
    cat > "$HISTORY_FILE" << 'HEOF'
---
version: "1.0"
actualizado: "2026-05-19"
publico: true
---

# HERMES — Historial de Sesiones

HEOF
fi

{
  echo ""
  echo "## $(date '+%Y-%m-%d %H:%M:%S') — init.sh"
  echo ""
  echo "- resultado: ${PASS} OK, ${WARN} WARN, ${FAIL} FAIL"
  echo "- mlx: up=${MLX_UP}, modelos=[${MLX_MODELS}]"
  echo "- hermes_agent: installed=${HERMES_INSTALLED}"
  echo "- telegram_gateway: up=${TG_UP}"
} >> "$HISTORY_FILE"

# ── 12. Código de salida ──────────────────────────────────────────
if (( FAIL > 0 )); then
    echo "  ❌ Corrige los errores antes de operar HERMES."
    exit 1
else
    echo "  ✅ Entorno validado. HERMES listo para operar."
    exit 0
fi
