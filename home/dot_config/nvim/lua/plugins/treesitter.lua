-- Syntax highlighting and indentation with treesitter (main branch API).
-- Parsers are compiled with the tree-sitter CLI from mise and a C compiler.
local parsers = {
  "bash",
  "diff",
  "dockerfile",
  "gitcommit",
  "go",
  "hcl",
  "javascript",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "ruby",
  "rust",
  "terraform",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install(parsers)

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
      callback = function(ev)
        -- Silently skip filetypes without a parser.
        if pcall(vim.treesitter.start, ev.buf) then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
