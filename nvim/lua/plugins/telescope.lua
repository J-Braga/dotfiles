local uv = vim.loop -- For filesystem operations

-- Function to check if Ruined.sln exists in the current directory
local function has_ruined_sln()
    local sln_path = vim.fn.getcwd() .. "Ruined.sln"
    return uv.fs_stat(sln_path) and true or false
end

return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        "nvim-tree/nvim-web-devicons",
        "folke/todo-comments.nvim",
    },
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")
        local transform_mod = require("telescope.actions.mt").transform_mod

        local trouble = require("trouble")
        local trouble_telescope = require("trouble.sources.telescope")

        -- or create your custom action
        local custom_actions = transform_mod({
            open_trouble_qflist = function(prompt_bufnr)
                trouble.toggle("quickfix")
            end,
        })

        telescope.setup({
            defaults = {
                file_ignore_patterns = {
                    "CachedNodeOutput",
                    "venv",
                    "Log",
                    "%.jpg$",
                    "%.png$",
                    "%.wav$",
                    "%.txt$",
                    "%.inputactions$",
                    "%.mask$",
                    "%.o$",
                    "%.pdf$",
                    "%.sln",
                    "%.meta",
                    "%.csproj",
                    "%.asset",
                    "%.FBX",
                    "%.fbx",
                    "%.prefab",
                    "%.unity",
                    "%.bin",
                    "%.lib",
                    "%.mat",
                    "%.asmref",
                    "%.lighting",
                    "%.gbc",
                    "%.bhc",
                    "%.pyc",
                    "%.svg",
                    "%.shadergraph",
                    "%.ghc",
                    "%.editorconfig",
                    "%.bak",
                    "%.bank",
                    "%.buildreport",
                    "%.info",
                    "%.cache",
                    "%.index",
                    "%.dwlt",
                    "%.dylib",
                    "%.bundle",
                    "%.anim",
                    "%.tga",
                    "%.controller",
                    "%.test",
                    "%.pdb",
                    "%.dll",
                    "%.xml",
                },
                pickers = {
                    find_files = {
                        -- Dynamically set find_command based on Ruined.sln presence
                        find_command = function()
                            if has_ruined_sln() then
                                return { "fd", "--type", "f", "--extension", "cs" } -- Only .cs files
                            else
                                return { "fd", "--type", "f" } -- Default: all files
                            end
                        end,
                    },
                    live_grep = {
                        -- Dynamically set glob_pattern based on Ruined.sln presence
                        glob_pattern = function()
                            if has_ruined_sln() then
                                return "*.cs" -- Only search in .cs files
                            else
                                return nil -- Default: no glob pattern (search all files)
                            end
                        end,
                    },
                },
                path_display = { "smart" },
                mappings = {
                    i = {
                        ["<C-k>"] = actions.move_selection_previous, -- move to prev result
                        ["<C-j>"] = actions.move_selection_next, -- move to next result
                        ["<C-q>"] = actions.send_selected_to_qflist + custom_actions.open_trouble_qflist,
                        ["<C-t>"] = trouble_telescope.open,
                    },
                },
            },
        })

        telescope.load_extension("fzf")

        -- set keymaps
        local keymap = vim.keymap -- for conciseness

        keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
        keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
        keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
        keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
        keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
    end,
}
