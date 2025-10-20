return {
  'NeogitOrg/neogit',
  cmd = "Neogit",
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    'sindrets/diffview.nvim', -- optional - Diff integration

    -- Only one of these is needed.
    'nvim-telescope/telescope.nvim', -- optional
    -- "ibhagwan/fzf-lua",              -- optional
    -- "echasnovski/mini.pick",         -- optional
    -- "folke/snacks.nvim",             -- optional
  },
  opts = {
    kind = 'vsplit',
    commit_editor = {
      kind = 'auto',
      show_staged_diff = true,
      staged_diff_split_kind = 'split',
      spell_check = true,
    },
  },
}
