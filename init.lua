-- Disable netrw (before plugins load)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Leader key (must be set before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specs
require("lazy").setup({

  -- Treesitter
{
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup()  -- minimal setup call

    -- Languages to install
    vim.treesitter.language.add("c")
    vim.treesitter.language.add("cpp")
    vim.treesitter.language.add("eex")
    vim.treesitter.language.add("typescript")
    vim.treesitter.language.add("elixir")
    vim.treesitter.language.add("erlang")
    vim.treesitter.language.add("go")
    vim.treesitter.language.add("heex")
    vim.treesitter.language.add("html")
    vim.treesitter.language.add("javascript")
    vim.treesitter.language.add("rust")
    vim.treesitter.language.add("tlaplus")
    vim.treesitter.language.add("toml")
    vim.treesitter.language.add("yaml")

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "elixir", "eelixir", "heex" },
      callback = function()
        vim.treesitter.start()
      end,
    })
  end,
  init = function()
    require("nvim-treesitter").install({
      "c", "cpp", "eex", "typescript", "elixir", "erlang", "go",
      "heex", "html", "javascript", "rust", "tlaplus", "toml", "yaml"
    })
  end,
},


  -- Testing
  {
    "janko-m/vim-test",
    config = function()
      vim.g["test#strategy"] = "neoterm"
      vim.keymap.set("n", "<leader>tn", ":TestNearest<CR>", { silent = true })
      vim.keymap.set("n", "<leader>tf", ":TestFile<CR>", { silent = true })
      vim.keymap.set("n", "<leader>ts", ":TestSuite<CR>", { silent = true })
      vim.keymap.set("n", "<leader>tl", ":TestLast<CR>", { silent = true })
      vim.keymap.set("n", "<leader>tv", ":TestVisit<CR>", { silent = true })
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          layout_strategy = "flex",
          layout_config = {
            flex = {
              flip_columns = 120,
            },
          },
        },
      })

      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<C-p>", builtin.find_files, { silent = true })
      vim.keymap.set("n", "<leader>m", builtin.oldfiles, { silent = true })
      vim.keymap.set("n", "<leader>b", builtin.buffers, { silent = true })
      vim.keymap.set("n", "<leader>a", builtin.find_files, { silent = true })

      -- Git
      vim.keymap.set("n", "<leader>gs", builtin.git_status, { silent = true, desc = "Git status" })
      vim.keymap.set("n", "<leader>gc", builtin.git_commits, { silent = true, desc = "Git commits" })
      vim.keymap.set("n", "<leader>gb", function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local previewers = require("telescope.previewers")
        local entry_display = require("telescope.pickers.entry_display")

        local file = vim.fn.expand("%:p")
        local relfile = vim.fn.systemlist("git ls-files --full-name " .. vim.fn.shellescape(file))[1]
        local results = vim.fn.systemlist(
          "git log --follow --pretty=format:'%h %as %s' -- " .. vim.fn.shellescape(file)
        )

        local displayer = entry_display.create({
          separator = " ",
          items = { { width = 8 }, { width = 10 }, { remaining = true } },
        })

        local entry_maker = function(line)
          local sha, date, msg = line:match("^(%S+)%s+(%S+)%s+(.+)$")
          return {
            value = line,
            ordinal = line,
            sha = sha,
            display = function()
              return displayer({
                { sha, "TelescopeResultsIdentifier" },
                { date, "TelescopeResultsComment" },
                msg,
              })
            end,
          }
        end

        local previewer = previewers.new_buffer_previewer({
          title = "Diff at revision",
          define_preview = function(self, entry)
            local content = vim.fn.systemlist(
              "git show " .. entry.sha .. " -- " .. vim.fn.shellescape(relfile)
            )
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, content)
            vim.bo[self.state.bufnr].filetype = "diff"
          end,
        })

        pickers.new({}, {
          prompt_title = "Buffer Commits",
          finder = finders.new_table({ results = results, entry_maker = entry_maker }),
          sorter = conf.generic_sorter({}),
          previewer = previewer,
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              vim.cmd("Gdiff " .. selection.sha)
            end)
            return true
          end,
        }):find()
      end, { silent = true, desc = "Git buffer commits" })
      vim.keymap.set("n", "<leader>gf", builtin.git_files, { silent = true, desc = "Git files" })
      vim.keymap.set("n", "<leader>gh", function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local previewers = require("telescope.previewers")

        local entry_display = require("telescope.pickers.entry_display")

        local file = vim.fn.expand("%:p")
        local relfile = vim.fn.systemlist("git ls-files --full-name " .. vim.fn.shellescape(file))[1]
        local results = vim.fn.systemlist(
          "git log --follow --pretty=format:'%h %as %s' -- " .. vim.fn.shellescape(file)
        )

        local displayer = entry_display.create({
          separator = " ",
          items = {
            { width = 8 },
            { width = 10 },
            { remaining = true },
          },
        })

        local entry_maker = function(line)
          local sha, date, msg = line:match("^(%S+)%s+(%S+)%s+(.+)$")
          return {
            value = line,
            ordinal = line,
            sha = sha,
            display = function()
              return displayer({
                { sha, "TelescopeResultsIdentifier" },
                { date, "TelescopeResultsComment" },
                msg,
              })
            end,
          }
        end

        local previewer = previewers.new_buffer_previewer({
          title = "File at revision",
          define_preview = function(self, entry)
            local sha = entry.sha or entry[1]:match("^(%S+)")
            local content = vim.fn.systemlist("git show " .. sha .. ":" .. vim.fn.shellescape(relfile))
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, content)
            local ft = vim.filetype.match({ filename = relfile }) or ""
            if ft ~= "" then
              vim.bo[self.state.bufnr].filetype = ft
            end
          end,
        })

        pickers.new({}, {
          prompt_title = "File History",
          finder = finders.new_table({ results = results, entry_maker = entry_maker }),
          sorter = conf.generic_sorter({}),
          previewer = previewer,
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              local sha = selection[1]:match("^(%S+)")
              vim.cmd("Gedit " .. sha .. ":%")
            end)
            return true
          end,
        }):find()
      end, { silent = true, desc = "Git file history (full file)" })
    end,
  },

  -- Tpope essentials
  { "tpope/vim-fugitive" },
  { "tpope/vim-repeat" },
  { "tpope/vim-commentary" },

  -- Tree-sitter compatible vim-surround replacement
  {
      "kylechui/nvim-surround",
      version = "^4.0.0", -- Use for stability; omit to use `main` branch for the latest features
      event = "VeryLazy",
      -- Optional: See `:h nvim-surround.configuration` and `:h nvim-surround.setup` for details
      -- config = function()
      --     require("nvim-surround").setup({
      --         -- Put your configuration here
      --     })
      -- end

  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    init = function()
      -- Disable entire built-in ftplugin mappings to avoid conflicts.
      -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
      vim.g.no_plugin_maps = true

      -- Or, disable per filetype (add as you like)
      -- vim.g.no_python_maps = true
      -- vim.g.no_ruby_maps = true
      -- vim.g.no_rust_maps = true
      -- vim.g.no_go_maps = true
    end,
    config = function()
      -- put your config here
    end,
  },

  -- Autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      map_cr = true,
    },
  },

  -- Tmux integration
  { "christoomey/vim-tmux-navigator" },
  { "epeli/slimux" },

  -- Undo tree
  {
    "jiaoshijie/undotree",
    opts = {
      -- your options
    },
    keys = { -- load the plugin only when using it's keybinding:
      { "<leader>u", "<cmd>lua require('undotree').toggle()<cr>" },
    },
  },

  -- Alignment
  { "godlygeek/tabular" },

  -- Emmet
  {
    "mattn/emmet-vim",
    config = function()
      vim.g.user_emmet_expandabbr_key = "<C-Y>y"
    end,
  },

  -- Text objects
  { "wellle/targets.vim" },

  -- Erlang runtime
  { "vim-erlang/vim-erlang-runtime" },

  -- ANSI escape sequences
  { "powerman/vim-plugin-AnsiEsc" },

  -- LSP (using Neovim 0.11+ native vim.lsp.config / vim.lsp.enable)
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Shared on_attach for keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local buf = args.buf
          local opts = { buffer = buf, silent = true }

          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
          vim.keymap.set("n", "<leader>lf", function()
          vim.lsp.buf.format({ async = true })
          end, opts)
        end,
      })

      -- Rust: rust-analyzer
      vim.lsp.config("rust_analyzer", {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        root_markers = { "Cargo.toml", "rust-project.json", ".git" },
        settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
            },
            checkOnSave = true,
            check = {
              command = "clippy",
            },
            procMacro = {
              enable = true,
            },
          },
        },
      })

      -- Python: pyright
      vim.lsp.config("pyright", {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = {
          "pyproject.toml", "setup.py", "setup.cfg",
          "requirements.txt", "Pipfile", "pyrightconfig.json", ".git",
        },
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
            },
          },
        },
      })

      -- JavaScript / TypeScript: ts_ls
      vim.lsp.config("ts_ls", {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = {
          "javascript", "javascriptreact", "javascript.jsx",
          "typescript", "typescriptreact", "typescript.tsx",
        },
        root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
      })

      -- Elixir: Expert (official Elixir language server)
      -- Install: download the release binary for your platform from
      -- https://github.com/elixir-lang/expert/releases
      -- and place it on your PATH (or adjust the cmd path below).
      vim.lsp.config("expert", {
        cmd = { "expert", "--stdio" },
        filetypes = { "elixir", "eelixir", "heex" },
        root_markers = { "mix.exs", ".git" },
      })

      -- Enable all configured servers
      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("pyright")
      vim.lsp.enable("ts_ls")
      -- vim.lsp.enable("expert")
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    opts = {},
  },

  -- File browser
  { "justinmk/vim-dirvish" },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
    keys = {
      { "<leader>n", ":NvimTreeToggle<CR>", silent = true, desc = "Toggle NvimTree" },
    },
  },
  { "nvim-tree/nvim-web-devicons" },

  -- Colorscheme
  -- {
  --   "maxmx03/solarized.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("solarized").setup({})
  --     vim.cmd.colorscheme("solarized")
  --   end,
  -- },
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      theme = "wave",      -- or "dragon" / "lotus"
      background = {
        dark = "wave",
      },
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd("colorscheme kanagawa")
    end,
  },

  -- Diff directories
  { "will133/vim-dirdiff" },

  -- Snippets
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      local ls = require("luasnip")

      -- Load friendly-snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      ls.config.set_config({
        history = true,
        updateevents = "TextChanged,TextChangedI",
        enable_autosnippets = true,
      })

      -- Expand or jump forward
      vim.keymap.set({ "i", "s" }, "<C-k>", function()
        if ls.expand_or_jumpable() then
          ls.expand_or_jump()
        end
      end, { silent = true })

      -- Jump backwards
      vim.keymap.set({ "i", "s" }, "<C-j>", function()
        if ls.jumpable(-1) then
          ls.jump(-1)
        end
      end, { silent = true })

      -- Cycle through choice nodes
      vim.keymap.set({ "i", "s" }, "<C-l>", function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true })
    end,
  },

  -- Markview (markdown previewer)
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },

  -- Jupyter / REPL (molten-nvim)
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_image_provider = "none"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
    end,
    keys = {
      { "<leader>ii", ":MoltenInit<CR>",                    silent = true, desc = "Molten: init kernel" },
      { "<leader>ie", ":MoltenEvaluateOperator<CR>",        silent = true, desc = "Molten: evaluate operator" },
      { "<leader>il", ":MoltenEvaluateLine<CR>",            silent = true, desc = "Molten: evaluate line" },
      { "<leader>ie", ":<C-u>MoltenEvaluateVisual<CR>",     silent = true, mode = "v", desc = "Molten: evaluate selection" },
      { "<leader>id", ":MoltenDelete<CR>",                  silent = true, desc = "Molten: delete cell" },
      { "<leader>ih", ":MoltenHideOutput<CR>",              silent = true, desc = "Molten: hide output" },
      { "<leader>io", ":MoltenShowOutput<CR>",              silent = true, desc = "Molten: show output" },
      { "<leader>ir", ":MoltenRestart!<CR>",                silent = true, desc = "Molten: restart kernel" },
    },
  },

}, {
  -- lazy.nvim options
  checker = { enabled = false },
})

