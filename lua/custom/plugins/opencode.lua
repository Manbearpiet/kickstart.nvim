return {
  'nickjvandyke/opencode.nvim',
  version = '*', -- Latest stable release
  config = function()
    local server_url = 'http://localhost:4096'

    ---@type opencode.Opts
    vim.g.opencode_opts = {
      server = {
        url = server_url,
        start = false,
      },
    }

    -- Ask OpenCode…
    -- Ask OpenCode…
    vim.keymap.set({ 'n', 'x' }, '<C-a>', function()
      require('opencode').ask '@this: '
    end, { desc = 'Ask OpenCode…' })

    -- Select OpenCode…
    vim.keymap.set({ 'n', 'x' }, '<C-x>', function()
      require('opencode').select()
    end, { desc = 'Select OpenCode…' })

    -- Append range to OpenCode
    vim.keymap.set({ 'n', 'x' }, 'go', function()
      return require('opencode').operator '@this '
    end, { desc = 'Append range to OpenCode', expr = true })

    -- Append line to OpenCode
    vim.keymap.set({ 'n' }, 'goo', function()
      return require('opencode').operator '@this ' .. '_'
    end, { desc = 'Append line to OpenCode', expr = true })

    -- Scroll OpenCode up
    vim.keymap.set({ 'n' }, '<S-C-u>', function()
      require('opencode').command 'session.half.page.up'
    end, { desc = 'Scroll OpenCode up' })

    -- Scroll OpenCode down
    vim.keymap.set({ 'n' }, '<S-C-d>', function()
      require('opencode').command 'session.half.page.down'
    end, { desc = 'Scroll OpenCode down' })

    -- Attach OpenCode in split
    vim.keymap.set('n', '<leader>oa', function()
      vim.cmd('vsplit')
      vim.cmd('terminal opencode attach --continue --dir ' .. vim.fn.shellescape(vim.fn.getcwd()) .. ' ' .. server_url)
    end, { desc = 'Attach OpenCode in split' })

    -- Start new OpenCode session
    vim.keymap.set('n', '<leader>on', function()
      require('opencode').command 'session.new'
    end, { desc = 'Start new OpenCode session' })

    -- Select OpenCode session
    vim.keymap.set('n', '<leader>os', function()
      require('opencode').select {
        prompts = false,
        server = false,
        commands = {
          ['session.select'] = 'Select session',
        },
      }
    end, { desc = 'Select OpenCode session' })
  end,
}
