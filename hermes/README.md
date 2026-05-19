# HERMES Personal Harness

> Orquestador IA personal para Mac Mini M4 · Apple Silicon · Zero-Friction

## ¿Qué es esto?

Un **harness** (arnés) que implementa los 3 pilares del Harness Engineering
sobre [Hermes Agent](https://github.com/nousresearch/hermes-agent) de Nous Research,
optimizado para Apple Silicon con MLX nativo como motor de inferencia local.

**El modelo LLM es el motor. Este harness es el chasis.**

## Stack

- **Motor local:** MLX · Qwen3-4B/8B/VL (Apple Silicon nativo, sin Ollama)
- **Motor nube:** OpenRouter (Nemotron 120B free · Gemini Pro · DeepSeek · +600 modelos)
- **Agente base:** Hermes Agent (Nous Research · MIT) — auto-mejora · memoria · gateway
- **Gateway:** Telegram + WhatsApp (acceso desde iPhone/iPad)
- **Entorno:** macOS · Zsh · dotfiles modulares · Zero-Friction

## Los 3 Pilares

1. **El Repositorio como Sistema** — `agents.md` define protocolos, `init.sh` valida el entorno
2. **Orquestación Multiagente** — líder despacha subagentes con contexto mínimo via `progress/`
3. **Verificación y Auto-mejora** — revisor ejecuta tests y puede modificar sus propias reglas

## Estructura

\`\`\`
hermes/
├── agents.md          # Protocolo raíz — punto de entrada del harness
├── Nexus.md           # Contexto personal universal (agnóstico al agente)
├── features.json      # Tablero de tareas con estado y criterios de aceptación
├── init.sh            # Validador de entorno (ejecutar antes de operar)
├── agents/            # Orquestador + subagentes especializados
├── skills/            # Wrappers reutilizables (MLX, file tools)
├── scripts/           # mlx-update y utilidades de mantenimiento
└── progress/          # Resultados de subagentes (ignorado por git)
\`\`\`

## Requisitos

- macOS 26+ · Apple Silicon (M1/M2/M3/M4)
- Python 3.11 (Homebrew)
- mlx-lm instalado: `pip install mlx-lm`
- Hermes Agent: `curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash`
- OpenRouter API key: https://openrouter.ai/keys

## Inicio rápido

\`\`\`bash
# 1. Validar entorno
bash hermes/init.sh

# 2. Iniciar servidor MLX local
hermes-mlx-start

# 3. Lanzar Hermes Agent
hermes
\`\`\`

## Filosofía

- 🔒 **Datos sensibles → solo MLX local.** Nunca salen de tu máquina.
- 🧩 **Modular:** cada agente es un archivo Python independiente.
- 📖 **Documentado en español** para la comunidad hispanohablante.
- 🔄 **Sin lock-in:** cambia de modelo sin tocar el harness.

## Autor

René Bedolla · [@Rene-Bedolla](https://github.com/Rene-Bedolla)
Licencia MIT
