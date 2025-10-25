return {
    {
        "mfussenegger/nvim-dap",
        dependencies = { "rcarriga/nvim-dap-ui" }, -- For UI integration
        config = function()
            local dap = require("dap")

            local mason_path = vim.fn.stdpath("data") .. "/mason" -- Standard, dynamic way to get Mason root
            local codelldb_pkg = mason_path .. "/packages/codelldb"
            local extension_path = codelldb_pkg .. "/extension/"
            local codelldb_path = extension_path .. "adapter/codelldb"
            local liblldb_path = extension_path .. "lldb/lib/liblldb.dylib" -- Adjust for your OS (e.g., .dylib on macOS, .dll on Windows)

            dap.adapters.codelldb = {
                type = "server",
                port = "${port}",
                executable = {
                    command = codelldb_path,
                    args = { "--liblldb", liblldb_path, "--port", "${port}" },
                },
            }
            -- Zig configurations with auto-build
            dap.configurations.zig = {
                {
                    name = "Build and Launch Zig Executable",
                    type = "codelldb",
                    request = "launch",
                    --program = "${workspaceFolder}/zig-out/bin/${workspaceFolderBasename}", -- Assumes default Zig build output; adjust if custom
                    program = function()
                        local cwd = vim.fn.getcwd()
                        local basename = vim.fn.fnamemodify(cwd, ":t"):gsub("-", "_") -- Replace hyphens with underscores
                        if vim.fn.filereadable(cwd .. "/build.zig") == 1 then
                            return cwd .. "/zig-out/bin/" .. basename
                        else
                            return vim.fn.expand("%:r"):gsub("-", "_") -- For single files: file without extension, with replacement
                        end
                    end,
                    cwd = "${workspaceFolder}",
                    stopOnEntry = false,
                    args = {},
                    preLaunchTask = function()
                        local build_cmd = "zig build" -- Or "zig build-exe yourfile.zig -O Debug" for single files
                        vim.fn.system(build_cmd) -- Run build; check exit code if needed for errors
                        -- Optional: Notify on failure
                        if vim.v.shell_error ~= 0 then
                            vim.notify("Zig build failed!", vim.log.levels.ERROR)
                        end
                    end,
                },
                --{
                --    name = "Build and Debug Zig Test",
                --    type = "codelldb",
                --    request = "launch",
                --    program = "${workspaceFolder}/zig-out/bin/${workspaceFolderBasename}-test", -- Assumes zig test output
                --    cwd = "${workspaceFolder}",
                --    args = { "--test-filter", vim.fn.input("Test filter (optional): ") },
                --    preLaunchTask = function()
                --        local test_build_cmd = "zig build test" -- Builds tests with debug symbols
                --        vim.fn.system(test_build_cmd)
                --        if vim.v.shell_error ~= 0 then
                --            vim.notify("Zig test build failed!", vim.log.levels.ERROR)
                --        end
                --    end,
                --},
            }

            vim.api.nvim_set_hl(0, "DapBreakpoint", { ctermbg = 0, bg = "#993939" })
            vim.api.nvim_set_hl(0, "DapLogPoint", { ctermbg = 0, bg = "#61afef" })
            vim.api.nvim_set_hl(0, "DapStopped", { ctermbg = 0, bg = "#98c379" })

            vim.fn.sign_define(
                "DapBreakpoint",
                { text = "🛑", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "", priority = 100 }
            )
            vim.fn.sign_define(
                "DapBreakpointRejected",
                { text = "🚫", texthl = "DapBreakpointRejected", linehl = "", numhl = "", priority = 100 }
            )
            vim.fn.sign_define(
                "DapStopped",
                { text = "->", texthl = "DapStopped", linehl = "Visual", numhl = "DapStopped", priority = 100 }
            )

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
