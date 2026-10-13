return {
    {
        -- Active colorscheme. Applied here (priority 1000 = loaded first) so plugins
        -- like lualine see vim.g.colors_name when they configure themselves.
        "AlexvZyl/nordic.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd.colorscheme("nordic")
        end,
    },
}
