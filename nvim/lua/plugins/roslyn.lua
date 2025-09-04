return {
    --"seblyng/roslyn.nvim",
    --ft = "cs",
    --opts = {
    --	config = {
    --		-- Here you can pass in any options that that you would like to pass to `vim.lsp.start`.
    --		-- Use `:h vim.lsp.ClientConfig` to see all possible options.
    --		-- The only options that are overwritten and won't have any effect by setting here:
    --		--     - `name`
    --		--     - `cmd`
    --		--     - `root_dir`
    --		settings = {
    --			["csharp|background_analysis"] = {
    --				dotnet_analyzer_diagnostics_scope = "fullSolution",

    --			},
    --		},
    --	},

    --	exe = {
    --		"dotnet",
    --		vim.fs.joinpath(vim.fn.stdpath("data"), "roslyn", "Microsoft.CodeAnalysis.LanguageServer.dll"),
    --	},
    --	args = {
    --		"--logLevel=Information",
    --		"--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
    --	},
    --	--[[
    ---- args can be used to pass additional flags to the language server
    --  ]]

    --	-- "auto" | "roslyn" | "off"
    --	--
    --	-- - "auto": Does nothing for filewatching, leaving everything as default
    --	-- - "roslyn": Turns off neovim filewatching which will make roslyn do the filewatching
    --	-- - "off": Hack to turn off all filewatching. (Can be used if you notice performance issues)
    --	filewatching = "auto",
    --	choose_target = nil,
    --	ignore_target = nil,
    --	broad_search = false,
    --	lock_target = false,
    --},
}
