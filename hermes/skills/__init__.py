"""
Paquete de skills para el harness HERMES.

Cada skill es un módulo que expone una clase que hereda de Skill
y se registra automáticamente a través de load_skills().
"""

from .base import Skill, load_skills  # noqa: F401
