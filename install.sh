#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: install.sh
# PROPÓSITO: Instalación de 1-Clic del Entorno Zsh Apple Silicon Copilot
# AUTOR: René López Bedolla
# ==============================================================================

echo "==========================================================="
echo "🚀 INICIANDO INSTALACIÓN: ZSH APPLE SILICON COPILOT"
echo "==========================================================="
echo "Este script configurará tu terminal e instalará las"
echo "herramientas necesarias (Homebrew, Zsh, MLX, etc)."
echo ""

# 1. Instalar Homebrew si no existe
if ! command -v brew &> /dev/null; then
    echo "🍺 1/5 Instalando Homebrew (Te pedirá tu contraseña)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ 1/5 Homebrew ya está instalado."
fi

# 2. Instalar dependencias
echo "📦 2/5 Instalando paquetes esenciales y Zoxide..."
brew install eza bat fzf zoxide python@3.11 ffmpeg jq
brew install romkatv/powerlevel10k/powerlevel10k
brew install zsh-autosuggestions zsh-syntax-highlighting

# 3. Clonar el repositorio
echo "📥 3/5 Descargando la configuración de GitHub..."
mkdir -p "$HOME/Documents"
if [ -d "$HOME/Documents/dotfiles" ]; then
    echo "   ⚠️ La carpeta dotfiles ya existe. Actualizando..."
    cd "$HOME/Documents/dotfiles" && git pull origin main
else
    git clone https://github.com/Rene-Bedolla/zsh-apple-silicon-copilot.git "$HOME/Documents/dotfiles"
fi

# 4. Configurar Enlaces Simbólicos
echo "🔗 4/5 Conectando el entorno a la terminal..."
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    echo "   Respaldando tu .zshrc anterior como .zshrc.backup"
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi
ln -sf "$HOME/Documents/dotfiles/.zshrc" "$HOME/.zshrc"

# 5. Configurar Scripts
echo "📂 5/5 Configurando scripts globales..."
if [ ! -d "$HOME/scripts" ]; then
    cp -R "$HOME/Documents/dotfiles/scripts" "$HOME/"
else
    cp -R "$HOME/Documents/dotfiles/scripts/"* "$HOME/scripts/" 2>/dev/null
fi

echo "==========================================================="
echo "🎉 ¡INSTALACIÓN COMPLETADA CON ÉXITO!"
echo "==========================================================="
echo "Para activar tu nuevo entorno, abre una nueva ventana"
echo "de la terminal o ejecuta: source ~/.zshrc"
echo ""
echo "💡 Para optimizar tu Mac, puedes ejecutar:"
echo "   macos-tweaks"
echo "==========================================================="
