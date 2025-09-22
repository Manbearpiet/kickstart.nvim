return {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  -- Kies zelf: "VeryLazy" om start-up licht te houden,
  -- of BufReadPre/BufNewFile als je de guides meteen wilt bij het openen.
  event = 'VeryLazy',
  opts = {
    indent = {
      highlight = {
        'RainbowRed',
        'RainbowYellow',
        'RainbowBlue',
        'RainbowOrange',
        'RainbowGreen',
        'RainbowViolet',
        'RainbowCyan',
      },
    },
    -- (optioneel) typische uitsluitingen
    exclude = {
      filetypes = { 'help', 'lazy', 'alpha', 'neo-tree', 'Trouble', 'mason' },
      buftypes = { 'terminal', 'nofile', 'quickfix', 'prompt' },
    },
  },
  config = function(_, opts)
    local hooks = require 'ibl.hooks'

    -- Zorg dat de highlight-groepen elke keer na een colorscheme reset opnieuw gezet worden
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, 'RainbowRed', { fg = '#E06C75' })
      vim.api.nvim_set_hl(0, 'RainbowYellow', { fg = '#E5C07B' })
      vim.api.nvim_set_hl(0, 'RainbowBlue', { fg = '#61AFEF' })
      vim.api.nvim_set_hl(0, 'RainbowOrange', { fg = '#D19A66' })
      vim.api.nvim_set_hl(0, 'RainbowGreen', { fg = '#98C379' })
      vim.api.nvim_set_hl(0, 'RainbowViolet', { fg = '#C678DD' })
      vim.api.nvim_set_hl(0, 'RainbowCyan', { fg = '#56B6C2' })
    end)

    -- Belangrijk: laat Lazy deze één keer aanroepen met jouw opts
    require('ibl').setup(opts)
  end,
}
