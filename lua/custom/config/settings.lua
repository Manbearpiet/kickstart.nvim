-- ~/nvim/lua/slydragonn/settings.lua
-- Neovim settings (duplicates removed)
local g = vim.g
local opt = vim.opt

g.have_nerd_font = true -- Indicate Nerd Font is installed (used for icons)

-- Core editor options
opt.number = true -- Show absolute line numbers
opt.relativenumber = true -- Show relative line numbers (cursor line stays absolute)
opt.autoindent = true -- Copy indent from current line when starting a new one
opt.cursorline = true -- Highlight the current line
opt.expandtab = true -- Convert typed <Tab> to spaces
opt.shiftwidth = 2 -- Indent width for >> << and autoindent
opt.tabstop = 2 -- Number of spaces a <Tab> counts for
opt.encoding = 'UTF-8' -- Default string encoding
opt.ruler = true -- Show cursor position in the status line
opt.mouse = 'a' -- Enable mouse support in all modes
opt.title = true -- Set terminal/window title to the file name
opt.hidden = true -- Allow switching buffers without saving
opt.ttimeoutlen = 0 -- No delay for key code sequences (faster ESC)
opt.wildmenu = true -- Enhanced command-line completion menu
opt.showcmd = true -- Show partially typed command in the last line
opt.showmatch = true -- Briefly jump to matching bracket when inserted
opt.inccommand = 'split' -- Live preview of :substitute in a split
opt.splitright = true -- Vertical splits open to the right
opt.splitbelow = true -- Horizontal splits open below
opt.termguicolors = true -- Enable 24-bit RGB colors
opt.breakindent = true -- Preserve indent when wrapping long lines
opt.undofile = true -- Persistent undo across sessions
opt.ignorecase = true -- Case-insensitive searching...
opt.smartcase = true -- ...unless search contains uppercase
opt.signcolumn = 'yes' -- Always show sign column (avoid text shift)
opt.updatetime = 250 -- Faster CursorHold & diagnostic update time
opt.timeoutlen = 300 -- Timeout for mapped sequence completion
opt.list = true -- Show invisible characters
opt.listchars = { -- Define characters for invisible items
    tab = '» ', -- Display tabs as » + space
    trail = '·', -- Display trailing spaces as ·
    nbsp = '␣' -- Display non-breaking space as ␣
}
opt.scrolloff = 10 -- Minimal lines above/below cursor when scrolling
opt.confirm = true -- Ask for confirmation instead of erroring on quit
opt.winborder = 'rounded' -- Use rounded borders for floating windows

vim.cmd('syntax on') -- Enable syntax highlighting (legacy command)

vim.schedule(function()
    vim.o.clipboard = 'unnamedplus' -- Use system clipboard (scheduled to not slow startup)
end)

-- Trim trailing whitespace before save
local trim_grp = vim.api.nvim_create_augroup('TrimWhitespace', {
    clear = true
})
vim.api.nvim_create_autocmd('BufWritePre', {
    group = trim_grp,
    pattern = '*',
    callback = function(a)
        local buf = a.buf
        if vim.bo[buf].binary or not vim.bo[buf].modifiable then
            return -- Skip non-modifiable or binary buffers
        end
        local view = vim.fn.winsaveview()
        local search = vim.fn.getreg('/')
        vim.cmd([[%s/\s\+$//e]]) -- Remove trailing whitespace
        vim.fn.setreg('/', search)
        vim.fn.winrestview(view)
    end,
    desc = 'Trim trailing whitespace on save'
})

