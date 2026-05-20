#!/usr/bin/env python3
"""
CLI mínima para probar skills del harness.

Ejemplos:

  python3 run_skill.py listar
  echo "Texto largo..." | python3 run_skill.py resumen_texto

"""

import sys
import asyncio
from . import load_skills


async def main() -> None:
    skills = load_skills()

    if len(sys.argv) < 2:
        print("Uso:")
        print("  python3 -m hermes.skills.run_skill listar")
        print("  python3 -m hermes.skills.run_skill resumen_texto < texto")
        return

    name = sys.argv[1]

    if name == "listar":
        print("\nSkills disponibles:\n")
        for sk_name, sk in skills.items():
            print(f"- {sk_name}: {sk.description}")
        print()
        return

    if name not in skills:
        print(f"Skill '{name}' no encontrado. Usa 'listar' para ver opciones.")
        return

    skill = skills[name]
    # Leer texto desde stdin
    input_text = sys.stdin.read()
    if not input_text.strip():
        print("No se recibió texto por stdin.")
        return

    resultado = await skill.run(input_text)
    print(resultado)


if __name__ == "__main__":
    asyncio.run(main())
