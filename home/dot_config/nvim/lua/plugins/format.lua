-- Format on save (replaces the BufWritePre LspDocumentFormatSync autocmds).
-- Uses the formatter listed below, otherwise the LSP server's formatter.
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>cf",
      function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" }, -- installed by mise
      sh = { "shfmt" },   -- installed by mise
      bash = { "shfmt" },
    },
    format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
  },
}
