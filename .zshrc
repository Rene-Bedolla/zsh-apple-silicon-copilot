# ==============================================================================
# ARCHIVO: .zshrc
# PROPÓSITO: Inicialización de ZSH (Arquitectura Modular - Zero Friction)
# ==============================================================================

# 1. Caché e Inicialización Rápida (Powerlevel10k)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 2. Oh My Zsh Base
export ZSH="$HOME/.oh-my-zsh"
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme  
plugins=(git)
source $ZSH/oh-my-zsh.sh

# 3. Historial y Autocompletado ZSH
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY HIST_VERIFY
setopt AUTO_CD CORRECT
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 4. Carga Modular Dinámica (Cero Fricción)
ZSH_CONFIG_DIR="$HOME/Documents/dotfiles/.zsh"

if [[ -d "$ZSH_CONFIG_DIR" ]]; then
    # 4.1 Cargar variables de entorno y alias base
    [[ -f "$ZSH_CONFIG_DIR/01-exports.zsh" ]] && source "$ZSH_CONFIG_DIR/01-exports.zsh"
    [[ -f "$ZSH_CONFIG_DIR/02-aliases.zsh" ]] && source "$ZSH_CONFIG_DIR/02-aliases.zsh"

    # 4.2 Cargar dinámicamente herramientas de la carpeta /funciones/
    if [[ -d "$ZSH_CONFIG_DIR/funciones" ]]; then
        for func_file in "$ZSH_CONFIG_DIR"/funciones/*.zsh; do
            source "$func_file"
        done
    fi
fi

# 4.3 Carga del entorno privado (Ignorado por GitHub, solo visible para ti)
if [[ -d "$HOME/Documents/dotfiles/privado" ]]; then
    # El modificador (N) evita errores si la carpeta existe pero está vacía
    for priv_file in "$HOME/Documents/dotfiles/privado"/*.zsh(N); do
        source "$priv_file"
    done
fi

# 5. Herramientas de Navegación Inteligente (Zoxide)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# 6. Plugins Finales y Sintaxis
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# 7. Tema Powerlevel10k (Debe ir al final absoluto)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
