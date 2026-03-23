#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: 01-exports.zsh
# PROPÓSITO: Definición de variables de entorno y PATH de macOS
# ==============================================================================

# 1. Idioma y Localización
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 2. PATH Principal (Homebrew, Binarios del Sistema)
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/Library/Apple/usr/bin:/opt/homebrew/bin

# 3. Scripts Personales Sincronizados (iCloud Drive)
export PATH="$HOME/scripts:$HOME/scripts/cerebro:$PATH"

# 4. Pyenv (Gestión de Python)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# 5. LM Studio CLI
export PATH="$PATH:$HOME/.lmstudio/bin"

# 6. Utilidades Locales
export PATH="$HOME/.local/bin:$PATH"

# 7. SDKMAN (Debe ir al final por su naturaleza de carga)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Mantener el PATH limpio de duplicados en ZSH
typeset -U PATH
