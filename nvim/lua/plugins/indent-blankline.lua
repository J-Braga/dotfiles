return {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPre", "BufNewFile" },
    main = "ibl",
    config = function()
        local highlight = {
            "Whitespace",
        }
        require("ibl").setup({
            indent = {
                highlight = highlight,
                char = "┊",
            },
            whitespace = {
                remove_blankline_trail = false,
            },
            scope = { enabled = false },
            exclude = {
                filetypes = { "help", "terminal", "dashboard" },
                buftypes = { "nofile", "prompt" },
            },
        })
    end,
}
