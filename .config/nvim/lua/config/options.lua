-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Filter known upstream Roslyn LSP noise on .slnx solutions
-- See: https://github.com/dotnet/roslyn/issues/81410
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
  if type(msg) == "string" and msg:match("Failed to get language for textDocument/diagnostic") then
    return
  end
  return orig_notify(msg, level, opts)
end
