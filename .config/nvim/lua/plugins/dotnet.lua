-- .NET configuration, organised by LAYER.
--
-- The stack is split into layers, each owned by the tool best suited to it:
--
--   [EDITOR]    roslyn.nvim   -> LSP, inlay hints, codelens, completion, formatting
--   [SYNTAX]    treesitter    -> c_sharp parser
--   [DAP]       easy-dotnet   -> debugging (bundled netcoredbg, dll resolution, rebuild)
--   [TEST]      easy-dotnet   -> Rider-style test runner
--   [BUILD/RUN] easy-dotnet   -> build / run / watch / clean / restore
--   [PACKAGES]  easy-dotnet   -> NuGet add/outdated/project view + blink autocomplete
--   [SCAFFOLD]  easy-dotnet   -> dotnet new, user secrets, EntityFramework
--
-- The DAP / TEST / BUILD-RUN / PACKAGES / SCAFFOLD layers all live inside the single
-- easy-dotnet plugin spec below; they're tagged inline within its `opts` and `keys`.
--
-- Dependencies:
--   - CLI - easy-dotnet -> dotnet tool install -g EasyDotnet
--   - CLI - dotnet ef -> dotnet tool install -g dotnet-ef
--   - LazyExtras - dap.core -> easy-dotnet's auto_register_dap hooks into nvim-dap
--
-- Additional notes:
--   - This config assumes the LazyVim `lang.dotnet` extra is DISABLED

