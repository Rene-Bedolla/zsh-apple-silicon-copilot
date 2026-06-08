#!/usr/bin/env python3
# ==============================================================================
# ARCHIVO: orchestrator.py
# PROPÓSITO: Agente líder del harness HERMES
#
# - Lee features.json
# - Carga contexto mínimo (Nexus, history, tablero)
# - Ejecuta las 3 fases multi-agente:
#     1. Explorador
#     2. Implementador
#     3. Revisor (ahora con soporte de Cerebro Obsidian vía skill buscar_cerebro)
#
# MOTOR LLM: Servidor MLX local (OpenAI-compatible) en :8000
# USO:
#   python3 hermes/agents/orchestrator.py --listar
#   python3 hermes/agents/orchestrator.py H-001
# ==============================================================================

from __future__ import annotations

import argparse
import asyncio
import json
import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional, List

import httpx

from hermes.skills import load_skills  # skills: resumen_texto, buscar_cerebro, etc.

# ── Rutas base ────────────────────────────────────────────────────────────────
HERMES_DIR = Path.home() / "Documents" / "dotfiles" / "hermes"
FEATURES_FILE = HERMES_DIR / "features.json"
NEXUS_FILE = HERMES_DIR / "Nexus.md"
HISTORY_FILE = HERMES_DIR / "history.md"

PROGRESS_DIR = HERMES_DIR / "progress"
EXPLORER_DIR = PROGRESS_DIR / "explorer"
IMPLEMENTER_DIR = PROGRESS_DIR / "implementer"
REVIEWER_DIR = PROGRESS_DIR / "reviewer"

for d in (EXPLORER_DIR, IMPLEMENTER_DIR, REVIEWER_DIR):
    d.mkdir(parents=True, exist_ok=True)

# ── MLX endpoint y modelos ───────────────────────────────────────────────────
MLX_CHAT_URL = "http://localhost:8000/v1/chat/completions"

MODELOS = {
    "local-fast": "mlx-community/Qwen3-4B-4bit",
    "local-deep": "mlx-community/Qwen3-8B-4bit",
}

# ── Helpers de datos ─────────────────────────────────────────────────────────


@dataclass
class Tarea:
    id: str
    titulo: str
    descripcion: str
    estado: str
    prioridad: str
    etiquetas: List[str]


def cargar_features() -> Dict[str, Any]:
    if not FEATURES_FILE.exists():
        raise FileNotFoundError(f"No se encontró features.json en {FEATURES_FILE}")
    return json.loads(FEATURES_FILE.read_text(encoding="utf-8"))


def obtener_tarea_por_id(features: Dict[str, Any], tarea_id: str) -> Tarea:
    for t in features.get("tareas", []):
        if t.get("id") == tarea_id:
            return Tarea(
                id=t.get("id"),
                titulo=t.get("titulo", ""),
                descripcion=t.get("descripcion", ""),
                estado=t.get("estado", ""),
                prioridad=str(t.get("prioridad", "")),
                etiquetas=list(t.get("etiquetas", [])),
            )
    raise ValueError(f"Tarea '{tarea_id}' no encontrada en features.json")


def limpiar_output(texto: str) -> str:
    """Elimina bloques <think> y estadísticas de salida de MLX."""
    texto = re.sub(r"<think>.*?</think>", "", texto, flags=re.DOTALL)
    texto = re.sub(
        r"(Prompt: .*?Peak memory: .*?MiB)",
        "",
        texto,
        flags=re.DOTALL,
    )
    return texto.strip()


def guardar_progreso(
    subdir: Path,
    tarea_id: str,
    contenido: str,
) -> Path:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    fname = f"{tarea_id}_{ts}.md"
    ruta = subdir / fname
    ruta.write_text(contenido, encoding="utf-8")
    return ruta


# ── Contexto mínimo ──────────────────────────────────────────────────────────


