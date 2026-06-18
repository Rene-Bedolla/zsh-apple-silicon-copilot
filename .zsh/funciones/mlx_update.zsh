#!/usr/bin/env zsh
# ==============================================================================
# ARCHIVO: mlx_update.zsh
# PROPÓSITO: Gestión completa de modelos MLX locales (actualizar/agregar/eliminar)
# INTEGRACIÓN: HERMES Harness — compatible con mlx-server-start.sh
# ==============================================================================

# Ruta al Python con mlx-lm instalado
_MLX_PY="/opt/homebrew/opt/python@3.11/libexec/bin/python3"
_MLX_CACHE="$HOME/.cache/huggingface/hub"
_MLX_PLIST="$HOME/Library/LaunchAgents/com.rene.hermes-mlx.plist"

# ------------------------------------------------------------------------------
# mlx-update (sin argumentos)
# Lista todos los modelos locales y los coteja contra Hugging Face
# ------------------------------------------------------------------------------
function mlx-update() {
    local accion="${1:-listar}"

    case "$accion" in

        # ── Sin argumento: listar y cotejar versiones ─────────────────────────
        listar|"")
            echo ""
            echo "  ╔══════════════════════════════════════════════════════╗"
            echo "  ║   🤖  MLX Models Manager — HERMES Harness           ║"
            echo "  ╚══════════════════════════════════════════════════════╝"
            echo ""

            local _net_ok=0
            curl -s --max-time 2 --head "https://huggingface.co" -o /dev/null 2>/dev/null \
                && _net_ok=1

            (( _net_ok )) \
                && echo "  🌐 Cotejando con Hugging Face...\n" \
                || echo "  📵 Sin red — mostrando solo caché local\n"

            local modelo_dir nombre tamano refs_file local_sha remote_sha api_json

            for modelo_dir in "$_MLX_CACHE"/models--mlx-community--*/; do
                [[ -d "$modelo_dir" ]] || continue
                nombre=$(basename "$modelo_dir" | sed 's/^models--mlx-community--//')
                tamano=$(du -sh "$modelo_dir" 2>/dev/null | awk '{print $1}')
                refs_file="$modelo_dir/refs/main"
                local_sha=$([[ -f "$refs_file" ]] && tr -d '[:space:]' < "$refs_file" | cut -c1-7 || echo "???????")

                if (( _net_ok )); then
                    api_json=$(curl -s --max-time 5 \
                        "https://huggingface.co/api/models/mlx-community/${nombre}" 2>/dev/null)
                    remote_sha=$("$_MLX_PY" -c \
                        "import sys,json; d=json.load(sys.stdin); print(d.get('sha','')[:7])" \
                        <<< "$api_json" 2>/dev/null)

                    if [[ -z "$remote_sha" ]]; then
                        printf "  ⚪ %-42s (%s)  [sin datos remotos]\n" "$nombre" "$tamano"
                    elif [[ "$local_sha" == "$remote_sha" ]]; then
                        printf "  ✅ %-42s (%s)  [%s · al día]\n" "$nombre" "$tamano" "$local_sha"
                    else
                        printf "  🆕 %-42s (%s)  [local:%s → remoto:%s]\n" \
                            "$nombre" "$tamano" "$local_sha" "$remote_sha"
                        echo "     → Actualizar: mlx-update --actualizar $nombre"
                    fi
                else
                    printf "  •  %-42s (%s)  [%s]\n" "$nombre" "$tamano" "$local_sha"
                fi
            done

            echo ""
            echo "  Modelo activo en :8000 → ${MLX_ACTIVE_MODEL:-mlx-community/Qwen3.5-4B-OptiQ-4bit}"
            echo "  Comandos: mlx-update --agregar <modelo> | --actualizar <modelo> | --eliminar <modelo>"
            echo ""
            ;;

        # ── Descargar y registrar un modelo nuevo ─────────────────────────────
        --agregar)
            local modelo="$2"
            if [[ -z "$modelo" ]]; then
                echo "❌ Uso: mlx-update --agregar <nombre-modelo>"
                echo "   Ej:  mlx-update --agregar Qwen3-14B-4bit"
                return 1
            fi
            echo "⬇️  Descargando mlx-community/$modelo..."
            "$_MLX_PY" -m mlx_lm.generate \
                --model "mlx-community/$modelo" \
                --prompt "hola" \
                --max-tokens 5 2>/dev/null \
                && echo "✅ Modelo $modelo descargado y listo" \
                || echo "❌ Error al descargar $modelo — verifica el nombre en huggingface.co/mlx-community"
            ;;

        # ── Actualizar modelo existente (borra caché y re-descarga) ───────────
        --actualizar)
            local modelo="$2"
            if [[ -z "$modelo" ]]; then
                echo "❌ Uso: mlx-update --actualizar <nombre-modelo>"
                return 1
            fi
            local modelo_dir="$_MLX_CACHE/models--mlx-community--${modelo/\//-}"
            if [[ -d "$modelo_dir" ]]; then
                # Detener servidor si está usando este modelo
                if launchctl list | grep -q "com.rene.hermes-mlx"; then
                    echo "⏸️  Deteniendo servidor MLX temporalmente..."
                    launchctl unload "$_MLX_PLIST" 2>/dev/null
                fi
                echo "🗑️  Eliminando caché de $modelo..."
                rm -rf "$modelo_dir"
                echo "⬇️  Re-descargando versión más reciente..."
                "$_MLX_PY" -m mlx_lm.generate \
                    --model "mlx-community/$modelo" \
                    --prompt "hola" \
                    --max-tokens 5 2>/dev/null \
                    && echo "✅ $modelo actualizado"
                echo "▶️  Reiniciando servidor MLX..."
                launchctl load "$_MLX_PLIST" 2>/dev/null
            else
                echo "⚠️  Modelo $modelo no encontrado en caché local."
                echo "   Usa: mlx-update --agregar $modelo"
            fi
            ;;

        # ── Eliminar modelo para liberar espacio ──────────────────────────────
        --eliminar)
            local modelo="$2"
            if [[ -z "$modelo" ]]; then
                echo "❌ Uso: mlx-update --eliminar <nombre-modelo>"
                return 1
            fi
            local modelo_dir="$_MLX_CACHE/models--mlx-community--${modelo/\//-}"
            if [[ -d "$modelo_dir" ]]; then
                local tamano=$(du -sh "$modelo_dir" 2>/dev/null | awk '{print $1}')
                echo "⚠️  ¿Eliminar $modelo ($tamano)? Escribe 'si' para confirmar:"
                read confirmacion
                if [[ "$confirmacion" == "si" ]]; then
                    rm -rf "$modelo_dir"
                    echo "✅ $modelo eliminado. Espacio liberado: $tamano"
                else
                    echo "🛑 Operación cancelada."
                fi
            else
                echo "❌ Modelo $modelo no encontrado en caché."
            fi
            ;;

        *)
            echo "❌ Acción no reconocida: $accion"
            echo "   Uso: mlx-update [--agregar|--actualizar|--eliminar] <modelo>"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# mlx-on / mlx-off / mlx-status
