local M = {}

-- LSP folding ranges per buffer, sorted by start line, so "[[" can jump to the previous fold.
local fold_ranges = {} -- { [bufnr] = { { start_line = <1 based>, end_line = <1 based> }, }, }

function M.update_ranges(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/foldingRange" })[1]
  if not client then return end

  local params = { textDocument = { uri = vim.uri_from_bufnr(bufnr) } }
  local tick = vim.b[bufnr].changedtick

  client:request("textDocument/foldingRange", params, function(err, ranges)
    if err
      or not ranges
      or not vim.api.nvim_buf_is_valid(bufnr)
      or tick ~= vim.b[bufnr].changedtick
    then
      return
    end

    for i, range in ipairs(ranges) do
      ranges[i] = {
        start_line = range.startLine + 1,
        end_line = range.endLine + 1
      }
    end

    -- Sort fold ranges for goto prev fold search
    table.sort(ranges, function(a, b)
      return a.start_line < b.start_line
    end)

    fold_ranges[bufnr] = ranges
  end)
end

function M.clear(bufnr)
  fold_ranges[bufnr] = nil
end

function M.goto_previous_fold()
  local bufnr = vim.api.nvim_get_current_buf()
  local ranges = fold_ranges[bufnr]
  if not ranges or #ranges == 0 then return end

  local row = vim.api.nvim_win_get_cursor(0)[1]

  for i = #ranges, 1, -1 do
    local start_line = ranges[i].start_line

    if start_line < row then
      return vim.api.nvim_win_set_cursor(0, { start_line, 0 })
    end
  end
end

return M
