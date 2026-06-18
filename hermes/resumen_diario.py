#!/usr/bin/env python3
from __future__ import annotations

import asyncio
import json
import re
import subprocess
import sys
import time
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import List

if __package__ is None:
    ROOT = Path(__file__).resolve().parents[1]
    sys.path.insert(0, str(ROOT))
    __package__ = "hermes"

from hermes.skills import load_skills  # type: ignore[import]

HERMES_DIR = Path.home() / "Documents" / "dotfiles" / "hermes"
HISTORY_FILE = HERMES_DIR / "history.md"
FEATURES_FILE = HERMES_DIR / "features.json"
RESUMEN_DIR = HERMES_DIR / "resumenes"
MLX_START_SH = HERMES_DIR / "scripts" / "mlx-server-start.sh"

MLX_ENDPOINT = "http://127.0.0.1:8000/v1/models"
MLX_START_WAIT = 24
MLX_POLL_CADA = 2


def _mlx_activo() -> bool:
    try:
        with urllib.request.urlopen(MLX_ENDPOINT, timeout=3) as r:
            return r.status == 200
    except Exception:
        return False


def _arrancar_mlx_si_necesario() -> bool:
    if _mlx_activo():
        return True

    if not MLX_START_SH.exists():
        return False

    try:
        subprocess.Popen(
            ["bash", str(MLX_START_SH)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        return False

    for _ in range(MLX_START_WAIT // MLX_POLL_CADA):
        time.sleep(MLX_POLL_CADA)
        if _mlx_activo():
            return True

    return False


def _leer_tail_history(max_chars: int = 3000) -> str:
    if not HISTORY_FILE.exists():
        return "No hay history.md disponible aún."

    try:
        texto = HISTORY_FILE.read_text(encoding="utf-8")
    except Exception as e:
        return f"No se pudo leer history.md: {e}"

    if len(texto) > max_chars:
        texto = texto[-max_chars:]

    return texto.strip()


def _separar_bloques_history(texto: str) -> List[str]:
    bloques: List[str] = []
    actual: List[str] = []

    for linea in texto.splitlines():
        if linea.startswith("## "):
            if actual:
                bloque = "\n".join(actual).strip()
                if bloque:
                    bloques.append(bloque)
                actual = []
        actual.append(linea)

    if actual:
        bloque = "\n".join(actual).strip()
        if bloque:
            bloques.append(bloque)

    return bloques


def _extraer_fecha_bloque(bloque: str) -> datetime | None:
    primera_linea = bloque.splitlines()[0] if bloque.splitlines() else ""
    match = re.match(r"^##\s+(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})", primera_linea)
    if not match:
        return None

    try:
        return datetime.strptime(f"{match.group(1)} {match.group(2)}", "%Y-%m-%d %H:%M:%S")
    except ValueError:
        return None


def _leer_history_reciente(max_bloques: int = 4, max_chars_fallback: int = 3000) -> str:
    if not HISTORY_FILE.exists():
        return "No hay history.md disponible aún."

    try:
        texto = HISTORY_FILE.read_text(encoding="utf-8")
    except Exception as e:
        return f"No se pudo leer history.md: {e}"

    bloques = _separar_bloques_history(texto)

    if not bloques:
        return _leer_tail_history(max_chars=max_chars_fallback)

    recientes = bloques[-max_bloques:]
    return "\n\n---\n\n".join(recientes).strip()


def _resumen_tareas_pendientes() -> str:
    if not FEATURES_FILE.exists():
        return "features.json no encontrado; no se puede listar tareas."

    try:
        data = json.loads(FEATURES_FILE.read_text(encoding="utf-8"))
    except Exception as e:
        return f"No se pudo parsear features.json: {e}"

    tareas: List[dict] = data.get("tareas", [])
    if not tareas:
        return "No hay tareas registradas en features.json."

    lineas: List[str] = []
    lineas.append(f"Proyecto: {data.get('proyecto', 'sin nombre')}")
    lineas.append("Tareas registradas:")

    for tarea in tareas:
        lineas.append(
            f"- {tarea.get('id')} · {tarea.get('titulo')} "
            f"(estado: {tarea.get('estado')}, prioridad: {tarea.get('prioridad')})"
        )

    return "\n".join(lineas)


async def generar_resumen_diario() -> str:
    if not _arrancar_mlx_si_necesario():
        return (
            "⚠️ El servidor MLX en :8000 no está disponible y no se pudo arrancar.\n"
            f"Verifica {MLX_START_SH} o actívalo manualmente con `hermes-local`."
        )

    skills = load_skills()
    if "resumen_texto" not in skills:
        return (
            "❌ Skill 'resumen_texto' no encontrado. "
            "Verifica hermes/skills/skill_resumen.py."
        )

    skill = skills["resumen_texto"]

    hoy = datetime.now().strftime("%Y-%m-%d")
    secciones: List[str] = []

    secciones.append(f"Resumen diario para la fecha: {hoy}")
    secciones.append("=== Historial reciente del harness (history.md) ===")
    secciones.append(_leer_history_reciente())

    secciones.append("=== Tablero de tareas (features.json) ===")
    secciones.append(_resumen_tareas_pendientes())

    texto_base = "\n\n".join(secciones).strip()
    resumen = await skill.run(texto_base, max_tokens=700)

    if not resumen or not resumen.strip():
        return (
            "⚠️ El modelo no devolvió contenido.\n"
            "MLX estaba activo pero la respuesta llegó vacía.\n"
            "Comprueba: curl -s http://127.0.0.1:8000/v1/models"
        )

    RESUMEN_DIR.mkdir(parents=True, exist_ok=True)
    ruta = RESUMEN_DIR / f"resumen-{hoy}.md"
    ruta.write_text(resumen, encoding="utf-8")

    return resumen


async def main() -> None:
    resumen = await generar_resumen_diario()
    print(resumen)


if __name__ == "__main__":
    asyncio.run(main())
