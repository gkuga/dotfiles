-- Colorscheme, key hints and file explorer.
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function() vim.cmd.colorscheme("tokyonight") end,
  },

  -- Shows available keys after <leader>; handy while learning the mappings.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>a", group = "ai / claude" },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "lsp / diagnostics" },
        { "<leader>f", group = "find" },
        { "<leader>h", group = "git hunk" },
      },
    },
  },

  -- Edit directories like buffers. "-" opens the parent directory.
  {
    "stevearc/oil.nvim",
    lazy = false,
    keys = { { "-", "<cmd>Oil<CR>", desc = "Open parent directory" } },
    opts = { view_options = { show_hidden = true } },
  },
}
