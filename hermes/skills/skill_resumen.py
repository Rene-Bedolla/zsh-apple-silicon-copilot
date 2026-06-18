#!/usr/bin/env python3
"""
Skill: resumen_texto

Genera un resumen estructurado en español usando el modelo local MLX.
Devuelve SOLO el campo 'content' de la respuesta, descartando cualquier
bloque de razonamiento (<think>...</think> o el campo 'reasoning').

Timeout generoso (300s / 5 min) porque MLX puede tardar si el modelo
está paginando o hay otros servicios compitiendo por RAM.
"""

from __future__ import annotations
import re
from typing import Optional

import httpx

from .base import Skill

MLX_URL = "http://localhost:8000/v1/chat/completions"
DEFAULT_MODEL_ID = "mlx-community/Qwen3.5-4B-OptiQ-4bit"

# Elimina bloques <think>...</think> que algunos servidores insertan en el stream
_RE_THINK = re.compile(r"<think>.*?</think>", re.DOTALL)


class ResumenTextoSkill(Skill):
    name = "resumen_texto"
    description = (
        "Genera un resumen estructurado de un texto largo usando el modelo local MLX."
    )

    async def run(
        self,
        input_text: str,
        *,
        max_tokens: int = 512,          # Reducido: menos tokens → menos tiempo de inferencia
        modelo_id: Optional[str] = None,
        extra_instrucciones: str = "",
    ) -> str:
        """
        Resume 'input_text' y devuelve Markdown limpio en español.

        Cambios respecto a la versión anterior:
        - timeout=300 (5 min) para tolerar la latencia de MLX con RAM compartida
        - max_tokens=512 por defecto (puede subirse desde resumen_diario.py si hay margen)
        - Usa SOLO 'content'; ignora 'reasoning' completamente
        - Limpia bloques <think>...</think> si el servidor los devuelve en 'content'
        - Instrucción de sistema más estricta para evitar el monólogo en inglés
        """

        texto = input_text.strip()
        if not texto:
            return "No se proporcionó texto para resumir."

        model_id = modelo_id or DEFAULT_MODEL_ID

        instruccion = (
            "Eres un asistente ejecutivo. "
            "SIEMPRE respondes en español. "
            "Responde SOLO con el contenido solicitado. "
            "PROHIBIDO: explicaciones previas, monólogos, análisis de qué vas a hacer. "
            "Usa Markdown (##, ###, - viñetas, **negrita**). "
        )
        if extra_instrucciones:
            instruccion += extra_instrucciones

        instruccion += (
            "\n\nGenera un resumen estructurado del siguiente texto con exactamente estas tres secciones:\n\n"
            "## Resumen general\n"
            "## Puntos clave\n"
            "## Acciones sugeridas\n\n"
            "Sé conciso. Máximo 3 viñetas por sección."
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

        # timeout=300: connect 10s + read 290s
        # MLX puede tardar ~2-4 min en generar 512 tokens con el modelo en RAM compartida
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(connect=10.0, read=290.0, write=10.0, pool=5.0)
        ) as client:
            resp = await client.post(MLX_URL, json=payload)
            resp.raise_for_status()
            data = resp.json()

        msg = data["choices"][0]["message"]

        # SOLO 'content'; nunca 'reasoning'
        contenido = (msg.get("content") or "").strip()

        # Limpieza de bloques de pensamiento si vinieron dentro de 'content'
        contenido = _RE_THINK.sub("", contenido).strip()

        if not contenido:
            return (
                "⚠️ El modelo no devolvió contenido en 'content'. "
                "Verifica que el servidor MLX en :8000 esté activo "
                "(`curl -s http://127.0.0.1:8000/v1/models`) "
                "y que el modelo no sea de razonamiento puro sin salida de texto."
            )

        return contenido


SkillClass = ResumenTextoSkill
