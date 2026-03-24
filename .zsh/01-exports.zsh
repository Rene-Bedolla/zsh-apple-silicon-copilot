#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: 01-exports.zsh
# PROPÓSITO: Definición de variables de entorno y PATH de macOS
# ==============================================================================

# 1. Idioma y Localización
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 2. PATH Principal
# FIX 1: Homebrew (/opt/homebrew/bin) DEBE ir al inicio en Apple Silicon
# para que sus comandos tengan prioridad sobre los de macOS.
export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/Library/Apple/usr/bin

# 3. Python de Homebrew (Prioridad para MLX IA)
# FIX 2: Asegurar que 'python3' sea el mismo que usa 'pip3' (donde vive mlx_lm)
if [[ -d "/opt/homebrew/opt/python@3.11/libexec/bin" ]]; then
    export PATH="/opt/homebrew/opt/python@3.11/libexec/bin:$PATH"
elif [[ -d "/opt/homebrew/opt/python@3.11/bin" ]]; then
    export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"
fi

# 4. Scripts Personales Sincronizados (iCloud Drive)
export PATH="$HOME/scripts:$HOME/scripts/cerebro:$PATH"

# 5. Pyenv (Gestión de Python)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# 6. LM Studio CLI
export PATH="$PATH:$HOME/.lmstudio/bin"

# 7. Utilidades Locales
export PATH="$HOME/.local/bin:$PATH"

# 8. SDKMAN (Debe ir al final por su naturaleza de carga)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Mantener el PATH limpio de duplicados en ZSH
typeset -U PATH