def cargar_contexto_minimo(
    tarea: Tarea,
    features: Dict[str, Any],
    max_chars: int = 4000,
) -> str:
    """
    Carga contexto mínimo para las fases del orquestador:

    - Fragmento de Nexus.md (identidad, stack, reglas).
    - Historial reciente de history.md (cola del archivo).
    - Resumen del tablero de tareas (features.json).
    - Ficha de la tarea actual.

    Recorta a max_chars para no desbordar la ventana de contexto del modelo.
    """
    partes: List[str] = []

    # 1) Fragmento de NEXUS
    if NEXUS_FILE.exists():
        try:
            nexus_text = NEXUS_FILE.read_text(encoding="utf-8")
            partes.append(
                "=== NEXUS (fragmento) ===\n" + nexus_text[:1500].strip()
            )
        except Exception:
            pass

    # 2) Cola de history.md
    if HISTORY_FILE.exists():
        try:
            hist_text = HISTORY_FILE.read_text(encoding="utf-8")
            partes.append(
                "=== Historial reciente (cola de history.md) ===\n"
                + hist_text[-1500:].strip()
            )
        except Exception:
            pass

    # 3) Resumen de tablero de tareas
    tareas = features.get("tareas", [])
    resumen_tareas = []
    for t in tareas:
        resumen_tareas.append(
            f"- {t.get('id')} · {t.get('titulo')} "
            f"(estado: {t.get('estado')}, prioridad {t.get('prioridad')})"
        )
    if resumen_tareas:
        partes.append(
            "=== Tablero de tareas (resumen) ===\n" + "\n".join(resumen_tareas)
        )

    # 4) Ficha de la tarea actual
    partes.append(
        "=== Tarea actual ===\n"
        f"ID: {tarea.id}\n"
        f"Título: {tarea.titulo}\n"
        f"Descripción: {tarea.descripcion}\n"
        f"Estado: {tarea.estado}\n"
        f"Prioridad: {tarea.prioridad}\n"
        f"Etiquetas: {', '.join(tarea.etiquetas) if tarea.etiquetas else '(sin etiquetas)'}"
    )

    contexto = "\n\n".join(partes)
    if len(contexto) > max_chars:
        contexto = contexto[:max_chars]
    return contexto.strip()


# ── Contexto adicional desde el Cerebro (Obsidian + ChromaDB) ───────────────


async def obtener_contexto_cerebro(
    tarea: Tarea,
    max_chars: int = 1500,
) -> str:
    """
    Usa el skill 'buscar_cerebro' para traer notas relevantes de la bóveda Obsidian.

    Estrategia:
      - Construir una consulta basada en título + descripción + etiquetas.
      - Pedir 3–5 resultados al skill.
      - Recortar el texto para no saturar el prompt del Revisor.

    Si el skill o el índice no están disponibles, devuelve cadena vacía.
    """
    try:
        skills = load_skills()
    except Exception:
        return ""

    skill = skills.get("buscar_cerebro")
    if not skill:
        return ""

    consulta_partes = [tarea.titulo, tarea.descripcion]
    if tarea.etiquetas:
        consulta_partes.append(" ".join(tarea.etiquetas))
    consulta = " ".join(p for p in consulta_partes if p).strip()
    if not consulta:
        return ""

    try:
        texto = await skill.run(
            consulta,
            n_resultados=5,
            solo_rutas=False,
        )
    except Exception:
        return ""

    texto = texto.strip()
    if not texto:
        return ""

    if len(texto) > max_chars:
        texto = texto[:max_chars]

    return (
        "=== Contexto del Cerebro (Obsidian / ChromaDB) ===\n"
        + texto
    )


# ── Cliente MLX (chat) ──────────────────────────────────────────────────────


