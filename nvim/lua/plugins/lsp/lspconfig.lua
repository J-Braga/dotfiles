return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
		{ "williamboman/mason.nvim" },
		{ "williamboman/mason-lspconfig.nvim" },
	},
	config = function()
		-- Initialize mason.nvim
		require("mason").setup()

		local function remove_bin(path)
			-- Find the position of "bin/python"
			local position = path:find("bin/python")
			if position then
				-- Remove "bin/python" from the path
				return path:sub(1, position - 1)
			else
				-- Return the original path if "bin/python" is not found
				return path
			end
		end

		local function get_python_path()
			-- Use activated virtualenv
			if vim.env.VIRTUAL_ENV then
				return vim.env.VIRTUAL_ENV .. "/bin/python"
			end

			-- Find and use pyenv environment
			local pyenv_path = vim.fn.system("pyenv which python"):gsub("\n", "")
			if vim.fn.filereadable(pyenv_path) == 1 then
				return pyenv_path
			end

			-- Default to system Python
			return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
		end

		-- Import plugins
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local keymap = vim.keymap -- for conciseness

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings
				local opts = { buffer = ev.buf, silent = true }

				-- Set keybinds
				opts.desc = "Show LSP references"
				keymap.set("n", "gR", vim.lsp.buf.references, opts)

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Show LSP definitions"
				--keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
				keymap.set("n", "gd", vim.lsp.buf.definition, opts)

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
			end,
		})

		-- Enable autocompletion
		local capabilities = cmp_nvim_lsp.default_capabilities()

    --capabilities.server_capabili:
		-- Change Diagnostic symbols in the sign column
		-- local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		-- for type, icon in pairs(signs) do
		-- 	local hl = "DiagnosticSign" .. type
		-- 	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		-- end

		require("mason-lspconfig").setup({
			ensure_installed = { "lua_ls", "graphql", "gopls", "ols", "pyright" }, -- Ensure these servers are installed
			automatic_installation = true,
		})

		vim.lsp.config.lua_ls = {
			capabilities = capabilities,
			--on_attach = on_attach,
			on_init = function(client)
				if client.workspace_folders then
					local path = client.workspace_folders[1].name
					if
						path ~= vim.fn.stdpath("config")
						and (vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc"))
					then
						return
					end
				end
				client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
					runtime = {
						version = "LuaJIT",
					},
					workspace = {
						checkThirdParty = false,
						library = {
							vim.env.VIMRUNTIME,
							"${3rd}/luv/library",
						},
					},
				})
			end,
			settings = {
				Lua = {
					telemetry = {
						enable = false,
					},
				},
			},
		}
        vim.lsp.enable("lua_ls")

		vim.lsp.config.gopls = {
			capabilities = capabilities
		}

		vim.lsp.config.pyright = {
			capabilities = capabilities,
			before_init = function(_, config)
				config.settings.python.pythonPath = get_python_path()
				config.settings.python.venv = remove_bin(get_python_path())
			end,
		}

		vim.lsp.config.ols = {
			capabilities = capabilities,
			init_options = {
				checker_args = "-strict-style",
				collections = {
					{ name = "shared", path = odin_root }, -- Ensure odin_root is defined
				},
			},
		}
		vim.lsp.config.graphql = {
			capabilities = capabilities,
			filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
		}
	end,
}
