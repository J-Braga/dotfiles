local M = {}

local namespace = vim.api.nvim_create_namespace("comment_hider")
local states = {}
local managed_windows = {}
local pending_refreshes = {}
local configured = false

local config = {
	keymap = "<leader>tc",
	conceallevel = 2,
	concealcursor = "",
	refresh_delay = 80,
	skip_hidden_lines = true,
	center_after_move = true,
	notify = true,
}

local navigation_keys = {
	j = 1,
	k = -1,
	["<Down>"] = 1,
	["<Up>"] = -1,
}

local function notify(message, level)
	if config.notify then
		vim.notify(message, level or vim.log.levels.INFO, { title = "Comment hider" })
	end
end

local function state_for(bufnr)
	states[bufnr] = states[bufnr] or {
		enabled = false,
		hidden_lines = 0,
		hidden_rows = {},
	}
	return states[bufnr]
end

local function normalize_buffer(bufnr)
	if bufnr == nil or bufnr == 0 then
		return vim.api.nvim_get_current_buf()
	end

	return bufnr
end

local function is_comment_capture(name)
	return name == "comment" or name:sub(1, 8) == "comment."
end

local function get_capture_range(node, bufnr, metadata)
	local ok, range = pcall(vim.treesitter.get_range, node, bufnr, metadata)
	if ok then
		return range[1], range[2], range[4], range[5]
	end

	return node:range()
end

