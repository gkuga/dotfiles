-- Completion (replaces asyncomplete). LSP capabilities are registered by
-- blink.cmp itself on Neovim 0.11+.
return {
  "saghen/blink.cmp",
  version = "1.*",
  event = "InsertEnter",
  opts = {
    keymap = {
      preset = "default", -- <C-space> open, <C-y> accept, <C-n>/<C-p> select, <C-e> close
      -- Keep insert-mode <C-k> = <Up> from keymaps.lua.
      ["<C-k>"] = { "fallback" },
    },
    completion = {
      documentation = { auto_show = true },
    },
    signature = { enabled = true },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
  },
}
