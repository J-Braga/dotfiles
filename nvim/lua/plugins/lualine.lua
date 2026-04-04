return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local lualine = require("lualine")
        local lazy_status = require("lazy.status") -- to configure lazy pending updates count

        local palette_module = "custom." .. (vim.g.colors_name or "personal")
        local ok, theme = pcall(require, palette_module)
        local colors = (ok and theme.palette) or require("custom.personal").palette

        local my_lualine_theme = {
            normal = {
                a = { bg = colors.fg, fg = colors.bg, gui = "bold" },
                b = { bg = colors.bg_highlight, fg = colors.fg },
                c = { bg = colors.bg, fg = colors.fg },
            },
            insert = {
                a = { bg = colors.string, fg = colors.bg, gui = "bold" },
                b = { bg = colors.bg_highlight, fg = colors.fg },
                c = { bg = colors.bg, fg = colors.fg },
            },
            visual = {
                a = { bg = colors.variables, fg = colors.bg, gui = "bold" },
                b = { bg = colors.bg_highlight, fg = colors.fg },
                c = { bg = colors.bg, fg = colors.fg },
            },
            command = {
                a = { bg = colors.accent, fg = colors.bg, gui = "bold" },
                b = { bg = colors.bg_highlight, fg = colors.fg },
                c = { bg = colors.bg, fg = colors.fg },
            },
            replace = {
                a = { bg = colors.error, fg = colors.bg, gui = "bold" },
                b = { bg = colors.bg_highlight, fg = colors.fg },
                c = { bg = colors.bg, fg = colors.fg },
            },
            inactive = {
                a = { bg = colors.bg, fg = colors.line_nr, gui = "bold" },
                b = { bg = colors.bg, fg = colors.line_nr },
                c = { bg = colors.bg, fg = colors.line_nr },
            },
        }

        -- configure lualine with modified theme
        lualine.setup({
            options = {
                theme = my_lualine_theme,
            },
            sections = {
                lualine_x = {
                    {
                        lazy_status.updates,
                        cond = lazy_status.has_updates,
                        color = { fg = colors.warning },
                    },
                    { "encoding" },
                    { "fileformat" },
                    { "filetype" },
                },
            },
        })
    end,
}
