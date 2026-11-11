"""Crea backend/.env a partir de .env.example con una SECRET_KEY nueva.

No sobrescribe un .env existente. Uso (desde la carpeta backend):
    python scripts/create_env.py
"""
from __future__ import annotations

import secrets
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parent.parent
EXAMPLE = BACKEND / ".env.example"
TARGET = BACKEND / ".env"


def main() -> int:
    if TARGET.exists():
        print(f"{TARGET} ya existe; no se modificó. Bórralo manualmente si quieres regenerarlo.")
        return 1
    content = EXAMPLE.read_text(encoding="utf-8").replace("SECRET_KEY=\n", f"SECRET_KEY={secrets.token_hex(32)}\n", 1)
    TARGET.write_text(content, encoding="utf-8")
    print(f"Creado {TARGET} con una SECRET_KEY nueva de 64 caracteres.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
