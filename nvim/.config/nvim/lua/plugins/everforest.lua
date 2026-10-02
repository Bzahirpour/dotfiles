-- Everforest colorscheme (official, by sainnhe) to match the terminal.
return {
  {
    "sainnhe/everforest",
    lazy = false,
    priority = 1000,
    init = function()
      vim.g.everforest_background = "hard"            -- matches terminal (#232a2e)
      vim.g.everforest_transparent_background = 1     -- let terminal transparency show through
      vim.g.everforest_enable_italic = 1
      vim.g.everforest_ui_contrast = "high"
      vim.g.everforest_better_performance = 1
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everforest",
    },
  },
}
