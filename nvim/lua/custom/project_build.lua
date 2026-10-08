-- Build and run the current project in a split terminal.
--
-- <leader>bb detects the project kind from the nearest marker file walking up
-- from the current buffer, then runs it in a reused terminal split so repeated
-- builds do not pile up windows.
--
--   build.zig     -> zig build <step>   (step picked from build.zig, cached)
--   bun.lock(b)   -> bun run <script>   (script picked from package.json)
--   package.json  -> bun run <script>   (bun is preferred over npm here)
--   build.odin    -> odin run build.odin -file [-- run|release]
--   ols.json      -> odin <cmd> .       (run/build/check/test; Odin has no build file,
--                                        so an .odin buffer alone falls back to its dir)

local M = {}

local config = {
	keymap = "<leader>bb",
	rerun_keymap = "<leader>bl",
	pick_keymap = "<leader>bp",
	size = 15,
	position = "botright",
	-- The split is only worth looking at when something went wrong: close it on
	-- success, and jump into it on failure so the errors are under the cursor.
	close_on_success = true,
	focus_on_error = true,
	-- Close the split after <CR> jumps to an error, so the code fills the window.
	close_on_goto = true,
	toggle_keymap = "<leader>bt",
	stop_keymap = "<leader>bk",
	-- Step/script preferred when one is not chosen explicitly.
	default_zig_step = "run",
	default_bun_script = "dev",
	default_odin_target = "run",
}

-- Odin has no build manifest; these are the `odin <cmd> .` subcommands offered.
local odin_targets = { "run", "build", "check", "test" }

-- A project-local build.odin script: target -> arguments passed after `--`.
-- "run" builds debug, then launches the game.
local odin_script_args = { run = " -- run", debug = "", release = " -- release" }
local odin_script_targets = { "run", "debug", "release" }

-- Marker -> project kind, checked in this order so a Zig project that also
-- carries a package.json still builds with Zig.
local markers = {
	{ file = "build.zig", kind = "zig" },
	{ file = "build.odin", kind = "odin_script" },
	{ file = "ols.json", kind = "odin" },
	{ file = "bun.lockb", kind = "bun" },
	{ file = "bun.lock", kind = "bun" },
	{ file = "package.json", kind = "bun" },
}

-- Per-project-root memory of the last step/script, so <leader>bl can repeat it.
local last_target = {}
-- Cached step/script lists, invalidated when the manifest's mtime changes.
local cache = {}

local terminal = { buf = nil, win = nil, job = nil, origin = nil }

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "Project build" })
end

-- Walk up from the buffer's directory looking for the first known marker.
-- Terminal/scratch buffers have no meaningful path, so those fall back to the
-- working directory rather than resolving against a relative name.
local function find_project(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	local start = vim.uv.cwd()
	if name ~= "" and vim.bo[bufnr].buftype == "" then
		start = vim.fs.dirname(vim.fn.fnamemodify(name, ":p"))
	end

	for _, marker in ipairs(markers) do
		local found = vim.fs.find(marker.file, { path = start, upward = true, type = "file" })[1]
		if found then
			-- Always key state off an absolute root; a relative one would make
			-- the remembered target miss on the next lookup.
			local root = vim.fs.dirname(vim.fn.fnamemodify(found, ":p"))
			-- Lockfiles only identify the project; the targets always come from
			-- the manifest sitting next to them.
			local manifest = marker.kind == "bun" and (root .. "/package.json") or found
			if vim.uv.fs_stat(manifest) then
				return { kind = marker.kind, root = root, manifest = manifest }
			end
		end
	end

	-- Most Odin projects are just a directory of .odin files (the package), so
	-- without an ols.json build the directory the buffer lives in.
	if name:match("%.odin$") then
		return { kind = "odin", root = start }
	end
end

local function manifest_mtime(path)
	local stat = vim.uv.fs_stat(path)
	return stat and stat.mtime.sec or 0
end

-- Zig steps come from `b.step("name", "desc")` in build.zig. Parsing beats
-- `zig build --list-steps` because that shells out and fails outright when a
-- dependency does not compile.
local function zig_steps(manifest)
	local steps = {}
	local seen = {}
	for _, line in ipairs(vim.fn.readfile(manifest)) do
		local name = line:match('%f[%w_]b%.step%(%s*"([^"]+)"')
		if name and not seen[name] then
			seen[name] = true
			steps[#steps + 1] = name
		end
	end
	return steps
end

local function bun_scripts(manifest)
	local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(manifest), "\n"))
	if not ok or type(decoded) ~= "table" or type(decoded.scripts) ~= "table" then
		return {}
	end

	local names = vim.tbl_keys(decoded.scripts)
	table.sort(names)
	return names
