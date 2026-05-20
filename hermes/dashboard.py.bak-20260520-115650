#!/opt/homebrew/opt/python@3.11/libexec/bin/python3
# ==============================================================================
# ARCHIVO: dashboard.py
# PROPÓSITO: Dashboard web local para visualizar el estado real del harness HERMES
# STACK: Python 3.11 stdlib únicamente, sin dependencias externas
# USO: HERMES_PORT=8421 python3 ~/Documents/dotfiles/hermes/dashboard.py
# ==============================================================================

from __future__ import annotations

import json
import html
import os
import mimetypes
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote

# ── Rutas base del harness ─────────────────────────────────────────────────────
HERMES_DIR = Path.home() / "Documents/dotfiles/hermes"
FEATURES_FILE = HERMES_DIR / "features.json"
PROGRESS_DIR = HERMES_DIR / "progress"
NEXUS_FILE = HERMES_DIR / "Nexus.md"

# ── Configuración de red ───────────────────────────────────────────────────────
HOST = "0.0.0.0"
PORT = int(os.environ.get("HERMES_PORT", "8421"))

# ── Utilidades de lectura ──────────────────────────────────────────────────────
def ahora() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def leer_json_seguro(ruta: Path) -> dict:
    if not ruta.exists():
        return {}
    try:
        return json.loads(ruta.read_text(encoding="utf-8"))
    except Exception:
        return {}

def leer_texto_seguro(ruta: Path) -> str:
    if not ruta.exists():
        return ""
    try:
        return ruta.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""

def preview(texto: str, limite: int = 500) -> str:
    limpio = " ".join(texto.strip().split())
    if len(limpio) <= limite:
        return limpio
    return limpio[:limite].rstrip() + "…"

def contar_lineas(ruta: Path) -> int:
    try:
        with ruta.open("r", encoding="utf-8", errors="replace") as f:
            return sum(1 for _ in f)
    except Exception:
        return 0

def fmt_ts(ts: float) -> str:
    return datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M:%S")

def extraer_frontmatter_valor(texto: str, clave: str) -> str:
    for linea in texto.splitlines():
        if linea.lower().startswith(f"{clave.lower()}:"):
            return linea.split(":", 1)[1].strip().strip('"')
    return ""

# ── Modelo de estado ───────────────────────────────────────────────────────────
def cargar_tareas() -> list[dict]:
    data = leer_json_seguro(FEATURES_FILE)
    return data.get("tareas", [])

def estadisticas_tareas(tareas: list[dict]) -> dict:
    total = len(tareas)
    pendientes = sum(1 for t in tareas if t.get("estado") == "pendiente")
    completadas = sum(1 for t in tareas if t.get("estado") in {"done", "completado", "completa", "finalizado"})
    en_progreso = total - pendientes - completadas
    return {
        "total": total,
        "pendientes": pendientes,
        "en_progreso": en_progreso,
        "completadas": completadas,
    }

def listar_archivos_agente(agente: str) -> list[Path]:
    carpeta = PROGRESS_DIR / agente
    if not carpeta.exists():
        return []
    return sorted(
        [p for p in carpeta.glob("*.md") if p.is_file()],
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )

def construir_estado() -> dict:
    tareas = cargar_tareas()
    nexus = leer_texto_seguro(NEXUS_FILE)

    agentes = ["explorer", "implementer", "reviewer"]
    progreso = {}

    for agente in agentes:
        archivos = listar_archivos_agente(agente)
        progreso[agente] = {
            "count": len(archivos),
            "latest": None,
            "items": [],
        }

        for archivo in archivos[:8]:
            texto = leer_texto_seguro(archivo)
            item = {
                "name": archivo.name,
                "mtime": fmt_ts(archivo.stat().st_mtime),
                "lines": contar_lineas(archivo),
                "preview": preview(texto, 320),
            }
            progreso[agente]["items"].append(item)

        if archivos:
            ultimo = archivos[0]
            texto = leer_texto_seguro(ultimo)
            progreso[agente]["latest"] = {
                "name": ultimo.name,
                "mtime": fmt_ts(ultimo.stat().st_mtime),
                "lines": contar_lineas(ultimo),
                "preview": preview(texto, 500),
            }

    return {
        "proyecto": leer_json_seguro(FEATURES_FILE).get("proyecto", "HERMES"),
        "descripcion": leer_json_seguro(FEATURES_FILE).get("descripcion", ""),
        "tareas": tareas,
        "stats": estadisticas_tareas(tareas),
        "progreso": progreso,
        "nexus_actualizado": extraer_frontmatter_valor(nexus, "actualizado") or "desconocido",
        "nexus_version": extraer_frontmatter_valor(nexus, "version") or "desconocida",
        "actualizado": ahora(),
    }

