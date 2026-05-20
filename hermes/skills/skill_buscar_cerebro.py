#!/usr/bin/env python3
"""
Skill: buscar_cerebro

Envuelve la búsqueda semántica en el Cerebro (bóveda Obsidian indexada en ChromaDB)
para que el orquestador y otros componentes de HERMES puedan reutilizarla.

Requiere:
  - Índice creado con indexar_cerebro.py (ChromaDB en ~/.hermes/memoria/chromadb).
"""

from __future__ import annotations
from typing import Optional, List

from .base import Skill


class BuscarCerebroSkill(Skill):
    name = "buscar_cerebro"
    description = (
        "Busca en el Cerebro (vault Obsidian indexado en ChromaDB) "
        "y devuelve las notas más relevantes en formato Markdown."
    )

    async def run(
        self,
        input_text: str,
        *,
        n_resultados: int = 5,
        solo_rutas: bool = False,
    ) -> str:
        """
        Ejecuta una búsqueda semántica en el Cerebro.

        Parámetros:
          - input_text: consulta en lenguaje natural.
          - n_resultados: máximo de notas a devolver.
          - solo_rutas: si es True, devuelve solo la lista de rutas.

        Devuelve:
          - Texto en Markdown listo para mostrarse en chat o logs.
        """
        consulta = input_text.strip()
        if not consulta:
            return "No se proporcionó una consulta para buscar en el Cerebro."

        try:
            # Importación perezosa para no forzar chromadb/sentence-transformers
            # en otros paths donde el skill no se usa.
            from hermes.memoria.buscar_cerebro import buscar as buscar_cerebro  # type: ignore
        except Exception as e:
            return (
                "No se pudo importar hermes.memoria.buscar_cerebro. "
                f"Verifica que indexar_cerebro.py y buscar_cerebro.py existan. Error: {e}"
            )

        try:
            resultados: List[dict] = buscar_cerebro(consulta, n_resultados)
        except SystemExit:
            # Los scripts originales usan sys.exit() en algunos casos; lo convertimos en texto.
            return (
                "El índice de Cerebro no está listo. "
                "Ejecuta primero: python3 hermes/memoria/indexar_cerebro.py --full"
            )
        except Exception as e:
            return f"Error al consultar el Cerebro: {e}"

        if not resultados:
            return f"No se encontraron notas relevantes para: **{consulta}**."

        if solo_rutas:
            lineas = [f"Rutas para consulta: **{consulta}**"]
            for r in resultados:
                lineas.append(f"- {r['ruta']}")
            return "\n".join(lineas)

        # Formato Markdown completo
        partes: List[str] = []
        partes.append(f"### Resultados en el Cerebro para: **{consulta}**\n")

        for i, r in enumerate(resultados, 1):
            relevancia = round((1 - r["distancia"]) * 100, 1)
            partes.append(
                f"{i}. **{r['titulo']}**  — {relevancia}% relevante\n"
                f"   - 📂 `{r['ruta']}`\n"
                f"   - 📄 {r['fragmento'].strip()}..."
            )

        return "\n\n".join(partes)


# Alias legible para el registrador automático
SkillClass = BuscarCerebroSkill