end

local function targets_for(project)
	if project.kind == "odin" then
		return odin_targets
	end
	if project.kind == "odin_script" then
		return odin_script_targets
	end

	local mtime = manifest_mtime(project.manifest)
	local entry = cache[project.manifest]
	if entry and entry.mtime == mtime then
		return entry.targets
	end

	local targets = project.kind == "zig" and zig_steps(project.manifest) or bun_scripts(project.manifest)
	cache[project.manifest] = { mtime = mtime, targets = targets }
	return targets
end

local function command_for(project, target)
	if project.kind == "zig" then
		return target and ("zig build " .. target) or "zig build"
	end
	if project.kind == "odin" then
		return ("odin %s ."):format(target or config.default_odin_target)
	end
	if project.kind == "odin_script" then
		return "odin run build.odin -file" .. odin_script_args[target or config.default_odin_target]
	end

	return target and ("bun run " .. target) or "bun install"
end

-- Parse "path:line:col: message" out of one output line. Compilers print paths
-- relative to the project root, so resolve against cwd before reporting a hit.
local function parse_location(line, cwd)
	-- Odin: /abs/path/file.odin(6:11) Error: ...
	local path, lnum, col = line:match("^%s*([^%s(][^(]*%.odin)%((%d+):(%d+)%)")
	if not path then
		path, lnum, col = line:match("([^%s:][^:]*):(%d+):(%d+)")
	end
	if not path then
		path, lnum = line:match("([^%s:][^:]*):(%d+)")
	end
	if not path then
		return nil
	end

	local full = path
	if not vim.startswith(path, "/") then
		full = cwd .. "/" .. path
	end
	if vim.fn.filereadable(full) ~= 1 then
		return nil
	end

	return full, tonumber(lnum), tonumber(col) or 1
end

