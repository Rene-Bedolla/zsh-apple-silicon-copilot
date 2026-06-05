#!/usr/bin/env python3
"""
SCRIPT: resumen_diario.py
PROPÓSITO: Generar un resumen diario automático usando el skill 'resumen_texto'.

Entrada:
  - No requiere argumentos.
  - Lee:
      - history.md (cola reciente de eventos del harness)
      - features.json (tareas y su estado)

Salida:
  - Imprime el resumen en stdout (para que Hermes/Telegram/WhatsApp puedan usarlo).
  - Guarda el resumen en:
      hermes/resumenes/resumen-YYYY-MM-DD.md
"""

from __future__ import annotations

# Bootstrap de ruta para que el script funcione tanto como:
#   python3 hermes/resumen_diario.py
# como:
#   python3 -m hermes.resumen_diario
import sys
from pathlib import Path

if __package__ is None:
    # Añadimos ~/Documents/dotfiles al sys.path como raíz del paquete 'hermes'
    ROOT = Path(__file__).resolve().parents[1]
    sys.path.insert(0, str(ROOT))
    __package__ = "hermes"

import asyncio
import json
from datetime import datetime
from typing import List

from hermes.skills import load_skills  # type: ignore[import]


HERMES_DIR = Path.home() / "Documents" / "dotfiles" / "hermes"
HISTORY_FILE = HERMES_DIR / "history.md"
FEATURES_FILE = HERMES_DIR / "features.json"
RESUMEN_DIR = HERMES_DIR / "resumenes"


def _leer_tail_history(max_chars: int = 3000) -> str:
    """
    Lee la cola de history.md (últimos eventos) para el resumen diario.
    No hace parsing sofisticado: simplemente toma el final del archivo.
    """
    if not HISTORY_FILE.exists():
        return "No hay history.md disponible aún."

    try:
        texto = HISTORY_FILE.read_text(encoding="utf-8")
    except Exception as e:
        return f"No se pudo leer history.md: {e}"

    if len(texto) > max_chars:
        texto = texto[-max_chars:]
    return texto.strip()


def _resumen_tareas_pendientes() -> str:
    """
    Genera una sección de texto con el estado de las tareas en features.json.
    """
    if not FEATURES_FILE.exists():
        return "features.json no encontrado; no se puede listar tareas."

    try:
        data = json.loads(FEATURES_FILE.read_text(encoding="utf-8"))
    except Exception as e:
        return f"No se pudo parsear features.json: {e}"

    tareas: List[dict] = data.get("tareas", [])
    if not tareas:
        return "No hay tareas registradas en features.json."

    lineas = []
    lineas.append(f"Proyecto: {data.get('proyecto', 'sin nombre')}")
    lineas.append("Tareas registradas:")
    for t in tareas:
        lineas.append(
            f"- {t.get('id')} · {t.get('titulo')} "
            f"(estado: {t.get('estado')}, prioridad: {t.get('prioridad')})"
        )
    return "\n".join(lineas)


async def generar_resumen_diario() -> str:
    """
    Construye el contexto del día y llama al skill 'resumen_texto'.
    """
    skills = load_skills()
    if "resumen_texto" not in skills:
        return "Skill 'resumen_texto' no encontrado. Verifica hermes/skills/skill_resumen.py."

    skill = skills["resumen_texto"]

    # 1) Construir texto base para el resumen
    hoy = datetime.now().strftime("%Y-%m-%d")
    secciones: List[str] = []

    secciones.append(f"Resumen diario para la fecha: {hoy}\n")
    secciones.append("=== Historial reciente del harness (history.md) ===")
    secciones.append(_leer_tail_history())

    secciones.append("\n=== Tablero de tareas (features.json) ===")
    secciones.append(_resumen_tareas_pendientes())

    texto_base = "\n\n".join(secciones).strip()

    # 2) Llamar al skill de resumen (usa MLX local por defecto)
    resumen = await skill.run(texto_base, max_tokens=700)

    # 3) Guardar en archivo
    RESUMEN_DIR.mkdir(parents=True, exist_ok=True)
    nombre_archivo = f"resumen-{hoy}.md"
    ruta = RESUMEN_DIR / nombre_archivo
    ruta.write_text(resumen, encoding="utf-8")

    return resumen


async def main() -> None:
    resumen = await generar_resumen_diario()
    print(resumen)


if __name__ == "__main__":
    asyncio.run(main())
