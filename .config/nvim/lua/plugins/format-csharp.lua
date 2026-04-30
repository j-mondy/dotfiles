return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.cs = {} -- no external formatter for C#
      opts.format_on_save = opts.format_on_save or {}
      opts.format_on_save.lsp_format = "fallback" -- uses OmniSharp for cs now
    end,
  },
}
