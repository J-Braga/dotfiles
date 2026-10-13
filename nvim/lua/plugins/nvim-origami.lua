return {
    "chrisgrieser/nvim-origami",
    event = "VeryLazy",
    opts = {
        foldtext = {
            lineCount = {
                template = "%d lines",
            },
        },
        foldKeymaps = {
            setup = false,
        },
        autoFold = {
            enabled = true,
            kinds = { "comment", "imports" }, ---@type lsp.FoldingRangeKind[]
        },
    },

    init = function()
        vim.opt.foldlevel = 99
        vim.opt.foldlevelstart = 99
        local fold_util = require("utils.code_folds")

        vim.keymap.set("n", "<CR>", "za", { noremap = true, silent = true })
        vim.keymap.set("n", "[[", fold_util.goto_previous_fold, { noremap = true, silent = true })
        vim.keymap.set("n", "]]", "zj", { noremap = true, silent = true })

        local group = vim.api.nvim_create_augroup("UserCodeFolds", { clear = true })
        vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "LspAttach" }, {
            group = group,
            callback = function(opts)
                fold_util.update_ranges(opts.buf)
            end,
        })

        vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
            group = group,
            callback = function(opts)
                fold_util.clear(opts.buf)
            end,
        })
    end,
}