# ── Render HTML ────────────────────────────────────────────────────────────────
def badge_estado(estado: str) -> str:
    mapa = {
        "pendiente": "pill pending",
        "done": "pill done",
        "completado": "pill done",
        "finalizado": "pill done",
        "en_progreso": "pill progress",
    }
    clase = mapa.get(estado, "pill progress")
    return f'<span class="{clase}">{html.escape(estado or "sin_estado")}</span>'

def badge_prioridad(prioridad: str) -> str:
    mapa = {
        "alta": "pill high",
        "media": "pill medium",
        "baja": "pill low",
    }
    clase = mapa.get(prioridad, "pill")
    return f'<span class="{clase}">{html.escape(prioridad or "n/d")}</span>'

def render_tabla_tareas(tareas: list[dict]) -> str:
    filas = []
    for tarea in tareas:
        criterios = tarea.get("criterios_aceptacion", [])
        filas.append(
            f"""
            <tr>
              <td><code>{html.escape(tarea.get("id", ""))}</code></td>
              <td>{html.escape(tarea.get("titulo", ""))}</td>
              <td>{badge_estado(tarea.get("estado", ""))}</td>
              <td>{badge_prioridad(tarea.get("prioridad", ""))}</td>
              <td><code>{html.escape(tarea.get("agente", ""))}</code></td>
              <td><code>{html.escape(tarea.get("modelo", ""))}</code></td>
              <td>{len(criterios)}</td>
            </tr>
            """
        )
    return "\n".join(filas) if filas else '<tr><td colspan="7">No hay tareas disponibles.</td></tr>'

def render_archivos_agente(nombre: str, data: dict) -> str:
    latest = data.get("latest")
    lista = data.get("items", [])

    latest_html = """
      <div class="empty">Sin archivos generados todavía.</div>
    """
    if latest:
        latest_html = f"""
        <div class="latest">
          <div class="latest-head">
            <strong>{html.escape(latest["name"])}</strong>
            <span>{html.escape(latest["mtime"])}</span>
          </div>
          <div class="meta">Líneas: {latest["lines"]}</div>
          <pre>{html.escape(latest["preview"])}</pre>
        </div>
        """

    items_html = ""
    if lista:
        bloques = []
        for item in lista:
            ruta = f"/raw/{nombre}/{item['name']}"
            bloques.append(
                f"""
                <a class="file-row" href="{html.escape(ruta)}" target="_blank" rel="noopener noreferrer">
                  <span class="file-name">{html.escape(item["name"])}</span>
                  <span class="file-time">{html.escape(item["mtime"])}</span>
                </a>
                """
            )
        items_html = "\n".join(bloques)
    else:
        items_html = '<div class="empty">No hay historial.</div>'

    return f"""
    <section class="panel">
      <div class="panel-top">
        <h3>{html.escape(nombre.title())}</h3>
        <span class="counter">{data.get("count", 0)} archivos</span>
      </div>
      {latest_html}
      <div class="list">
        {items_html}
      </div>
    </section>
    """

