-- Grep including gitignored directories.
--
-- fff.nvim's Rust core always honours .gitignore, so <leader>fs cannot reach
-- vendored dependencies (zig-pkg/, node_modules/, .zig-cache/). This runs
-- ripgrep with --no-ignore and loads the hits into the quickfix list.

local M = {}

local config = {
	keymap = "<leader>fS",
	cword_keymap = "<leader>fC",
	filetype_keymap = "<leader>fz",
	binding_keymap = "<leader>fb",
	-- Still skip version-control internals and build caches; they are noise,
	-- not dependencies you would read.
	exclude = { ".git", ".zig-cache", "zig-out", "target", "dist", "build" },
}

local function search(pattern, opts)
	opts = opts or {}
	if pattern == nil or pattern == "" then
		return
	end

	local cmd = { "rg", "--vimgrep", "--no-ignore", "--hidden", "--smart-case" }
	for _, dir in ipairs(config.exclude) do
		table.insert(cmd, "--glob")
		table.insert(cmd, "!**/" .. dir .. "/**")
	end
	if opts.glob then
		table.insert(cmd, "--glob")
		table.insert(cmd, opts.glob)
	end

	table.insert(cmd, "--regexp")
	table.insert(cmd, pattern)
	table.insert(cmd, opts.path or ".")

	local result = vim.system(cmd, { text = true, cwd = opts.cwd or vim.uv.cwd() }):wait()

	-- rg exits 1 for "no matches", which is not an error worth a stack trace.
	if result.code > 1 then
		vim.notify("ripgrep failed: " .. (result.stderr or "unknown"), vim.log.levels.ERROR, { title = "Grep all" })
		return
	end

	local lines = vim.split(result.stdout or "", "\n", { trimempty = true })
	if #lines == 0 then
		vim.notify("No matches for " .. pattern, vim.log.levels.WARN, { title = "Grep all" })
		return
	end

	vim.fn.setqflist({}, " ", { title = "rg --no-ignore " .. pattern, lines = lines })
	vim.cmd("copen")
	vim.notify(("%d match%s for %s"):format(#lines, #lines == 1 and "" or "es", pattern), vim.log.levels.INFO, {
		title = "Grep all",
	})
end

M.search = search

-- Prompt accepts "pattern | glob" so a noisy vendored tree can be narrowed
-- without a second keymap: `GetTick | *.zig` searches only Zig sources.
function M.prompt(opts)
	vim.ui.input({ prompt = "Grep (incl. ignored) [pattern | glob]: " }, function(input)
		if not input or input == "" then
			return
		end

		local pattern, glob = input:match("^(.-)%s*|%s*(.+)$")
		opts = vim.tbl_extend("force", opts or {}, { glob = glob })
		search(pattern or input, opts)
	end)
end

-- Grep only files sharing the current buffer's extension, which is usually
-- what you want when chasing an API through a vendored dependency.
function M.prompt_filetype(opts)
	local ext = vim.fn.expand("%:e")
	if ext == "" then
		return M.prompt(opts)
	end

	vim.ui.input({ prompt = ("Grep (*.%s, incl. ignored): "):format(ext) }, function(pattern)
		search(pattern, vim.tbl_extend("force", opts or {}, { glob = "*." .. ext }))
	end)
end

-- Zig wrappers rename every C symbol (SDL_GetTicks -> getMillisecondsSinceInit),
-- so grepping the C name lands on the extern call, not the API you call. Search
-- the C name, then report the `pub fn` that encloses each hit.
function M.zig_binding(symbol, opts)
	opts = opts or {}
	symbol = symbol ~= "" and symbol or vim.fn.expand("<cword>")
	if symbol == nil or symbol == "" then
		return
	end

	-- Match the extern call site only (`c.SDL_Foo(`); a bare name also hits doc
	-- comments, which would resolve to whatever function happens to sit below.
	local pattern = ("\\bc\\.%s\\s*\\("):format(vim.pesc(symbol):gsub("%%", ""))
	local cmd = { "rg", "--vimgrep", "--no-ignore", "--glob", "*.zig", "--regexp", pattern, opts.path or "." }
	local result = vim.system(cmd, { text = true, cwd = opts.cwd or vim.uv.cwd() }):wait()
	if result.code > 1 then
		vim.notify("ripgrep failed", vim.log.levels.ERROR, { title = "Zig binding" })
		return
	end

	local items = {}
	local seen = {}
	for _, hit in ipairs(vim.split(result.stdout or "", "\n", { trimempty = true })) do
		local file, lnum = hit:match("^([^:]+):(%d+):")
		if file and lnum then
			-- Walk back to the nearest `pub fn` above the hit: that is the name
			-- the caller actually writes.
			local lines = vim.fn.readfile(file)
			for row = tonumber(lnum), 1, -1 do
				-- Methods inside a struct are indented, so do not anchor to
				-- column 0; the nearest enclosing `pub fn` is the right answer.
				local name = (lines[row] or ""):match("^%s*pub fn ([%w_]+)")
				if name then
					local key = file .. ":" .. name
					if not seen[key] then
						seen[key] = true
						items[#items + 1] = {
							filename = file,
							lnum = row,
							col = 1,
							text = "pub fn " .. name .. "  <- " .. symbol,
						}
					end
					break
				end
			end
		end
	end

	if #items == 0 then
		vim.notify("No Zig wrapper found for " .. symbol, vim.log.levels.WARN, { title = "Zig binding" })
		return
	end

	vim.fn.setqflist({}, " ", { title = "Zig wrappers for " .. symbol, items = items })
	vim.cmd("copen")
end

function M.cword(opts)
	search(vim.fn.expand("<cword>"), opts)
end

function M.setup(user_config)
	config = vim.tbl_deep_extend("force", config, user_config or {})

	vim.api.nvim_create_user_command("GrepAll", function(args)
		search(args.args ~= "" and args.args or nil)
	end, { nargs = "*", desc = "Grep including gitignored files" })

	vim.api.nvim_create_user_command("ZigBinding", function(args)
		M.zig_binding(args.args)
	end, { nargs = "?", desc = "Find the Zig wrapper for a C symbol" })

	if config.keymap then
		vim.keymap.set("n", config.keymap, M.prompt, { desc = "Grep incl. ignored", silent = true })
	end
	if config.filetype_keymap then
		vim.keymap.set("n", config.filetype_keymap, M.prompt_filetype, {
			desc = "Grep incl. ignored, current filetype",
			silent = true,
		})
	end
	if config.binding_keymap then
		vim.keymap.set("n", config.binding_keymap, function()
			M.zig_binding(vim.fn.expand("<cword>"))
		end, { desc = "Find Zig wrapper for C symbol", silent = true })
	end
	if config.cword_keymap then
		vim.keymap.set("n", config.cword_keymap, M.cword, { desc = "Grep word incl. ignored", silent = true })
	end
end

return M
