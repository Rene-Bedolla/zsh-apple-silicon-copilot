#!/usr/bin/env python3
"""
Skill: procesar_inbox_obsidian

Versión 1 (modo seguro, solo lectura):
- Recorre el Inbox de Obsidian en ~/Notas/Notas.
- Detecta notas con frontmatter:
    estado: pendiente
    tags: que contenga 'inbox'
- Devuelve un listado en Markdown con metadatos y un breve extracto del cuerpo.

NO mueve archivos ni modifica el frontmatter.
La idea es usar este skill para:
- Tener una vista rápida de "qué hay en el Inbox".
- Servir como base para una versión futura que sí proponga destinos y cambios.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Dict

from .base import Skill


INBOX_DIR = Path.home() / "Notas" / "Notas"


@dataclass
class NotaInbox:
    ruta: Path
    titulo: str
    fecha_captura: Optional[str]
    fecha_modificacion: Optional[str]
    origen: Optional[str]
    estado: Optional[str]
    tags: List[str]
    preview: str


def _parse_frontmatter(contenido: str) -> tuple[Dict[str, object], str]:
    """
    Extrae un frontmatter YAML muy sencillo del inicio del archivo y devuelve:
      (dict_frontmatter, cuerpo_sin_frontmatter)

    Asume formato:

    ---
    clave: valor
    otra: cosa
    tags:
      - inbox
      - algo
    ---
    resto...

    Si no hay frontmatter, retorna ({}, contenido).
    """
    if not contenido.startswith("---"):
        return {}, contenido

    lineas = contenido.splitlines()
    if len(lineas) < 3:
        return {}, contenido

    # Buscar cierre del bloque ---
    cierre_idx: Optional[int] = None
    for i in range(1, len(lineas)):
        if lineas[i].strip() == "---":
            cierre_idx = i
            break

    if cierre_idx is None:
        return {}, contenido

    bloque = lineas[1:cierre_idx]
    cuerpo = "\n".join(lineas[cierre_idx + 1 :])

    fm: Dict[str, object] = {}
    i = 0
    while i < len(bloque):
        linea = bloque[i]
        if not linea.strip():
            i += 1
            continue

        # tags:
        if linea.strip().startswith("tags:"):
            tags: List[str] = []
            i += 1
            while i < len(bloque) and bloque[i].lstrip().startswith("- "):
                tag_raw = bloque[i].strip()[2:]
                if tag_raw:
                    tags.append(tag_raw.strip())
                i += 1
            fm["tags"] = tags
            continue

        # clave: valor
        if ":" in linea:
            clave, valor = linea.split(":", 1)
            fm[clave.strip()] = valor.strip()
        i += 1

    return fm, cuerpo


def _cargar_notas_inbox(max_notas: int) -> List[NotaInbox]:
    """
    Lee hasta max_notas archivos .md en INBOX_DIR que cumplan:
      - estado: pendiente
      - tags incluye 'inbox'
    """
    notas: List[NotaInbox] = []

    if not INBOX_DIR.is_dir():
        return notas

    archivos = sorted(
        INBOX_DIR.glob("*.md"),
        key=lambda p: p.stat().st_mtime,
    )

    for path in archivos:
        try:
            texto = path.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue

        fm, cuerpo = _parse_frontmatter(texto)

        estado = str(fm.get("estado", "")).strip().lower()
        tags = [t.strip() for t in fm.get("tags", [])] if isinstance(fm.get("tags"), list) else []

        if estado != "pendiente":
            continue
        if "inbox" not in {t.lower() for t in tags}:
            continue

        titulo = str(fm.get("titulo", path.stem)).strip()
        fecha_captura = str(fm.get("fecha_captura", "")).strip() or None
        fecha_modificacion = str(fm.get("fecha_modificacion", "")).strip() or None
        origen = str(fm.get("origen", "")).strip() or None

        cuerpo_limpio = cuerpo.strip()
        preview = cuerpo_limpio.split("\n", 4)
        # Tomamos hasta 4 líneas y las recortamos un poco
        preview_text = "\n".join(preview[:4]).strip()
        if len(preview_text) > 300:
            preview_text = preview_text[:300].rstrip() + "…"

        notas.append(
            NotaInbox(
                ruta=path,
                titulo=titulo or path.stem,
                fecha_captura=fecha_captura,
                fecha_modificacion=fecha_modificacion,
                origen=origen,
                estado=estado,
                tags=tags,
                preview=preview_text,
            )
        )

        if len(notas) >= max_notas:
            break

    return notas


class ProcesarInboxObsidianSkill(Skill):
    name = "procesar_inbox_obsidian"
    description = (
        "Lista las notas pendientes del Inbox de Obsidian (~/Notas/Notas) "
        "con estado=pendiente y tag 'inbox', mostrando metadatos y un extracto."
    )

    async def run(
        self,
        input_text: str,
        *,
        max_notas: int = 10,
    ) -> str:
        """
        Versión 1 (solo lectura):

        - input_text puede incluir un número para ajustar max_notas (ej. '5').
        - Si no se encuentra número, max_notas se mantiene en el valor por defecto.
        """
        # Permitir que el usuario pase un número simple en input_text
        texto = (input_text or "").strip()
        if texto:
            for token in texto.split():
                if token.isdigit():
                    try:
                        max_notas = max(1, int(token))
                    except ValueError:
                        pass
                    break

        notas = _cargar_notas_inbox(max_notas=max_notas)

        if not notas:
            return (
                "No hay notas pendientes en el Inbox (`~/Notas/Notas`) "
                "con `estado: pendiente` y tag `inbox`."
            )

        partes: List[str] = []
        partes.append(
            f"### Notas pendientes en el Inbox (máximo {max_notas})\n"
            "_Versión 1 – solo lectura, sin mover archivos ni cambiar frontmatter._\n"
        )

        for i, n in enumerate(notas, 1):
            partes.append(f"#### {i}. {n.titulo}\n")
            partes.append(f"- 📄 Ruta: `{n.ruta}`")
            if n.fecha_captura:
                partes.append(f"- 🗓️ Captura: `{n.fecha_captura}`")
            if n.fecha_modificacion:
                partes.append(f"- ✏️ Última modificación: `{n.fecha_modificacion}`")
            if n.origen:
                partes.append(f"- 🏷️ Origen: `{n.origen}`")
            partes.append(f"- 🔖 Tags: {', '.join(n.tags) if n.tags else '(sin tags)'}")
            partes.append("\n**Preview:**\n")
            partes.append(f"> {n.preview}\n")

        return "\n".join(partes)


SkillClass = ProcesarInboxObsidianSkill
