#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: macos-defaults.sh
# PROPÓSITO: Aplicar configuraciones ocultas de macOS (Hacker Defaults)
# ADVERTENCIA: Cerrará el Finder y el Dock al finalizar para aplicar los cambios.
# ==============================================================================

# Pedir permisos de administrador por si acaso (algunos defaults lo requieren)
sudo -v

echo "🍏 Aplicando optimizaciones extremas para macOS..."

# -------------------------------------------------------------------
# 1. SISTEMA Y RENDIMIENTO
# -------------------------------------------------------------------
echo "   ↳ Acelerando animaciones de ventanas..."
defaults write -g NSWindowResizeTime -float 0.001

echo "   ↳ Expandiendo siempre la ventana de Guardar y de Impresión..."
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# -------------------------------------------------------------------
# 2. TECLADO (Vital para terminal y Vim)
# -------------------------------------------------------------------
echo "   ↳ Desactivando la pulsación larga de acentos (para poder dejar apretada una tecla)..."
defaults write -g ApplePressAndHoldEnabled -bool false

echo "   ↳ Configurando velocidad de repetición de teclas a nivel dios..."
defaults write -g KeyRepeat -int 1
defaults write -g InitialKeyRepeat -int 10

# -------------------------------------------------------------------
# 3. FINDER
# -------------------------------------------------------------------
echo "   ↳ Mostrando archivos ocultos y extensiones por defecto..."
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "   ↳ Desactivando advertencia al cambiar extensión de archivo..."
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

echo "   ↳ Evitando que se creen archivos .DS_Store en discos de red y USBs..."
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# -------------------------------------------------------------------
# 4. DOCK
# -------------------------------------------------------------------
echo "   ↳ Eliminando el retraso (delay) al ocultar el Dock..."
defaults write com.apple.dock autohide-delay -float 0

echo "   ↳ Acelerando la animación del Dock..."
defaults write com.apple.dock autohide-time-modifier -float 0.2

# -------------------------------------------------------------------
# 5. SAFARI (Opcional, para devs)
# -------------------------------------------------------------------
echo "   ↳ Habilitando menú de Desarrollo e Inspector Web en Safari..."
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

echo "\n🔄 Reiniciando servicios para aplicar los cambios..."
killall Finder
killall Dock

echo "\n✅ ¡Terminado! Tu Mac ahora vuela."
echo "Nota: Si tu velocidad de teclado no cambia, es posible que necesites reiniciar la Mac."
