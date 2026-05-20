#!/usr/bin/env python3
"""
CLI de conveniencia para el orquestador HERMES.

Permite usar:
  python3 hermes/orchestrator_cli.py --listar
  python3 hermes/orchestrator_cli.py H-001

sin preocuparte por el PYTHONPATH o el modo -m.
"""

from __future__ import annotations

import sys
from pathlib import Path

# Bootstrap: añadir ~/Documents/dotfiles a sys.path para que el paquete 'hermes'
# se pueda importar aunque ejecutemos este archivo directamente.
ROOT = Path(__file__).resolve().parents[1]  # ~/Documents/dotfiles
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.agents.orchestrator import main  # type: ignore[import]


if __name__ == "__main__":
    # Pasar argumentos tal cual al main() del orquestador
    main()
