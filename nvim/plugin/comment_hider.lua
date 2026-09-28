if vim.g.loaded_comment_hider == 1 then
	return
end

vim.g.loaded_comment_hider = 1
require("comment_hider").setup()
