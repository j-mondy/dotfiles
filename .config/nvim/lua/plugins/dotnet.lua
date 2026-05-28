return {
  -- Disable omnisharp and register LSP code action keymaps
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = { enabled = false },
      },
    },
  },

  -- Disable csharpier; use Roslyn for formatting instead
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cs = {},
        razor = {},
      },
    },
  },

  -- Roslyn LSP plugin + server-side settings
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor" },
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
      broad_search = true,
      lock_target = false,
      filewatching = "auto",
    },
    config = function(_, opts)
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
        },
      })
    end,
  },

  -- Enable code lens for Roslyn buffers
  {
    "neovim/nvim-lspconfig",
    opts = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("roslyn_codelens", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "roslyn" then
            return
          end
          if not client:supports_method("textDocument/codeLens") then
            return
          end
          vim.lsp.codelens.enable(true, { bufnr = args.buf })
        end,
      })
    end,
  },

  -- Improved nvim-dap configuration for .NET
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      -- Helper: find the most recently built .dll under bin/Debug
      local function find_dll()
        local cwd = vim.fn.getcwd()
        local dlls = vim.fn.glob(cwd .. "/**/bin/Debug/**/*.dll", false, true)
        local candidates = vim.tbl_filter(function(p)
          return not p:match("/ref/") and not p:match("%.deps%.dll$")
        end, dlls)
        if #candidates == 0 then
          return vim.fn.input("Path to dll: ", cwd .. "/", "file")
        end
        if #candidates == 1 then
          return candidates[1]
        end
        return vim.fn.input("Path to dll: ", cwd .. "/", "file")
      end

      for _, lang in ipairs({ "cs", "fsharp", "vb" }) do
        dap.configurations[lang] = {
          {
            type = "netcoredbg",
            name = "Launch (auto-discover dll)",
            request = "launch",
            program = find_dll,
            cwd = "${workspaceFolder}",
            stopAtEntry = false,
          },
          {
            type = "netcoredbg",
            name = "Launch with args",
            request = "launch",
            program = find_dll,
            args = function()
              local input = vim.fn.input("Args: ")
              return vim.split(input, " ", { trimempty = true })
            end,
            cwd = "${workspaceFolder}",
            stopAtEntry = false,
          },
          {
            type = "netcoredbg",
            name = "Attach to process",
            request = "attach",
            processId = require("dap.utils").pick_process,
          },
        }
      end
    end,
  },

  -- dotnet CLI keymaps
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>cd", group = "dotnet CLI" },
      },
    },
    keys = {
      -- LSP code actions (Roslyn)
      {
        "<leader>ca",
        function()
          vim.lsp.buf.code_action()
        end,
        mode = { "n", "v" },
        desc = "Code Action",
        ft = { "cs", "razor" },
      },
      {
        "<leader>cA",
        function()
          vim.lsp.buf.code_action({
            context = { only = { "source" }, diagnostics = {} },
          })
        end,
        desc = "Source Action",
        ft = { "cs", "razor" },
      },
      {
        "<leader>co",
        function()
          vim.lsp.buf.code_action({
            apply = true,
            context = { only = { "source.organizeImports" }, diagnostics = {} },
          })
        end,
        desc = "Organize Imports",
        ft = { "cs", "razor" },
      },
      {
        "<leader>cR",
        function()
          vim.lsp.buf.code_action({
            context = { only = { "refactor" }, diagnostics = {} },
          })
        end,
        desc = "Refactor",
        ft = { "cs", "razor" },
      },
      {
        "<leader>cq",
        function()
          vim.lsp.buf.code_action({
            context = { only = { "quickfix" }, diagnostics = {} },
          })
        end,
        desc = "Quick Fix",
        ft = { "cs", "razor" },
      },

      -- dotnet CLI
      {
        "<leader>cdb",
        function()
          vim.cmd("make")
        end,
        desc = "Build (quickfix)",
        ft = { "cs", "fsharp", "vb" },
      },
      {
        "<leader>cdr",
        function()
          vim.cmd("split | terminal dotnet run")
          vim.cmd("startinsert")
        end,
        desc = "Run",
        ft = { "cs", "fsharp", "vb" },
      },
      {
        "<leader>cdc",
        function()
          vim.cmd("!dotnet clean")
        end,
        desc = "Clean",
        ft = { "cs", "fsharp", "vb" },
      },
      {
        "<leader>cdR",
        function()
          vim.cmd("!dotnet restore")
        end,
        desc = "Restore",
        ft = { "cs", "fsharp", "vb" },
      },
      {
        "<leader>cdt",
        function()
          vim.cmd("split | terminal dotnet test")
          vim.cmd("startinsert")
        end,
        desc = "Test (terminal)",
        ft = { "cs", "fsharp", "vb" },
      },

      -- Roslyn plugin commands
      {
        "<leader>cdT",
        "<cmd>Roslyn target<cr>",
        desc = "Select Solution Target",
        ft = { "cs", "razor" },
      },
      {
        "<leader>cds",
        "<cmd>Roslyn restart<cr>",
        desc = "Restart Roslyn Server",
        ft = { "cs", "razor" },
      },
    },
  },
}
