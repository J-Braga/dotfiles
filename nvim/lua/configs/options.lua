vim.cmd("let g:netrw_liststyle = 3")

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 4 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one
opt.list = true
opt.listchars = {
    lead = "·", -- Middle dot for every space (including leading whitespace)
    trail = "·", -- Same dot for trailing spaces
    tab = "▸ ", -- Optional: Arrow + space for tabs
    eol = "¬", -- Optional: Symbol for end-of-line
}
opt.wrap = false

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

opt.cursorline = true

-- turn on termguicolors for tokyonight colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
--opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift
--opt.signcolumn = "auto:3"

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

vim.opt.autowrite = true -- Enable auto write
-- clipboard

opt.completeopt = "menu,menuone,noselect"
opt.clipboard = "unnamedplus" -- Sync with system clipboard

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
opt.swapfile = false

vim.filetype.add({
    extension = {
        j2 = "jinaj",
    },
})
