local function assert_equal(actual, expected, message)
	if not vim.deep_equal(actual, expected) then
		error(("%s: expected %s, got %s"):format(message, vim.inspect(expected), vim.inspect(actual)))
	end
end

local comment_hider = require("comment_hider")
comment_hider.setup({ keymap = false, notify = false, refresh_delay = 0 })

local cases = {
	{
		filetype = "lua",
		lines = {
			"-- standalone",
			"local value = 1 -- inline",
			"  -- indented",
			"local other = 2",
		},
		hidden = 2,
	},
	{
		filetype = "javascript",
		lines = {
			"// standalone",
			"const value = 1; // inline",
			"/* block",
			" * comment",
			" */",
			"const other = 2;",
		},
		hidden = 4,
	},
	{
		filetype = "python",
		lines = {
			"# standalone",
			"value = 1  # inline",
			"    # indented",
			"other = 2",
		},
		hidden = 2,
	},
	{
		filetype = "html",
		lines = {
			"<!-- standalone -->",
			'<div class="item"><!-- inline --></div>',
			"<p>kept</p>",
		},
		hidden = 1,
	},
	{
		filetype = "c",
		lines = {
			"// standalone",
			"int value = 1; // inline",
			"/* block",
			" * comment",
			" */",
			"int other = 2;",
		},
		hidden = 4,
	},
	{
		filetype = "go",
		lines = {
			"// standalone",
			"value := 1 // inline",
			"/* block",
			"comment */",
			"other := 2",
		},
		hidden = 3,
	},
	{
		filetype = "zig",
		lines = {
			"// standalone",
			"const value = 1; // inline",
			"    // indented",
			"const other = 2;",
		},
		hidden = 2,
	},
	{
		filetype = "bash",
		lines = {
			"# standalone",
			"value=1 # inline",
			"  # indented",
			"other=2",
		},
		hidden = 2,
	},
	{
		filetype = "css",
		lines = {
			"/* standalone */",
			"color: red; /* inline */",
			"/* block",
			"comment */",
			"display: block;",
		},
		hidden = 3,
	},
	{
		filetype = "typescript",
		lines = {
			"// standalone",
			"const value = 1; // inline",
			"  // indented",
			"const other = 2;",
		},
		hidden = 2,
	},
}

for _, case in ipairs(cases) do
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(bufnr)
	vim.bo[bufnr].filetype = case.filetype
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, case.lines)

	local enabled, result = comment_hider.enable(bufnr)
	assert_equal(enabled, true, case.filetype .. " parser enabled")
	assert_equal(result, case.hidden, case.filetype .. " hidden line count")
	assert_equal(comment_hider.hidden_line_count(bufnr), case.hidden, case.filetype .. " state count")

	comment_hider.disable(bufnr)
	assert_equal(comment_hider.hidden_line_count(bufnr), 0, case.filetype .. " disabled count")
	vim.api.nvim_buf_delete(bufnr, { force = true })
end

local function screen_line(row)
	local characters = {}
	for column = 1, vim.o.columns do
		characters[#characters + 1] = vim.fn.screenstring(row, column)
	end
	return table.concat(characters):gsub("%s+$", "")
end

local render_buffer = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(render_buffer)
vim.bo[render_buffer].filetype = "lua"
local render_lines = {
	"-- standalone",
	"local first = 1 -- inline",
	"--[[",
	"block comment",
	"]]",
	"local second = 2",
	"local third = 3 --[[ trailing block",
	"still part of the trailing comment",
	"]]",
	"local fourth = 4",
}
vim.api.nvim_buf_set_lines(render_buffer, 0, -1, false, render_lines)
vim.keymap.set("n", "j", "gj", { buffer = render_buffer })
vim.api.nvim_win_set_cursor(0, { 10, 0 })

local enabled, hidden_count = comment_hider.enable(render_buffer)
assert_equal(enabled, true, "render buffer enabled")
assert_equal(hidden_count, 4, "render buffer hidden line count")

local extmarks = vim.api.nvim_buf_get_extmarks(render_buffer, -1, 0, -1, { details = true })
assert_equal(#extmarks, 2, "contiguous comments use two extmarks")
assert_equal(extmarks[1][2], 0, "first extmark start row")
assert_equal(extmarks[1][4].end_row, 0, "first extmark ends on its comment row")
assert_equal(extmarks[2][2], 2, "block extmark start row")
assert_equal(extmarks[2][4].end_row, 4, "block extmark ends on its final comment row")

local active_j_mapping = vim.fn.maparg("j", "n", false, true)
assert_equal(type(active_j_mapping.callback), "function", "visible-line navigation mapping is active")

vim.api.nvim_win_set_cursor(0, { 2, 0 })
comment_hider.move(1, 1)
assert_equal(vim.api.nvim_win_get_cursor(0)[1], 6, "down skips a hidden block")
comment_hider.move(-1, 1)
assert_equal(vim.api.nvim_win_get_cursor(0)[1], 2, "up skips a hidden block")
comment_hider.move(1, 2)
assert_equal(vim.api.nvim_win_get_cursor(0)[1], 7, "counts apply to visible lines")

vim.api.nvim_buf_set_lines(render_buffer, 5, 6, false, { "-- changed while inserting" })
vim.api.nvim_exec_autocmds("TextChangedI", { buffer = render_buffer })
vim.wait(100)
assert_equal(comment_hider.hidden_line_count(render_buffer), 4, "insert changes wait until InsertLeave")
vim.api.nvim_exec_autocmds("InsertLeave", { buffer = render_buffer })
assert_equal(comment_hider.hidden_line_count(render_buffer), 5, "InsertLeave refreshes comments")
vim.api.nvim_buf_set_lines(render_buffer, 5, 6, false, { render_lines[6] })
comment_hider.refresh(render_buffer)

vim.api.nvim_win_set_cursor(0, { 10, 0 })
vim.cmd("redraw!")
assert_equal(screen_line(1), "local first = 1 -- inline", "code after a comment stays visible")
assert_equal(screen_line(2), "local second = 2", "code after a block comment stays visible")
assert_equal(screen_line(3), "local third = 3 --[[ trailing block", "trailing comment start stays visible")
assert_equal(screen_line(4), "still part of the trailing comment", "trailing block body stays visible")
assert_equal(screen_line(5), "]]", "trailing block end stays visible")
assert_equal(screen_line(6), "local fourth = 4", "code after trailing block stays visible")

comment_hider.disable(render_buffer)
vim.cmd("redraw!")
assert_equal(screen_line(1), "-- standalone", "toggle restores comments")
assert_equal(vim.fn.maparg("j", "n", false, true).rhs, "gj", "buffer-local navigation mapping is restored")
assert_equal(
	vim.api.nvim_buf_get_lines(render_buffer, 0, -1, false),
	render_lines,
	"hiding and showing do not alter buffer text"
)
vim.api.nvim_buf_delete(render_buffer, { force = true })

print("comment_hider: all tests passed")
