-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.keymap.set

-- Delete single char but not copy to clipboard
keymap("n", "x", '"_x', opts)

-- Better split keybinds
keymap("n", "<leader>sv", ":vsplit<CR>", opts)
keymap("n", "<leader>sh", ":split<CR>", opts)
keymap("n", "<leader>se", "<C-w>=", opts)
keymap("n", "<leader>sx", ":close<CR>", opts)

-- Buffer
keymap("n", "<leader>bd", ":bp | bd #<CR>", opts)

-- no hl
keymap("n", "<leader>h", ":set hlsearch!<CR>", opts)

-- Resize with arrows
keymap("n", "<S-Up>", ":resize -2<CR>", opts)
keymap("n", "<S-Down>", ":resize +2<CR>", opts)
keymap("n", "<S-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<S-Right>", ":vertical resize +2<CR>", opts)

-- Code runner
keymap("n", "<leader>r", "", opts)

-- Source init
keymap("n", "<C-s>", ":luafile %<CR>", opts)
keymap("n", "<C-w>", ":w<CR>", opts)

-- Fixing defaults
keymap("n", "Y", "y$", opts)
keymap("n", "n", "nzzzv", opts)
keymap("n", "N", "Nzzzv", opts)
keymap("n", "J", "mzJ`z", opts)
keymap("n", "G", "Gzz", opts)
keymap("n", "j", "jzz", opts)
keymap("n", "k", "kzz", opts)
keymap("n", "<DOWN>", "jzz", opts)
keymap("n", "<UP>", "kzz", opts)
keymap("n", "#", "#zz", opts)
keymap("n", "*", "*zz", opts)
keymap("n", "<C-U>", "11kzz", opts)
keymap("n", "<C-D>", "11jzz", opts)
keymap("i", ",", ",<C-g>u", opts)
keymap("i", ".", ".<C-g>u", opts)
keymap("i", "!", "!<C-g>u", opts)
keymap("i", ":", ":<C-g>u", opts)
keymap("i", "?", "?<C-g>u", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- Navigate Splits
keymap("n", "<C-l>", "<C-W><C-L>", opts)
keymap("n", "<C-k>", "<C-W><C-K>", opts)
keymap("n", "<C-j>", "<C-W><C-J>", opts)
keymap("n", "<C-h>", "<C-W><C-H>", opts)

-- Manage Splits
keymap("n", "<C-q>", "<C-W><C-q>", opts)
--keymap("n", "<C-o>", "<C-W><C-o>", opts)

keymap("n", "<A-j>", "<Esc>:m .+1<CR>==g", opts)
-- Move text up and down
keymap("n", "<A-k>", "<Esc>:m .-2<CR>==g", opts)

-- Insert --
-- Press jk fast to enter
keymap("i", "jk", "<ESC>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<A-k>", ":m .-2<CR>==", opts)
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "p", '"_dP', opts)

-- Visual Block --
-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- ToggleTerm from normal and insert mode
keymap("n", "<C-t>", ":ToggleTerm<CR>", opts)
-- keymap("t", "<C-t>", "<ESC> :ToggleTerm<CR>", term_opts)
keymap("i", "<C-t>", "<ESC> :ToggleTerm<CR>", opts)
--
keymap("t", "<C-t>", "<C-\\><C-n>:ToggleTerm<CR>", term_opts)
keymap("t", "<ESC>", "<C-\\><C-n>", term_opts)
keymap("t", "jk", "<C-\\><C-n>:ToggleTerm<CR>", term_opts)
keymap("t", "<C-h>", [[<Cmd>wincmd h<CR>]], term_opts)
keymap("t", "<C-j>", [[<Cmd>wincmd j<CR>]], term_opts)
keymap("t", "<C-k>", [[<Cmd>wincmd k<CR>]], term_opts)
keymap("t", "<C-l>", [[<Cmd>wincmd l<CR>]], term_opts)
keymap("t", "<C-w>", [[<C-\><C-n><C-w>]], term_opts)

vim.keymap.set("n", "<leader>rp", ":!python %<CR>", { desc = "Run Python File" })