-------------------------------------------------------------------------------
-- Options
-------------------------------------------------------------------------------
vim.opt.autoread = true
vim.opt.background = "dark"
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.backup = true
vim.opt.backupdir = vim.fn.expand("~/.config/nvim/backup/")
vim.opt.directory = vim.fn.expand("~/.config/nvim/swap/")
vim.opt.clipboard = "unnamed"
vim.opt.complete:remove("i")
vim.opt.completeopt = { "menuone", "longest" }
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.hidden = true
vim.opt.history = 10000
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.incsearch = true
vim.opt.laststatus = 2
vim.opt.lazyredraw = true
vim.opt.listchars = { eol = "$", tab = ">-", trail = "~", extends = ">", precedes = "<" }
vim.opt.joinspaces = false
vim.opt.modeline = false
vim.opt.showmode = false
vim.opt.nrformats:remove("octal")
vim.opt.number = true
vim.opt.path:append("**")
vim.opt.ruler = true
vim.opt.scrolloff = 3
vim.opt.shiftwidth = 2
vim.opt.showcmd = true
vim.opt.showmatch = true
vim.opt.smartcase = true
vim.opt.shortmess:append("c")
vim.opt.signcolumn = "yes"
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.switchbuf = "useopen"
vim.opt.tabstop = 2
vim.opt.ttimeoutlen = 50
vim.opt.updatetime = 300
vim.opt.wildignorecase = true
vim.opt.wildmenu = true
vim.opt.wildmode = { "longest", "full" }
vim.opt.inccommand = "nosplit"
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"