def render_html(state: dict) -> str:
    tareas = state["tareas"]
    progreso = state["progreso"]
    stats = state["stats"]

    return f"""<!DOCTYPE html>
<html lang="es" data-theme="dark">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="refresh" content="20">
  <title>HERMES Dashboard</title>
  <style>
    :root {{
      --bg: #111315;
      --surface: #171a1d;
      --surface-2: #1f2429;
      --border: #2f363d;
      --text: #eef2f5;
      --muted: #a7b0b8;
      --primary: #4f98a3;
      --pending: #e8af34;
      --progress: #5591c7;
      --done: #6daa45;
      --high: #dd6974;
      --medium: #fdab43;
      --low: #4f98a3;
      --code: #0e1114;
      --shadow: 0 10px 30px rgba(0,0,0,.25);
      --radius: 18px;
    }}
    * {{ box-sizing: border-box; }}
    html, body {{ margin: 0; padding: 0; background: var(--bg); color: var(--text); font-family: Inter, system-ui, -apple-system, sans-serif; }}
    body {{ min-height: 100vh; }}
    .wrap {{ max-width: 1380px; margin: 0 auto; padding: 24px; }}
    .hero {{
      display: grid;
      gap: 18px;
      grid-template-columns: 1.4fr .8fr;
      margin-bottom: 22px;
    }}
    .card {{
      background: linear-gradient(180deg, var(--surface), var(--surface-2));
      border: 1px solid var(--border);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      padding: 22px;
    }}
    h1, h2, h3, p {{ margin: 0; }}
    h1 {{ font-size: clamp(2rem, 4vw, 3.25rem); line-height: 1.05; margin-bottom: 10px; }}
    .subtitle {{ color: var(--muted); max-width: 70ch; }}
    .meta-grid {{
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 12px;
      margin-top: 16px;
    }}
    .meta-item {{
      background: rgba(255,255,255,.02);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 12px 14px;
    }}
    .meta-label {{ color: var(--muted); font-size: .85rem; margin-bottom: 4px; }}
    .stats {{
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 14px;
      margin: 0 0 22px;
    }}
    .stat {{
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 18px;
    }}
    .stat .label {{ color: var(--muted); font-size: .88rem; }}
    .stat .value {{ font-size: 2rem; font-weight: 800; margin-top: 6px; }}
    .layout {{
      display: grid;
      grid-template-columns: 1.15fr .85fr;
      gap: 18px;
    }}
    .panel {{
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 18px;
      margin-bottom: 18px;
    }}
    .panel-top {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 14px;
    }}
    .counter {{
      color: var(--muted);
      font-size: .85rem;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      overflow: hidden;
      border-radius: 12px;
    }}
    th, td {{
      text-align: left;
      padding: 12px 10px;
      border-bottom: 1px solid var(--border);
      vertical-align: top;
      font-size: .94rem;
    }}
    th {{ color: var(--muted); font-weight: 600; }}
    tr:last-child td {{ border-bottom: none; }}
    code {{
      background: var(--code);
      border: 1px solid var(--border);
      padding: 2px 7px;
      border-radius: 8px;
      color: #d9f3f7;
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      font-size: .86rem;
    }}
    .pill {{
      display: inline-flex;
      align-items: center;
      gap: 6px;
      border-radius: 999px;
      padding: 5px 10px;
      font-size: .78rem;
      font-weight: 700;
      letter-spacing: .02em;
      border: 1px solid transparent;
      text-transform: uppercase;
    }}
    .pending {{ background: rgba(232,175,52,.14); color: #ffd36f; border-color: rgba(232,175,52,.28); }}
    .progress {{ background: rgba(85,145,199,.14); color: #8fc2ef; border-color: rgba(85,145,199,.28); }}
    .done {{ background: rgba(109,170,69,.14); color: #92d966; border-color: rgba(109,170,69,.28); }}
    .high {{ background: rgba(221,105,116,.14); color: #ff95a0; border-color: rgba(221,105,116,.28); }}
    .medium {{ background: rgba(253,171,67,.14); color: #ffc578; border-color: rgba(253,171,67,.28); }}
    .low {{ background: rgba(79,152,163,.14); color: #8fd0d8; border-color: rgba(79,152,163,.28); }}
    .latest {{
      background: rgba(255,255,255,.02);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 14px;
      margin-bottom: 14px;
    }}
    .latest-head {{
      display: flex;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 8px;
      flex-wrap: wrap;
    }}
    .meta {{ color: var(--muted); font-size: .84rem; margin-bottom: 8px; }}
    pre {{
      margin: 0;
      white-space: pre-wrap;
      word-break: break-word;
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      font-size: .84rem;
      line-height: 1.5;
      color: #d4dde5;
    }}
    .list {{
      display: grid;
      gap: 8px;
    }}
    .file-row {{
      display: flex;
      justify-content: space-between;
      gap: 12px;
      text-decoration: none;
      color: var(--text);
      background: rgba(255,255,255,.02);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 10px 12px;
    }}
    .file-row:hover {{
      border-color: var(--primary);
      background: rgba(79,152,163,.08);
    }}
    .file-name {{
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      font-size: .84rem;
    }}
    .file-time {{
      color: var(--muted);
      font-size: .8rem;
      white-space: nowrap;
    }}
    .empty {{
      color: var(--muted);
      padding: 12px 0;
    }}
    .footer {{
      color: var(--muted);
      font-size: .85rem;
      margin-top: 10px;
    }}
    @media (max-width: 980px) {{
      .hero, .layout {{ grid-template-columns: 1fr; }}
      .stats {{ grid-template-columns: repeat(2, minmax(0, 1fr)); }}
    }}
    @media (max-width: 640px) {{
      .wrap {{ padding: 14px; }}
      .stats {{ grid-template-columns: 1fr; }}
      .meta-grid {{ grid-template-columns: 1fr; }}
      th:nth-child(7), td:nth-child(7) {{ display: none; }}
      .file-row {{ flex-direction: column; }}
    }}
  </style>
</head>
<body>
  <main class="wrap">
    <section class="hero">
      <div class="card">
        <h1>HERMES Dashboard</h1>
        <p class="subtitle">{html.escape(state["descripcion"] or "Estado operativo del harness multiagente local.")}</p>
        <div class="meta-grid">
          <div class="meta-item">
            <div class="meta-label">Proyecto</div>
            <div>{html.escape(state["proyecto"])}</div>
          </div>
          <div class="meta-item">
            <div class="meta-label">Actualización del dashboard</div>
            <div>{html.escape(state["actualizado"])}</div>
          </div>
          <div class="meta-item">
            <div class="meta-label">Nexus</div>
            <div>v{html.escape(state["nexus_version"])} · actualizado {html.escape(state["nexus_actualizado"])}</div>
          </div>
          <div class="meta-item">
            <div class="meta-label">Fuente de verdad</div>
            <div><code>features.json</code> + <code>progress/</code></div>
          </div>
        </div>
      </div>
      <div class="card">
        <h2>Pipeline</h2>
        <p class="subtitle" style="margin-top:8px;">Explorer → Implementer → Reviewer</p>
        <div class="meta-grid" style="margin-top:18px;">
          <div class="meta-item">
            <div class="meta-label">Explorer</div>
            <div>{progreso["explorer"]["count"]} artefactos</div>
          </div>
          <div class="meta-item">
            <div class="meta-label">Implementer</div>
            <div>{progreso["implementer"]["count"]} artefactos</div>
          </div>
          <div class="meta-item">
            <div class="meta-label">Reviewer</div>
            <div>{progreso["reviewer"]["count"]} artefactos</div>
          </div>
          <div class="meta-item">
            <div class="meta-label">Auto-refresh</div>
            <div>cada 20 segundos</div>
          </div>
        </div>
      </div>
    </section>

    <section class="stats">
      <div class="stat">
        <div class="label">Tareas totales</div>
        <div class="value">{stats["total"]}</div>
      </div>
      <div class="stat">
        <div class="label">Pendientes</div>
        <div class="value">{stats["pendientes"]}</div>
      </div>
      <div class="stat">
        <div class="label">En progreso</div>
        <div class="value">{stats["en_progreso"]}</div>
      </div>
      <div class="stat">
        <div class="label">Completadas</div>
        <div class="value">{stats["completadas"]}</div>
      </div>
    </section>

    <section class="layout">
      <div>
        <section class="panel">
          <div class="panel-top">
            <h3>Tareas</h3>
            <span class="counter">{len(tareas)} registradas</span>
          </div>
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Título</th>
                <th>Estado</th>
                <th>Prioridad</th>
                <th>Agente</th>
                <th>Modelo</th>
                <th>Criterios</th>
              </tr>
            </thead>
            <tbody>
              {render_tabla_tareas(tareas)}
            </tbody>
          </table>
        </section>
      </div>

      <div>
        {render_archivos_agente("explorer", progreso["explorer"])}
        {render_archivos_agente("implementer", progreso["implementer"])}
        {render_archivos_agente("reviewer", progreso["reviewer"])}
      </div>
    </section>

    <div class="footer">
      Dashboard HERMES local · Python stdlib · lectura directa del repo
    </div>
  </main>
</body>
</html>
"""

