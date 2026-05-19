#!/bin/zsh
# ==============================================================================
# ARCHIVO: dashboard-start.sh
# PROPÓSITO: Lanzador simple del dashboard local de HERMES
# USO: bash ~/Documents/dotfiles/hermes/scripts/dashboard-start.sh
# ==============================================================================

export HERMES_PORT="${HERMES_PORT:-8421}" && \
exec /opt/homebrew/opt/python@3.11/libexec/bin/python3 ~/Documents/dotfiles/hermes/dashboard.py
