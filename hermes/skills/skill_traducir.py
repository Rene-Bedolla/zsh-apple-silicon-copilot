#!/usr/bin/env python3
"""
Skill: traducir_texto

Traduce texto usando el modelo local MLX (Qwen3-8B) vía API OpenAI-compatible.

Este skill está pensado para:
- Traducir fragmentos de notas de Obsidian.
- Traducir mensajes o documentación técnica.
"""

from __future__ import annotations
from typing import Literal, Optional

import httpx

from .base import Skill

MLX_URL = "http://localhost:8000/v1/chat/completions"
DEFAULT_MODEL_ID = "mlx-community/Qwen3-8B-4bit"

Idioma = Literal["es", "en"]


class TraducirTextoSkill(Skill):
    name = "traducir_texto"
    description = (
        "Traduce texto entre español e inglés usando el modelo local MLX."
    )

    async def run(
        self,
        input_text: str,
        *,
        origen: Idioma = "es",
        destino: Idioma = "en",
        max_tokens: int = 800,
        modelo_id: Optional[str] = None,
    ) -> str:
        """
        Traduce input_text de 'origen' -> 'destino'.

        Idiomas soportados: 'es' (español), 'en' (inglés).
        """

        texto = input_text.strip()
        if not texto:
            return "No se proporcionó texto para traducir."

        if origen == destino:
            return texto

        if origen not in ("es", "en") or destino not in ("es", "en"):
            return (
                "Idiomas no soportados. Usa 'es' o 'en' para origen/destino. "
                f"Recibido origen={origen}, destino={destino}."
            )

        model_id = modelo_id or DEFAULT_MODEL_ID

        if origen == "es" and destino == "en":
            instruccion = (
                "Traduce el siguiente texto del español al inglés.\n"
                "Mantén el significado fiel, tono neutro-profesional y formato básico.\n"
                "No añadas explicaciones, solo la traducción."
            )
        else:
            instruccion = (
                "Traduce el siguiente texto del inglés al español.\n"
                "Mantén el significado fiel, tono neutro-profesional y formato básico.\n"
                "No añadas explicaciones, solo la traducción."
            )

        messages = [
            {"role": "system", "content": instruccion},
            {"role": "user", "content": texto},
        ]

        payload = {
            "model": model_id,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": 0.3,
        }

        async with httpx.AsyncClient(timeout=120) as client:
            resp = await client.post(MLX_URL, json=payload)
            resp.raise_for_status()
            data = resp.json()
            msg = data["choices"][0]["message"]
            contenido = msg.get("content") or msg.get("reasoning", "")
            return (contenido or "").strip()


SkillClass = TraducirTextoSkill
