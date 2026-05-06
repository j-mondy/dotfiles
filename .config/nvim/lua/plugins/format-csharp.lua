return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      -- no external formatter for C#
      opts.formatters_by_ft.cs = {}
    end,
  },
}
