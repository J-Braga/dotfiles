-- Drive a running RAD Debugger from Neovim over its --ipc channel.
--
-- nvim-dap owns <leader>d* for languages it has an adapter for. Odin on macOS is
-- debugged with the RAD Debugger instead (started by <leader>bg, see
-- project_build.lua), so in Odin buffers the same keys talk to it:
--
--   <leader>db  toggle a line breakpoint at the cursor
--   <leader>dc  clear every breakpoint (here and in the debugger)
--   <leader>dr  run / continue
--   <leader>dh  halt
--   <leader>do  step over       <leader>di  step into       <leader>du  step out
--   <leader>dk  kill the target
--
-- Breakpoints added here get a gutter sign; the debugger keeps its own list, so a
-- breakpoint toggled in its UI is not mirrored back. <leader>dc resets both.
--
-- The debugger only listens while it runs, so breakpoints toggled before it is
-- started are queued. <leader>bg launches it with build.odin's `debug wait`, which
-- leaves the game unstarted; this module waits for the new instance, sends the
-- queue, then sends `run`, so even a breakpoint in startup code is in place in
-- time. The debugger itself remembers breakpoints across its own restarts, so
-- only the queued ones need sending.

local M = {}

local config = {
	raddbg = "/Applications/RAD Debugger.app/Contents/MacOS/raddbg",
	filetypes = { "odin" },
	sign = "RaddbgBreakpoint",
	sign_text = "●",
	sign_hl = "DapBreakpoint",
	-- How long <leader>bg's build plus launch may take before giving up on them.
	launch_wait_seconds = 180,
}

-- bufnr -> { [lnum] = sign_id }
local breakpoints = {}
-- "<path>:<line>" -> true: set while no debugger was running, sent on launch.
local queued = {}
local launch_timer = nil
-- The debugger remembers breakpoints across its own restarts, so a clear done
-- while it is closed is replayed to the next instance <leader>bg starts.
local clear_pending = false

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "RAD Debugger" })
end

-- The pid of the instance <leader>bg started last; commands go to it while it
-- lives, so a second debugger left open does not receive them by accident.
local last_pid = nil