async def llamar_mlx_chat(
    modelo_alias: str,
    sistema: str,
    usuario: str,
    max_tokens: int = 900,
    temperatura: float = 0.4,
) -> str:
    modelo_id = MODELOS.get(modelo_alias)
    if not modelo_id:
        raise ValueError(f"Modelo alias desconocido: {modelo_alias}")

    payload = {
        "model": modelo_id,
        "messages": [
            {"role": "system", "content": sistema},
            {"role": "user", "content": usuario},
        ],
        "max_tokens": max_tokens,
        "temperature": temperatura,
    }

    async with httpx.AsyncClient(timeout=180) as client:
        resp = await client.post(MLX_CHAT_URL, json=payload)
        resp.raise_for_status()
        data = resp.json()
        msg = data["choices"][0]["message"]
        contenido = msg.get("content") or msg.get("reasoning", "")
        return limpiar_output(contenido or "")


# ── Fases del orquestador ───────────────────────────────────────────────────


async def fase_explorador(tarea: Tarea, features: Dict[str, Any]) -> str:
    contexto = cargar_contexto_minimo(tarea, features)

    sistema = (
        "Eres el EXPLORADOR de HERMES. Trabajo para René.\n"
        "Tu función es entender a fondo la tarea y delimitar el problema.\n"
        "Responde SIEMPRE en Markdown en español, con esta estructura:\n"
        "1. Contexto y objetivo de la tarea\n"
        "2. Preguntas clave (si las hubiera)\n"
        "3. Riesgos y supuestos\n"
        "4. Criterios de éxito claros y medibles\n"
        "NO propongas todavía implementación concreta (scripts, código, etc.).\n"
    )

    usuario = (
        f"Contexto mínimo del sistema:\n\n{contexto}\n\n"
        "Con base en la información anterior, actúa como Explorador "
        "y desarrolla los puntos solicitados."
    )

    respuesta = await llamar_mlx_chat(
        "local-fast",
        sistema,
        usuario,
        max_tokens=900,
        temperatura=0.4,
    )

    ruta = guardar_progreso(EXPLORER_DIR, tarea.id, respuesta)
    print(f"  📝 [explorer] → {ruta.name}")
    return respuesta


async def fase_implementador(
    tarea: Tarea,
    features: Dict[str, Any],
    resumen_explorador: str,
) -> str:
    contexto = cargar_contexto_minimo(tarea, features)

    sistema = (
        "Eres el IMPLEMENTADOR de HERMES. Trabajo para René.\n"
        "Tu función es proponer un plan de implementación concreto, "
        "aterrizado a su entorno (Mac Mini M4, MLX, dotfiles).\n"
        "Responde en Markdown en español con:\n"
        "1. Plan paso a paso (máx. 10 pasos)\n"
        "2. Artefactos a crear/editar (scripts, configuraciones, archivos)\n"
        "3. Consideraciones de seguridad y rendimiento\n"
        "No ejecutes nada: solo describe con precisión qué habría que hacer.\n"
    )

    usuario = (
        f"Contexto mínimo del sistema:\n\n{contexto}\n\n"
        "Resumen del Explorador:\n"
        "------------------------\n"
        f"{resumen_explorador}\n\n"
        "Con esta información, diseña el plan de implementación solicitado."
    )

    respuesta = await llamar_mlx_chat(
        "local-fast",
        sistema,
        usuario,
        max_tokens=1200,
        temperatura=0.35,
    )

    ruta = guardar_progreso(IMPLEMENTER_DIR, tarea.id, respuesta)
    print(f"  📝 [implementer] → {ruta.name}")
    return respuesta


