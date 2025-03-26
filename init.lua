vim.opt.runtimepath:prepend('~/.vim')
vim.opt.runtimepath:append('~/.vim/after')
vim.cmd('source ~/.vimrc')

-- Increase oldfiles limit to 2000
vim.opt.shada = "!,'2000,<50,s10,h"

-- Enable diagnostics virtual text
vim.diagnostic.config({ virtual_text = true })

-- Start server
local serverfile = os.getenv('HOME') .. '/NVIM'
if vim.fn.filereadable(serverfile) == 0 then
  vim.fn.serverstart(serverfile)
end

-- Replace vimtools#EchoSyntax map
vim.keymap.set('n', '<Leader>y', vim.show_pos)

-- Load cmp configuration
require('cmpconfig')

-- Set up mason
require('mason').setup()

-- Set up nvim-treesitter
require('nvim-treesitter.configs').setup {
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "c", "cpp", "lua", "vim", "markdown", "python" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  -- List of parsers to ignore installing (or "all")
  ignore_install = { "javascript" },

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

  highlight = {
    enable = true,

    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
    -- the name of the parser)
    -- list of language that will be disabled
    disable = { "rust" },

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}

require('nvim-treesitter.configs').setup {
  textobjects = {
    select = {
      enable = true,

      -- Automatically jump forward to textobj, similar to targets.vim
      lookahead = true,

      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["am"] = "@function.outer",
        ["im"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },
    },
  },
}

-- treesitter highlight customization
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    vim.schedule(function()
      vim.api.nvim_set_hl(0, "@keyword.import", { link = "Include" })
      vim.api.nvim_set_hl(0, "@variable", { link = "Normal" })
    end)
  end,
})

-- <Leader>tt toggles diagnostics
vim.keymap.set('n', '<Leader>tt', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { silent = true, noremap = true, desc = 'Toggle diagnostics' })

-- <Leader>df shows floating diagnostics
vim.keymap.set('n', '<Leader>df', function()
  vim.diagnostic.open_float()
end, { silent = true, noremap = true })

-- Telescope configuration
require('telescope').setup{
  defaults = {
    layout_strategy = 'vertical',
    layout_config = { height = 0.95, width = 0.9 },
    mappings = {
      n = {
        ["<C-c>"] = require('telescope.actions').close,
        ["q"] = require('telescope.actions').close,
      },
      i = {
        ["<C-j>"] = require('telescope.actions').move_selection_next,
        ["<C-k>"] = require('telescope.actions').move_selection_previous,
      },
    },
  },
}
require('telescope').load_extension('fzf')
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<Leader>T', vim.cmd.Telescope)
vim.keymap.set('n', '<Leader>H', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<C-n>',     builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<C-o>',     builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', ',a',        builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<C-h>',     builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<C-p>',     builtin.oldfiles, { desc = 'Telescope oldfiles' })
vim.keymap.set('n', 'ga',        builtin.grep_string, { desc = 'Telescope grep string' })
vim.keymap.set('n', ',d',        builtin.resume, { desc = 'Telescope resume' })
vim.keymap.set('n', '<M-/>',     builtin.current_buffer_fuzzy_find,
{ desc = 'Telescope current buffer fuzzy find' })
vim.keymap.set('x', 'ga', function()
  local s = vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'))
  builtin.grep_string({ default_text = require('table').concat(s, '\n') })
end, { desc = 'Search for visual selection' })

-- Solarized setup
vim.o.termguicolors = true
vim.o.background = 'dark'
require('solarized').setup{
  variant = 'autumn',
  on_highlights = function(colors, _)
    local groups = {
      StatusFlag = { fg = colors.red, bg = colors.base02 },
      StatusModified = { fg = colors.yellow, bg = colors.base02 },
    }
    if vim.o.background == 'light' then
      groups.StatusFlag.bg = colors.base2
      groups.StatusModified.bg = colors.base2
    end
    return groups
  end
}
local function change_background(arg)
  vim.o.background = arg
  vim.cmd('Runtime autoload/lightline/colorscheme/solarized_custom.vim')
  vim.fn['lightline#colorscheme']()
end
local function create_background_maps()
  vim.keymap.set('n', '[ob', function() change_background('light') end)
  vim.keymap.set('n', ']ob', function() change_background('dark') end)
  vim.keymap.set('n', 'cob', function()
    local change_table = { ['dark'] = 'light', ['light'] = 'dark' }
    change_background(change_table[vim.o.background])
  end)
end
vim.api.nvim_create_autocmd('VimEnter', { callback = create_background_maps })
vim.cmd.colorscheme 'solarized'
