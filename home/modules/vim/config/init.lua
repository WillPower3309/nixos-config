vim.loader.enable()

vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>wv', ':vsplit<CR>', { noremap=true, silent=true })
vim.keymap.set('n', '<leader>ws', ':split<CR>', { noremap=true, silent=true })
vim.keymap.set('n', '<leader>wh', '<C-w>h', { noremap=true, silent=true })
vim.keymap.set('n', '<leader>wj', '<C-w>j', { noremap=true, silent=true })
vim.keymap.set('n', '<leader>wk', '<C-w>k', { noremap=true, silent=true })
vim.keymap.set('n', '<leader>wl', '<C-w>l', { noremap=true, silent=true })
vim.keymap.set('n', '<leader>wH', '<C-w>H', { noremap=true, silent=true })
vim.keymap.set('n', '<leader>wJ', '<C-w>J', { noremap=true, silent=true })
vim.keymap.set('n', '<leader>wK', '<C-w>K', { noremap=true, silent=true })
vim.keymap.set('n', '<leader>wL', '<C-w>L', { noremap=true, silent=true })
vim.keymap.set('n', '<leader>wc', '<C-w>c', { noremap=true, silent=true })
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { noremap=true, silent=true })
-- better find
vim.keymap.set('n', 'n', 'nzz')

-- Term Toggle Keymap
local term_buf = nil
local term_win = nil
vim.keymap.set("n", "<leader>oe", function()
    if term_win and vim.api.nvim_win_is_valid(term_win) then
        vim.cmd("hide")
    else
        vim.cmd("botright new")
        local new_buf = vim.api.nvim_get_current_buf()
        vim.cmd("resize " .. 15)
        if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
            vim.cmd("buffer " .. term_buf) -- go to terminal buffer
            vim.cmd("bd " .. new_buf) -- cleanup new buffer
        else
            vim.cmd("terminal")
            term_buf = vim.api.nvim_get_current_buf()
        end
    vim.cmd.startinsert()
    term_win = vim.api.nvim_get_current_win()
    end
end)

-- built in terminal config
vim.opt_local.mouse = '' -- TODO: terminal only
vim.api.nvim_create_autocmd({ 'WinEnter' }, {
    pattern = term_win,
    callback = function()
        vim.cmd.startinsert()
    end
})

-- Disable unused builtins and language provider support (lua and vimscript plugins only, LSP handles the rest)
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_netrw = 1 -- wanted by nvim-tree
vim.g.loaded_netrwPlugin = 1 -- wanted by nvim-tree
vim.g.loaded_netrwFileHandlers = true
vim.g.loaded_netrwSettings = true
vim.g.loaded_gzip = true
vim.g.loaded_rrhelper = true
vim.g.loaded_tarPlugin = true
vim.g.loaded_zipPlugin = true
vim.g.loaded_2html_plugin = true
vim.g.loaded_vimballPlugin = true
vim.g.loaded_getscriptPlugin = true
vim.g.loaded_logipat = true
vim.g.loaded_tutor_mode_plugin = true
vim.g.loaded_matchit = true

-- TODO: style like https://github.com/reyhankaplan/dotfiles/tree/f40a05211494748a5c0f08ab965b5e0bee6b268c
require('nvim-tree').setup({
    renderer = {
        group_empty = true,
        icons = {
            -- TODO: set glyphs
            git_placement = 'after',
            padding = ' ',
            show = {
                git = false,
                folder_arrow = false,
            },
        },
    },
    hijack_cursor = true,
    diagnostics = { enable = true }, -- lsp highlighting
    update_focused_file = {
        enable = true,
        update_root = true,
    },
})
vim.keymap.set('n', '<leader>op', '<cmd>NvimTreeToggle<CR>', {})

require('telescope').load_extension('fzf') -- fzf is faster
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader> ', builtin.find_files, {})
vim.keymap.set('n', '<leader>*', builtin.live_grep, {})
vim.keymap.set('n', 'gd', '<cmd>Telescope lsp_definitions<CR>', {})

vim.opt.number = true

local augroup = vim.api.nvim_create_augroup('numbertoggle', {})
vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'InsertLeave', 'CmdlineLeave', 'WinEnter' }, {
    pattern = '*',
    group = augroup,
    callback = function()
        if vim.o.nu and vim.api.nvim_get_mode ~= 'i' then
            vim.opt.relativenumber = true
        end
    end
})
vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost', 'InsertEnter', 'CmdlineEnter', 'WinLeave' }, {
    pattern = '*',
    group = augroup,
    callback = function()
        if vim.o.nu then
            vim.opt.relativenumber = false
            -- workaround for https://github.com/neovim/neovim/issues/32068
            if not vim.tbl_contains({'@', '-'}, vim.v.event.cmdtype) then
                vim.cmd 'redraw'
            end
        end
    end
})

-- Spaces & tabs
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4

-- Directories
vim.o.undodir = vim.fn.stdpath('cache') .. '/undo'
vim.o.backupdir = vim.fn.stdpath('cache') .. '/backup'
vim.o.directory = vim.fn.stdpath('cache') .. '/swap'

-- Pop-ups should have a rounded border
vim.o.winborder = 'rounded'

-- Load colorscheme
vim.cmd [[colorscheme lena]]

-- Display different types of white spaces
vim.o.list = true
vim.o.listchars = 'tab:│ ,trail:•,extends:#,nbsp:.'

-- Characters to fill the statuslines and vertical separators
vim.o.fillchars='stl:━,stlnc:━,vert:┃,vertleft:┫,vertright:┣,verthoriz:╋,horiz:━,horizup:┻,horizdown:┳,eob: '

