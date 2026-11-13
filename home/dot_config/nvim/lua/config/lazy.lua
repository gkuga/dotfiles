-- Bootstrap lazy.nvim, then load every spec under lua/plugins/.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n" .. out, "ErrorMsg" } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  -- Plugin versions are pinned in ~/.config/nvim/lazy-lock.json, which is
  -- tracked by chezmoi. After :Lazy update, run `chezmoi re-add` to save it.
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
