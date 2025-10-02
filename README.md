# neomark-pad
---
This is a neovim plugin designed for the part of your brain that requres silence..., nothing but the void.

A dead-simple Neovim plugin that opens a **centered floating Markdown pad** for distraction-free writing and lets you **preview** your Markdown in your default browser.

* Clean centered floating window, tuned for reading & writing
* Preview in browser:

  * **HTML mode** (via `pandoc` if available, with CSS and dark-mode)
  * **RAW mode** (open `.md` directly; use a browser markdown extension if you want rendering)
* Zero dependencies required (pandoc optional)

## Install

### lazy.nvim

```lua
return {
  "JonahRoleson/neomark-pad",
  config = function()
    require("neomark_pad").setup({
      -- preview_mode = "html", -- "html" (via pandoc) or "raw" (open .md directly)
    })
  end,
}
```

### packer.nvim

```lua
use({
  "JonahRoleson/neomark-pad",
  config = function()
    require("neomark_pad").setup({})
  end,
})
```

## Usage

* `:NeoMarkPadOpen` (alias `:NeoMarkPad`) — open a centered floating Markdown pad
* `:NeoMarkPadPreview` — preview current buffer in default browser

Keymaps inside the pad:

* `<leader>mp` — preview in browser
* `<leader>mi` (visual) — italic wrap
* `<leader>mb` (visual) — bold wrap
* `<Esc>` — close window

---

## LICENSE

Apache 2.0 License
