return {
  -- Disable omnisharp that LazyVim's dotnet extra sets up
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = { mason = false, autostart = false },
      },
    },
  },

  -- Also remove omnisharp-extended (only needed for omnisharp)
  { "Hoffs/omnisharp-extended-lsp.nvim", enabled = false },

  -- Add roslyn.nvim
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor" },
    opts = {
      -- Pick up LazyVim's on_attach & capabilities automatically
      config = {
        settings = {
          ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            csharp_enable_inlay_hints_for_types = true,
            dotnet_enable_inlay_hints_for_indexer_parameters = true,
            dotnet_enable_inlay_hints_for_object_creation_parameters = true,
            dotnet_enable_inlay_hints_for_other_parameters = true,
            dotnet_enable_inlay_hints_for_parameters = true,
            dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
          },
          ["csharp|completion"] = {
            dotnet_provide_regex_completions = true,
            dotnet_show_completion_items_from_unimported_namespaces = true,
            dotnet_show_name_completion_suggestions = true,
          },
        },
      },
    },

    -- Add C# formatter
    {
      "stevearc/conform.nvim",
      opts = function(_, opts)
        opts.formatters_by_ft = opts.formatters_by_ft or {}
        -- no external formatter for C#
        opts.formatters_by_ft.cs = {}
      end,
    },
  },
}