return {
  -----------------------------------------------------------------------------
  -- [EDITOR] roslyn.nvim -- LSP, inlay hints, codelens, completion, formatting
  -----------------------------------------------------------------------------
  -- roslyn.nvim registers through vim.lsp.config / vim.lsp.enable, NOT lspconfig,
  -- so LazyVim's capability-gated keymap layer never attaches to it. Editor-layer
  -- keymaps (code actions, etc.) are bound directly via LspAttach further down.
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor" },
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
      broad_search = true,
      lock_target = false,
      filewatching = true,
    },
    config = function(_, opts)
      -- [EDITOR] Roslyn LSP server settings
      require("roslyn").setup(opts)

      vim.lsp.config("roslyn", {
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
          ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
            dotnet_enable_tests_code_lens = true,
          },
          -- Solution-wide diagnostics: this is what gives us errors/warnings across
          -- the whole .slnx rather than just open buffers
          ["csharp|background_analysis"] = {
            dotnet_analyzer_diagnostics_scope = "fullSolution",
            dotnet_compiler_diagnostics_scope = "fullSolution",
          },
          ["csharp|completion"] = {
            dotnet_provide_regex_completions = true,
            dotnet_show_completion_items_from_unimported_namespaces = true,
            dotnet_show_name_completion_suggestions = true,
          },
          ["csharp|formatting"] = {
            dotnet_organize_imports_on_format = true,
            dotnet_separate_import_directive_groups = true,
            dotnet_sort_system_directives_first = true,
          },
          ["csharp|symbol_search"] = {
            dotnet_search_reference_assemblies = true,
          },
        },
      })

      -- [EDITOR] LazyVim's keymap system can't see roslyn (no lspconfig client),
      -- so bind the editor-layer maps when the roslyn client attaches.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "roslyn" then
            return
          end
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
          end
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action (Roslyn)")
          map("<leader>cr", vim.lsp.buf.rename, "Rename (Roslyn)")
        end,
      })
    end,
  },

  -----------------------------------------------------------------------------
  -- [EDITOR] formatting -- Roslyn LSP via conform
  -----------------------------------------------------------------------------
  -- No external C# formatter: conform falls back to the Roslyn LSP formatter,
  -- which also honours organize-imports through the LSP's format/code-action path.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- [EDITOR] empty -> conform uses lsp_format fallback (Roslyn)
        cs = {},
      },
    },
  },

  -----------------------------------------------------------------------------
  -- [SYNTAX] treesitter -- c_sharp parser
  -----------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "c_sharp" })
    end,
  },

  -----------------------------------------------------------------------------
  -- easy-dotnet.nvim -- owns [DAP] [TEST] [BUILD/RUN] [PACKAGES] [SCAFFOLD]
  -----------------------------------------------------------------------------
  {
    "GustavEikaas/easy-dotnet.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
    ft = { "cs", "fsharp", "razor" },
    opts = {
      -- [EDITOR] off: roslyn.nvim is the LSP. Never let easy-dotnet start a second Roslyn.
      lsp = { enabled = false },

      -- [DAP] register netcoredbg adapter + configs into nvim-dap so the standard
      -- <leader>dc (continue) works in C# buffers with dll resolution + rebuild.
      -- Set to false if you only ever debug through the <leader>cd maps below.
      debugger = { auto_register_dap = true },

      -- [TEST] Rider-style grouped test tree with aggregate results.
      test_runner = { viewmode = "split" },

      -- match the global picker so all easy-dotnet prompts use snacks.
      picker = "snacks",
    },
    config = function(_, opts)
      require("easy-dotnet").setup(opts)
    end,
    -- Operational-layer keymap surface, bound to easy-dotnet's Lua API (the stable
    -- interface) rather than the `:Dotnet` command wrapper. Layer ownership for each
    -- group is tagged inline below.
    keys = {
      { "<leader>cD", "", desc = "+dotnet", ft = { "cs", "fsharp", "razor" } },

      -- [BUILD/RUN]
      { "<leader>cDr", "<cmd>Dotnet run<cr>", desc = "dotnet run", ft = { "cs", "fsharp" } },
      { "<leader>cDR", "<cmd>Dotnet run profile<cr>", desc = "dotnet run (profile)", ft = { "cs", "fsharp" } },
      { "<leader>cDb", "<cmd>Dotnet build quickfix<cr>", desc = "dotnet build", ft = { "cs", "fsharp" } },
      { "<leader>cDw", "<cmd>Dotnet watch<cr>", desc = "dotnet watch", ft = { "cs", "fsharp" } },
      { "<leader>cDC", "<cmd>Dotnet clean<cr>", desc = "dotnet clean", ft = { "cs", "fsharp" } },
      { "<leader>cDo", "<cmd>Dotnet restore<cr>", desc = "dotnet restore", ft = { "cs", "fsharp" } },

      -- [DAP]
      { "<leader>cDd", "<cmd>Dotnet debug<cr>", desc = "dotnet debug", ft = { "cs", "fsharp" } },
      { "<leader>cDD", "<cmd>Dotnet debug profile<cr>", desc = "dotnet debug (profile)", ft = { "cs", "fsharp" } },
      { "<leader>cDA", "<cmd>Dotnet debug attach<cr>", desc = "dotnet debug (attach)", ft = { "cs", "fsharp" } },

      -- [TEST]
      { "<leader>cDt", "<cmd>Dotnet testrunner<cr>", desc = "dotnet test (runner)", ft = { "cs", "fsharp" } },

      -- [PACKAGES]
      { "<leader>cDa", "<cmd>Dotnet add package<cr>", desc = "dotnet add package", ft = { "cs", "fsharp" } },
      { "<leader>cDu", "<cmd>Dotnet outdated<cr>", desc = "dotnet outdated", ft = { "cs", "fsharp" } },

      -- [SCAFFOLD]
      { "<leader>cDn", "<cmd>Dotnet new<cr>", desc = "dotnet new", ft = { "cs", "fsharp" } },
      { "<leader>cDs", "<cmd>Dotnet secrets<cr>", desc = "dotnet secrets", ft = { "cs", "fsharp" } },
      { "<leader>cDe", "<cmd>Dotnet ef database update<cr>", desc = "dotnet ef database update", ft = { "cs" } },
      { "<leader>cDm", "<cmd>Dotnet ef migrations add<cr>", desc = "dotnet ef add database migration", ft = { "cs" } },
    },
  },

  -------------------------------------------------------------------------------
  -- [PACKAGES] blink.cmp -- NuGet version autocomplete inside csproj/fsproj
  -----------------------------------------------------------------------------
  -- Append form: registers the easy-dotnet source and adds it to the default
  -- list WITHOUT clobbering LazyVim's existing sources (lsp/path/snippet/buffer).
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.easy_dotnet = {

        name = "easy-dotnet",
        module = "easy-dotnet.completion.blink",
        score_offset = 10000,
      }
      opts.sources.default = opts.sources.default or {}
      table.insert(opts.sources.default, "easy_dotnet")
    end,
  },
}
