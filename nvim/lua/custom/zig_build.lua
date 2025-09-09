-- Function to build Zig project

local function run_build(build_name)
    local path = vim.fn.expand("%")
    local current_file = "  " .. vim.fn.fnamemodify(path, ":.")
    if current_file == "" then
        vim.notify("No file associated with the current buffer", vim.log.levels.ERROR)
        return
    end

    local project_dir = vim.fn.fnamemodify(current_file, ":h")

    -- Check for build.zig in the project directory
    local build_file = project_dir .. "/build.zig"
    if vim.fn.filereadable(build_file) ~= 1 then
        vim.notify("No build.zig found in " .. project_dir, vim.log.levels.ERROR)
        return
    end

    vim.notify("Building Zig project in " .. project_dir, vim.log.levels.INFO)
    vim.system({ "zig", "build", build_name }, { cwd = project_dir, text = true }, function(obj)
        if obj.code == 0 then
            vim.notify("Zig build succeeded", vim.log.levels.INFO)
        else
            vim.notify("Zig build failed:\n" .. (obj.stderr or "Unknown error"), vim.log.levels.ERROR)
        end
    end)
end

local function zig_build_no_name()
    vim.ui.input({
        prompt = "Enter build to run: ",
    }, function(build_name)
        run_build(build_name)
    end)
end

local function zig_build_voxer()
    run_build("voxer")
end

local function zig_build_last_run()
    run_build(_G.last_zig_build_name)
end

-- Function to build Zig project with selectable steps
local function zig_build()
    if _G.project_dir == nil then
        -- Get the current buffer's directory
        local path = vim.fn.expand("%")
        local current_file = "  " .. vim.fn.fnamemodify(path, ":.")
        if current_file == "" then
            vim.notify("No file associated with the current buffer", vim.log.levels.ERROR)
            return
        end
        if current_file == "" then
            vim.notify("No file associated with the current buffer", vim.log.levels.ERROR)
            return
        end
        _G.project_dir = vim.fn.fnamemodify(current_file, ":h")
    end

    local project_dir = _G.project_dir

    if _G.cached_steps == nil then
        _G.cached_steps = {}
        vim.notify("nothing cached")
        -- Check for build.zig in the project directory
        local build_file = project_dir .. "/build.zig"
        if vim.fn.filereadable(build_file) ~= 1 then
            vim.notify("No build.zig found in " .. project_dir, vim.log.levels.ERROR)
            return
        end

        -- Read the build.zig file
        local lines = vim.fn.readfile(build_file)

        -- Parse build.zig for steps like build.step("name", "description")
        for _, line in ipairs(lines) do
            -- Match pattern: build.step("name", "description")
            local step_name = line:match('b%.step%("([^"]+)",%s*"[^"]+"%)')
            if step_name then
                table.insert(_G.cached_steps, step_name)
            end
        end
    end
    local steps = _G.cached_steps

    if #steps == 0 then
        vim.notify("No build steps found in build.zig", vim.log.levels.WARN)
        -- Fallback to default zig build
        vim.notify("Running default zig build in " .. project_dir, vim.log.levels.INFO)
        vim.system({ "zig", "build" }, { cwd = project_dir, text = true }, function(obj)
            if obj.code == 0 then
                vim.notify("Zig build succeeded", vim.log.levels.INFO)
            else
                vim.notify("Zig build failed:\n" .. (obj.stderr or "Unknown error"), vim.log.levels.ERROR)
            end
        end)
        return
    end

    vim.cmd('echo ""') -- WHY IS THIS NEEDED? select doesn't show the options after the first run
    vim.ui.select(steps, {
        prompt = "Select Zig build step: ",
        format_item = function(item)
            if steps[#steps] == item then
                return "zig build " .. item .. "\n"
            else
                return "zig build " .. item
            end
        end,
    }, function(choice)
        if not choice then
            vim.notify("Build step selection cancelled", vim.log.levels.INFO)
            choice = nil
            return
        end

        _G.last_zig_build_name = choice
        -- Run zig build with the selected step
        vim.notify("Running zig build " .. choice .. " in " .. project_dir, vim.log.levels.INFO)
        vim.system({ "zig", "build", choice }, { cwd = project_dir, text = true }, function(obj)
            if obj.code ~= 0 then
                vim.notify(
                    "Zig build " .. choice .. " failed:\n" .. (obj.stderr or "Unknown error"),
                    vim.log.levels.ERROR
                )
            end
        end)
    end)
end

-- Create a user command using Lua API
-- vim.api.nvim_create_user_command("ZigBuild", zig_build_no_name, {})

-- Set keybinding for <Leader>zb in normal mode
vim.keymap.set("n", "<Leader>zb", zig_build, { desc = "Build Zig project" })
vim.keymap.set("n", "<Leader>zbr", zig_build_last_run, { desc = "Build Zig project" })
vim.keymap.set("n", "<Leader>zbp", zig_build_no_name, { desc = "Build Zig project" })
vim.keymap.set("n", "<Leader>zbz", zig_build_voxer, { desc = "Build Zig project" })
