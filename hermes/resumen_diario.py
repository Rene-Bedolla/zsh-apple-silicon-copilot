#!/usr/bin/env python3
"""
SCRIPT: resumen_diario.py
PROPÓSITO:
    Generar un resumen diario automático de HERMES usando el skill
    'resumen_texto', a partir de dos fuentes locales:

    1) history.md    -> bitácora operativa del harness / sistema
    2) features.json -> tablero de tareas y estado funcional

DISEÑO:
    - No recibe argumentos por CLI.
    - Imprime el resumen final en stdout para que el wrapper shell lo entregue
      por Telegram u otro canal.
    - Guarda una copia del resumen en:
          ~/Documents/dotfiles/hermes/resumenes/resumen-YYYY-MM-DD.md
    - Intenta usar bloques recientes de history.md, no solo una cola ciega
      de caracteres. Esto reduce el sesgo hacia entradas viejas grandes.

COMPATIBILIDAD:
    - Debe funcionar tanto como:
          python3 ~/Documents/dotfiles/hermes/resumen_diario.py
      como:
          python3 -m hermes.resumen_diario
"""

from __future__ import annotations

import asyncio
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import List

# ============================================================================
# Bootstrap de ruta del paquete
# ----------------------------------------------------------------------------
# Cuando se ejecuta el archivo directamente, Python no siempre conoce la raíz
# del paquete 'hermes'. Aquí añadimos ~/Documents/dotfiles al sys.path para que
# el import "from hermes.skills import load_skills" funcione de forma estable.
# ============================================================================
if __package__ is None:
    ROOT = Path(__file__).resolve().parents[1]
    sys.path.insert(0, str(ROOT))
    __package__ = "hermes"

from hermes.skills import load_skills  # type: ignore[import]


# ============================================================================
# Rutas principales del proyecto HERMES
# ============================================================================
HERMES_DIR = Path.home() / "Documents" / "dotfiles" / "hermes"
HISTORY_FILE = HERMES_DIR / "history.md"
FEATURES_FILE = HERMES_DIR / "features.json"
RESUMEN_DIR = HERMES_DIR / "resumenes"


def _leer_tail_history(max_chars: int = 3000) -> str:
    """
    Fallback simple: lee la cola textual de history.md.

    Se conserva como red de seguridad por si el parseo estructurado falla
    o si el archivo no sigue el formato esperado de encabezados con "## ".

    Args:
        max_chars: número máximo de caracteres a conservar desde el final.

    Returns:
        Texto final de history.md o un mensaje de error legible.
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


def _separar_bloques_history(texto: str) -> List[str]:
    """
    Divide history.md en bloques lógicos tomando como delimitador las líneas
    que comienzan con '## '.

    Convención esperada:
        ## YYYY-MM-DD HH:MM:SS — nombre-del-evento

    No valida estrictamente el formato de fecha; solo usa el encabezado '## '
    como separador de entradas, lo que lo hace resistente a pequeñas variantes
    del título del bloque.

    Args:
        texto: contenido completo de history.md

    Returns:
        Lista de bloques no vacíos, en el mismo orden del archivo.
    """
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
    """
    Intenta extraer la fecha/hora del encabezado de un bloque de history.md.

    Formato esperado del inicio de bloque:
        ## 2026-05-26 12:25:48 — resumen-diario

    Si no encuentra una fecha válida, devuelve None. Esto permite seguir
    usando el bloque, pero sin ordenarlo por fecha exacta.

    Args:
        bloque: bloque completo de texto del historial

    Returns:
        datetime si pudo parsearse; en otro caso None.
    """
    primera_linea = bloque.splitlines()[0] if bloque.splitlines() else ""
    match = re.match(r"^##\s+(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})", primera_linea)
    if not match:
        return None

    try:
        return datetime.strptime(f"{match.group(1)} {match.group(2)}", "%Y-%m-%d %H:%M:%S")
    except ValueError:
        return None


def _leer_history_reciente(max_bloques: int = 4, max_chars_fallback: int = 3000) -> str:
    """
    Lee los bloques recientes de history.md usando una estrategia estructurada.

    Estrategia:
        1) Leer el archivo completo.
        2) Separarlo en bloques por encabezados '## '.
        3) Tomar los últimos N bloques.
        4) Si algo falla o no hay bloques claros, usar fallback al tail textual.

    Esta función no intenta "resumir" por sí misma; solo entrega al skill un
    contexto mejor recortado y con menos mezcla temporal.

    Args:
        max_bloques: cantidad máxima de bloques recientes a incluir.
        max_chars_fallback: tamaño del fallback textual si no hubo parseo útil.

    Returns:
        Texto listo para usarse como contexto del resumen.
    """
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
    """
    Genera una vista textual del estado de las tareas registradas en features.json.

    Supuesto actual:
        features.json contiene una clave 'tareas' con una lista de objetos.

    Si el archivo cambia de forma en el futuro, esta función es el punto natural
    para adaptar el parser sin tocar la lógica principal del resumen diario.

    Returns:
        Texto plano con proyecto y listado de tareas, o un mensaje legible
        si el archivo no existe / no parsea / no contiene tareas.
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
    """
    Construye el contexto del día, invoca el skill 'resumen_texto' y guarda
    el resultado en disco.

    Flujo:
        1) Cargar skills.
        2) Verificar que exista 'resumen_texto'.
        3) Armar un texto base con historial reciente + tablero de tareas.
        4) Pedir al skill un resumen breve y útil.
        5) Guardarlo en ~/Documents/dotfiles/hermes/resumenes/.

    Returns:
        Resumen final como texto listo para stdout.
    """
    skills = load_skills()
    if "resumen_texto" not in skills:
        return (
            "Skill 'resumen_texto' no encontrado. "
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

    RESUMEN_DIR.mkdir(parents=True, exist_ok=True)
    ruta = RESUMEN_DIR / f"resumen-{hoy}.md"
    ruta.write_text(resumen, encoding="utf-8")

    return resumen


async def main() -> None:
    """
    Punto de entrada asíncrono del script.

    Se mantiene separado para que asyncio.run() quede limpio en el bloque
    principal y el flujo sea más fácil de testear o reutilizar.
    """
    resumen = await generar_resumen_diario()
    print(resumen)


if __name__ == "__main__":
    asyncio.run(main())
