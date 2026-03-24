#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: 01-exports.zsh
# PROPÓSITO: Definición de variables de entorno y PATH de macOS
# ==============================================================================

# 1. Idioma y Localización
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 2. PATH Principal (Homebrew va primero en Apple Silicon)
export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/Library/Apple/usr/bin

# 3. Python de Homebrew
if [[ -d "/opt/homebrew/opt/python@3.11/libexec/bin" ]]; then
export PATH="/opt/homebrew/opt/python@3.11/libexec/bin:$PATH"
elif [[ -d "/opt/homebrew/opt/python@3.11/bin" ]]; then
export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"
fi

# 4. Scripts Públicos (Dotfiles)
export PATH="$HOME/Documents/dotfiles/scripts:$PATH"

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

# 8. SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Mantener el PATH limpio de duplicados en ZSH
typeset -U PATH