-- Only one statusline for all windows
vim.opt.laststatus = 3
-- Always show tabline, since statusline has no information
vim.o.showtabline = 2

local function LineInfo()
    return table.concat {
        '%#CustomTablineBubbleEdge#',
        '%#CustomTablineBubbleLine# ',
        '%2l', -- Space-padded line number
        '%#CustomTablineBubbleSeparator# ✖ ',
        '%#CustomTablineBubbleColumn#',
        '%-2c', -- Space padded, right-aligned column number
        ' %#CustomTablineBubbleEdge#',
        '%#CustomTablineBubblePercentage# ',
        '%P', -- Space-padded line number
        '%#CustomTablineBubbleSeparator# ● ',
        '%#CustomTablineBubbleTotalLines#',
        '%L',
        ' %#CustomTablineBubbleEdge# ',
    }
end

function FiletypeAndDirectoryAndGit()
    local full_path = vim.fn.expand('%:p:h'):gsub(vim.fn.expand('~'), '~')
    local components = vim.split(full_path, '/')

    -- Get the direct parent directory
    local parent_dir = table.remove(components)

    -- Truncate each component to a maximum of three characters
    for i, component in ipairs(components) do
        components[i] = string.sub(component, 1, 3)
    end

    -- Add the direct parent directory back to the components
    table.insert(components, parent_dir)

    -- Reconstruct the truncated path
    local truncated_path = table.concat(components, '/')

    local git_info = vim.b.gitsigns_status_dict

    local git_info_or_end_bubble
    if not git_info or git_info.head == '' then
        git_info_or_end_bubble = ' %#CustomTablineBubbleEdge#'
    else
        git_info_or_end_bubble = ' %#CustomTablineBubbleEdge#%#CustomTablineBubbleGit# '..git_info.head..' %#CustomTablineBubbleEdge#'
    end

    return table.concat {
        '%#CustomTablineBubbleEdge#',
        '%#CustomTablineBubbleFiletype# ',
        vim.bo.filetype == '' and '-' or vim.bo.filetype,
        ' %#CustomTablineBubbleEdge#',
        '%#CustomTablineBubbleDirectory# ',
        truncated_path,
        git_info_or_end_bubble
    }
end

function Tabs()
    local selected_tabnr = vim.fn.tabpagenr()
    local total_tabs = vim.fn.tabpagenr('$')

    local tabs_string = ''
    local i = 1
    while i <= total_tabs do
        local buflist = vim.fn.tabpagebuflist(i)
        local winnr = vim.fn.tabpagewinnr(i)
        local file = vim.fn.fnamemodify(vim.fn.bufname(buflist[winnr]), ':p:t')
        if (file == '') then
            file = '[No Name]'
        end
        local tab_bubble, hi_label, hi_index
        if (i == selected_tabnr) then
            hi_index = '%#CustomTablineBubbleIndexSel#'
            if (vim.bo.modified) then
                hi_label = '%#CustomTablineBubbleLabelSelModified#'
            else
                hi_label = '%#CustomTablineBubbleLabelSel#'
            end
        else
            hi_index = '%#CustomTablineBubbleIndex#'
            hi_label = '%#CustomTablineBubbleLabel#'
        end

        tab_bubble = table.concat {
            '%'..i..'T', -- Start of clickable section for tab i
            '%#CustomTablineBubbleEdge#',
            hi_index..' '..i..' ',
            '%#CustomTablineBubbleEdge#',
            '%#CustomTablineBubbleEdge#',
            hi_label..' '..file..' ',
            '%#CustomTablineBubbleEdge#',
            '%X', -- End of clickable section
            ' ',
        }
        tabs_string = tabs_string..tab_bubble
        i = i + 1
    end
    return tabs_string
end

function CustomTabline()
    return table.concat {
        Tabs(),
        '%=', -- Switch to right side
        FiletypeAndDirectoryAndGit(),
        ' ',
        LineInfo(),
    }
end

-- Empty since all the info is in the tabline now
-- TODO Add LSP info in statusline at some point
function CustomStatusline()
    return ''
end

-- Since some of the displayed information does not update automatically in the
-- tabline, but only the statusline, we need to use this autocmd to update it
-- on relevant events
vim.api.nvim_create_autocmd({'CursorMoved', 'BufEnter'}, {
    callback = function()
        vim.api.nvim_command('redrawtabline')
    end,
})

vim.api.nvim_exec([[
    set tabline=%!v:lua.CustomTabline()
    set statusline=%!v:lua.CustomStatusline()
]], false)

vim.o.termguicolors = true

-- resize splits if window resized
vim.api.nvim_create_autocmd({ 'VimResized' }, {
    callback = function()
        local current_tab = vim.fn.tabpagenr()
        vim.cmd('tabdo wincmd =')
        vim.cmd('tabnext ' .. current_tab)
    end
})

-- wrap and spellcheck in text files
vim.api.nvim_create_autocmd({ 'VimResized' }, {
    callback = function()
        pattern = { 'text', 'plaintex', 'typst', 'gitcommit', 'markdown' }
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end
})

-- lsp
vim.lsp.config.clangd = {
    filetypes = { 'c', 'cpp', 'cc', 'h', 'hh', 'hpp' },
    cmd = { 'clangd', '--background-index' },
    root_markers = { '.git' },
}

vim.lsp.enable({ 'clangd' })

-- remove diagnostic signs to the left of the line number column
vim.diagnostic.config({ signs = false })