vim.g.python3_host_prog = vim.fn.expand("~/.venvs/neovim/bin/python")

vim.opt.grepprg = "rg --vimgrep --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m,%f:%l:%m"

-- ocp-indent (OCaml)
vim.opt.rtp:prepend("/Users/lee.bannard/.opam/default/share/ocp-indent/vim")

-------------------------------------------------------------------------------
-- Keymaps
-------------------------------------------------------------------------------
local map = vim.keymap.set

-- Workaround for C-h not working with vim-tmux-navigator in neovim
map("n", "<BS>", ":TmuxNavigateLeft<CR>", { silent = true })

-- Don't clobber register 0 when pasting
map('x', 'p', '"_dP')

-- Move by visual lines
map("n", "j", "gj")
map("n", "k", "gk")

-- Stamp: replace current word with last yanked text
map("n", "S", 'diw"0P')
map("v", "S", 'd"0P')

-- Splits
map("n", "<Leader>h", ":sp<CR>", { silent = true })
map("n", "<Leader>v", ":vsp<CR>", { silent = true })
map("", "<S-Up>", "2<C-w>+")
map("", "<S-Down>", "2<C-w>-")
map("", "<S-Left>", "4<C-w><")
map("", "<S-Right>", "4<C-w>>")

map("n", "<Leader>+", ':exe "resize " . (winheight(0) * 3/2)<CR>', { silent = true })
map("n", "<Leader>-", ':exe "resize " . (winheight(0) * 2/3)<CR>', { silent = true })
map("n", "<Leader>>", ':exe "vertical resize " . (winwidth(0) * 3/2)<CR>', { silent = true })
map("n", "<Leader><", ':exe "vertical resize " . (winwidth(0) * 2/3)<CR>', { silent = true })

