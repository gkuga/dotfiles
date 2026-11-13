-- Fuzzy finder for files, grep, buffers, LSP symbols and ghq repositories.
return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-telescope/telescope-ghq.nvim",
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Grep" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
    { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
    { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Symbols" },
    -- Like Ctrl-G (ghql) in the shell
    { "<leader>fp", "<cmd>Telescope ghq list<CR>", desc = "ghq repositories" },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({})
    pcall(telescope.load_extension, "fzf")
    pcall(telescope.load_extension, "ghq")
  end,
}
