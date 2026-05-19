#!/usr/bin/env python3
# ==============================================================================
# ARCHIVO: buscar_cerebro.py
# PROPÓSITO: Búsqueda semántica en la bóveda Obsidian indexada en ChromaDB
# USO: python3 buscar_cerebro.py "tu consulta en lenguaje natural"
#      python3 buscar_cerebro.py "consulta" --n 5   (top 5 resultados)
# REQUIERE: ChromaDB indexado — ejecutar indexar_cerebro.py primero
# ==============================================================================

import sys
import logging
logging.getLogger('sentence_transformers').setLevel(logging.ERROR)
logging.getLogger('transformers').setLevel(logging.ERROR)

from pathlib import Path
import chromadb
from chromadb.config import Settings
from sentence_transformers import SentenceTransformer

CHROMA_DIR = Path.home() / ".hermes/memoria/chromadb"
COLECCION  = "cerebro_obsidian"
MODELO_EMB = "all-MiniLM-L6-v2"

def buscar(consulta: str, n_resultados: int = 3) -> list[dict]:
    """Búsqueda semántica — devuelve las notas más relevantes para la consulta."""
    if not CHROMA_DIR.exists():
        print("❌ ChromaDB no inicializado. Ejecuta: python3 indexar_cerebro.py --full")
        sys.exit(1)

    cliente = chromadb.PersistentClient(
        path=str(CHROMA_DIR),
        settings=Settings(anonymized_telemetry=False)
    )
    coleccion = cliente.get_collection(COLECCION)

    if coleccion.count() == 0:
        print("⚠️  Colección vacía. Ejecuta: python3 indexar_cerebro.py --full")
        sys.exit(1)

    # Generar embedding de la consulta con el mismo modelo
    modelo = SentenceTransformer(MODELO_EMB)
    embedding_consulta = modelo.encode(consulta).tolist()

    resultados = coleccion.query(
        query_embeddings=[embedding_consulta],
        n_results=min(n_resultados, coleccion.count()),
        include=["documents", "metadatas", "distances"]
    )

    return [
        {
            "titulo": resultados["metadatas"][0][i]["titulo"],
            "ruta": resultados["metadatas"][0][i]["ruta"],
            "distancia": resultados["distances"][0][i],
            "fragmento": resultados["documents"][0][i][:300]
        }
        for i in range(len(resultados["ids"][0]))
    ]

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 buscar_cerebro.py \"tu consulta\" [--n N]")
        sys.exit(1)

    consulta = sys.argv[1]
    n = int(sys.argv[sys.argv.index("--n") + 1]) if "--n" in sys.argv else 3

    print(f"\n  🔍 Buscando: \"{consulta}\"\n")
    resultados = buscar(consulta, n)

    for i, r in enumerate(resultados, 1):
        relevancia = round((1 - r["distancia"]) * 100, 1)
        print(f"  {i}. {r['titulo']}  [{relevancia}% relevante]")
        print(f"     📄 {r['fragmento'][:150]}...")
        print(f"     📂 {r['ruta']}\n")

if __name__ == "__main__":
    main()
