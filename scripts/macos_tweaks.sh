#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: macos_tweaks.sh
# PROPÓSITO: Menú interactivo para aplicar o revertir configuraciones de macOS
# ==============================================================================

sudo -v # Pedir permisos una sola vez

function aplicar_defaults() {
    echo "\n🍏 Selecciona las configuraciones a aplicar (s/n):"
    
    read -p "1. ¿Mostrar siempre archivos y carpetas ocultas? (s/n): " resp
    if [[ "$resp" == "s" ]]; then
        defaults write com.apple.finder AppleShowAllFiles -bool true
    fi

    read -p "2. ¿Acelerar brutalmente el teclado y quitar acentos de tecla larga? (s/n): " resp
    if [[ "$resp" == "s" ]]; then
        defaults write -g ApplePressAndHoldEnabled -bool false
        defaults write -g KeyRepeat -int 1
        defaults write -g InitialKeyRepeat -int 10
    fi

    read -p "3. ¿Eliminar el retraso (delay) al ocultar el Dock? (s/n): " resp
    if [[ "$resp" == "s" ]]; then
        defaults write com.apple.dock autohide-delay -float 0
        defaults write com.apple.dock autohide-time-modifier -float 0.2
    fi

    read -p "4. ¿Acelerar las animaciones de todas las ventanas? (s/n): " resp
    if [[ "$resp" == "s" ]]; then
        defaults write -g NSWindowResizeTime -float 0.001
    fi

    echo "\n🔄 Reiniciando Finder y Dock para aplicar cambios..."
    killall Finder
    killall Dock
    echo "✅ Configuraciones aplicadas."
}

function revertir_defaults() {
    echo "\n⏪ Revertiendo configuraciones a los valores de fábrica de Apple..."
    
    # Revertir Finder
    defaults delete com.apple.finder AppleShowAllFiles 2>/dev/null
    
    # Revertir Teclado
    defaults delete -g ApplePressAndHoldEnabled 2>/dev/null
    defaults delete -g KeyRepeat 2>/dev/null
    defaults delete -g InitialKeyRepeat 2>/dev/null
    
    # Revertir Dock
    defaults delete com.apple.dock autohide-delay 2>/dev/null
    defaults delete com.apple.dock autohide-time-modifier 2>/dev/null
    
    # Revertir Animaciones
    defaults delete -g NSWindowResizeTime 2>/dev/null

    echo "\n🔄 Reiniciando Finder y Dock para aplicar cambios..."
    killall Finder
    killall Dock
    echo "✅ Restauración completada. Tu Mac ha vuelto a la normalidad."
}

echo "=========================================================="
echo "      🛠️  MACOS HACKER DEFAULTS (MENÚ INTERACTIVO)      "
echo "=========================================================="
echo "1) Aplicar configuraciones ocultas (preguntar una a una)"
echo "2) Revertir TODO a como Apple lo entrega de fábrica"
echo "3) Salir"
echo "=========================================================="
read -p "Elige una opción (1-3): " opcion

case $opcion in
    1) aplicar_defaults ;;
    2) revertir_defaults ;;
    3) exit 0 ;;
    *) echo "Opción no válida." ;;
esac
