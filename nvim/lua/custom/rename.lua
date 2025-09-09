--fFunction to rename the current buffer's file
function rename_file()
    -- Get the current buffer's file path using Lua API
    local old_name = vim.api.nvim_buf_get_name(0)
    if old_name == "" then
        vim.notify("No file associated with the current buffer", vim.log.levels.ERROR)
        return
    end

    vim.notify("rename called")
    -- Prompt for the new file name
    vim.ui.input({
        prompt = "New file name: ",
        default = old_name,
    }, function(new_name)
        if not new_name or new_name == "" then
            vim.notify("Rename cancelled", vim.log.levels.INFO)
            return
        end

        -- Expand the new name to a full path using vim.fn (no direct Lua API equivalent)
        new_name = vim.fn.fnamemodify(new_name, ":p")

        -- Check if the new file already exists using vim.fn (no direct Lua API equivalent)
        if vim.fn.filereadable(new_name) == 1 then
            vim.notify("File already exists: " .. new_name, vim.log.levels.ERROR)
            return
        end

        -- Attempt to rename the file
        local success, err = os.rename(old_name, new_name)
        if not success then
            vim.notify("Error renaming file: " .. err, vim.log.levels.ERROR)
            return
        end

        -- Update the buffer's name using Lua API
        vim.api.nvim_buf_set_name(0, new_name)
        -- Save the buffer using Lua API
        vim.api.nvim_buf_call(0, function()
            vim.cmd("w!")
        end)
        vim.notify("File renamed to: " .. new_name, vim.log.levels.INFO)

        -- Update the buffer's modified status using Lua API
        --vim.api.nvim_buf_set_option(0, "modified", false)
    end)
end

-- Create a user command using Lua API
vim.api.nvim_create_user_command("RenameFile", rename_file, {})

-- Set keybinding for <Leader>rf in normal mode
vim.keymap.set("n", "<leader>rf", rename_file, { desc = "Rename current file", noremap = true, silent = true })
