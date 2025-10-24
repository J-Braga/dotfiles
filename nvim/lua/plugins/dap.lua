return {
    {
        "mfussenegger/nvim-dap",
        dependencies = { "rcarriga/nvim-dap-ui" }, -- For UI integration
        config = function()
            local dap = require("dap")
            --vim.fn.sign_define("DapBreakpoint", { text = "•", texthl = "red", linehl = "", numhl = "" })

            --vim.api.nvim_set_hl(0, "SignColumn", { bg = "#1E1E1E", ctermbg = 235 })  -- Dark gray background
            --vim.highlight.create('DapBreakpoint', { ctermbg=0, guifg='#993939', guibg='#31353f' }, false)
            --vim.highlight.create('DapLogPoint', { ctermbg=0, guifg='#61afef', guibg='#31353f' }, false)
            --vim.highlight.create('DapStopped', { ctermbg=0, guifg='#98c379', guibg='#31353f' }, false)

            --vim.api.nvim_set_hl(0, "blue",   { fg = "#3d59a1" }) 
            --vim.api.nvim_set_hl(0, "green",  { fg = "#9ece6a" }) 
            --vim.api.nvim_set_hl(0, "yellow", { fg = "#FFFF00" }) 
            --vim.api.nvim_set_hl(0, "orange", { fg = "#f09000" }) 

            vim.api.nvim_set_hl(0, 'DapBreakpoint', { ctermbg = 0, bg = '#993939'})
            vim.api.nvim_set_hl(0, 'DapLogPoint', { ctermbg = 0, bg = '#61afef' })
            vim.api.nvim_set_hl(0, 'DapStopped', { ctermbg = 0, bg = '#98c379' })

            -- Define signs with text (ASCII), highlights, and priority
            vim.fn.sign_define("DapBreakpoint", {
              text = "🛑", --"B>",  -- Visible ASCII text
              texthl = "DapBreakpoint",
              linehl = "DapBreakpoint",
              numhl = "",
              priority = 100,
            })
            vim.fn.sign_define("DapBreakpointRejected", {
              text = "🚫",
              texthl = "DapBreakpointRejected",
              linehl = "",
              numhl = "",
              priority = 100,
            })
            vim.fn.sign_define("DapStopped", {
              text = "->",
              texthl = "DapStopped",
              linehl = "Visual",
              numhl = "DapStopped",
              priority = 100,
            })


            -- Basic keymaps for debugging
            vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
            vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue/Start Debugging" })
            vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Step Over" })
            vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
            vim.keymap.set("n", "<leader>du", dap.step_out, { desc = "Step Out" })
            vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
        end,
    },
    {
        "mfussenegger/nvim-dap-python",
        ft = "python", -- Lazy-load on Python filetypes
        dependencies = { "mfussenegger/nvim-dap" },
        config = function()
            local mason_registry = require("mason-registry")
            mason_registry.refresh(function()
                local path = "/usr/bin/python3"
                require("dap-python").setup(path)

                -- Automatic venv detection (handles active VIRTUAL_ENV or common folders like .venv)
                require("dap-python").resolve_python = function()
                    local venv_path = os.getenv("VIRTUAL_ENV")
                    if venv_path then
                        return venv_path .. "/bin/python"
                    else
                        local cwd = vim.fn.getcwd()
                        if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
                            return cwd .. "/.venv/bin/python"
                        end
                        return "/usr/bin/python" -- Fallback to system Python
                    end
                end

                -- Optional: Example custom configuration
                table.insert(require("dap").configurations.python, {
                    type = "python",
                    request = "launch",
                    name = "Launch with active venv",
                    program = "${file}",
                    pythonPath = function()
                        local venv = os.getenv("VIRTUAL_ENV")
                        return venv and (venv .. "/bin/python") or "/usr/bin/python"
                    end,
                })
            end)
        end,
    },
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
        config = function()
            local dap, dapui = require("dap"), require("dapui")
            dapui.setup() -- Default setup; customize options as needed (see :help dapui.setup)

            -- Auto-open/close UI on debug events
            dap.listeners.before.attach.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.launch.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated.dapui_config = function()
                dapui.close()
            end
            dap.listeners.before.event_exited.dapui_config = function()
                dapui.close()
            end

            -- Optional: Keymaps for UI elements
            vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
        end,
    },
}
