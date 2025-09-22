-- Define helper function for setting keymaps more easily
local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', {
  desc = 'Clear search highlights',
})

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>ld', vim.diagnostic.setloclist, {
  desc = 'Diagnostics loclist',
})

-- Quit
map('n', '<leader>q', '<CMD>q<CR>', {
  desc = 'Quit window',
})

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
map('t', '<Esc><Esc>', '<C-\\><C-n>', {
  desc = 'Exit terminal mode',
})

-- TIP: Disable arrow keys in normal mode
map('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
map('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
map('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
map('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Window navigatie (enkel één definitie)
map('n', '<C-h>', '<C-w>h', {
  desc = 'Window left',
})
map('n', '<C-l>', '<C-w>l', {
  desc = 'Window right',
})
map('n', '<C-j>', '<C-w>j', {
  desc = 'Window down',
})
map('n', '<C-k>', '<C-w>k', {
  desc = 'Window up',
})

-- Resize
map('n', '<C-Left>', '<C-w><')
map('n', '<C-Right>', '<C-w>>')
map('n', '<C-Up>', '<C-w>+')
map('n', '<C-Down>', '<C-w>-')

-- Save
map('n', '<leader>w', '<CMD>update<CR>', {
  desc = 'Write buffer',
})

-- Exit insert mode
map('i', 'jk', '<ESC>')

-- New Windows
map('n', '<leader>o', '<CMD>vsplit<CR>')
map('n', '<leader>p', '<CMD>split<CR>')

-- Toggle light/dark background
map('n', '<leader>bl', function()
  vim.o.background = (vim.o.background == 'dark') and 'light' or 'dark'
end, {
  desc = 'Toggle light/dark background',
})

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight on yank',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', {
    clear = true,
  }),
  callback = function()
    vim.hl.on_yank()
  end,
})