# Interruptor del servidor MLX — útil cuando necesitas toda la RAM
# ------------------------------------------------------------------------------
function mlx-on() {
    if lsof -i :8000 -sTCP:LISTEN &>/dev/null; then
        echo "⚠️  Servidor MLX ya está activo en :8000"
        return 0
    fi
    launchctl load "$_MLX_PLIST" 2>/dev/null
    echo "⏳ Iniciando servidor MLX (${MLX_ACTIVE_MODEL:-Qwen3.5-4B-OptiQ-4bit})..."
    local intentos=0
    until curl -s http://localhost:8000/v1/models &>/dev/null || (( intentos >= 30 )); do
        sleep 1
        (( intentos++ ))
    done
    if curl -s http://localhost:8000/v1/models &>/dev/null; then
        echo "✅ Servidor MLX activo en :8000 (${intentos}s)"
    else
        echo "❌ El servidor no respondió en 30s — revisa: tail ~/.hermes-mlx.log"
    fi
}

function mlx-off() {
    launchctl unload "$_MLX_PLIST" 2>/dev/null
    # Matar proceso residual si quedó huérfano
    local pid=$(lsof -ti :8000 2>/dev/null)
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null
        echo "✅ Proceso MLX terminado (PID $pid)"
    fi
    echo "✅ Servidor MLX detenido — RAM liberada"
}

function mlx-status() {
    echo ""
    if lsof -i :8000 -sTCP:LISTEN &>/dev/null; then
        local pid=$(lsof -ti :8000 -sTCP:LISTEN 2>/dev/null)
        local modelo=$(curl -s http://localhost:8000/v1/models 2>/dev/null | \
            python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data'][0]['id'])" 2>/dev/null)
        echo "  🟢 MLX activo   PID: $pid"
        echo "  🤖 Modelo:      ${modelo:-desconocido}"
        echo "  🌐 Endpoint:    http://localhost:8000/v1"
    else
        echo "  🔴 MLX inactivo — usa mlx-on para iniciarlo"
    fi

    # RAM disponible aproximada
    local ram_libre=$(memory_pressure 2>/dev/null | grep "Pages free" | \
        awk '{print $3}' | python3 -c \
        "import sys; pages=int(sys.stdin.read().strip() or 0); print(f'{pages*4/1024/1024:.1f} GB libres')" 2>/dev/null)
    [[ -n "$ram_libre" ]] && echo "  💾 RAM libre:   $ram_libre"
    echo ""
}

# ------------------------------------------------------------------------------
# cerebro-buscar / cerebro-indexar
# Interfaz rápida para la memoria semántica de HERMES
# ------------------------------------------------------------------------------
function cerebro-buscar() {
    if [[ -z "$1" ]]; then
        echo "Uso: cerebro-buscar \"tu consulta\""
        return 1
    fi
    python3 ~/Documents/dotfiles/hermes/memoria/buscar_cerebro.py "$1"
}

function cerebro-indexar() {
    local modo="${1:---incremental}"
    echo "🧠 Indexando bóveda Obsidian ($modo)..."
    python3 ~/Documents/dotfiles/hermes/memoria/indexar_cerebro.py "$modo"
}
