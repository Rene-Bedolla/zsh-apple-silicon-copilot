<div align="center">
  <h1>🚀 Zsh Apple Silicon Copilot</h1>
  <p><b>Un entorno Zsh modular de cero fricción, potenciado con IA Local Offline para Mac.</b></p>
  <a href="README.md">🇺🇸 Read in English</a>
  <br><br>
</div>

![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Zsh](https://img.shields.io/badge/Zsh-111?style=for-the-badge&logo=gnubash&logoColor=white)
![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M1%2FM2%2FM3%2FM4-blue?style=for-the-badge)

A diferencia de los dotfiles tradicionales, este repositorio está diseñado exclusivamente para **Macs con Apple Silicon**. Utiliza el entorno [MLX de Apple](https://github.com/ml-explore/mlx) para ejecutar un Copiloto de Desarrollo de IA Local directamente en tu máquina: sin llaves de API, sin suscripciones, 100% offline y rápido.

## 📦 Instalación de 1-Clic

Abre tu terminal en Mac y pega este comando:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Rene-Bedolla/zsh-apple-silicon-copilot/main/install.sh)"
```

*Este script es seguro. Instalará Homebrew (si no lo tienes), las herramientas modernas (`eza`, `bat`, `zoxide`), y respaldará tu `.zshrc` actual antes de aplicar la nueva configuración.*

---

## 🛠️ Referencia Completa de Comandos

Este entorno está diseñado para maximizar la productividad y minimizar la fricción cognitiva, con comandos intuitivos en español.

### 🧠 1. Copiloto de IA para Desarrolladores (MLX)
Utiliza modelos locales (como Qwen3) para asistirte en tu flujo de trabajo sin necesidad de internet.

| Comando | Descripción |
| :--- | :--- |
| `explicar "<comando>"` | Desglosa comandos complejos de shell o errores en español. Ej: `explicar "tar -xzvf archivo.tar.gz"` |
| `git-ia` | Lee tus cambios (`git diff`) y genera 3 opciones profesionales de mensajes de commit (Conventional Commits). |
| `procesar-minuta` | Analiza transcripciones largas y extrae: 1) Resumen, 2) Tareas asignadas, 3) Puntos críticos. |

### 📝 2. Captura Rápida Universal (Notas Markdown)
Un sistema de fricción cero para guardar ideas desde la terminal a una bandeja de entrada diaria (`~/.notas_inbox`).

| Comando | Descripción |
| :--- | :--- |
| `nota "<texto>"` | Guarda un punto con la hora exacta en tu bandeja de hoy. Ej: `nota "Revisar el bug de CSS"` |
| `leer-notas` | Muestra en pantalla las notas que has capturado el día de hoy con formato enriquecido. |

### 🍏 3. Optimización y Mantenimiento del Sistema
Comandos para acelerar macOS y mantener el entorno limpio.

| Comando | Descripción |
| :--- | :--- |
| `macos-tweaks` | Menú interactivo para aplicar "Hacker Defaults" (teclado ultra rápido, Dock sin retraso, ver archivos ocultos). Incluye opción para revertir todo. |
| `actualizar` | Ejecuta `brew update && brew upgrade` en un solo paso. |
| `limpiar` | Limpia la caché de Homebrew y elimina paquetes huérfanos. |
| `refresco` | Recarga la configuración del `.zshrc` instantáneamente sin cerrar la terminal. |
| `respaldo-cold`| Genera un `.zip` portable con toda tu configuración personal y scripts en el Escritorio. |

### 🎙️ 4. Multimedia y Transcripción (MLX-Whisper)
Aprovecha la memoria unificada de Apple Silicon para procesar audio y video.

| Comando | Descripción |
| :--- | :--- |
| `transcribir-video <archivo>` | Extrae el audio de un video y genera un archivo de subtítulos `.srt` de alta precisión. |
| `transcribir-rápido <archivo>`| Igual que el anterior, pero usa el modelo `tiny` para velocidad extrema. |
| `traducir-srt` | Traduce archivos `.srt` localmente manteniendo las marcas de tiempo exactas. |

### 🚀 5. Herramientas CLI de Nueva Generación
El entorno reemplaza comandos clásicos de Unix por alternativas modernas escritas en Rust:
- `ls` / `ll` / `la` → Utilizan **`eza`** (Muestra íconos, estado de git y colores).
- `cat` → Utiliza **`bat`** (Resaltado de sintaxis y números de línea).
- `cd` → Potenciado por **`zoxide`** (Escribe `z nombre_carpeta` para saltar instantáneamente a carpetas frecuentes).

---

## 🏗️ Arquitectura Modular (Zero-Friction)
Este sistema usa una arquitectura dinámica. Solo necesitas arrastrar cualquier script `.zsh` dentro de la carpeta `~/.zsh/funciones/`, y se cargará automáticamente al abrir la terminal. 

*Nota de Privacidad:* Si creas una carpeta llamada `~/Documents/dotfiles/privado/`, el sistema la leerá, pero Git la ignorará para proteger tus contraseñas y alias de trabajo.

*Desarrollado con ❤️ por [René Bedolla](https://github.com/Rene-Bedolla).*
