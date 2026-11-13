-- Global keymaps. LSP keymaps are set per buffer in plugins/lsp.lua.
local map = vim.keymap.set

-- Insert-mode cursor movement, from ~/.vimrc.
-- (<C-h> was mapped twice there; the effective one was "backspace with undo break".)
map("i", "<C-j>", "<Down>")
map("i", "<C-k>", "<Up>")
map("i", "<C-l>", "<Right>")
map("i", "<C-h>", "<C-g>u<C-h>", { silent = true })
map("i", "<C-d>", "<Del>", { silent = true })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Leave terminal mode (useful for AI agents running in :terminal)
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write buffer" })
