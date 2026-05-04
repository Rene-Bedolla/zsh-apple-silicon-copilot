" ══════════════════════════════════════════════════════════════
" ARCHIVO: init.vim
" PROPÓSITO: Configuración principal de Neovim — René Bedolla
" COMPATIBLE: Neovim 0.9+ (Apple Silicon M4 / MacBook Air M1)
" GESTOR DE PLUGINS: vim-plug
" ÚLTIMA REVISIÓN: 2026-05-04
" ══════════════════════════════════════════════════════════════

" ── Apariencia y comportamiento base ──────────────────────────
syntax enable                   " Resaltado de sintaxis
filetype indent plugin on       " Detección de tipo de archivo

set number                      " Números de línea absolutos
set relativenumber              " Números relativos al cursor
set numberwidth=1               " Ancho mínimo de columna de números
set cursorline                  " Resalta línea actual
set scrolloff=999               " Modo máquina de escribir: cursor centrado
set sidescrolloff=5             " Margen lateral

" ── Codificación y visualización ──────────────────────────────
set encoding=utf-8              " Soporte para ñ y caracteres especiales
set showcmd                     " Muestra comandos en curso
set ruler                       " Muestra posición del cursor
set showmatch                   " Resalta paréntesis/llave coincidente
set showmode                    " Muestra modo actual (INSERT, VISUAL, etc.)
set wrap                        " Corta líneas largas visualmente

" ── Búsqueda ──────────────────────────────────────────────────
set incsearch                   " Búsqueda incremental mientras escribes
set hlsearch                    " Resalta coincidencias
set ignorecase                  " Ignora mayúsculas/minúsculas
set smartcase                   " Respeta mayúsculas si las escribes explícitamente

" ── Indentación ───────────────────────────────────────────────
set sw=2                        " Ancho de sangría: 2 espacios
set smartindent                 " Sangría inteligente por contexto

" ── Archivos e historial ──────────────────────────────────────
set noswapfile                  " Sin archivos .swp
set nobackup                    " Sin copias de seguridad automáticas
set undofile                    " Historial de deshacer persistente entre sesiones
set undodir=~/.config/nvim/undodir  " Ruta local, no se sube al repo

" ── Portapapeles e integración macOS ──────────────────────────
set clipboard=unnamed           " Integración con portapapeles del sistema
set mouse=a                     " Soporte completo de ratón
set bs=indent,eol,start         " Backspace sobre todo en modo inserción

" ── Compatibilidad ────────────────────────────────────────────
set nocompatible                " Sin compatibilidad con vi clásico
set laststatus=2                " Barra de estado siempre visible

" ── Colores y terminal ────────────────────────────────────────
set termguicolors               " Colores true color
if $TERM_PROGRAM =~ "iTerm"
  set termguicolors
endif
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

" ── FZF (Homebrew Apple Silicon — /opt/homebrew) ──────────────
if isdirectory('/opt/homebrew/opt/fzf')
  set rtp+=/opt/homebrew/opt/fzf
endif

" ══════════════════════════════════════════════════════════════
" PLUGINS — vim-plug
" ══════════════════════════════════════════════════════════════
call plug#begin('~/.local/share/nvim/plugged')

" Tema visual
Plug 'morhetz/gruvbox'

" Navegación y movimiento
Plug 'easymotion/vim-easymotion'
Plug 'christoomey/vim-tmux-navigator'

" Árbol de archivos
Plug 'scrooloose/nerdtree'

" Autocompletado inteligente (usa Node.js, no Python)
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Barra de estado
Plug 'vim-airline/vim-airline'

" Soporte JavaScript y TypeScript
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'

" Autocompletado de paréntesis y llaves
Plug 'tmsvg/pear-tree'

call plug#end()

" ══════════════════════════════════════════════════════════════
" CONFIGURACIÓN DE PLUGINS
" ══════════════════════════════════════════════════════════════

" ── Tema gruvbox ──────────────────────────────────────────────
colorscheme gruvbox
let g:gruvbox_contrast_dark = "hard"

" ── NERDTree ──────────────────────────────────────────────────
let NERDTreeQuitOnOpen = 1      " Cierra NERDTree al abrir un archivo

" ── vim-airline ───────────────────────────────────────────────
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'default'
let g:airline_section_c = '%f'                    " nombre de archivo
let g:airline_section_z = '%L líneas  %{airline#util#wrap(airline#parts#ffenc(),0)}'
" ══════════════════════════════════════════════════════════════
" ATAJOS DE TECLADO (Leader = Espacio)
" ══════════════════════════════════════════════════════════════
let mapleader = " "

" ── Navegación rápida ─────────────────────────────────────────
nmap <Leader>s  <Plug>(easymotion-s2)
nmap <Leader>nt :NERDTreeFind<CR>
nmap <Leader>fs :FZF<CR>

" ── Guardar y salir ───────────────────────────────────────────
nmap <Leader>w  :w<CR>
nmap <Leader>q  :q<CR>
nmap <Leader>q! :q!<CR>
nmap <Leader>wq :wq<CR>

" ── Corrector ortográfico en español ──────────────────────────
nmap <Leader>orto :setlocal spell! spelllang=es<CR>

" ── COC (autocompletado y navegación de código) ───────────────
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <Leader>gs :CocSearch
nmap <Leader>fs :FZF<CR>

" ── Utilidades ────────────────────────────────────────────────
nnoremap <F5>  :!python %:p<CR>  " Ejecutar archivo Python activo con F5
imap ii <ESC>                    " Salir de modo inserción escribiendo 'ii'
