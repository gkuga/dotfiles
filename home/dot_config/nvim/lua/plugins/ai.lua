-- AI: Copilot for inline (ghost text) completion, Claude Code as the agent.
-- Replaces copilot.vim and copilot-chat.vim from the old ~/.vimrc.
return {
  -- Ghost-text suggestions while typing. Run :Copilot auth once per machine.
  -- <Tab> accepts (wired in plugins/completion.lua); the old <C-j>/<C-l> stay
  -- insert-mode <Down>/<Right> from config/keymaps.lua.
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      -- The default server type is the native copilot-language-server binary,
      -- so Node.js (mise has 20, the nodejs server wants 22+) is not needed.
      suggestion = {
        auto_trigger = true, -- like copilot.vim
        -- Otherwise <M-w> with no suggestion yet is swallowed to request one.
        trigger_on_accept = false,
        -- Hidden while the blink.cmp menu is open (hide_during_completion).
        keymap = {
          accept = false, -- <Tab>, see plugins/completion.lua
          accept_word = "<M-w>",
          accept_line = false,
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = { enabled = false },
    },
  },

  -- Claude Code in a side terminal, with access to the open buffers, the
  -- current selection and Neovim diffs for its edits. Needs the `claude` CLI
  -- (installed by scripts/mise.sh).
  {
    "coder/claudecode.nvim",
    -- Load (and start the IDE server) right after startup, so that `claude`
    -- in another tmux pane finds this Neovim with /ide before any key is used.
    event = "VeryLazy",
    -- Command stubs for the moment before VeryLazy (e.g. `nvim +ClaudeCode`).
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSelectModel",
      "ClaudeCodeAdd",
      "ClaudeCodeSend",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeStatus",
      "ClaudeCodeStart",
      "ClaudeCodeStop",
      "ClaudeCodeOpen",
      "ClaudeCodeClose",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeCloseAllDiffs",
    },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<CR>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<CR>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<CR>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<CR>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<CR>", desc = "Select Claude model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<CR>", desc = "Add current buffer" },
      -- Like the old `vmap <leader>a <Plug>CopilotChatAddSelection`.
      { "<leader>as", "<cmd>ClaudeCodeSend<CR>", mode = "v", desc = "Send selection to Claude" },
      { "<leader>as", "<cmd>ClaudeCodeTreeAdd<CR>", ft = "oil", desc = "Add file to Claude" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<CR>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<CR>", desc = "Deny diff" },
    },
    opts = {
      -- Neovim's own terminal; no snacks.nvim dependency.
      terminal = { provider = "native" },
    },
    init = function()
      -- Keys for the Claude terminal buffer only; other terminals keep the
      -- global <Esc><Esc> from config/keymaps.lua.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_claudecode_terminal", { clear = true }),
        pattern = "claudecode",
        callback = function(ev)
          local function tmap(lhs, rhs, desc)
            vim.keymap.set("t", lhs, rhs, { buffer = ev.buf, nowait = true, desc = desc })
          end
          -- Claude Code uses <Esc> (interrupt) and <Esc><Esc> (rewind) itself:
          -- send it at once instead of waiting for the global <Esc><Esc>.
          tmap("<Esc>", "<Esc>", "Send <Esc> to Claude")
          -- Leave terminal mode; then <C-w>h etc. move between windows. Other
          -- control keys (<C-j> newline, <C-k>, <C-l>, ...) stay with Claude Code.
          tmap("<C-q>", [[<C-\><C-n>]], "Leave terminal mode")
          -- Coming back from another window: type to Claude again right away.
          vim.api.nvim_create_autocmd("BufEnter", {
            buffer = ev.buf,
            callback = function() vim.cmd.startinsert() end,
          })
        end,
      })
    end,
  },
}
