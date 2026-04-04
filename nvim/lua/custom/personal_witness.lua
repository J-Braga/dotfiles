local M = {}

M.palette = {
    bg = "#072626",
    bg_highlight = "#072626",
    bg_alt = "#072626",
    fg = "#d3b58d",
    comment = "#35c81d",
    string = "#0fdfaf",
    variables = "#add8e6",
    constant = "#79ffcf",
    accent = "#d3b58d",
    type = "#90ee90",
    white = "#ffffff",
    selection = "#0000ff",
    line_nr = "#d3b58d",
    caret = "#90ee90",
    invalid_bg = "#504038",
    invalid_fg = "#8fbc8f",
    error = "#c74138",
    warning = "#c7a538",
}

local function set(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

function M.apply()
    local c = M.palette

    vim.o.termguicolors = true
    vim.o.background = "dark"
    vim.cmd("highlight clear")

    if vim.fn.exists("syntax_on") == 1 then
        vim.cmd("syntax reset")
    end

    vim.g.colors_name = "personal_witness"

    set("Normal", { fg = c.fg, bg = c.bg })
    set("NormalFloat", { fg = c.fg, bg = c.bg })
    set("SignColumn", { fg = c.fg, bg = c.bg })
    set("FloatBorder", { fg = c.line_nr, bg = c.bg })
    set("ColorColumn", { bg = c.bg_highlight })
    set("Cursor", { fg = c.bg, bg = c.caret })
    set("CursorLine", { bg = c.bg_highlight })
    set("CursorColumn", { bg = c.bg_highlight })
    set("CursorLineNr", { fg = c.fg, bg = c.bg, bold = true })
    set("LineNr", { fg = c.fg, bg = c.bg })
    set("LineNrAbove", { fg = c.fg, bg = c.bg })
    set("LineNrBelow", { fg = c.fg, bg = c.bg })
    set("FoldColumn", { fg = c.fg, bg = c.bg })
    set("Folded", { fg = c.fg, bg = c.bg })
    set("EndOfBuffer", { fg = c.bg, bg = c.bg })
    set("NonText", { fg = c.line_nr, bg = c.bg })
    set("Whitespace", { fg = c.line_nr })
    set("Visual", { fg = c.fg, bg = c.selection })
    set("Search", { fg = c.bg, bg = c.fg })
    set("IncSearch", { fg = c.bg, bg = c.string })
    set("CurSearch", { fg = c.bg, bg = c.string, bold = true })
    set("MatchParen", { fg = c.white, bg = c.bg_highlight, bold = true })
    set("Pmenu", { fg = c.fg, bg = c.bg })
    set("PmenuSel", { fg = c.bg, bg = c.fg })
    set("PmenuSbar", { bg = c.bg_highlight })
    set("PmenuThumb", { bg = c.fg })
    set("StatusLine", { fg = c.bg, bg = c.fg, bold = true })
    set("StatusLineNC", { fg = c.fg, bg = c.bg })
    set("WinSeparator", { fg = c.fg, bg = c.bg })
    set("VertSplit", { fg = c.fg, bg = c.bg })
    set("Directory", { fg = c.fg, bg = c.bg })

    set("Comment", { fg = c.comment })
    set("Constant", { fg = c.type })
    set("String", { fg = c.string })
    set("Character", { fg = c.string })
    set("Number", { fg = c.constant })
    set("Boolean", { fg = c.constant })
    set("Float", { fg = c.constant })
    set("Identifier", { fg = c.variables })
    set("Function", { fg = c.white })
    set("Statement", { fg = c.white })
    set("Conditional", { fg = c.white })
    set("Repeat", { fg = c.white })
    set("Label", { fg = c.white })
    set("Operator", { fg = c.fg })
    set("Keyword", { fg = c.white })
    set("Exception", { fg = c.error })
    set("PreProc", { fg = c.fg })
    set("Include", { fg = c.fg })
    set("Define", { fg = c.fg })
    set("Macro", { fg = c.fg })
    set("PreCondit", { fg = c.fg })
    set("Type", { fg = c.type })
    set("StorageClass", { fg = c.white })
    set("Structure", { fg = c.type })
    set("Typedef", { fg = c.type })
    set("Special", { fg = c.fg })
    set("SpecialChar", { fg = c.fg })
    set("Tag", { fg = c.variables, underline = true })
    set("Delimiter", { fg = c.fg, underline = true })
    set("SpecialComment", { fg = c.comment })
    set("Debug", { fg = c.error })
    set("Underlined", { fg = c.variables, underline = true })
    set("Bold", { bold = true })
    set("Italic", { italic = true })
    set("Error", { fg = c.invalid_fg, bg = c.invalid_bg })
    set("ErrorMsg", { fg = c.invalid_fg, bg = c.invalid_bg })
    set("Todo", { fg = c.warning, bold = true })

    set("DiagnosticError", { fg = c.error, bg = c.bg })
    set("DiagnosticWarn", { fg = c.warning, bg = c.bg })
    set("DiagnosticInfo", { fg = c.variables, bg = c.bg })
    set("DiagnosticHint", { fg = c.constant, bg = c.bg })
    set("DiagnosticUnderlineError", { undercurl = true, sp = c.error })
    set("DiagnosticUnderlineWarn", { undercurl = true, sp = c.warning })
    set("DiagnosticUnderlineInfo", { undercurl = true, sp = c.variables })
    set("DiagnosticUnderlineHint", { undercurl = true, sp = c.constant })

    set("TelescopeNormal", { fg = c.fg, bg = c.bg })
    set("TelescopeBorder", { fg = c.line_nr, bg = c.bg })
    set("TelescopeSelection", { fg = c.fg, bg = c.bg_highlight })
    set("LazyNormal", { fg = c.fg, bg = c.bg })
    set("LazyButton", { fg = c.fg, bg = c.bg })
    set("LazyButtonActive", { fg = c.bg, bg = c.fg })
    set("MasonNormal", { fg = c.fg, bg = c.bg })
    set("MasonHeading", { fg = c.fg, bg = c.bg })

    set("@comment", { fg = c.comment })
    set("@constant", { fg = c.type })
    set("@constant.builtin", { fg = c.constant })
    set("@string", { fg = c.string })
    set("@variable", { fg = c.variables })
    set("@variable.member", { fg = c.fg })
    set("@parameter", { fg = c.type })
    set("@function", { fg = c.white })
    set("@function.call", { fg = c.fg })
    set("@keyword", { fg = c.white })
    set("@keyword.type", { fg = c.white })
    set("@type", { fg = c.type })
    set("@type.builtin", { fg = c.type })
    set("@operator", { fg = c.fg })
    set("@preproc", { fg = c.fg })
    set("@tag", { fg = c.variables, underline = true })
    set("@punctuation.bracket", { fg = c.fg, underline = true })
    set("@punctuation.delimiter", { fg = c.fg })

    vim.g.terminal_color_0 = c.bg
    vim.g.terminal_color_1 = c.error
    vim.g.terminal_color_2 = c.comment
    vim.g.terminal_color_3 = c.warning
    vim.g.terminal_color_4 = c.constant
    vim.g.terminal_color_5 = c.variables
    vim.g.terminal_color_6 = c.string
    vim.g.terminal_color_7 = c.fg
    vim.g.terminal_color_8 = c.line_nr
    vim.g.terminal_color_9 = "#ff6b68"
    vim.g.terminal_color_10 = "#5fd74f"
    vim.g.terminal_color_11 = "#e6d76a"
    vim.g.terminal_color_12 = "#a9d6ff"
    vim.g.terminal_color_13 = c.white
    vim.g.terminal_color_14 = "#7fe6d1"
    vim.g.terminal_color_15 = "#f7e7ce"
end

return M
