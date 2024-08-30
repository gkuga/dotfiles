let mapleader = "\<space>"

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

" lsp
let g:lsp_diagnostics_echo_cursor = 1
autocmd BufWritePre <buffer> LspDocumentFormatSync
autocmd BufWritePre *.py call execute('LspDocumentFormatSync --server=python-lsp-server')
nnoremap <leader>dd :LspDefinition<cr>
nnoremap <leader>dn :LspNextDiagnostic<cr>
nnoremap <leader>dp :LspPreviousDiagnostic<cr>
nnoremap <leader>df :LspReferences<cr>
nnoremap <leader>dr :LspRename<cr>
nnoremap <leader>ds :LspStopServer<cr>
nnoremap <leader>dp :LspPeekDefinition<cr>
nnoremap <leader>da :LspCodeAction<cr>
nnoremap <leader>dh :LspHover<cr>
nnoremap <leader>df :LspDocumentFormat<cr>
nnoremap <leader>dd :LspDefinition<cr>

let g:lsp_settings = {
\ 'pylsp-all': {
\   'workspace_config': {
\     'pylsp': {
\       'plugins': {
\         'pycodestyle': {
\           'ignore': ["E221", "E501"]
\         }
\       }
\     }
\   }
\ },
\}
