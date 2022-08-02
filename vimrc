set paste
set number
set hidden
set title
set ruler
set backspace=indent,eol,start
set autoindent
set smartindent
set expandtab
retab 2
set tabstop=2
set shiftwidth=2
set shiftround
set matchpairs+=<:>
set fileencoding=utf-8

inoremap <silent> ,, <ESC>

inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-h> <Left>
inoremap <C-l> <Right>
inoremap <silent> <C-h> <C-g>u<C-h>
inoremap <silent> <C-d> <Del>

call plug#begin()
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'mattn/vim-sonictemplate'
call plug#end()

let g:lsp_diagnostics_echo_cursor = 1
autocmd BufWritePre <buffer> LspDocumentFormatSync
autocmd BufWritePre *.py call execute('LspDocumentFormatSync --server=python-lsp-server')

source $VIMRUNTIME/macros/matchit.vim