-- Make Y follow the same pattern as C and D
map("", "Y", "y$")

-- Break undo before CTRL-U
map("i", "<C-U>", "<C-G>u<C-U>")

-- Insert mode: go to end/start of line
map("i", "<C-e>", "<C-o>$")
map("i", "<C-a>", "<C-o>0")

-- Enter key selects popup menu item
map("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true })

-- Auto-select first item in popup
map("i", "<C-n>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  else
    return '<C-n><C-r>=pumvisible() ? "\\<Down>" : ""<CR>'
  end
end, { expr = true })

map("i", "<C-x><C-l>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-x><C-l>"
  else
    return '<C-x><C-l><C-r>=pumvisible() ? "\\<Down>" : ""<CR>'
  end
end, { expr = true })

map("i", "<C-x><C-o>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-x><C-o>"
  else
    return '<C-x><C-o><C-r>=pumvisible() ? "\\<Down>" : ""<CR>'
  end
end, { expr = true })

-- Toggle relative line numbers
map('n', '<Leader>r', function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = 'Toggle relative line numbers' })

-- Clear search highlight
map("n", "<Leader><Space>", ":nohlsearch<CR>", { silent = true })

-- Edit/source config
map("n", "<Leader>re", ":edit $MYVIMRC<CR>")
map("n", "<Leader>rs", ":source $MYVIMRC<CR>")

