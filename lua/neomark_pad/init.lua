local M = {}

-- ===== Defaults =====
local defaults = {
	width = 0.7,
	height = 0.85,
	border = "rounded",
	title = " NeoMark Pad ",
	title_pos = "center",

	preview_mode = "html", -- "html" or "raw"
	browser_cmd = nil, -- nil = auto: xdg-open/open/start
	use_pandoc = true, -- used in html mode only
	keymaps = true,

	css = [[
html { scroll-behavior: smooth; }
body {
  margin: 2rem auto;
  max-width: 860px;
  padding: 0 1rem;
  line-height: 1.6;
  font-size: 18px;
  font-family: ui-serif, Georgia, Cambria, "Times New Roman", Times, serif;
}
@media (prefers-color-scheme: dark) {
  body { background: #0b0e14; color: #e6e6e6; }
  a { color: #7aa2f7; }
  code, pre { background: #10151f; }
  blockquote { color: #c2c2c2; border-left-color: #3a3f4b; }
}
h1,h2,h3 { line-height: 1.25; }
h1 { font-size: 2.0rem; margin-top: 1.5rem; }
h2 { font-size: 1.6rem; margin-top: 1.25rem; }
h3 { font-size: 1.25rem; margin-top: 1.0rem; }
img, video { max-width: 100%; height: auto; }
pre, code {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
  font-size: 0.95em;
}
pre {
  overflow: auto; padding: 0.8rem 1rem; border-radius: 8px;
}
code { padding: 0.1rem 0.3rem; border-radius: 6px; }
blockquote {
  margin: 1rem 0; padding: 0.5rem 1rem; border-left: 4px solid #d0d0d0;
}
table { border-collapse: collapse; }
th, td { border: 1px solid #ccc; padding: 0.4rem 0.6rem; }
  ]],
}

local cfg = vim.deepcopy(defaults)

-- ===== Helpers =====

local function has_cmd(cmd)
	return vim.fn.executable(cmd) == 1
end

local function detect_browser_cmd()
	if cfg.browser_cmd and #cfg.browser_cmd > 0 then
		return cfg.browser_cmd
	end
	local sys = vim.loop.os_uname().sysname
	if sys == "Darwin" then
		return "open"
	end
	if sys:match("Windows") then
		return "start"
	end
	return "xdg-open"
end

local function write_tmp(content, ext)
	local name = (vim.fn.tempname() .. (ext or ""))
	local f = assert(io.open(name, "w"))
	f:write(content)
	f:close()
	return name
end

local function open_in_browser(path)
	local opener = detect_browser_cmd()
	if opener == "start" then
		vim.fn.jobstart({ "cmd.exe", "/c", "start", "", path }, { detach = true })
	else
		vim.fn.jobstart({ opener, path }, { detach = true })
	end
end

-- Markdown -> HTML (prefer pandoc; fallback safe wrapper)
local function md_to_html(markdown)
	local css_text = cfg.css or defaults.css
	local css_path = write_tmp(css_text, ".css")

	if cfg.use_pandoc and has_cmd("pandoc") then
		local md_path = write_tmp(markdown, ".md")
		local html_path = md_path:gsub("%.md$", ".html")
		local cmd = {
			"pandoc",
			md_path,
			"-f",
			"markdown",
			"-t",
			"html5",
			"-s",
			"-c",
			css_path,
			"-o",
			html_path,
		}
		vim.fn.system(cmd)
		if vim.v.shell_error == 0 then
			return html_path
		else
			vim.notify("[neomark_pad] pandoc failed; using fallback HTML.", vim.log.levels.WARN)
		end
	end

	local safe = markdown:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")

	local html = string.format(
		[[
<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Preview</title>
<link rel="stylesheet" href="%s">
<body>
<pre>%s</pre>
</body>
</html>
]],
		css_path,
		safe
	)

	return write_tmp(html, ".html")
end

-- ===== UI: centered floating window =====
local function open_centered_win()
	local ui = vim.api.nvim_list_uis()[1]
	local total_w = ui.width
	local total_h = ui.height

	local w = math.floor(total_w * cfg.width)
	local h = math.floor(total_h * cfg.height)
	local row = math.floor((total_h - h) / 2)
	local col = math.floor((total_w - w) / 2)

	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = w,
		height = h,
		row = row,
		col = col,
		border = cfg.border,
		title = cfg.title,
		title_pos = cfg.title_pos,
		style = "minimal",
		noautocmd = false,
	})

	-- Minimal writing vibe
	local wo = vim.wo[win]
	wo.number = false
	wo.relativenumber = false
	wo.signcolumn = "no"
	wo.cursorline = false
	wo.wrap = true
	wo.linebreak = true
	wo.conceallevel = 2
	wo.foldcolumn = "0"
	wo.list = false
	wo.colorcolumn = ""

	local bo = vim.bo[buf]
	bo.swapfile = false
	bo.bufhidden = "hide"
	bo.modifiable = true

	vim.cmd("setlocal spell spelllang=en_us")
	vim.cmd("setlocal formatoptions+=t")
	vim.cmd("setlocal textwidth=0")

	if cfg.keymaps then
		local opts = { noremap = true, silent = true, nowait = true, buffer = buf }
		vim.keymap.set("n", "<leader>mp", function()
			M.preview(buf)
		end, opts)
		vim.keymap.set("v", "<leader>mi", 'c*<C-r>"*<Esc>', opts)
		vim.keymap.set("v", "<leader>mb", 'c**<C-r>"**<Esc>', opts)
		vim.keymap.set("n", "<Esc>", function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end, opts)
	end

	return buf, win
end

-- ===== Public API =====

function M.open()
	return open_centered_win()
end

function M.preview(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		vim.notify("[neomark_pad] Invalid buffer", vim.log.levels.ERROR)
		return
	end
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local text = table.concat(lines, "\n")

	if cfg.preview_mode == "raw" then
		-- Write to a temp .md and open directly
		local md_path = write_tmp(text, ".md")
		open_in_browser(md_path)
	else
		-- HTML mode
		local html = md_to_html(text)
		open_in_browser(html)
	end
end

function M.setup(opts)
	cfg = vim.tbl_deep_extend("force", defaults, opts or {})
end

-- Internal preset hook used by plugin/ loader if user sets setup before load.
M._preset = nil

return M
