#!/usr/bin/env python3
# ==============================================================================
# ARCHIVO: indexar_cerebro.py
# PROPÓSITO: Indexar bóveda Obsidian en ChromaDB para búsqueda semántica
# MOTOR: ChromaDB embebido (SQLite, sin Docker) + sentence-transformers local
# BÓVEDA: /Users/ren/Notas (symlink → iCloud Obsidian)
# USO: python3 indexar_cerebro.py [--full | --incremental]
#      --full         → reindexar todo desde cero
#      --incremental  → solo notas modificadas en las últimas 24h (default)
# ==============================================================================

import os
import sys
import hashlib
import re
from pathlib import Path
from datetime import datetime, timedelta

import logging
logging.getLogger('sentence_transformers').setLevel(logging.ERROR)
logging.getLogger('transformers').setLevel(logging.ERROR)

import chromadb
from chromadb.config import Settings
from sentence_transformers import SentenceTransformer

# ── Rutas ─────────────────────────────────────────────────────────────────────
BOVEDA_DIR  = Path("/Users/ren/Notas")
CHROMA_DIR  = Path.home() / ".hermes/memoria/chromadb"
MODELO_EMB  = "all-MiniLM-L6-v2"   # 22MB, rápido, buena calidad semántica
COLECCION   = "cerebro_obsidian"

# Carpetas de Obsidian a ignorar
IGNORAR = {".obsidian", ".trash", "templates", "Templates", "_attachments"}

def limpiar_markdown(texto: str) -> str:
    """Elimina frontmatter YAML, wikilinks y sintaxis Markdown para indexar texto limpio."""
    texto = re.sub(r'^---.*?---\n', '', texto, flags=re.DOTALL)   # frontmatter
    texto = re.sub(r'\[\[([^\]]+)\]\]', r'\1', texto)              # wikilinks
    texto = re.sub(r'[#*`>~_]', '', texto)                         # markdown
    texto = re.sub(r'\n{3,}', '\n\n', texto)                       # líneas extra
    return texto.strip()

def calcular_hash(contenido: str) -> str:
    """Hash MD5 del contenido para detectar cambios sin releer todo."""
    return hashlib.md5(contenido.encode()).hexdigest()

def obtener_notas(modo_incremental: bool = True) -> list[Path]:
    """Devuelve lista de archivos .md a indexar según el modo."""
    if not BOVEDA_DIR.exists():
        print(f"❌ Bóveda no encontrada en {BOVEDA_DIR}")
        sys.exit(1)

    corte = datetime.now() - timedelta(hours=24) if modo_incremental else None
    notas = []

    for md_file in BOVEDA_DIR.rglob("*.md"):
        # Ignorar carpetas del sistema Obsidian
        if any(parte in IGNORAR for parte in md_file.parts):
            continue
        # En modo incremental solo notas modificadas recientemente
        if corte:
            mtime = datetime.fromtimestamp(md_file.stat().st_mtime)
            if mtime < corte:
                continue
        notas.append(md_file)

    return notas

def indexar(modo_full: bool = False):
    """Función principal de indexación."""
    print(f"\n  🧠 HERMES — Indexador de Cerebro Obsidian")
    print(f"  Modo: {'completo' if modo_full else 'incremental (últimas 24h)'}")
    print(f"  Bóveda: {BOVEDA_DIR}\n")

    # Crear directorio de ChromaDB
    CHROMA_DIR.mkdir(parents=True, exist_ok=True)

    # Inicializar cliente ChromaDB embebido (persiste en disco, sin servidor)
    cliente = chromadb.PersistentClient(
        path=str(CHROMA_DIR),
        settings=Settings(anonymized_telemetry=False)
    )

    # Obtener o crear colección con función de distancia coseno
    coleccion = cliente.get_or_create_collection(
        name=COLECCION,
        metadata={"hnsw:space": "cosine"}
    )

    # Cargar modelo de embeddings (se descarga solo la primera vez, ~22MB)
    print(f"  📦 Cargando modelo de embeddings ({MODELO_EMB})...")
    modelo = SentenceTransformer(MODELO_EMB)

    # Obtener notas a indexar
    notas = obtener_notas(modo_incremental=not modo_full)
    if not notas:
        print("  ✅ No hay notas nuevas para indexar.")
        return

    print(f"  📝 Indexando {len(notas)} nota(s)...\n")

    indexadas = 0
    omitidas = 0

    for nota_path in notas:
        try:
            contenido_raw = nota_path.read_text(encoding="utf-8")
            contenido_limpio = limpiar_markdown(contenido_raw)

            if len(contenido_limpio) < 50:   # ignorar notas vacías
                continue

            # ID único basado en ruta relativa a la bóveda
            doc_id = str(nota_path.relative_to(BOVEDA_DIR))
            hash_actual = calcular_hash(contenido_limpio)

            # Verificar si la nota ya existe y no cambió
            try:
                existente = coleccion.get(ids=[doc_id])
                if existente["metadatas"] and \
                   existente["metadatas"][0].get("hash") == hash_actual:
                    omitidas += 1
                    continue
            except Exception:
                pass

            # Generar embedding y guardar en ChromaDB
            embedding = modelo.encode(contenido_limpio[:2000]).tolist()

            coleccion.upsert(
                ids=[doc_id],
                embeddings=[embedding],
                documents=[contenido_limpio[:2000]],
                metadatas=[{
                    "titulo": nota_path.stem,
                    "ruta": str(nota_path),
                    "hash": hash_actual,
                    "actualizado": datetime.now().isoformat()
                }]
            )
            print(f"  ✅ {nota_path.stem}")
            indexadas += 1

        except Exception as e:
            print(f"  ⚠️  Error en {nota_path.name}: {e}")

    print(f"\n  Resultado: {indexadas} indexadas · {omitidas} sin cambios")
    print(f"  📂 ChromaDB en: {CHROMA_DIR}")
    print(f"  Total en colección: {coleccion.count()} documentos\n")

if __name__ == "__main__":
    modo_full = "--full" in sys.argv
    indexar(modo_full=modo_full)

# Silenciar warnings de carga de modelo al inicio del script