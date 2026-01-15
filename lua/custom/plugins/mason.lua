return {
  'williamboman/mason.nvim',
  event = 'VeryLazy',
  config = function()
    require('mason').setup {
      registries = {
        'github:mason-org/mason-registry',
        'github:Crashdummyy/mason-registry',
      },
    }
  end,
}
