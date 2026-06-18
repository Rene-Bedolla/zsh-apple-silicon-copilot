---
version: "1.0"
actualizado: "2026-05-04"
publico: true
---

# Nexus — Contexto Personal Universal

> Archivo raíz agnóstico al agente. Cualquier LLM que trabaje contigo
> debe leer este archivo antes de operar.

## Identidad

- **Nombre:** René Bedolla
- **Ubicación:** Ciudad de México, México
- **Perfil:** Desarrollador, geek, otaku, gamer
- **Estudios activos:** Ingeniería en Sistemas Computacionales (UVEG)
- **Intereses:** Ciencia · Neurociencias · IA · Divulgación · Patrimonio cultural

## Hardware y Entorno

- **Principal:** Mac Mini M4 · 16GB RAM · macOS 26+ · IP local: 192.168.1.243
- **Secundario:** MacBook Air M1 · iPhone · iPad
- **Shell:** Zsh + Oh My Zsh + Powerlevel10k · iTerm2
- **Editor:** Neovim (NUNCA sugerir nano o VSCode CLI)
- **Dotfiles:** `~/Documents/dotfiles` (git, rama main)

## Stack Tecnológico

### IA Local (MLX — Apple Silicon nativo)
- Motor: `mlx-lm` · Sin Ollama · Sin llama.cpp como runtime primario
- Servidor REST: `localhost:8000` (OpenAI-compatible)
- Modelos activos:
  - `Qwen3.5-4B-OptiQ-4bit` → rápido, copiloto terminal
  - `Qwen3.5-4B-OptiQ-4bit` → análisis complejo
  - `Qwen3-VL-4B-Instruct-4bit` → visión multimodal
  - `whisper-small-mlx` → STT local

### IA Nube (OpenRouter)
- Modelo principal: `nvidia/nemotron-3-super-120b-a12b:free`
- Acceso: `https://openrouter.ai/api/v1`

### Python
- Versión: 3.11.15 (Homebrew) · Sin virtualenvs · Sin pyenv · Sin conda · Sin uv
- Ruta: `/opt/homebrew/opt/python@3.11/libexec/bin/python3`

### Node.js
- v24.15.0 (NVM) · npm 11.12.1

## Filosofía de Desarrollo

- **Zero-Friction:** sin pasos manuales innecesarios, sin fricción de configuración
- **Modular:** cada componente es independiente y reemplazable
- **Documentado en español:** comentarios y docs en español
- **Público/Privado:** datos sensibles en `privado/`, nunca en git
- **Sin lock-in:** cambiar de modelo sin tocar el harness

## Reglas de Interacción

1. Respuestas en **español** siempre
2. Código con **comentarios inline completos**
3. Archivos creados con **bloques EOF** — nunca sugerir abrir editor manualmente
4. Comandos encadenados con `&&`
5. Ante datos sensibles → **solo MLX local**, nunca APIs externas
6. Ante incertidumbre técnica → declararlo antes de proponer solución

## Memoria y Notas

- **Obsidian:** `~/Notas/` — bóveda principal
- **Sync:** Apple Notes ↔ Obsidian (launchd cada 30 min)
- **Captura rápida:** función `nota` en terminal → `~/.notas_inbox/`

## Proyectos Activos

- **HERMES Personal Harness** — orquestador IA en Mac Mini M4
- **Dotfiles Zero-Friction** — configuración modular de entorno macOS
