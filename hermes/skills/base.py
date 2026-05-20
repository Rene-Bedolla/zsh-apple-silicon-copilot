#!/usr/bin/env python3
"""
Interfaz base de Skills para HERMES.

Diseño:
- Cada archivo skill_*.py debe exponer explícitamente `SkillClass`.
- El loader evita barridos ambiguos con dir(module), porque eso genera
  falsos duplicados cuando hay aliases, imports reexportados o más de una
  clase derivada visible en el módulo.
"""

from __future__ import annotations
from abc import ABC, abstractmethod
from pathlib import Path
from importlib import import_module
from typing import Dict, Type
import sys


class Skill(ABC):
    """
    Interfaz base de un Skill.

    - name: identificador corto del skill (ej. "resumen_diario").
    - description: texto breve para describir qué hace.
    - run(input: str, **kwargs) -> str: ejecuta la habilidad y devuelve texto.
    """

    name: str = ""
    description: str = ""

    def __init__(self) -> None:
        if not getattr(self, "name", None):
            raise ValueError(f"{self.__class__.__name__} debe definir 'name'.")
        if not getattr(self, "description", None):
            raise ValueError(f"{self.__class__.__name__} debe definir 'description'.")

    @abstractmethod
    async def run(self, input_text: str, **kwargs) -> str:
        """
        Ejecuta el skill sobre input_text.

        Debe ser idempotente y no asumir estado global.
        """
        ...


def _resolve_skill_class(module, module_name: str) -> Type[Skill] | None:
    """
    Resuelve la clase concreta del skill para un módulo dado.

    Regla principal:
    - Si existe `SkillClass`, se usa esa.

    Fallback:
    - Buscar exactamente una subclase de Skill definida en el propio módulo.
    - Si hay cero o más de una, avisar y no registrar.
    """
    explicit = getattr(module, "SkillClass", None)
    if explicit is not None:
        if not isinstance(explicit, type) or not issubclass(explicit, Skill) or explicit is Skill:
            print(
                f"[Skills] Error: {module_name}.SkillClass no es una subclase válida de Skill.",
                file=sys.stderr,
            )
            return None
        return explicit

    candidates: list[Type[Skill]] = []

    for attr_name in dir(module):
        attr = getattr(module, attr_name)
        if not (
            isinstance(attr, type)
            and issubclass(attr, Skill)
            and attr is not Skill
        ):
            continue

        if getattr(attr, "__module__", None) != module_name:
            continue

        candidates.append(attr)

    if len(candidates) == 1:
        return candidates[0]

    if len(candidates) == 0:
        print(
            f"[Skills] Error: {module_name} no expone SkillClass ni contiene una clase Skill válida.",
            file=sys.stderr,
        )
        return None

    print(
        f"[Skills] Error: {module_name} contiene múltiples clases Skill. "
        f"Exporta explícitamente `SkillClass = TuClase`.",
        file=sys.stderr,
    )
    return None


def load_skills() -> Dict[str, Skill]:
    """
    Descubre módulos skill_*.py e instancia una clase Skill por archivo.

    Política:
    - Un archivo = un skill registrable.
    - Si dos módulos distintos comparten el mismo `name`, se conserva el primero
      y se ignora el segundo, dejando advertencia en stderr.
    """
    skills_dir = Path(__file__).parent
    skills: Dict[str, Skill] = {}

    for path in sorted(skills_dir.glob("skill_*.py")):
        if path.name in {"__init__.py", "base.py"}:
            continue

        module_name = f"hermes.skills.{path.stem}"

        try:
            module = import_module(module_name)
        except Exception as e:
            print(f"[Skills] Error importando {module_name}: {e}", file=sys.stderr)
            continue

        skill_cls = _resolve_skill_class(module, module_name)
        if skill_cls is None:
            continue

        try:
            instance = skill_cls()
        except Exception as e:
            print(
                f"[Skills] Error instanciando {skill_cls.__name__} en {module_name}: {e}",
                file=sys.stderr,
            )
            continue

        if instance.name in skills:
            print(
                f"[Skills] Advertencia: skill duplicado real '{instance.name}' "
                f"entre módulos. Se conserva el primero y se ignora {module_name}.",
                file=sys.stderr,
            )
            continue

        skills[instance.name] = instance

    return skills
