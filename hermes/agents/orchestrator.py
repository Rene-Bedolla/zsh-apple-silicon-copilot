#!/usr/bin/env python3
# ==============================================================================
# ARCHIVO: orchestrator.py
# PROPÓSITO: Agente Líder — lee features.json y despacha subagentes
# PILAR: 2 — Orquestación Multiagente
# MOTOR: MLX REST API :8000 (OpenAI-compatible) o OpenRouter como fallback
# RAM: ~150MB (solo cliente HTTP, no carga modelo directamente)
# USO: python3 orchestrator.py [tarea_id]
#      python3 orchestrator.py --listar
# ==============================================================================

import json
import httpx
import asyncio
import re
from pathlib import Path
from datetime import datetime

# ── Rutas del harness ─────────────────────────────────────────────────────────
HERMES_DIR    = Path.home() / "Documents/dotfiles/hermes"
FEATURES_FILE = HERMES_DIR / "features.json"
PROGRESS_DIR  = HERMES_DIR / "progress"

# ── Endpoints de inferencia ───────────────────────────────────────────────────
MLX_URL        = "http://localhost:8000/v1/chat/completions"
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"

# ── Mapeo de modelos por alias ─────────────────────────────────────────────────
MODELOS = {
    "local-fast": ("mlx-community/Qwen3-4B-4bit",  "local",  MLX_URL),
    "local-deep": ("mlx-community/Qwen3-8B-4bit",  "local",  MLX_URL),
    "cloud":      ("nvidia/nemotron-3-super-120b-a12b:free", None, OPENROUTER_URL),
}

def limpiar_output(texto: str) -> str:
    """Elimina bloques <think> y estadísticas de MLX del output."""
    texto = re.sub(r'<think>.*?</think>', '', texto, flags=re.DOTALL)
    texto = re.sub(r'\n?(Generation:|Prompt:|Peak memory:|=====).*', '', texto)
    return texto.strip()

async def llamar_modelo(prompt: str, modelo_alias: str = "local-fast",
                        max_tokens: int = 1500) -> str:
    """
    Cliente async unificado — usa MLX local o OpenRouter según el alias.
    El orquestador nunca carga el modelo directamente, solo hace HTTP.
    """
    import os
    modelo_id, api_key, url = MODELOS.get(modelo_alias, MODELOS["local-fast"])

    # OpenRouter necesita la key del entorno
    if api_key is None:
        api_key = os.environ.get("OPENROUTER_API_KEY", "")

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}",
    }
    # Header de identificación para OpenRouter
    if "openrouter" in url:
        headers["HTTP-Referer"] = "https://github.com/Rene-Bedolla"
        headers["X-Title"] = "HERMES Personal Harness"

    payload = {
        "model": modelo_id,
        "messages": [{"role": "user", "content": f"/no_think {prompt}"}],
        "max_tokens": max_tokens,
        "temperature": 0.3,
    }

    async with httpx.AsyncClient(timeout=120) as client:
        resp = await client.post(url, json=payload, headers=headers)
        resp.raise_for_status()
        data = resp.json()
        msg = data["choices"][0]["message"]
        # MLX puede devolver el texto en 'content' o 'reasoning'
        texto = msg.get("content") or msg.get("reasoning", "")
        return limpiar_output(texto)

def escribir_progreso(agente: str, tarea_id: str, contenido: str) -> Path:
    """
    Escribe resultado de un subagente en progress/{agente}/.
    Los subagentes se comunican SOLO leyendo estos archivos — nunca memoria viva.
    """
    directorio = PROGRESS_DIR / agente
    directorio.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    archivo = directorio / f"{tarea_id}_{timestamp}.md"
    archivo.write_text(contenido, encoding="utf-8")
    print(f"  📝 [{agente}] → {archivo.name}")
    return archivo

async def fase_explorador(tarea: dict) -> str:
    """
    Agente Explorador: investiga y planifica. NO modifica archivos.
    Recibe SOLO el contexto mínimo — nunca el historial completo.
    """
    prompt = f"""Eres un agente explorador técnico para macOS Apple Silicon M4.
Tu única misión: analizar la tarea y proponer un plan de implementación.
NO generes código ejecutable todavía. Solo analiza y planifica.

TAREA: {tarea['titulo']}
CONTEXTO: {tarea.get('contexto_minimo', '')}
CRITERIOS DE ÉXITO: {json.dumps(tarea['criterios_aceptacion'], ensure_ascii=False)}

Responde con:
1. Análisis de la tarea (2-3 líneas)
2. Pasos concretos ordenados
3. Posibles bloqueos o dependencias
4. Comando de verificación final

Máximo 250 palabras. Sé preciso y directo."""

    modelo = tarea.get("modelo", "local-fast")
    return await llamar_modelo(prompt, modelo_alias=modelo, max_tokens=800)

