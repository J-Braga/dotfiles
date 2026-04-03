return {
    "dmtrKovalenko/fff.nvim",
    build = function()
        require("fff.download").download_or_build_binary()
    end,
    opts = {},
    lazy = false,
    keys = {
        {
            "<leader>ff",
            function()
                require("fff").find_files()
            end,
            desc = "Find files in cwd",
        },
        {
            "<leader>fs",
            function()
                require("fff").live_grep()
            end,
            desc = "Live grep in cwd",
        },
        {
            "<leader>fc",
            function()
                require("fff").live_grep({ query = vim.fn.expand("<cword>") })
            end,
            desc = "Grep word under cursor",
        },
    },
}
