syntax enable 		" Activa los colores en la sintaxis
filetype indent plugin on

set number 		" Muestra los números
set mouse=a 		" Activa el mouse
set numberwidth=1
set clipboard=unnamed
set showcmd 		" Muestra la consola del sistema
set ruler 		" Muestra la regla
set encoding=utf-8 	" Para utilizar caracteres como ñ
set showmatch
set showmode
set sw=2
set relativenumber 	" Muestra la numeración relativa a la posición del cursor
set laststatus=2
set smartindent 	" Agrega tabulaciones inteligentes
set wrap 		" Corta las líneas para que se visualice en pantalla
set incsearch 		" Busca los términos en forma incremental
set hlsearch 		" Resalta los caracteres coincidentes con la búsqueda
set ignorecase 		" Ignora en las búsquedas mayúsculas y minúsculas
" set list 		" Agregar $ a cada salto de línea
set cursorline 		" Muestra la línea sobre la que está el cursor
set nocompatible 	" Ignora incompatibilidad con VI
" Guarda el historial de cambios aún cuando se ha cerrado el archivo
set undofile 
set undodir=~/.vim/undodir
set termguicolors
set laststatus=2
set rtp+=/usr/local/opt/fzf
set noswapfile		" No crea los swapfiles
set nobackup		" No crea copias de seguridad
set bs=indent,eol,start " backspace over everything in insert mode
set rtp+=/usr/local/opt/fzf

" ═══════════════════════════════════════════════════════════
" MODO MÁQUINA DE ESCRIBIR (Typewriter Mode)
" Cursor siempre centrado verticalmente al escribir
" ═══════════════════════════════════════════════════════════
set scrolloff=999          " Mantiene cursor centrado (valor alto = más centrado)
set sidescrolloff=5        " Centrado horizontal opcional (margen lateral)


call plug#begin('~/.vim/plugged')

" Tema
Plug 'morhetz/gruvbox'

" IDE
Plug 'easymotion/vim-easymotion'
Plug 'scrooloose/nerdtree'
Plug 'christoomey/vim-tmux-navigator'

" COC
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Vim Airline
Plug 'vim-airline/vim-airline'
" JavaScript and TypeScript support
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
" Autocompletado de paréntesis
Plug 'tmsvg/pear-tree'

call plug#end()

" Compatibilidad con tmux
if $TERM_PROGRAM =~ "iTerm"
  set termguicolors
endif

let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

colorscheme gruvbox
let g:gruvbox_contrast_dark = "hard"
let NERDTreeQuitOnOpen=1

let mapleader=" "

" Configuraciones de vim-airline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'default'

" Atajos de teclado
nmap <Leader>s <Plug>(easymotion-s2)
nmap <Leader>nt :NERDTreeFind <CR>

nmap <Leader>w :w<CR>
nmap <Leader>q :q<CR>
nmap <Leader>q! :q!<CR>
nmap <Leader>wq :wq<CR>

" Activa el corrector ortográfico en español
nmap <Leader>orto :setlocal spell! spelllang=es<CR>

" Atajos de COC
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Otros atajos de COC y FZF
nmap <Leader>gs :CocSearch 
nmap <Leader>fs :FZF<CR>
nnoremap <F5> :!python %:p<CR>
:imap ii <ESC>

