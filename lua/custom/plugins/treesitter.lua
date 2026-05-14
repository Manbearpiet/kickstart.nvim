return { -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  event = 'VeryLazy',
  build = ':TSUpdate',
  -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
  init = function()
    -- Enable treesitter highlighting and indentation via FileType autocmd
    vim.api.nvim_create_autocmd('FileType', {
      callback = function()
        pcall(vim.treesitter.start)
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
  config = function()
    local ts = require 'nvim-treesitter'
    ts.setup { auto_install = true }

    local ensure_installed = {
      'bash',
      'c',
      'c_sharp',
      'diff',
      'html',
      'json',
      'lua',
      'luadoc',
      'markdown',
      'markdown_inline',
      'powershell',
      'query',
      'vim',
      'vimdoc',
    }

    -- Install parsers that are not yet installed (new main branch API)
    local ok, ts_config = pcall(require, 'nvim-treesitter.config')
    if ok and ts_config.get_installed then
      local already_installed = ts_config.get_installed()
      local to_install = vim
        .iter(ensure_installed)
        :filter(function(parser)
          return not vim.tbl_contains(already_installed, parser)
        end)
        :totable()
      if #to_install > 0 then
        ts.install(to_install)
      end
    end
  end,
  -- There are additional nvim-treesitter modules that you can use to interact
  -- with nvim-treesitter. You should go explore a few and see what interests you:
  --
  --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
  --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
  --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
}