-- DiffOrig
vim.api.nvim_create_user_command("DiffOrig", function()
  vim.cmd("vert new | set bt=nofile | r # | 0d_ | diffthis | wincmd p | diffthis")
end, {})
map("n", "<Leader>rd", ":DiffOrig<CR>")

-- Dir path for current file (command-line abbreviation)
vim.keymap.set("c", "%%", function()
  return vim.fn.expand("%:h") .. "/"
end, { expr = true })

-- Change to directory of current file
map("n", "<Leader>cd", ":cd %:p:h<CR>")

-- Emmet custom expander
map("i", "<C-Y>o", "<C-Y>y<CR><C-o>O<C-i>")

-- Slimux
map("n", "<C-c><C-c>", ":SlimuxREPLSendLine<CR>", { silent = true })
map("v", "<C-c><C-c>", ":SlimuxREPLSendSelection<CR>", { silent = true })

-- Replace word under cursor with last yank
map("n", "<Leader>p", 'viw"0p')

-- Grep mappings
map("n", "<Leader>f", function()
  require("telescope.builtin").live_grep()
end, { desc = "Grep" })
map("n", "gs", function()
  require("telescope.builtin").grep_string({ word_match = "-w" })
end, { silent = true })
map("x", "gs", function()
  vim.cmd('normal! "sy')
  require("telescope.builtin").grep_string({ search = vim.fn.getreg("s") })
end, { silent = true })

-------------------------------------------------------------------------------
-- Strip trailing whitespace
-------------------------------------------------------------------------------
local function strip_whitespace()
  local save_cursor = vim.fn.getpos(".")
  local old_query = vim.fn.getreg("/")
  vim.cmd([[%s/\s\+$//e]])
  vim.fn.setpos(".", save_cursor)
  vim.fn.setreg("/", old_query)
end
map("n", "<Leader>w", strip_whitespace, { desc = "Strip trailing whitespace" })

-------------------------------------------------------------------------------
-- Rename file
-------------------------------------------------------------------------------
local function rename_file()
  local old_name = vim.fn.expand("%")
  local new_name = vim.fn.input("New file name: ", vim.fn.expand("%"), "file")
  if new_name ~= "" and new_name ~= old_name then
    vim.cmd(":saveas " .. new_name)
    vim.cmd(":silent !rm " .. old_name)
    vim.cmd("redraw!")
  end
end
map("n", "<Leader>rf", rename_file, { desc = "Rename file" })

-------------------------------------------------------------------------------
-- SetTestDirs (buffer-local function)
-------------------------------------------------------------------------------
local function set_test_dirs(src_dir, test_dir, src_ext, test_post, test_ext)
  vim.b.src_dir = src_dir
  vim.b.test_dir = test_dir
  vim.b.src_ext = src_ext
  vim.b.test_post = test_post
  vim.b.test_ext = test_ext
end
-- Expose as a global if needed from other configs
_G.SetTestDirs = set_test_dirs

-------------------------------------------------------------------------------
-- Autocommands
-------------------------------------------------------------------------------
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Cursorline only on active window
local cursorline_group = augroup("MyCursorLine", { clear = true })
autocmd("WinLeave", {
  group = cursorline_group,
  callback = function()
    vim.wo.cursorline = false
  end,
})
autocmd({ "WinEnter", "BufRead" }, {
  group = cursorline_group,
  callback = function()
    vim.wo.cursorline = true
  end,
})

-- Text files: set textwidth
local textfile_group = augroup("MyTextFiles", { clear = true })
autocmd("FileType", {
  group = textfile_group,
  pattern = "text",
  callback = function()
    vim.bo.textwidth = 78
  end,
})

-- Restore cursor position
local restore_group = augroup("MyRestoreCursor", { clear = true })
autocmd("BufReadPost", {
  group = restore_group,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 1 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- HTML indentation
vim.g.html_indent_inctags = "html,body,head,tbody,p"

-- Filetype plugin indent
vim.cmd("filetype plugin indent on")
