-- Editor options. The first block is carried over from the old ~/.vimrc.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- from ~/.vimrc
opt.number = true
opt.title = true
opt.smartindent = true
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.shiftround = true
opt.matchpairs:append("<:>")
opt.fileencoding = "utf-8"

-- additions
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 5
opt.ignorecase = true
opt.smartcase = true
opt.splitright = true
opt.splitbelow = true
opt.undofile = true
opt.updatetime = 250
opt.mouse = "a"
opt.clipboard = "unnamedplus" -- system clipboard (pbcopy / OSC 52 / clip.exe)
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Diagnostics: show the message for the current line inline
-- (replaces vim-lsp's g:lsp_diagnostics_echo_cursor).
vim.diagnostic.config({
  virtual_text = { current_line = true },
  severity_sort = true,
  float = { border = "rounded" },
})
