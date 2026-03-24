#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: install.sh
# PROPÓSITO: Instalación de 1-Clic del Entorno Zsh Apple Silicon Copilot
# AUTOR: René López Bedolla
# ==============================================================================

set -e

echo "==========================================================="
echo "🚀 INICIANDO INSTALACIÓN: Zsh Apple Silicon Copilot"
echo "==========================================================="
echo "Este script configurará tu terminal completa y automáticamente."

# 1. INSTALAR HOMEBREW
echo "🍺 1/7 Instalando Homebrew..."
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo " ✅ Homebrew ya está instalado."
fi

# 2. INSTALAR HERRAMIENTAS CLI MODERNAS
echo "📦 2/7 Instalando herramientas CLI modernas..."
brew install eza bat fzf zoxide python@3.11 ffmpeg jq

# 3. INSTALAR TEMA Y PLUGINS ZSH
echo "🎨 3/7 Instalando Powerlevel10k y plugins Zsh..."
brew install romkatv/powerlevel10k/powerlevel10k
brew install zsh-autosuggestions zsh-syntax-highlighting

# 4. INSTALAR MLX (LA SOLUCIÓN NATIVA Y SEGURA)
echo "🤖 4/7 Instalando MLX para IA Local (Cerebro de la terminal)..."
# Instalamos la versión oficial de Homebrew para asegurar dependencias nativas
brew install mlx-lm
# Instalamos usando --user para evitar errores de permisos "Permission denied"
# y --break-system-packages para evitar el candado "externally-managed"
/opt/homebrew/bin/python3 -m pip install --user mlx mlx-lm mlx-vlm --break-system-packages --ignore-installed --quiet
echo " ✅ Motor MLX configurado con éxito."

# Creamos el alias universal para que los scripts nunca fallen
mkdir -p "$HOME/.local/bin"
ln -sf "/opt/homebrew/bin/python3" "$HOME/.local/bin/mlx_python"

# 5. DESCARGAR MODELO DE IA BASE
echo "🧠 5/7 Descargando modelo de IA local (Qwen3 4B)..."
"$HOME/.local/bin/mlx_python" -c "
from mlx_lm import load
model, tokenizer = load('mlx-community/Qwen3-4B-4bit')
print('✅ Modelo descargado y listo para usar')
"

# 6. CLONAR EL REPOSITORIO
echo "📥 6/7 Descargando la configuración desde GitHub..."
mkdir -p "$HOME/Documents"
cd "$HOME/Documents"
if [ -d "dotfiles" ]; then
  echo " Actualizando repositorio existente..."
  cd dotfiles && git pull origin main && cd ..
else
  git clone https://github.com/Rene-Bedolla/zsh-apple-silicon-copilot.git dotfiles
fi

# 7. CONFIGURAR ENLACES SIMBÓLICOS
echo "🔗 7/7 Conectando el entorno a la terminal..."
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M)"
fi
ln -sf "$HOME/Documents/dotfiles/.zshrc" "$HOME/.zshrc"

mkdir -p "$HOME/scripts"
cp -R "$HOME/Documents/dotfiles/scripts/"* "$HOME/scripts/" 2>/dev/null || true

echo "==========================================================="
echo "🎉 ¡INSTALACIÓN COMPLETADA CON ÉXITO!"
echo "🔄 Ejecuta 'source ~/.zshrc' para activar."
echo "==========================================================="