-- The terminal hard-wraps output at its width, so a long absolute path (Odin
-- prints those) lands split across rows. Rejoin rows that filled the full width
-- into logical lines, remembering which rows each one spans.
local function output_lines(bufnr)
	local rows = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local cols = vim.b[bufnr].project_build_cols
	local lines = {}
	local row = 1
	while row <= #rows do
		local first, text = row, rows[row]
		while cols and row < #rows and vim.fn.strdisplaywidth(rows[row]) >= cols do
			row = row + 1
			text = text .. rows[row]
		end
		lines[#lines + 1] = { text = text, first = first, last = row }
		row = row + 1
	end
	return lines
end

-- <CR> / gf inside the build output: open the file the cursor's line points at.
function M.goto_error()
	local bufnr = vim.api.nvim_get_current_buf()
	local cwd = vim.b[bufnr].project_build_cwd or vim.uv.cwd()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local line = ""
	for _, output in ipairs(output_lines(bufnr)) do
		if row >= output.first and row <= output.last then
			line = output.text
			break
		end
	end

	local path, lnum, col = parse_location(line, cwd)
	if not path then
		notify("No file:line reference on this line", vim.log.levels.WARN)
		return
	end

	-- Jump in the window the build was launched from, so the split stays put.
	local target_win = terminal.origin
	if not (target_win and vim.api.nvim_win_is_valid(target_win)) then
		target_win = nil
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if win ~= terminal.win and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "" then
				target_win = win
				break
			end
		end
	end

	if target_win then
		vim.api.nvim_set_current_win(target_win)
	else
		vim.cmd("topleft split")
	end

	vim.cmd.edit(vim.fn.fnameescape(path))
	pcall(vim.api.nvim_win_set_cursor, 0, { lnum, math.max(col - 1, 0) })
	vim.cmd("normal! zz")

	-- The output has served its purpose; the buffer stays so <leader>bt can
	-- bring it back to reach the next error.
	if config.close_on_goto then
		M.close()
	end
end

-- Row of the first output line that resolves to a real file, so a failed build
-- can drop the cursor straight on it.
local function first_error_row(bufnr, cwd)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return nil
	end

	for _, output in ipairs(output_lines(bufnr)) do
		if parse_location(output.text, cwd) then
			return output.first
		end
	end
end

-- Feed the whole build output through 'errorformat' so :copen / ]q work. The
-- default errorformat already understands Zig's file:line:col: error: form;
-- Odin's file(line:col) form is prepended.
local function populate_quickfix(bufnr, cmd, cwd)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return 0
	end

	local lines = {}
	for _, output in ipairs(output_lines(bufnr)) do
		if output.text:match("%S") then
			lines[#lines + 1] = output.text
		end
	end

	local efm = "%f(%l:%c) %m," .. vim.o.errorformat
	vim.fn.setqflist({}, " ", { title = cmd, lines = lines, efm = efm })

	-- Keep only entries that resolved to a real file; build logs are noisy and
	-- partial matches would send you to nonexistent buffers.
	local items = vim.tbl_filter(function(item)
		return item.valid == 1
			and item.bufnr > 0
			and item.lnum > 0
			and vim.fn.filereadable(vim.api.nvim_buf_get_name(item.bufnr)) == 1
	end, vim.fn.getqflist())

	vim.fn.setqflist({}, "r", { title = cmd, items = items })
	return #items
end

-- Reuse one terminal window per Neovim instance. Opening a second build while
-- the first is running would otherwise leave an orphaned job and split.
local function open_terminal(cmd, cwd)
	if terminal.job then
		vim.fn.jobstop(terminal.job)
		terminal.job = nil
	end

	local reused = terminal.win and vim.api.nvim_win_is_valid(terminal.win)
	local origin = vim.api.nvim_get_current_win()
	local previous = terminal.buf

	-- A fresh scratch buffer must exist BEFORE the terminal attaches. `:split`
	-- shows the origin buffer in the new window, and jobstart({term=true})
	-- converts the current buffer in place -- which would turn the file you are
	-- editing into the terminal, in every window showing it.
	local scratch = vim.api.nvim_create_buf(false, true)

	if reused then
		vim.api.nvim_set_current_win(terminal.win)
	else
		vim.cmd(("%s %dsplit"):format(config.position, config.size))
		terminal.win = vim.api.nvim_get_current_win()
	end

	vim.api.nvim_win_set_buf(terminal.win, scratch)
	terminal.buf = scratch

	-- The old terminal buffer is no longer displayed, so `bufhidden` never
	-- fires for it. Wipe it explicitly, otherwise its name collides with the
	-- next run of the same command (E95).
	if previous and previous ~= terminal.buf and vim.api.nvim_buf_is_valid(previous) then
		vim.api.nvim_buf_delete(previous, { force = true })
	end

	-- Strip the gutter before the job starts: the pty takes the window's text
	-- width at spawn, and that width is where long output rows get hard-wrapped.
	for option, value in pairs({ number = false, relativenumber = false, signcolumn = "no", foldcolumn = "0" }) do
		vim.wo[terminal.win][option] = value
	end
	local info = vim.fn.getwininfo(terminal.win)[1]
	local cols = info.width - info.textoff

	terminal.job = vim.fn.jobstart({ vim.o.shell, "-c", cmd }, {
		term = true,
		cwd = cwd,
		on_exit = function(job, code)
			-- A stale job finishing after a newer build started must not touch
			-- the current split.
			if terminal.job ~= nil and terminal.job ~= job then
				return
			end
			terminal.job = nil

			if code == 0 then
				vim.fn.setqflist({}, "r", { title = cmd, items = {} })
				if config.close_on_success then
					M.close()
				end
				notify(cmd .. " succeeded")
				return
			end

			local count = populate_quickfix(terminal.buf, cmd, cwd)

			-- Errors are the reason to look at the split, so put the cursor on
			-- the first one rather than making the user go find it.
			if config.focus_on_error and terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
				vim.api.nvim_set_current_win(terminal.win)
				local row = first_error_row(terminal.buf, cwd)
				if row then
					pcall(vim.api.nvim_win_set_cursor, terminal.win, { row, 0 })
					vim.cmd("normal! zz")
				end
			end

			if count > 0 then
				notify(("%s failed (%d error%s) -- <CR> to jump, q to close"):format(
					cmd,
					count,
					count == 1 and "" or "s"
				), vim.log.levels.ERROR)
			else
				notify(("%s exited with %d"):format(cmd, code), vim.log.levels.ERROR)
			end
		end,
	})

	if terminal.job <= 0 then
		notify("Failed to start: " .. cmd, vim.log.levels.ERROR)
		return
	end

	-- Name is advisory only; keep it unique so a stale buffer can never block a
	-- rerun of the same command.
	pcall(vim.api.nvim_buf_set_name, terminal.buf, ("build://%d/%s"):format(terminal.buf, cmd))

	-- Remember where the build came from so errors open in that window, and
	-- where it ran so relative paths in the output resolve.
	terminal.origin = origin
	vim.b[terminal.buf].project_build_cwd = cwd
	vim.b[terminal.buf].project_build_cols = cols

	-- Jump to the error under the cursor. The terminal's own mode map means
	-- <CR> only reaches us from normal mode, which is where you scroll anyway.
	for _, lhs in ipairs({ "<CR>", "gf", "gF" }) do
		vim.keymap.set("n", lhs, M.goto_error, {
			buffer = terminal.buf,
			desc = "Go to error under cursor",
			silent = true,
		})
	end

	-- `q` is the usual "dismiss this output pane" key; keep the buffer around
	-- so <leader>bt can bring the same output back.
	vim.keymap.set("n", "q", M.dismiss, {
		buffer = terminal.buf,
		desc = "Close build output, killing it if still running",
		silent = true,
	})
	-- Follow the output, then hand focus straight back: a build that is still
	-- running has nothing to read yet. On failure, on_exit pulls the cursor in.
	vim.cmd("normal! G")
	if vim.api.nvim_win_is_valid(origin) then
		vim.api.nvim_set_current_win(origin)
	end
end

local function run(project, target)
	last_target[project.root] = target
	open_terminal(command_for(project, target), project.root)
end

-- Pick a target, remembering the choice for this project root.
local function choose(project, on_choice)
	local targets = targets_for(project)
	if #targets == 0 then
		return on_choice(nil)
	end
	if #targets == 1 then
		return on_choice(targets[1])
	end

	vim.ui.select(targets, {
		prompt = "Select build target:",
		format_item = function(item)
			return command_for(project, item)
		end,
	}, function(choice)
		if choice then
			on_choice(choice)
		end
	end)
end

-- <leader>bb: run the remembered target, else a sensible default, else prompt.
function M.build()
	local project = find_project(vim.api.nvim_get_current_buf())
	if not project then
		notify("No build.zig, build.odin, ols.json, bun.lock, package.json, or .odin file found", vim.log.levels.WARN)
		return
	end

	local remembered = last_target[project.root]
	if remembered then
		return run(project, remembered)
	end

	local targets = targets_for(project)
	local preferred = ({
		zig = config.default_zig_step,
		bun = config.default_bun_script,
		odin = config.default_odin_target,
		odin_script = config.default_odin_target,
	})[project.kind]
	if vim.tbl_contains(targets, preferred) then
		return run(project, preferred)
	end

	choose(project, function(target)
		run(project, target)
	end)
end

-- <leader>bp: always prompt, ignoring the remembered target.
function M.pick()
	local project = find_project(vim.api.nvim_get_current_buf())
	if not project then
		notify("No build.zig, build.odin, ols.json, bun.lock, package.json, or .odin file found", vim.log.levels.WARN)
		return
	end

	choose(project, function(target)
		run(project, target)
	end)
end

-- <leader>bl: repeat the last target for this project without prompting.
function M.rerun()
	local project = find_project(vim.api.nvim_get_current_buf())
	if not project then
		notify("No project found above this file", vim.log.levels.WARN)
		return
	end
	if last_target[project.root] == nil then
		return M.build()
	end

	run(project, last_target[project.root])
end

-- Close the build split, leaving the job alone if one is still running.
function M.close()
	if not (terminal.win and vim.api.nvim_win_is_valid(terminal.win)) then
		return false
	end

	vim.api.nvim_win_close(terminal.win, true)
	terminal.win = nil
	return true
end

-- `q` in the build window: dismissing a build that is still going means you
-- are done with it, so kill the job rather than leaving it running unseen.
function M.dismiss()
	if terminal.job then
		M.stop()
	end
	M.close()
end

-- Hide the split if it is open, otherwise bring the last output back.
function M.toggle()
	if M.close() then
		return
	end
	if not (terminal.buf and vim.api.nvim_buf_is_valid(terminal.buf)) then
		notify("No build output to show")
		return
	end

	-- Reopening is an explicit request to read the output, so keep the cursor
	-- here, at the end of the log where the newest lines are.
	local origin = vim.api.nvim_get_current_win()
	terminal.origin = vim.api.nvim_win_is_valid(origin) and origin or nil

	vim.cmd(("%s %dsplit"):format(config.position, config.size))
	terminal.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(terminal.win, terminal.buf)
	vim.cmd("normal! G")
end

function M.stop()
	if not terminal.job then
		notify("No build is running")
		return
	end

	local job = terminal.job
	local pid = vim.fn.jobpid(job)
	terminal.job = nil

	-- jobstop signals the process group, which covers the spawned binary too.
	-- Follow up with SIGKILL for anything that ignores SIGTERM -- a game loop
	-- holding the audio device will not always unwind on its own.
	vim.fn.jobstop(job)
	vim.defer_fn(function()
		if pid and pid > 0 and vim.fn.jobwait({ job }, 0)[1] == -1 then
			pcall(vim.fn.system, { "kill", "-KILL", "-" .. pid })
		end
	end, 300)

	notify("Build stopped")
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})

	vim.api.nvim_create_user_command("ProjectBuild", M.build, { desc = "Build and run the current project" })
	vim.api.nvim_create_user_command("ProjectBuildPick", M.pick, { desc = "Pick a build target and run it" })
	vim.api.nvim_create_user_command("ProjectBuildStop", M.stop, { desc = "Stop the running build" })
	vim.api.nvim_create_user_command("ProjectBuildToggle", M.toggle, { desc = "Show or hide the build output" })

	if config.keymap then
		vim.keymap.set("n", config.keymap, M.build, { desc = "Build and run project", silent = true })
	end
	if config.pick_keymap then
		vim.keymap.set("n", config.pick_keymap, M.pick, { desc = "Pick build target", silent = true })
	end
	if config.stop_keymap then
		vim.keymap.set("n", config.stop_keymap, M.stop, { desc = "Kill the running build", silent = true })
	end
	if config.toggle_keymap then
		vim.keymap.set("n", config.toggle_keymap, M.toggle, { desc = "Toggle build output", silent = true })
	end
	if config.rerun_keymap then
		vim.keymap.set("n", config.rerun_keymap, M.rerun, { desc = "Rerun last build target", silent = true })
	end

	-- A spawned game or server must not outlive the editor that started it.
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = vim.api.nvim_create_augroup("ProjectBuildExit", { clear = true }),
		callback = function()
			if terminal.job then
				pcall(vim.fn.jobstop, terminal.job)
				terminal.job = nil
			end
		end,
	})

	-- Drop cached window state when the terminal window closes, so the next
	-- build opens a fresh split instead of targeting a dead window id.
	vim.api.nvim_create_autocmd("WinClosed", {
		group = vim.api.nvim_create_augroup("ProjectBuild", { clear = true }),
		callback = function(args)
			if tonumber(args.match) == terminal.win then
				terminal.win = nil
			end
		end,
	})
end

return M
