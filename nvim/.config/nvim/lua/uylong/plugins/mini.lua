return {
  {
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      require('mini.splitjoin').setup({
        mappings = {
          toggle = 'gs',
          split = '',
          join = '',
        },

        detect = {
          brackets = nil,
          -- String Lua pattern defining argument separator
          separator = ',',
          exclude_regions = nil,
        },

        -- Split options
        split = {
          hooks_pre = {},
          hooks_post = {},
        },

        -- Join options
        join = {
          hooks_pre = {},
          hooks_post = {},
        },
      })
    end,
  },
}