local function standalone_range(bufnr, start_row, start_col, end_row, end_col)
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	if start_row < 0 or start_row >= line_count then
		return nil
	end

	local last_row = end_row
	local last_col = end_col
	if end_row > start_row and end_col == 0 then
		last_row = end_row - 1
		local previous_line = vim.api.nvim_buf_get_lines(bufnr, last_row, last_row + 1, false)[1]
		last_col = previous_line and #previous_line or 0
	end

	if last_row < start_row or last_row >= line_count then
		return nil
	end

	local boundary_lines = vim.api.nvim_buf_get_lines(bufnr, start_row, last_row + 1, false)
	local first_line = boundary_lines[1] or ""
	local final_line = boundary_lines[#boundary_lines] or ""

	local prefix = first_line:sub(1, start_col)
	local suffix = final_line:sub(last_col + 1)
	if prefix:find("%S") or suffix:find("%S") then
		return nil
	end

	return start_row, last_row
end

local function collect_hidden_rows(bufnr)
	local ok, parser, parser_error = pcall(vim.treesitter.get_parser, bufnr)
	if not ok then
		return nil, parser
	end
	if not parser then
		return nil, parser_error or "No Tree-sitter parser is available for this buffer"
	end

	local parse_ok, parse_error = pcall(parser.parse, parser)
	if not parse_ok then
		return nil, parse_error
	end

	local rows = {}
	local seen_ranges = {}
	local found_query = false
	local query_error

	parser:for_each_tree(function(tree, language_tree)
		local lang = language_tree:lang()
		local query_ok, query = pcall(vim.treesitter.query.get, lang, "highlights")
		if not query_ok then
			query_error = query
			return
		end
		if not query then
			return
		end

		found_query = true
		local capture_ok, capture_error = pcall(function()
			for id, node, metadata in query:iter_captures(tree:root(), bufnr) do
				local capture_name = query.captures[id]
				if capture_name and is_comment_capture(capture_name) then
					local capture_metadata = metadata and metadata[id] or nil
					local start_row, start_col, end_row, end_col = get_capture_range(node, bufnr, capture_metadata)
					local range_key = table.concat({ start_row, start_col, end_row, end_col }, ":")

					if not seen_ranges[range_key] then
						seen_ranges[range_key] = true
						local first_row, last_row = standalone_range(bufnr, start_row, start_col, end_row, end_col)
						if first_row then
							for row = first_row, last_row do
								rows[row] = true
							end
						end
					end
				end
			end
		end)

		if not capture_ok then
			query_error = capture_error
		end
	end)

	if query_error then
		return nil, query_error
	end
	if not found_query then
		return nil, "No Tree-sitter highlights query is available for this buffer"
	end

	return rows
end

local function conceal_rows(bufnr, rows)
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

	local sorted_rows = vim.tbl_keys(rows)
	table.sort(sorted_rows)

	local hidden_count = #sorted_rows
	local index = 1
	while index <= hidden_count do
		local first_row = sorted_rows[index]
		local last_row = first_row

		while index < hidden_count and sorted_rows[index + 1] == last_row + 1 do
			index = index + 1
			last_row = sorted_rows[index]
		end

		local final_line = vim.api.nvim_buf_get_lines(bufnr, last_row, last_row + 1, false)[1] or ""

		vim.api.nvim_buf_set_extmark(bufnr, namespace, first_row, 0, {
			end_row = last_row,
			end_col = #final_line,
			conceal_lines = "",
		})
		index = index + 1
	end

	return hidden_count
end

local function sync_window(winid)
	if not vim.api.nvim_win_is_valid(winid) then
		managed_windows[winid] = nil
		return
	end

	local bufnr = vim.api.nvim_win_get_buf(winid)
	local state = states[bufnr]
	local should_conceal = state and state.enabled
	local saved = managed_windows[winid]

	if should_conceal then
		if not saved then
			saved = {
				conceallevel = vim.wo[winid].conceallevel,
				concealcursor = vim.wo[winid].concealcursor,
			}
			managed_windows[winid] = saved
		end

		vim.wo[winid].conceallevel = math.max(vim.wo[winid].conceallevel, config.conceallevel)
		vim.wo[winid].concealcursor = config.concealcursor
	elseif saved then
		vim.wo[winid].conceallevel = saved.conceallevel
		vim.wo[winid].concealcursor = saved.concealcursor
		managed_windows[winid] = nil
	end
end

local function sync_windows()
	for _, winid in ipairs(vim.api.nvim_list_wins()) do
		sync_window(winid)
	end
end

local function get_buffer_mapping(bufnr, lhs)
	local mapping
	vim.api.nvim_buf_call(bufnr, function()
		mapping = vim.fn.maparg(lhs, "n", false, true)
	end)

	if type(mapping) == "table" and mapping.buffer == 1 and mapping.lhs ~= "" then
		return mapping
	end
end

local function remove_navigation(bufnr)
	local state = states[bufnr]
	if not state or not state.navigation_installed or not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	for lhs in pairs(navigation_keys) do
		pcall(vim.keymap.del, "n", lhs, { buffer = bufnr })

		local saved_mapping = state.saved_mappings and state.saved_mappings[lhs]
		if saved_mapping then
			vim.api.nvim_buf_call(bufnr, function()
				vim.fn.mapset("n", false, saved_mapping)
			end)
		end
	end

	state.navigation_installed = false
	state.saved_mappings = nil
end

function M.move(direction, count)
	if direction ~= 1 and direction ~= -1 then
		error("direction must be 1 or -1")
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local state = states[bufnr]
	local key = direction == 1 and "j" or "k"
	local remaining = count or vim.v.count1

	while remaining > 0 do
		local previous_row = vim.api.nvim_win_get_cursor(0)[1]
		vim.cmd.normal({ args = { key }, bang = true })
		local current_row = vim.api.nvim_win_get_cursor(0)[1]

		if current_row == previous_row then
			break
		end
		if not state or not state.enabled or not state.hidden_rows[current_row - 1] then
			remaining = remaining - 1
		end
	end

	if config.center_after_move then
		vim.cmd.normal({ args = { "zz" }, bang = true })
	end
end

local function install_navigation(bufnr)
	local state = state_for(bufnr)
	if not config.skip_hidden_lines or state.navigation_installed then
		return
	end

	state.saved_mappings = {}
	for lhs, direction in pairs(navigation_keys) do
		state.saved_mappings[lhs] = get_buffer_mapping(bufnr, lhs)
		vim.keymap.set("n", lhs, function()
			M.move(direction)
		end, {
			buffer = bufnr,
			desc = direction == 1 and "Move to next visible line" or "Move to previous visible line",
			silent = true,
		})
	end

	state.navigation_installed = true
end

function M.refresh(bufnr)
	bufnr = normalize_buffer(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
		return nil, "Buffer is not available"
	end

	local state = state_for(bufnr)
	if not state.enabled then
		return 0
	end

	local rows, error_message = collect_hidden_rows(bufnr)
	if not rows then
		vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
		state.hidden_lines = 0
		state.hidden_rows = {}
		state.last_error = tostring(error_message)
		return nil, state.last_error
	end

	state.hidden_lines = conceal_rows(bufnr, rows)
	state.hidden_rows = rows
	state.last_error = nil
	return state.hidden_lines
end

local function schedule_refresh(bufnr)
	if not states[bufnr] or not states[bufnr].enabled then
		return
	end

	pending_refreshes[bufnr] = (pending_refreshes[bufnr] or 0) + 1
	local refresh_id = pending_refreshes[bufnr]

	vim.defer_fn(function()
		if pending_refreshes[bufnr] ~= refresh_id then
			return
		end
		if states[bufnr] and states[bufnr].enabled and vim.api.nvim_buf_is_valid(bufnr) then
			M.refresh(bufnr)
		end
	end, config.refresh_delay)
end

function M.enable(bufnr)
	bufnr = normalize_buffer(bufnr)
	local state = state_for(bufnr)
	state.enabled = true

	local hidden_count, error_message = M.refresh(bufnr)
	if hidden_count == nil then
		state.enabled = false
		remove_navigation(bufnr)
		sync_windows()
		notify(error_message, vim.log.levels.WARN)
		return false, error_message
	end

	install_navigation(bufnr)
	sync_windows()
	notify(("Comments hidden (%d line%s)"):format(hidden_count, hidden_count == 1 and "" or "s"))
	return true, hidden_count
end

function M.disable(bufnr)
	bufnr = normalize_buffer(bufnr)
	local state = state_for(bufnr)
	state.enabled = false
	state.hidden_lines = 0
	state.hidden_rows = {}
	pending_refreshes[bufnr] = (pending_refreshes[bufnr] or 0) + 1

	if vim.api.nvim_buf_is_valid(bufnr) then
		vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
	end

	remove_navigation(bufnr)
	sync_windows()
	notify("Comments shown")
	return true
end

function M.toggle(bufnr)
	bufnr = normalize_buffer(bufnr)
	if states[bufnr] and states[bufnr].enabled then
		return M.disable(bufnr)
	end

	return M.enable(bufnr)
end

function M.is_enabled(bufnr)
	bufnr = normalize_buffer(bufnr)
	return states[bufnr] ~= nil and states[bufnr].enabled
end

function M.hidden_line_count(bufnr)
	bufnr = normalize_buffer(bufnr)
	return states[bufnr] and states[bufnr].hidden_lines or 0
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
	if configured then
		return
	end
	configured = true

	if vim.fn.has("nvim-0.11") == 0 then
		notify("Comment hider requires Neovim 0.11 or newer", vim.log.levels.ERROR)
		return
	end

	vim.api.nvim_create_user_command("HideCommentsToggle", function()
		M.toggle(0)
	end, { desc = "Toggle standalone comment lines" })

	vim.api.nvim_create_user_command("HideComments", function()
		M.enable(0)
	end, { desc = "Hide standalone comment lines" })

	vim.api.nvim_create_user_command("ShowComments", function()
		M.disable(0)
	end, { desc = "Show hidden comment lines" })

	if config.keymap then
		vim.keymap.set("n", config.keymap, M.toggle, {
			desc = "Toggle standalone comments",
			silent = true,
		})
	end

	local group = vim.api.nvim_create_augroup("CommentHider", { clear = true })
	vim.api.nvim_create_autocmd({ "TextChanged", "FileType" }, {
		group = group,
		callback = function(args)
			schedule_refresh(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		group = group,
		callback = function(args)
			if states[args.buf] and states[args.buf].enabled then
				M.refresh(args.buf)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinEnter" }, {
		group = group,
		callback = function()
			sync_window(vim.api.nvim_get_current_win())
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(args)
			states[args.buf] = nil
			pending_refreshes[args.buf] = nil
		end,
	})

	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(args)
			managed_windows[tonumber(args.match)] = nil
		end,
	})
end

return M
