return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        current_line_blame = true, -- Enable inline blame messages by default
        current_line_blame_opts = {
            virt_text = true, -- Show as virtual text (default)
            virt_text_pos = "right_align", -- Position: 'eol' (end of line), 'overlay', or 'right_align'
            delay = 50, -- Delay in ms before showing (adjust if too slow/fast)
            ignore_whitespace = false, -- Ignore whitespace changes in blame
            virt_text_priority = 100, -- Rendering priority
        },
        current_line_blame_formatter = "<author>, <author_time:%R> - <summary>", -- Customize the format (default is similar)
    },
}