# ── Servidor HTTP ──────────────────────────────────────────────────────────────
class HermesHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "HERMESDashboard/1.0"
    sys_version = ""

    def _send(self, body: bytes, content_type: str = "text/html; charset=utf-8", status: int = 200) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        if self.path == "/":
            state = construir_estado()
            body = render_html(state).encode("utf-8")
            self._send(body)
            return

        if self.path == "/api/state":
            body = json.dumps(construir_estado(), ensure_ascii=False, indent=2).encode("utf-8")
            self._send(body, "application/json; charset=utf-8")
            return

        if self.path.startswith("/raw/"):
            partes = self.path.split("/", 3)
            if len(partes) != 4:
                self._send(b"Ruta invalida", "text/plain; charset=utf-8", 400)
                return

            _, _, agente, nombre = partes
            agente = unquote(agente)
            nombre = unquote(nombre)

            if agente not in {"explorer", "implementer", "reviewer"}:
                self._send(b"Agente invalido", "text/plain; charset=utf-8", 400)
                return

            ruta = (PROGRESS_DIR / agente / nombre).resolve()
            base = (PROGRESS_DIR / agente).resolve()

            if not str(ruta).startswith(str(base)) or not ruta.exists() or not ruta.is_file():
                self._send(b"No encontrado", "text/plain; charset=utf-8", 404)
                return

            mime, _ = mimetypes.guess_type(str(ruta))
            contenido = ruta.read_bytes()
            self._send(contenido, mime or "text/plain; charset=utf-8")
            return

        self._send(b"No encontrado", "text/plain; charset=utf-8", 404)

    def log_message(self, fmt: str, *args) -> None:
        marca = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{marca}] dashboard :: {self.address_string()} :: {fmt % args}")

def main() -> None:
    servidor = ThreadingHTTPServer((HOST, PORT), HermesHandler)
    print(f"HERMES Dashboard escuchando en http://127.0.0.1:{PORT}")
    print(f"HERMES Dashboard red local en  http://0.0.0.0:{PORT}")
    try:
        servidor.serve_forever()
    except KeyboardInterrupt:
        print("\\nApagando dashboard...")
    finally:
        servidor.server_close()

if __name__ == "__main__":
    main()
