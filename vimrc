set nocompatible
set title
set ruler
set autoindent
set smartindent
set expandtab
set backspace=indent,eol,start

set tabstop=2
set shiftwidth=2
set shiftround
set matchpairs+=<:>
set fileencoding=utf-8

set expandtab
retab 2

set paste
set number
set hidden
set tags+=tags;

inoremap <silent> ,, <ESC>

inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-h> <Left>
inoremap <C-l> <Right>
inoremap <silent> <C-h> <C-g>u<C-h>
inoremap <silent> <C-d> <Del>

call plug#begin('~/.vim/plugged')
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'hashivim/vim-terraform'
Plug 'rust-lang/rust.vim'
call plug#end()

" Coloer
syntax on
colorscheme desert
set background=dark
hi Search cterm=bold ctermfg=2 ctermbg=0

" vim-terraform
let g:terraform_fmt_on_save=1
 
