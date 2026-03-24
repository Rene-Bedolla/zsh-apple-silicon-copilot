#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: sistema.zsh
# PROPÓSITO: Funciones de mantenimiento y respaldo del entorno de usuario
# ==============================================================================

function generar_cold_backup() {
    echo "📦 Iniciando creación del Respaldo Portable Inteligente..."

    local FECHA=$(date +"%Y-%m-%d_%H%M")
    local CARPETA_RESPALDO="$HOME/Desktop/Entorno_Ren_$FECHA"
    local ARCHIVO_ZIP="$HOME/Desktop/Entorno_Ren_$FECHA.zip"

    mkdir -p "$CARPETA_RESPALDO/dotfiles"
    mkdir -p "$CARPETA_RESPALDO/scripts"

    echo "   ↳ Copiando configuración modular Zsh..."
    cp -RL "$HOME/Documents/dotfiles/.zshrc" "$CARPETA_RESPALDO/dotfiles/" 2>/dev/null
    cp -RL "$HOME/Documents/dotfiles/.zsh" "$CARPETA_RESPALDO/dotfiles/" 2>/dev/null

    echo "   ↳ Copiando scripts de automatización..."
    cp -RL "$HOME/scripts/"* "$CARPETA_RESPALDO/scripts/" 2>/dev/null

    # -----------------------------------------------------------------
    # 1. SCRIPT DE BOOTSTRAP (PARA MACS NUEVAS)
    # -----------------------------------------------------------------
    echo "   ↳ Generando script de preparación (Bootstrap)..."
    cat << 'EOF' > "$CARPETA_RESPALDO/00_preparar_mac_nueva.command"
#!/usr/bin/env bash
echo "==========================================================="
echo "🍏 PREPARACIÓN DE MAC NUEVA - ENTORNO ZSH (René)"
echo "==========================================================="
echo "Este script instalará las herramientas base (Homebrew, "
echo "Oh My Zsh, eza, bat, Powerlevel10k). Pedirá tu contraseña."
echo ""

# 1. Instalar Homebrew si no existe
if ! command -v brew &> /dev/null; then
    echo "🍺 Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew ya está instalado."
fi

# 2. Instalar paquetes esenciales
echo "📦 Instalando paquetes esenciales (eza, bat, fzf, python)..."
brew install eza bat fzf zoxide python@3.11 ffmpeg

# 3. Instalar Oh My Zsh si no existe
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "⚙️ Instalando Oh My Zsh..."
    RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "✅ Oh My Zsh ya está instalado."
fi

# 4. Instalar Tema y Plugins
echo "🎨 Descargando Tema y Plugins de Zsh..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k 2>/dev/null
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null

# Para Homebrew tap de powerlevel10k y plugins
brew install romkatv/powerlevel10k/powerlevel10k
brew install zsh-autosuggestions zsh-syntax-highlighting

echo ""
echo "==========================================================="
echo "🎉 PREPARACIÓN COMPLETADA."
echo "Ahora puedes ejecutar '01_instalar_entorno.command'."
echo "==========================================================="
read -p "Presiona [Enter] para salir..."
EOF

    # -----------------------------------------------------------------
    # 2. SCRIPT DE INSTALACIÓN DEL ENTORNO (TU CONFIGURACIÓN)
    # -----------------------------------------------------------------
    echo "   ↳ Generando script autoinstalador..."
    cat << 'EOF' > "$CARPETA_RESPALDO/01_instalar_entorno.command"
#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "==========================================================="
echo "🚀 INYECTANDO ENTORNO MODULAR (René)"
echo "==========================================================="

echo "📂 Instalando carpeta de Scripts..."
if [ ! -d "$HOME/scripts" ]; then
    cp -R "$DIR/scripts" "$HOME/"
else
    cp -R "$DIR/scripts/"* "$HOME/scripts/" 2>/dev/null
fi

echo "⚙️ Instalando Arquitectura Modular en Documents..."
mkdir -p "$HOME/Documents/dotfiles"
cp -R "$DIR/dotfiles/"* "$HOME/Documents/dotfiles/"

echo "🔗 Conectando cerebro a la terminal..."
if [ -f "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi
ln -s "$HOME/Documents/dotfiles/.zshrc" "$HOME/.zshrc"

echo "==========================================================="
echo "🎉 ¡INSTALACIÓN COMPLETADA! Abre una nueva ventana de terminal."
echo "==========================================================="
read -p "Presiona [Enter] para salir..."
EOF

    # Dar permisos de ejecución a ambos scripts
    chmod +x "$CARPETA_RESPALDO/00_preparar_mac_nueva.command"
    chmod +x "$CARPETA_RESPALDO/01_instalar_entorno.command"

    # Generar archivo Léeme explicativo corto
    echo "   ↳ Generando archivo LEEME.txt..."
    cat << 'EOF' > "$CARPETA_RESPALDO/LEEME.txt"
¡Hola! Para instalar este entorno de terminal:

CASO A: ES UNA MAC NUEVA (No tiene nada instalado)
1. Haz doble clic en "00_preparar_mac_nueva.command" y espera a que termine.
2. Haz doble clic en "01_instalar_entorno.command".
3. Abre tu aplicación Terminal. ¡Listo!

CASO B: ES TU MAC (Solo quieres restaurar un respaldo)
1. Ignora el archivo 00.
2. Haz doble clic directo en "01_instalar_entorno.command".
3. Abre tu aplicación Terminal. ¡Listo!
EOF

    # Comprimir y Limpiar
    echo "   ↳ Comprimiendo en formato universal (.zip)..."
    (cd "$HOME/Desktop" && zip -rq "Entorno_Ren_$FECHA.zip" "Entorno_Ren_$FECHA")
    rm -rf "$CARPETA_RESPALDO"

    echo "\n✅ ¡ÉXITO! Tu respaldo completo está listo:"
    echo "   📄 Archivo: Entorno_Ren_$FECHA.zip"
}

# -------------------------------------------------------------------
# git-sync
# Asistente interactivo paso a paso para respaldar en GitHub.
# Integra git-ia para generar los mensajes automáticamente.
# -------------------------------------------------------------------
function git-sync() {
    # 1. Verificar si estamos en un repositorio
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Error: No estás dentro de un repositorio de Git."
        return 1
    fi

    echo "\n📦 Estado actual de tus archivos:"
    git status -s
    echo ""

    # Preguntar si deseamos agregar todo (Empacar la caja)
    if read -q "?¿Deseas agregar todos los cambios (git add .)? [y/N]: "; then
        echo "\n"
        git add .
        echo "✅ Archivos preparados."
    else
        echo "\n🛑 Operación cancelada por el usuario."
        return 1
    fi

    echo "\n🤖 Consultando a tu IA Local (Qwen3) para sugerir la etiqueta..."
    # Llamamos a tu propia función de dev_copilot.zsh
    git-ia 

    echo "\n📝 Escribe el mensaje para tu commit (puedes pegar una opción de arriba):"
    echo "   (O presiona Enter sin escribir nada para cancelar)"
    read "MENSAJE"

    if [[ -n "$MENSAJE" ]]; then
        git commit -m "$MENSAJE"
        echo "✅ Caja sellada (Commit creado)."
    else
        echo "🛑 Cancelado: Un commit requiere un mensaje."
        # Revertir el 'git add' para dejar el repositorio como estaba
        git reset HEAD >/dev/null 2>&1
        return 1
    fi

    # Preguntar si subimos a GitHub (Llamar a la paquetería)
    echo ""
    if read -q "?¿Deseas subir los cambios a GitHub (git push)? [y/N]: "; then
        echo "\n🚀 Subiendo al servidor..."
        git push
        echo "🎉 ¡Sincronización exitosa!"
    else
        echo "\n📦 Los cambios están guardados localmente, pero NO se subieron a GitHub."
    fi
}

# -------------------------------------------------------------------
# reescribir
# Función para reemplazar rápidamente todo el contenido de un archivo
# Uso: reescribir ruta/al/archivo
# -------------------------------------------------------------------
function reescribir() {
    if [[ -z "$1" ]]; then
        echo "❌ Uso: reescribir ruta/al/archivo"
        return 1
    fi
    echo "📝 Pega todo el nuevo contenido ahora."
    echo "Cuando termines, presiona Enter, luego Ctrl+D."
    echo "--------------------------------------------------------"
    cat > "$1"
    echo "--------------------------------------------------------"
    echo "✅ Archivo $1 actualizado correctamente."
}
