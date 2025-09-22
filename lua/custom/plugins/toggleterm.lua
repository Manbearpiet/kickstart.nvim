-- ~/nvim/lua/slydragonn/plugins/toggleterm.lua
return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup {
      size = 5,
      open_mapping = [[<C-`>]], -- toggle met Ctrl-`
      direction = 'horizontal', -- mooie floating terminal
      start_in_insert = true,
      shade_terminals = true,
      close_on_exit = true,
    }

    -- Makkelijke navigatie vanuit terminal
    vim.api.nvim_create_autocmd('TermOpen', {
      pattern = 'term://*',
      callback = function(a)
        local opts = {
          buffer = a.buf,
          silent = true,
        }
        vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', '<C-h>', [[<C-\><C-n><C-w>h]], opts)
        vim.keymap.set('t', '<C-j>', [[<C-\><C-n><C-w>j]], opts)
        vim.keymap.set('t', '<C-k>', [[<C-\><C-n><C-w>k]], opts)
        vim.keymap.set('t', '<C-l>', [[<C-\><C-n><C-w>l]], opts)
      end,
    })
  end,
}
