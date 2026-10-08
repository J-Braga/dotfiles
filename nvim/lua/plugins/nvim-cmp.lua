return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer", -- source for text in buffer
      "hrsh7th/cmp-path", -- source for file system paths
      {
        "L3MON4D3/LuaSnip",
        -- follow latest release.
        version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
        -- install jsregexp (optional!).
        build = "make install_jsregexp",
      },
      "saadparwaiz1/cmp_luasnip", -- for autocompletion
      "rafamadriz/friendly-snippets", -- useful snippets
      "onsails/lspkind.nvim", -- vs-code like pictograms
    },
    config = function()
      local cmp = require("cmp")
  
      local luasnip = require("luasnip")
  
      local lspkind = require("lspkind")
  
      -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
      require("luasnip.loaders.from_vscode").lazy_load()

      -- zls never suggests uN/iN (arbitrary-width ints), so offer the common ones in zig buffers.
      local zig_int_items = {}
      for _, sign in ipairs({ "u", "i" }) do
        for _, bits in ipairs({ 8, 16, 32, 64, 128 }) do
          table.insert(zig_int_items, {
            label = sign .. bits,
            kind = cmp.lsp.CompletionItemKind.TypeParameter,
          })
        end
      end
      cmp.register_source("zig_ints", {
        is_available = function()
          return vim.bo.filetype == "zig"
        end,
        complete = function(_, _, callback)
          callback(zig_int_items)
        end,
      })

      cmp.setup({
        completion = {
          completeopt = "menu,menuone,preview,noselect",
        },
        -- zls can take >500ms (the default) on big translate-c modules like SDL's c.zig.
        performance = {
          fetching_timeout = 2000,
        },
        snippet = { -- configure how nvim-cmp interacts with snippet engine
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
          ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
          ["<C-e>"] = cmp.mapping.abort(), -- close completion window
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
        }),
        -- sources for autocompletion
        sources = cmp.config.sources({
          { name = "nvim_lsp"},
          { name = "zig_ints" },
          { name = "luasnip" }, -- snippets
          { name = "buffer" }, -- text within current buffer
          { name = "path" }, -- file system paths
        }),
  
        -- configure lspkind for vs-code like pictograms in completion menu
        formatting = {
          format = lspkind.cmp_format({
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
      })
    end,
  }