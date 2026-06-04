return {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
        "windwp/nvim-ts-autotag",
    },
    config = function()
        -- import nvim-treesitter plugin
        local treesitter = require("nvim-treesitter.configs")
        local parser_install_dir = vim.fn.stdpath("data") .. "/treesitter"

        vim.opt.runtimepath:prepend(parser_install_dir)

        -- configure treesitter
        treesitter.setup({ -- enable syntax highlighting
            parser_install_dir = parser_install_dir,
            highlight = {
                enable = true,
                --disable = {},
                --additional_vim_regex_highlighting = false,
            },
            -- enable indentation
            indent = { enable = true },
            --
            -- enable autotagging (w/ nvim-ts-autotag plugin)
            autotag = {
                enable = true,
            },
            -- ensure these language parsers are installed
            ensure_installed = {
                "json",
                "jinja",
                "javascript",
                "typescript",
                "tsx",
                "yaml",
                "html",
                "css",
                "markdown",
                "markdown_inline",
                "graphql",
                "bash",
                "lua",
                "vim",
                "dockerfile",
                "gitignore",
                "query",
                "vimdoc",
                "c",
                "c_sharp",
                "odin",
                "python",
                "terraform",
                "go",
                "zig",
            },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<C-space>",
                    node_incremental = "<C-space>",
                    scope_incremental = false,
                    node_decremental = "<bs>",
                },
            },
        })
    end,
}