async def fase_revisor(
    tarea: Tarea,
    features: Dict[str, Any],
    resumen_explorador: str,
    propuesta_implementador: str,
) -> str:
    contexto = cargar_contexto_minimo(tarea, features)
    contexto_cerebro = await obtener_contexto_cerebro(tarea)

    sistema = (
        "Eres el REVISOR de HERMES. Trabajo para René.\n"
        "Tu función es auditar críticamente el plan del Implementador "
        "usando el contexto del sistema y, cuando esté disponible, el Cerebro "
        "(notas de Obsidian indexadas en ChromaDB).\n\n"
        "Debes responder SIEMPRE en español y en formato Markdown con esta estructura EXACTA:\n"
        "## VEREDICTO: ACEPTADO | NECESITA_REVISION\n\n"
        "## Issues críticos (bloquean ejecución)\n"
        "- Lista de problemas graves o 'Ninguno' si no hay.\n\n"
        "## Advertencias (no bloquean pero degradan calidad)\n"
        "- Lista de advertencias o 'Ninguna'.\n\n"
        "## Criterios de éxito cubiertos\n"
        "- Qué criterios de éxito (del Explorador) sí están cubiertos.\n\n"
        "## Recomendación final\n"
        "- Resumen de próximos pasos o ajustes.\n\n"
        "No inventes capacidades que no existan en el entorno descrito. "
        "Si detectas discrepancias con el contexto del Cerebro, menciónalas explícitamente.\n"
    )

    bloques: List[str] = []
    bloques.append(f"Contexto mínimo del sistema:\n\n{contexto}")
    if contexto_cerebro:
        bloques.append(f"\n{contexto_cerebro}")

    bloques.append(
        "\n=== Resumen del Explorador ===\n"
        f"{resumen_explorador}"
    )
    bloques.append(
        "\n=== Propuesta del Implementador ===\n"
        f"{propuesta_implementador}"
    )

    usuario = "\n\n".join(bloques)

    respuesta = await llamar_mlx_chat(
        "local-fast",
        sistema,
        usuario,
        max_tokens=1200,
        temperatura=0.25,
    )

    ruta = guardar_progreso(REVIEWER_DIR, tarea.id, respuesta)
    print(f"  📝 [reviewer] → {ruta.name}")
    return respuesta


# ── CLI ──────────────────────────────────────────────────────────────────────


def listar_tareas(features: Dict[str, Any]) -> None:
    print("\n  📋 Tareas en HERMES Personal Harness:\n")
    for t in features.get("tareas", []):
        estado = t.get("estado")
        icon = "✅" if estado == "done" else ("⏳" if estado in {"todo", "doing"} else "⚪")
        print(f"  {icon} [{t.get('id')}] {t.get('titulo')} ({t.get('prioridad')})")
    print()


async def ejecutar_tarea(tarea_id: str) -> None:
    features = cargar_features()
    tarea = obtener_tarea_por_id(features, tarea_id)

    print(f"\n  🎯 Orquestando: [{tarea.id}] {tarea.titulo}")
    print("  🤖 Modelo: local-fast\n")

    # Fase 1 — Explorador
    print("  🔍 Fase 1 — Explorador...")
    resumen_explorador = await fase_explorador(tarea, features)

    # Fase 2 — Implementador
    print("  ⚙️  Fase 2 — Implementador...")
    propuesta_implementador = await fase_implementador(
        tarea,
        features,
        resumen_explorador,
    )

    # Fase 3 — Revisor (ahora con Cerebro)
    print("  🔎 Fase 3 — Reviewer (con Cerebro)...")
    _ = await fase_revisor(
        tarea,
        features,
        resumen_explorador,
        propuesta_implementador,
    )

    print(
        "\n  ✅ Completado. Resultados en:",
        str(PROGRESS_DIR),
    )
    print(
        "  📂 Revisar con: "
        f"cat {REVIEWER_DIR}/{tarea.id}_*.md\n"
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="HERMES Personal Harness — Orquestador multiagente",
    )
    parser.add_argument(
        "tarea_id",
        nargs="?",
        help="ID de la tarea a orquestar (ej. H-001).",
    )
    parser.add_argument(
        "--listar",
        action="store_true",
        help="Listar tareas conocidas en features.json.",
    )

    args = parser.parse_args()
    features = cargar_features()

    if args.listar or not args.tarea_id:
        listar_tareas(features)
        return

    asyncio.run(ejecutar_tarea(args.tarea_id))


if __name__ == "__main__":
    main()
