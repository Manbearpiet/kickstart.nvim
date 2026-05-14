return {
  'goolord/alpha-nvim',
  event = 'VimEnter',
  dependencies = {
    -- { 'echasnovski/mini.icons', config = function() require('mini.icons').setup() end },
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('alpha').setup(require('alpha.themes.theta').config)
  end,
}
