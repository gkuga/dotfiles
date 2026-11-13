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
      -- <Tab> accepts a visible Copilot suggestion (plugins/ai.lua); otherwise
      -- it jumps in a snippet or inserts a tab, as in the default preset.
      ["<Tab>"] = {
        function()
          local suggestion = package.loaded["copilot.suggestion"]
          if suggestion and suggestion.is_visible() then
            suggestion.accept()
            return true
          end
        end,
        "snippet_forward",
        "fallback",
      },
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
