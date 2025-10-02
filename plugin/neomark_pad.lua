-- Auto-loaded by Neovim when placed under plugin/
-- Registers user commands and sets up the plugin.

local ok, pad = pcall(require, "neomark_pad")
if not ok then
	return
end

-- Users can override via require("neomark_pad").setup({...}) earlier in their config.
pad.setup(pad._preset or {})

vim.api.nvim_create_user_command("NeoMarkPadOpen", function()
	pad.open()
end, {})

vim.api.nvim_create_user_command("NeoMarkPadPreview", function()
	pad.preview()
end, {})

-- Convenience alias
vim.api.nvim_create_user_command("NeoMarkPad", function()
	pad.open()
end, {})