-- Debugger instances only: the `raddbg --ipc ...` senders share the name and
-- can linger for seconds when the instance they targeted has just quit.
local function instance_pids()
	if vim.fn.executable(config.raddbg) ~= 1 then
		return {}
	end
	local pids = {}
	for _, line in ipairs(vim.fn.systemlist({ "ps", "-axo", "pid=,command=" })) do
		local pid, command = line:match("^%s*(%d+)%s+(.*)$")
		-- Only the executable itself counts: build.odin runs it through a shell wrapper
		-- whose command line also mentions the path. The path has a space in it, so
		-- compare against the configured path rather than the first word.
		local n = #config.raddbg
		if pid and command:sub(1, n) == config.raddbg and (#command == n or command:sub(n + 1, n + 1) == " ")
			and not command:find("--ipc", 1, true) then
			pids[tonumber(pid)] = true
		end
	end
	return pids
end

local function instance_running()
	local pids = instance_pids()
	if last_pid and not pids[last_pid] then
		last_pid = nil
	end
	return next(pids) ~= nil
end

-- Two senders started at the same moment deadlock on the debugger's IPC lock, so
-- commands go out one at a time, each after the previous sender has exited.
local send_queue = {}
local send_in_flight = false

local function send_next()
	if send_in_flight or #send_queue == 0 then
		return
	end
	local item = table.remove(send_queue, 1)
	local args = { config.raddbg, "--ipc" }
	if last_pid then
		args[#args + 1] = "--pid:" .. last_pid
	end
	args[#args + 1] = item.command
	send_in_flight = true
	vim.system(args, { text = true, timeout = 15000 }, function(result)
		vim.schedule(function()
			send_in_flight = false
			if item.on_done then
				item.on_done(result)
			end
			send_next()
		end)
	end)
end

local function send(command, on_done)
	send_queue[#send_queue + 1] = { command = command, on_done = on_done }
	send_next()
end

-- Send every queued breakpoint to the running instance.
local function flush_queue()
	local count = 0
	for location in pairs(queued) do
		send("add_breakpoint " .. location)
		count = count + 1
	end
	queued = {}
	if count > 0 then
		notify(("Sent %d queued breakpoint%s to the debugger"):format(count, count == 1 and "" or "s"))
	end
end

-- Send one text command (see `add_breakpoint`, `run`, ... in raddbg.mdesk).
-- The sender returns 0 even when no instance picked the message up, so the
-- running check happens here, not from the exit code.
local function ipc(command, on_done)
	if not instance_running() then
		notify("RAD Debugger is not running; start it with <leader>bg", vim.log.levels.WARN)
		return false
	end
	flush_queue()
	send(command, on_done)
	return true
end

local function stop_launch_timer()
	if launch_timer then
		launch_timer:stop()
		launch_timer:close()
		launch_timer = nil
	end
end

-- Called when <leader>bg starts the debugger with `debug wait`: the build and
-- the launch take a while, so poll for a *new* instance, hand it the queued
-- breakpoints, then tell it to run the game.
function M.on_debugger_launch()
	stop_launch_timer()
	local before = instance_pids()
	local waited = 0
	launch_timer = vim.uv.new_timer()
	launch_timer:start(1000, 1000, function()
		waited = waited + 1
		vim.schedule(function()
			if not launch_timer then
				return
			end
			local new_pid = nil
			for pid in pairs(instance_pids()) do
				if not before[pid] then
					new_pid = pid
					break
				end
			end
			if new_pid then
				stop_launch_timer()
				last_pid = new_pid
				-- Give it a moment to finish starting before talking to it.
				vim.defer_fn(function()
					if clear_pending then
						clear_pending = false
						send("clear_breakpoints")
					end
					flush_queue()
					send("run")
				end, 1500)
			elseif waited >= config.launch_wait_seconds then
				stop_launch_timer()
				notify("Debugger never started; press <leader>dr once it is up", vim.log.levels.WARN)
			end
		end)
	end)
end

-- "<absolute path>:<line>" is the form add_breakpoint / remove_breakpoint take as
-- their plain argument. (toggle_breakpoint only works from the debugger's own
-- text view, so toggling is done here with add + remove.)
local function cursor_location()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" or vim.bo.buftype ~= "" then
		return nil
	end
	path = vim.fn.fnamemodify(path, ":p")
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	return path .. ":" .. lnum, lnum
end

function M.toggle_breakpoint()
	local location, lnum = cursor_location()
	if not location then
		notify("No file under the cursor", vim.log.levels.WARN)
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	breakpoints[bufnr] = breakpoints[bufnr] or {}
	local sign_id = breakpoints[bufnr][lnum]
	local running = instance_running()

	if sign_id then
		vim.fn.sign_unplace("raddbg", { buffer = bufnr, id = sign_id })
		breakpoints[bufnr][lnum] = nil
		if queued[location] then
			-- Never reached the debugger; nothing to remove there.
			queued[location] = nil
		elseif running then
			ipc("remove_breakpoint " .. location)
		else
			notify("Debugger not running; it still holds this breakpoint until <leader>dB", vim.log.levels.WARN)
		end
		return
	end

	breakpoints[bufnr][lnum] = vim.fn.sign_place(0, "raddbg", config.sign, bufnr, { lnum = lnum, priority = 100 })
	if running then
		ipc("add_breakpoint " .. location)
	else
		queued[location] = true
		notify("Breakpoint queued; sent when the debugger starts (<leader>bg)")
	end
end

function M.clear_breakpoints()
	vim.fn.sign_unplace("raddbg")
	breakpoints = {}
	queued = {}
	if instance_running() then
		clear_pending = false
		send("clear_breakpoints")
		notify("Cleared all breakpoints")
	else
		clear_pending = true
		notify("Cleared queued breakpoints; the debugger's own list is cleared when it next starts")
	end
end

-- Plain commands: each is a one-word debugger command.
local plain = {
	run = "run",
	halt = "halt",
	step_over = "step_over",
	step_into = "step_into",
	step_out = "step_out",
	kill = "kill_all",
}
for name, command in pairs(plain) do
	M[name] = function()
		ipc(command)
	end
end

local function map(bufnr, lhs, fn, desc)
	vim.keymap.set("n", lhs, fn, { buffer = bufnr, desc = "RAD: " .. desc, silent = true })
end

-- Buffer-local maps shadow nvim-dap's global <leader>d* only where the RAD
-- Debugger is the debugger in use.
local function attach(bufnr)
	map(bufnr, "<leader>db", M.toggle_breakpoint, "Toggle breakpoint")
	map(bufnr, "<leader>dc", M.clear_breakpoints, "Clear all breakpoints")
	map(bufnr, "<leader>dr", M.run, "Run / continue")
	map(bufnr, "<leader>dh", M.halt, "Halt")
	map(bufnr, "<leader>do", M.step_over, "Step over")
	map(bufnr, "<leader>di", M.step_into, "Step into")
	map(bufnr, "<leader>du", M.step_out, "Step out")
	map(bufnr, "<leader>dk", M.kill, "Kill target")
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})

	vim.fn.sign_define(config.sign, { text = config.sign_text, texthl = config.sign_hl, priority = 100 })

	vim.api.nvim_create_user_command("RadToggleBreakpoint", M.toggle_breakpoint, { desc = "RAD Debugger: toggle breakpoint at cursor" })
	vim.api.nvim_create_user_command("RadClearBreakpoints", M.clear_breakpoints, { desc = "RAD Debugger: clear all breakpoints" })
	vim.api.nvim_create_user_command("RadRun", M.run, { desc = "RAD Debugger: run / continue" })
	vim.api.nvim_create_user_command("Rad", function(cmd)
		ipc(cmd.args, function(result)
			if result.stdout and result.stdout ~= "" then
				print(result.stdout)
			end
		end)
	end, { nargs = "+", desc = "RAD Debugger: send a raw --ipc command (e.g. :Rad state)" })

	local group = vim.api.nvim_create_augroup("Raddbg", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = config.filetypes,
		callback = function(args)
			attach(args.buf)
		end,
	})
	-- Buffers already open when this runs (e.g. after :source) get the maps too.
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.tbl_contains(config.filetypes, vim.bo[bufnr].filetype) then
			attach(bufnr)
		end
	end
	-- Signs belong to one debugging session; drop them with the buffer.
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(args)
			breakpoints[args.buf] = nil
		end,
	})
end

return M
