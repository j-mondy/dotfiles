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
  -- [EDITOR] formatting -- Roslyn LSP via conform (csharpier dropped)
  -----------------------------------------------------------------------------
  -- No external C# formatter: conform falls back to the Roslyn LSP formatter,
  -- which also honours organize-imports through the LSP's format/code-action path.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cs = {}, -- [EDITOR] empty -> conform uses lsp_format fallback (Roslyn)
      },
    },
  },

  -----------------------------------------------------------------------------
  -- [SYNTAX] treesitter -- c_sharp parser (was supplied by the disabled extra)
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
      { "<leader>cd", "", desc = "+dotnet", ft = { "cs", "fsharp", "razor" } },

      -- [BUILD/RUN]
      { "<leader>cdr", "<cmd>Dotnet run<cr>", desc = "dotnet run", ft = { "cs", "fsharp" } },
      { "<leader>cdR", "<cmd>Dotnet run profile<cr>", desc = "dotnet run (profile)", ft = { "cs", "fsharp" } },
      { "<leader>cdb", "<cmd>Dotnet build<cr>", desc = "dotnet build", ft = { "cs", "fsharp" } },
      { "<leader>cdw", "<cmd>Dotnet watch<cr>", desc = "dotnet watch", ft = { "cs", "fsharp" } },
      { "<leader>cdC", "<cmd>Dotnet clean<cr>", desc = "dotnet clean", ft = { "cs", "fsharp" } },
      { "<leader>cdo", "<cmd>Dotnet restore<cr>", desc = "dotnet restore", ft = { "cs", "fsharp" } },

      -- [DAP]
      {
        "<leader>cdd",
        function()
          require("dap").continue()
        end,
        desc = "Debug (continue)",
        ft = { "cs", "fsharp" },
      },
      { "<leader>cdD", "<cmd>Dotnet debug profile<cr>", desc = "Debug (profile)", ft = { "cs", "fsharp" } },

      -- [TEST]
      { "<leader>cdt", "<cmd>Dotnet testrunner<cr>", desc = "Test runner", ft = { "cs", "fsharp" } },

      -- [PACKAGES]
      { "<leader>cdp", "<cmd>Dotnet solution select<cr>", desc = "Project/solution view", ft = { "cs", "fsharp" } },
      { "<leader>cda", "<cmd>Dotnet add package<cr>", desc = "Add NuGet package", ft = { "cs", "fsharp" } },
      { "<leader>cdu", "<cmd>Dotnet outdated<cr>", desc = "Outdated packages", ft = { "cs", "fsharp" } },

      -- [SCAFFOLD]
      { "<leader>cdn", "<cmd>Dotnet new<cr>", desc = "New from template", ft = { "cs", "fsharp" } },
      { "<leader>cds", "<cmd>Dotnet secrets<cr>", desc = "User secrets", ft = { "cs", "fsharp" } },
      { "<leader>cde", "<cmd>Dotnet ef database update<cr>", desc = "EF: database update", ft = { "cs" } },
      { "<leader>cdm", "<cmd>Dotnet ef migrations add<cr>", desc = "EF: add migration", ft = { "cs" } },
    },
  },

  -------------------------------------------------------------------------------
  -- [PACKAGES] blink.cmp -- NuGet version autocomplete inside csproj/fsproj
  -----------------------------------------------------------------------------
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        providers = {
          easy_dotnet = {
            name = "easy-dotnet",
            module = "easy-dotnet.completion.blink",
            score_offset = 10000,
          },
        },
        default = { "easy_dotnet" },
      },
    },
  },
  --
  -- -- Disable omnisharp and register LSP code action keymaps
  -- {
  --   "neovim/nvim-lspconfig",
  --   opts = {
  --     servers = {
  --       omnisharp = { enabled = false },
  --     },
  --   },
  -- },
  --
  -- -- Disable csharpier; use Roslyn for formatting instead
  -- {
  --   "stevearc/conform.nvim",
  --   opts = {
  --     formatters_by_ft = {
  --       cs = {},
  --       razor = {},
  --     },
  --   },
  -- },
  --
  -- -- Enable code lens for Roslyn buffers
  -- {
  --   "neovim/nvim-lspconfig",
  --   opts = function()
  --     vim.api.nvim_create_autocmd("LspAttach", {
  --       group = vim.api.nvim_create_augroup("roslyn_codelens", { clear = true }),
  --       callback = function(args)
  --         local client = vim.lsp.get_client_by_id(args.data.client_id)
  --         if not client or client.name ~= "roslyn" then
  --           return
  --         end
  --         if not client:supports_method("textDocument/codeLens") then
  --           return
  --         end
  --         vim.lsp.codelens.enable(true, { bufnr = args.buf })
  --       end,
  --     })
  --   end,
  -- },
  --
  -- -- Improved nvim-dap configuration for .NET
  -- {
  --   "mfussenegger/nvim-dap",
  --   opts = function()
  --     local dap = require("dap")
  --
  --     -- Helper: find the most recently built .dll under bin/Debug
  --     local function find_dll()
  --       local cwd = vim.fn.getcwd()
  --       local dlls = vim.fn.glob(cwd .. "/**/bin/Debug/**/*.dll", false, true)
  --       local candidates = vim.tbl_filter(function(p)
  --         return not p:match("/ref/") and not p:match("%.deps%.dll$")
  --       end, dlls)
  --       if #candidates == 0 then
  --         return vim.fn.input("Path to dll: ", cwd .. "/", "file")
  --       end
  --       if #candidates == 1 then
  --         return candidates[1]
  --       end
  --       return vim.fn.input("Path to dll: ", cwd .. "/", "file")
  --     end
  --
  --     for _, lang in ipairs({ "cs", "fsharp", "vb" }) do
  --       dap.configurations[lang] = {
  --         {
  --           type = "netcoredbg",
  --           name = "Launch (auto-discover dll)",
  --           request = "launch",
  --           program = find_dll,
  --           cwd = "${workspaceFolder}",
  --           stopAtEntry = false,
  --         },
  --         {
  --           type = "netcoredbg",
  --           name = "Launch with args",
  --           request = "launch",
  --           program = find_dll,
  --           args = function()
  --             local input = vim.fn.input("Args: ")
  --             return vim.split(input, " ", { trimempty = true })
  --           end,
  --           cwd = "${workspaceFolder}",
  --           stopAtEntry = false,
  --         },
  --         {
  --           type = "netcoredbg",
  --           name = "Attach to process",
  --           request = "attach",
  --           processId = require("dap.utils").pick_process,
  --         },
  --       }
  --     end
  --   end,
  -- },
  --
  -- -- dotnet CLI keymaps
  -- {
  --   "folke/which-key.nvim",
  --   opts = {
  --     spec = {
  --       { "<leader>cd", group = "dotnet CLI" },
  --     },
  --   },
  --   keys = {
  --     -- LSP code actions (Roslyn)
  --     {
  --       "<leader>ca",
  --       function()
  --         vim.lsp.buf.code_action()
  --       end,
  --       mode = { "n", "v" },
  --       desc = "Code Action",
  --       ft = { "cs", "razor" },
  --     },
  --     {
  --       "<leader>cA",
  --       function()
  --         vim.lsp.buf.code_action({
  --           context = { only = { "source" }, diagnostics = {} },
  --         })
  --       end,
  --       desc = "Source Action",
  --       ft = { "cs", "razor" },
  --     },
  --     {
  --       "<leader>co",
  --       function()
  --         vim.lsp.buf.code_action({
  --           apply = true,
  --           context = { only = { "source.organizeImports" }, diagnostics = {} },
  --         })
  --       end,
  --       desc = "Organize Imports",
  --       ft = { "cs", "razor" },
  --     },
  --     {
  --       "<leader>cR",
  --       function()
  --         vim.lsp.buf.code_action({
  --           context = { only = { "refactor" }, diagnostics = {} },
  --         })
  --       end,
  --       desc = "Refactor",
  --       ft = { "cs", "razor" },
  --     },
  --     {
  --       "<leader>cq",
  --       function()
  --         vim.lsp.buf.code_action({
  --           context = { only = { "quickfix" }, diagnostics = {} },
  --         })
  --       end,
  --       desc = "Quick Fix",
  --       ft = { "cs", "razor" },
  --     },
  --
  --     -- dotnet CLI
  --     {
  --       "<leader>cdb",
  --       function()
  --         vim.cmd("make")
  --       end,
  --       desc = "Build (quickfix)",
  --       ft = { "cs", "fsharp", "vb" },
  --     },
  --     {
  --       "<leader>cdr",
  --       function()
  --         vim.cmd("split | terminal dotnet run")
  --         vim.cmd("startinsert")
  --       end,
  --       desc = "Run",
  --       ft = { "cs", "fsharp", "vb" },
  --     },
  --     {
  --       "<leader>cdc",
  --       function()
  --         vim.cmd("!dotnet clean")
  --       end,
  --       desc = "Clean",
  --       ft = { "cs", "fsharp", "vb" },
  --     },
  --     {
  --       "<leader>cdR",
  --       function()
  --         vim.cmd("!dotnet restore")
  --       end,
  --       desc = "Restore",
  --       ft = { "cs", "fsharp", "vb" },
  --     },
  --     {
  --       "<leader>cdt",
  --       function()
  --         vim.cmd("split | terminal dotnet test")
  --         vim.cmd("startinsert")
  --       end,
  --       desc = "Test (terminal)",
  --       ft = { "cs", "fsharp", "vb" },
  --     },
  --
  --     -- Roslyn plugin commands
  --     {
  --       "<leader>cdT",
  --       "<cmd>Roslyn target<cr>",
  --       desc = "Select Solution Target",
  --       ft = { "cs", "razor" },
  --     },
  --     {
  --       "<leader>cds",
  --       "<cmd>Roslyn restart<cr>",
  --       desc = "Restart Roslyn Server",
  --       ft = { "cs", "razor" },
  --     },
  --   },
  -- },
}
