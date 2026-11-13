-- LSP: servers are installed by mason and enabled through Neovim 0.11's
-- vim.lsp.config / vim.lsp.enable (configs come from nvim-lspconfig).
-- Replaces vim-lsp + vim-lsp-settings.

local servers = {
  "bashls",
  "gopls",
  "lua_ls",
  "pylsp",
  "rust_analyzer",
  "terraformls",
  "ts_ls",
}

return {
  { "mason-org/mason.nvim", cmd = "Mason", opts = {} },

  -- Type information for the Neovim API when editing this config.
  { "folke/lazydev.nvim", ft = "lua", opts = {} },

  {
    "mason-org/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      -- Server-specific settings (from the old g:lsp_settings).
      vim.lsp.config("pylsp", {
        settings = {
          pylsp = {
            plugins = {
              pycodestyle = { ignore = { "E221", "E501" } },
            },
          },
        },
      })

      -- Installs missing servers and calls vim.lsp.enable() for them.
      require("mason-lspconfig").setup({ ensure_installed = servers })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_keymaps", { clear = true }),
        callback = function(ev)
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          -- Same keys as the old vim-lsp mappings (duplicates resolved).
          map("<leader>dd", vim.lsp.buf.definition, "Definition")
          map("<leader>df", vim.lsp.buf.references, "References")
          map("<leader>dr", vim.lsp.buf.rename, "Rename")
          map("<leader>da", vim.lsp.buf.code_action, "Code action")
          map("<leader>dh", vim.lsp.buf.hover, "Hover")
          map("<leader>dn", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
          map("<leader>dpr", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
          map("<leader>ds", function()
            vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = ev.buf }))
          end, "Stop LSP clients")
        end,
      })
    end,
  },
}