async def fase_implementador(tarea: dict, plan: str) -> str:
    """
    Agente Implementador: genera comandos ejecutables basándose en el plan.
    Lee el plan del explorador desde progress/ — no se comunica directamente.
    """
    prompt = f"""Eres un agente implementador para Mac Mini M4, macOS 26+.
Stack: Python 3.11 Homebrew, MLX, Zsh, sin virtualenvs, sin sudo para pip.

TAREA: {tarea['titulo']}
PLAN DEL EXPLORADOR:
{plan}

Genera los comandos bash exactos y ejecutables.
Usa bloques EOF para crear archivos.
Encadena comandos con &&.
Documenta cada bloque con comentarios inline en español."""

    return await llamar_modelo(prompt, modelo_alias=tarea.get("modelo", "local-fast"),
                               max_tokens=2000)

async def fase_reviewer(tarea: dict, plan: str, implementacion: str) -> str:
    """
    Agente Reviewer: audita el output del implementador contra criterios de éxito.
    Lee SOLO los artefactos de progress/ — nunca se comunica con los otros agentes.
    Detecta alucinaciones, comandos inexistentes y bloqueantes críticos.
    Emite veredicto: APROBADO / NECESITA_REVISION con lista de issues.
    """
    prompt = f"""Eres un agente revisor técnico senior para macOS Apple Silicon M4.
Tu misión: auditar el plan y la implementación propuesta. Sé crítico y preciso.

TAREA: {tarea['titulo']}
STACK REAL: Mac Mini M4, macOS 26+, Python 3.11 Homebrew, MLX, Zsh, Homebrew.
            NO existe CLI 'hermes' en Homebrew. NO usar Ollama. NO sudo para pip.

CRITERIOS DE ÉXITO REQUERIDOS:
{json.dumps(tarea['criterios_aceptacion'], ensure_ascii=False)}

PLAN DEL EXPLORADOR:
{plan}

IMPLEMENTACIÓN PROPUESTA:
{implementacion}

Responde con este formato EXACTO:

## VEREDICTO: [APROBADO|NECESITA_REVISION]

## Issues críticos (bloquean ejecución)
- (lista de problemas que impedirían que funcione, o "Ninguno")

## Advertencias (no bloquean pero degradan calidad)
- (lista de advertencias, o "Ninguna")

## Criterios de éxito cubiertos
- (cuáles criterios quedan satisfechos con esta implementación)

## Recomendación final
(1-2 líneas de acción concreta)"""

    # El reviewer siempre usa el modelo más capaz disponible localmente
    return await llamar_modelo(prompt, modelo_alias="local-deep", max_tokens=1000)

async def orquestar(tarea_id: str = None, solo_listar: bool = False):
    """Función principal del orquestador."""

    # Cargar tablero de tareas
    with open(FEATURES_FILE, "r", encoding="utf-8") as f:
        features = json.load(f)

    # Modo listar
    if solo_listar:
        print(f"\n  📋 Tareas en {features['proyecto']}:\n")
        for t in features["tareas"]:
            icono = "⏳" if t["estado"] == "pendiente" else "✅"
            print(f"  {icono} [{t['id']}] {t['titulo']} ({t['prioridad']})")
        print()
        return

    # Seleccionar tarea
    pendientes = [t for t in features["tareas"] if t["estado"] == "pendiente"]
    if not pendientes:
        print("  ✅ No hay tareas pendientes en features.json")
        return

    tarea = next((t for t in pendientes if t["id"] == tarea_id), pendientes[0])
    print(f"\n  🎯 Orquestando: [{tarea['id']}] {tarea['titulo']}")
    print(f"  🤖 Modelo: {tarea.get('modelo', 'local-fast')}\n")

    # Fase 1: Exploración (contexto mínimo, limpio)
    print("  🔍 Fase 1 — Explorador...")
    plan = await fase_explorador(tarea)
    escribir_progreso("explorer", tarea["id"],
                      f"# Plan: {tarea['titulo']}\n\n{plan}")

    # Fase 2: Implementación (lee del explorador, no del orquestador)
    print("  ⚙️  Fase 2 — Implementador...")
    implementacion = await fase_implementador(tarea, plan)
    escribir_progreso("implementer", tarea["id"],
                      f"# Implementación: {tarea['titulo']}\n\n{implementacion}")

    # Fase 3: Review (audita ambos outputs, usa local-deep siempre)
    # El reviewer recibe plan + implementación pero NO el historial del orquestador
    print("  🔎 Fase 3 — Reviewer...")
    revision = await fase_reviewer(tarea, plan, implementacion)
    escribir_progreso("reviewer", tarea["id"],
                      f"# Revisión: {tarea['titulo']}\n\n{revision}")

    print(f"\n  ✅ Completado. Resultados en: {PROGRESS_DIR}")
    print(f"  📂 Revisar con: cat {PROGRESS_DIR}/reviewer/{tarea['id']}*.md\n")

if __name__ == "__main__":
    import sys
    if "--listar" in sys.argv:
        asyncio.run(orquestar(solo_listar=True))
    else:
        tarea_id = sys.argv[1] if len(sys.argv) > 1 else None
        asyncio.run(orquestar(tarea_id))
