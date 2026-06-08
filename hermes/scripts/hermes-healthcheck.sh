#!/bin/zsh
set -u

HERMES_DIR="$HOME/Documents/dotfiles/hermes"
SOUL_FILE="$HOME/.hermes/SOUL.md"
AGENTS_FILE="$HERMES_DIR/AGENTS.md"
ARCHIVIST_README="$HERMES_DIR/agents/archivist/README.md"
ARCHIVIST_TEMPLATE_SUMMARY="$HERMES_DIR/agents/archivist/templates/session-summary.md"
ARCHIVIST_TEMPLATE_SKILL="$HERMES_DIR/agents/archivist/templates/skill-proposal.md"
DEVOPS_README="$HERMES_DIR/agents/devops-harness/README.md"
MLX_PORT="8000"

ok()   { printf "  ✅ %s\n" "$1"; }
warn() { printf "  ⚠️  %s\n" "$1"; }
err()  { printf "  ❌ %s\n" "$1"; }
info() { printf "  ℹ️  %s\n" "$1"; }

exists_file() {
  [[ -f "$1" ]]
}

exists_dir() {
  [[ -d "$1" ]]
}

section() {
  printf "\n%s\n" "$1"
}

printf "\n"
printf "╔══════════════════════════════════════════════════════╗\n"
printf "║   HERMES — Healthcheck local de Mac Mini M4         ║\n"
printf "╚══════════════════════════════════════════════════════╝\n"

section "=== 1) Rutas críticas ==="
if exists_dir "$HERMES_DIR"; then ok "Proyecto Hermes presente en $HERMES_DIR"; else err "No existe $HERMES_DIR"; fi
if exists_file "$SOUL_FILE"; then ok "SOUL.md presente en ~/.hermes"; else err "Falta ~/.hermes/SOUL.md"; fi
if exists_file "$AGENTS_FILE"; then ok "AGENTS.md presente"; else err "Falta $AGENTS_FILE"; fi
if exists_file "$ARCHIVIST_README"; then ok "Archivist README presente"; else warn "Falta $ARCHIVIST_README"; fi
if exists_file "$ARCHIVIST_TEMPLATE_SUMMARY"; then ok "Plantilla session-summary presente"; else warn "Falta $ARCHIVIST_TEMPLATE_SUMMARY"; fi
if exists_file "$ARCHIVIST_TEMPLATE_SKILL"; then ok "Plantilla skill-proposal presente"; else warn "Falta $ARCHIVIST_TEMPLATE_SKILL"; fi
if exists_file "$DEVOPS_README"; then ok "devops-harness README presente"; else warn "Falta $DEVOPS_README"; fi

section "=== 2) CLI y binarios ==="
if command -v hermes >/dev/null 2>&1; then
  ok "Hermes CLI disponible: $(command -v hermes)"
else
  err "hermes no está en PATH"
fi

if command -v python3 >/dev/null 2>&1; then
  ok "python3 disponible: $(command -v python3)"
  info "Versión Python: $(python3 --version 2>/dev/null)"
else
  err "python3 no está en PATH"
fi

if command -v lsof >/dev/null 2>&1; then
  ok "lsof disponible"
else
  warn "lsof no está disponible"
fi

section "=== 3) Estado de Hermes ==="
if command -v hermes >/dev/null 2>&1; then
  HERMES_VERSION="$(hermes --version 2>/dev/null | head -n 1)"
  if [[ -n "${HERMES_VERSION}" ]]; then
    ok "Hermes responde: ${HERMES_VERSION}"
  else
    warn "Hermes CLI existe pero --version no devolvió salida"
  fi
else
  warn "Se omite validación de versión de Hermes"
fi

if command -v hermes >/dev/null 2>&1; then
  GATEWAY_STATUS="$(hermes gateway status 2>/dev/null | head -n 20)"
  if [[ -n "${GATEWAY_STATUS}" ]]; then
    ok "Hermes gateway responde a status"
    printf "%s\n" "${GATEWAY_STATUS}" | sed 's/^/     /'
  else
    warn "hermes gateway status no devolvió salida"
  fi
fi

section "=== 4) MLX local ==="
if lsof -nP -iTCP:${MLX_PORT} -sTCP:LISTEN >/dev/null 2>&1; then
  ok "Puerto ${MLX_PORT} en escucha"
  lsof -nP -iTCP:${MLX_PORT} -sTCP:LISTEN | sed 's/^/     /'
else
  warn "No hay proceso escuchando en :${MLX_PORT}"
fi

MLX_MODELS_JSON="$(curl -s --max-time 3 http://127.0.0.1:${MLX_PORT}/v1/models 2>/dev/null)"
if [[ -n "${MLX_MODELS_JSON}" ]]; then
  ok "Endpoint MLX responde en http://127.0.0.1:${MLX_PORT}/v1/models"
  printf "%s\n" "${MLX_MODELS_JSON}" | head -c 300 | sed 's/^/     /'
  printf "\n"
else
  warn "El endpoint MLX no respondió en 3 segundos"
fi

section "=== 5) Procesos relevantes ==="
PROCESS_MATCHES="$(ps aux | grep -E 'hermes|mlx|uvicorn|python.*resumen_diario|telegram' | grep -v grep | head -n 20)"
if [[ -n "${PROCESS_MATCHES}" ]]; then
  ok "Se detectaron procesos relevantes"
  printf "%s\n" "${PROCESS_MATCHES}" | sed 's/^/     /'
else
  warn "No se detectaron procesos relevantes con el filtro actual"
fi

section "=== 6) Scripts clave ==="
if exists_file "$HERMES_DIR/resumen_diario.py"; then ok "resumen_diario.py presente"; else warn "Falta resumen_diario.py"; fi
if exists_dir "$HERMES_DIR/resumenes"; then ok "Directorio resumenes presente"; else warn "Falta directorio resumenes"; fi
if exists_dir "$HERMES_DIR/skills/proposals"; then ok "Directorio skills/proposals presente"; else warn "Falta directorio skills/proposals"; fi
if exists_dir "$HERMES_DIR/backlog"; then ok "Directorio backlog presente"; else warn "Falta directorio backlog"; fi

section "=== 7) Riesgos rápidos ==="
if lsof -nP -iTCP:${MLX_PORT} -sTCP:LISTEN >/dev/null 2>&1; then
  info "MLX está levantado; si cargas modelos más pesados en paralelo, vigila RAM"
else
  info "MLX no está activo; esto reduce consumo de RAM, pero el stack local queda incompleto"
fi

if [[ -d "$HOME/.hermes/logs" ]]; then
  ok "Carpeta de logs de Hermes presente en ~/.hermes/logs"
else
  warn "No existe ~/.hermes/logs"
fi

section "=== 8) Resultado ==="
info "Este healthcheck valida solo el entorno local de la Mac Mini"
info "No revisa Synology, GCP ni servicios externos en esta iteración"
info "Si un bloque marca advertencia, no significa fallo total; solo indica que conviene revisar"

printf "\n"
printf "Healthcheck completado.\n"
