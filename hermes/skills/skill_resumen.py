#!/usr/bin/env python3
"""
Skill: resumen_texto

Genera un resumen estructurado en español usando el modelo local MLX.
Prioriza una salida directa, sin cadena de razonamiento visible.
"""

from __future__ import annotations

import re
from typing import Optional

import httpx

from .base import Skill

MLX_URL = "http://localhost:8000/v1/chat/completions"
DEFAULT_MODEL_ID = "mlx-community/Qwen3.5-4B-OptiQ-4bit"

_RE_THINK = re.compile(r"<think>.*?</think>", re.DOTALL)


def _limpiar_texto(texto: str) -> str:
    texto = _RE_THINK.sub("", texto or "").strip()
    texto = texto.replace("<think>", "").replace("</think>", "").strip()
    return texto


class ResumenTextoSkill(Skill):
    name = "resumen_texto"
    description = "Genera un resumen estructurado de un texto largo usando el modelo local MLX."

    async def run(
        self,
        input_text: str,
        *,
        max_tokens: int = 512,
        modelo_id: Optional[str] = None,
        extra_instrucciones: str = "",
    ) -> str:
        texto = input_text.strip()
        if not texto:
            return "No se proporcionó texto para resumir."

        model_id = modelo_id or DEFAULT_MODEL_ID

        instruccion = (
            "Eres un asistente ejecutivo. "
            "Siempre respondes en español. "
            "Responde solo con el contenido solicitado, sin explicaciones previas. "
            "No muestres razonamiento interno. "
            "Usa Markdown con exactamente estas tres secciones:\n"
            "## Resumen general\n"
            "## Puntos clave\n"
            "## Acciones sugeridas\n"
            "Máximo 3 viñetas por sección."
        )

        if extra_instrucciones:
            instruccion += "\n" + extra_instrucciones.strip()

        messages = [
            {"role": "system", "content": instruccion},
            {"role": "user", "content": texto + "\n\n/no_think"},
        ]

        payload = {
            "model": model_id,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": 0.2,
        }

        async with httpx.AsyncClient(
            timeout=httpx.Timeout(connect=10.0, read=290.0, write=10.0, pool=5.0)
        ) as client:
            resp = await client.post(MLX_URL, json=payload)
            resp.raise_for_status()
            data = resp.json()

        choice = (data.get("choices") or [{}])[0]
        msg = choice.get("message") or {}

        contenido = _limpiar_texto(msg.get("content", ""))

        if not contenido:
            reasoning = _limpiar_texto(msg.get("reasoning", ""))
            if reasoning and "## " in reasoning:
                contenido = reasoning

        if not contenido:
            texto_plano = _limpiar_texto(str(msg))
            if "## " in texto_plano:
                contenido = texto_plano

        if not contenido:
            return (
                "⚠️ El modelo no devolvió contenido utilizable.\n"
                "Verifica que MLX responda bien en :8000 y que Qwen3.5 esté activo.\n"
                "Prueba: curl -s http://127.0.0.1:8000/v1/models"
            )

        return contenido


SkillClass = ResumenTextoSkill
