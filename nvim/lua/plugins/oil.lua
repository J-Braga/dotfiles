return {
    {
        "stevearc/oil.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            CustomOilBar = function()
                local path = vim.fn.expand("%")
                path = path:gsub("oil://", "")
                return "  " .. vim.fn.fnamemodify(path, ":.")
            end
            local function yank_names(first, last)
                local oil = require("oil")
                local bufnr = vim.api.nvim_get_current_buf()
                local names = {}
                for lnum = first, last do
                    local entry = oil.get_entry_on_line(bufnr, lnum)
                    if entry and entry.name ~= ".." then
                        table.insert(names, entry.name)
                    end
                end
                vim.fn.setreg("+", table.concat(names, "\n"))
            end

            local function yank_line_names()
                local first = vim.fn.line(".")
                yank_names(first, math.min(first + vim.v.count1 - 1, vim.fn.line("$")))
            end

            local function yank_selected_names()
                local first, last = vim.fn.line("v"), vim.fn.line(".")
                if first > last then
                    first, last = last, first
                end
                yank_names(first, last)
                vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
            end

            require("oil").setup({
                columns = { "icon" },
                keymaps = {
                    ["<C-h>"] = false,
                    ["<C-l>"] = false,
                    ["<C-k>"] = false,
                    ["<C-j>"] = false,
                    ["<M-h>"] = "actions.select_split",
                    ["<ESCAPE>"] = "actions.close",
                    -- Yanks copy clean names instead of raw lines with the hidden "/001" entry id
                    -- (gives up oil's yank/paste-to-copy-files, which is unused).
                    ["yy"] = { callback = yank_line_names, desc = "Yank entry names", mode = "n" },
                    ["Y"] = { callback = yank_line_names, desc = "Yank entry names", mode = "n" },
                    ["gY"] = { "actions.yank_entry", desc = "Yank entry full path" },
                    ["y"] = { callback = yank_selected_names, desc = "Yank selected names", mode = "x" },
                    ["Y"] = { callback = yank_selected_names, desc = "Yank selected names", mode = "x" },
                },
                win_options = {
                    winbar = "%{v:lua.CustomOilBar()}",
                },
                view_options = {
                    show_hidden = true,
                    is_always_hidden = function(name, _)
                        local folder_skip = { "dev-tools.locks", "dune.lock", "_build" }
                        return vim.tbl_contains(folder_skip, name)
                    end,
                },
            })
            vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
            vim.keymap.set("n", "<space>-", require("oil").toggle_float)
        end,
    },
}
