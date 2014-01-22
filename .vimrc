" Use Vim settings, rather then Vi settings (much better!).
set nocompatible

set rtp+=~/.vim/bundle/neobundle.vim

call neobundle#rc(expand('~/.vim/bundle/'))

NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'Shougo/vimproc', {
            \ 'build' : {
            \     'windows' : 'make -f make_mingw32.mak',
            \     'cygwin' : 'make -f make_cygwin.mak',
            \     'mac' : 'make -f make_mac.mak',
            \     'unix' : 'make -f make_unix.mak',
            \    },
            \ }

"NeoBundle 'Shougo/unite.vim'
"NeoBundle 'Shougo/vimfiler.vim'
"NeoBundle 'Shougo/unite-outline'
"NeoBundle 'Shougo/unite-help'
"NeoBundle 'Shougo/unite-session'
"NeoBundle 'thinca/vim-unite-history'

NeoBundle 'sjl/clam.vim'
NeoBundle 'godlygeek/tabular'
NeoBundle 'davidhalter/jedi-vim'
NeoBundle 'scrooloose/nerdcommenter'
NeoBundle 'kien/ctrlp.vim'
NeoBundle 'bling/vim-airline'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'jakar/vim-json'
NeoBundle 'tpope/vim-surround'
NeoBundle 'tpope/vim-unimpaired'
NeoBundle 'mattn/emmet-vim'
NeoBundle 'altercation/vim-colors-solarized'
NeoBundle 'marijnh/tern_for_vim'
NeoBundle 'jnwhiteh/vim-golang'

"snipmate needs vim-addon-mw-utils and tlib_vim
NeoBundle 'garbas/vim-snipmate'
NeoBundle 'MarcWeber/vim-addon-mw-utils'
NeoBundle 'tomtom/tlib_vim'
NeoBundle 'honza/vim-snippets'

"NeoBundle 'klen/python-mode'

filetype plugin indent on     " required!

NeoBundleCheck

" Set augroup
augroup MyAutoCmd
  autocmd!
augroup END

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

"execute pathogen#infect()
"call pathogen#helptags()

if has("vms")
    set nobackup		" do not keep a backup file, use versions instead
else
    set backup		" keep a backup file
endif

set history=1000		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set incsearch		" do incremental searching
set shiftwidth=4
set ts=4
set number
set expandtab
set hidden
set laststatus=2
set cursorline
set scrolloff=3
set ignorecase
set smartcase
set winwidth=84
set showcmd
set showmatch
set switchbuf=useopen

set backupdir=~/.vim/backup/
set directory=~/.vim/swap/

let mapleader=","

" Useful shortcuts for working with splits
nnoremap <silent> <Leader>s :sp<cr>
nnoremap <silent> <Leader>v :vsp<cr>
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
map <S-up> <C-w>+
map <S-down> <C-w>-
map <S-left> <C-w><
map <S-right> <C-w>>
nnoremap <silent> <Leader>+ :exe "resize " . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "resize " . (winheight(0) * 2/3)<CR>
nnoremap <silent> <Leader>> :exe "vertical resize " . (winwidth(0) * 3/2)<CR>
nnoremap <silent> <Leader>< :exe "vertical resize " . (winwidth(0) * 2/3)<CR>

" Don't use Ex mode, use Q for formatting
map Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
    set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
    syntax on
    set hlsearch
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")

    " Enable file type detection.
    " Use the default filetype settings, so that mail gets 'tw' set to 72,
    " 'cindent' is on in C files, etc.
    " Also load indent files, to automatically do language-dependent indenting.
    filetype plugin indent on
    "turn off docstring window for jedi
    autocmd FileType python setlocal completeopt-=preview

    "Put these in an autocmd group, so that we can delete them easily.
    augroup vimrcEx
        au!

        " For all text files set 'textwidth' to 78 characters.
        autocmd FileType text setlocal textwidth=78

        " When editing a file, always jump to the last known cursor position.
        " Don't do it when the position is invalid or when inside an event handler
        " (happens when dropping a file on gvim).
        " Also don't do it when the mark is in the first line, that is the default
        " position when opening a file.
        autocmd BufReadPost *
                    \ if line("'\"") > 1 && line("'\"") <= line("$") |
                    \   exe "normal! g`\"" |
                    \ endif

    augroup END

else
    set autoindent		" always set autoindenting on

endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
    command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
                \ | wincmd p | diffthis
endif

map <leader>. :nohlsearch<CR>

syntax enable

if has('gui_running')
    set background=light
    set guifont=menlo\ regular:h13
    set timeout
    set timeoutlen=500
else
    set background=dark
endif
colorscheme solarized

"cmap cd. lcd %:p:h
"
"turn off auto syntax checking for html because it doesn't like Angular
let syntastic_mode_map = { 'passive_filetypes': ['html'] }

let g:user_zen_leader_key = '<c-m>'
set clipboard=unnamed

map <leader>m :CtrlPMRU<CR>
map <leader>g :CtrlPBuffer<CR>
"remove trailing whitespace
map <leader>w :%s/\s\+$//<CR>

let g:ctrlp_max_height = 30

"turn off most off of pymode by default
let g:pymode_rope = 0
let g:pymode_syntax = 0
let g:pymode_folding = 0
let g:pymode_rope_autocomplete_map = ""
let g:pymode_rope_vim_completion = 0
let g:pymode_lint=0
let g:pymode_options = 0

let g:jedi#show_call_signatures = 0
let g:jedi#goto_assignments_command = ''
let g:jedi#usages_command = '<leader><leader>n'
let g:jedi#popup_on_dot = 0
let g:jedi#show_call_signatures = 0

nmap <leader>r :call Ranger()<cr>

"===============================================================================
" Unite
"===============================================================================

" Use the fuzzy matcher for everything

"call unite#filters#matcher_default#use(['matcher_fuzzy'])
"" Use the rank sorter for everything
"call unite#filters#sorter_default#use(['sorter_rank'])

"" Set up some custom ignores
"call unite#custom_source('file_rec,file_rec/async,file_mru,file,buffer,grep',
      "\ 'ignore_pattern', join([
      "\ '\.git/',
      "\ 'git5/.*/review/',
      "\ 'google/obj/',
      "\ 'tmp/',
      "\ '.sass-cache',
      "\ ], '\|'))

"" Map space to the prefix for Unite
"nnoremap [unite] <Nop>
"nmap <space> [unite]

"" General fuzzy search
"nnoremap <silent> [unite]<space> :<C-u>Unite
      "\ -buffer-name=files buffer file_mru bookmark file_rec/async<CR>

"" Quick registers
"nnoremap <silent> [unite]r :<C-u>Unite -buffer-name=register register<CR>

"" Quick buffer and mru
"nnoremap <silent> [unite]u :<C-u>Unite -auto-resize -buffer-name=buffers buffer file_mru<CR>

"" Quick yank history
"nnoremap <silent> [unite]y :<C-u>Unite -buffer-name=yanks history/yank<CR>

"" Quick outline
"nnoremap <silent> [unite]o :<C-u>Unite -buffer-name=outline -vertical outline<CR>

"" Quick sessions (projects)
"nnoremap <silent> [unite]p :<C-u>Unite -buffer-name=sessions session<CR>

"" Quick sources
"nnoremap <silent> [unite]a :<C-u>Unite -buffer-name=sources source<CR>

"" Quick snippet
"nnoremap <silent> [unite]s :<C-u>Unite -buffer-name=snippets snippet<CR>

"" Quickly switch lcd
"nnoremap <silent> [unite]d
      "\ :<C-u>Unite -buffer-name=change-cwd -default-action=lcd directory_mru<CR>

"" Quick file search
"nnoremap <silent> [unite]f :<C-u>Unite -buffer-name=files file_rec/async file/new<CR>

"" Quick file search
"nnoremap <silent> [unite]q :<C-u>Unite -auto-resize file_rec/async<CR>

"" Quick grep from cwd
"nnoremap <silent> [unite]g :<C-u>Unite -buffer-name=grep grep:.<CR>

"" Quick help
"nnoremap <silent> [unite]h :<C-u>Unite -buffer-name=help help<CR>

"" Quick line using the word under cursor
"nnoremap <silent> [unite]l :<C-u>UniteWithCursorWord -buffer-name=search_file line<CR>

"" Quick MRU search
"nnoremap <silent> [unite]m :<C-u>Unite -buffer-name=mru file_mru<CR>

"" Quick find
"nnoremap <silent> [unite]n :<C-u>Unite -buffer-name=find find:.<CR>

"" Quick commands
"nnoremap <silent> [unite]c :<C-u>Unite -buffer-name=commands command<CR>

"" Quick bookmarks
"nnoremap <silent> [unite]b :<C-u>Unite -buffer-name=bookmarks bookmark<CR>

"" Fuzzy search from current buffer
"" nnoremap <silent> [unite]b :<C-u>UniteWithBufferDir
      "" \ -buffer-name=files -prompt=%\  buffer file_mru bookmark file<CR>

"" Quick commands
"nnoremap <silent> [unite]; :<C-u>Unite -buffer-name=history history/command command<CR>

"" Custom Unite settings
"autocmd MyAutoCmd FileType unite call s:unite_settings()
"function! s:unite_settings()

  "nmap <buffer> <ESC> <Plug>(unite_exit)
  "imap <buffer> <ESC> <Plug>(unite_exit)
  "" imap <buffer> <c-j> <Plug>(unite_select_next_line)
  "imap <buffer> <c-j> <Plug>(unite_insert_leave)
  "nmap <buffer> <c-j> <Plug>(unite_loop_cursor_down)
  "nmap <buffer> <c-k> <Plug>(unite_loop_cursor_up)
  "imap <buffer> <c-a> <Plug>(unite_choose_action)
  "imap <buffer> <Tab> <Plug>(unite_exit_insert)
  "imap <buffer> jj <Plug>(unite_insert_leave)
  "imap <buffer> <C-w> <Plug>(unite_delete_backward_word)
  "imap <buffer> <C-u> <Plug>(unite_delete_backward_path)
  "imap <buffer> '     <Plug>(unite_quick_match_default_action)
  "nmap <buffer> '     <Plug>(unite_quick_match_default_action)
  "nmap <buffer> <C-r> <Plug>(unite_redraw)
  "imap <buffer> <C-r> <Plug>(unite_redraw)
  "inoremap <silent><buffer><expr> <C-s> unite#do_action('split')
  "nnoremap <silent><buffer><expr> <C-s> unite#do_action('split')
  "inoremap <silent><buffer><expr> <C-v> unite#do_action('vsplit')
  "nnoremap <silent><buffer><expr> <C-v> unite#do_action('vsplit')

  "let unite = unite#get_current_unite()
  "if unite.buffer_name =~# '^search'
    "nnoremap <silent><buffer><expr> r     unite#do_action('replace')
  "else
    "nnoremap <silent><buffer><expr> r     unite#do_action('rename')
  "endif

  "nnoremap <silent><buffer><expr> cd     unite#do_action('lcd')

  "" Using Ctrl-\ to trigger outline, so close it using the same keystroke
  "if unite.buffer_name =~# '^outline'
    "imap <buffer> <C-\> <Plug>(unite_exit)
  "endif

  "" Using Ctrl-/ to trigger line, close it using same keystroke
  "if unite.buffer_name =~# '^search_file'
    "imap <buffer> <C-_> <Plug>(unite_exit)
  "endif
"endfunction

"" Start in insert mode
"let g:unite_enable_start_insert = 1

"" Enable short source name in window
"" let g:unite_enable_short_source_names = 1

"" Enable history yank source
"let g:unite_source_history_yank_enable = 1

"" Open in bottom right
""let g:unite_split_rule = "botright"

"" Shorten the default update date of 500ms
"let g:unite_update_time = 200

"let g:unite_source_file_mru_limit = 1000
"let g:unite_cursor_line_highlight = 'CursorLine'
 ""let g:unite_abbr_highlight = 'TabLine'

"let g:unite_source_file_mru_filename_format = ':~:.'
"let g:unite_source_file_mru_time_format = ''

"" For ack.
"if executable('ack-grep')
  "let g:unite_source_grep_command = 'ack-grep'
  "" Match whole word only. This might/might not be a good idea
  "let g:unite_source_grep_default_opts = '--no-heading --no-color -a -w'
  "let g:unite_source_grep_recursive_opt = ''
"elseif executable('ack')
  "let g:unite_source_grep_command = 'ack'
  "let g:unite_source_grep_default_opts = '--no-heading --no-color -a -w'
  "let g:unite_source_grep_recursive_opt = ''
"endif

"nmap <leader>m [unite]u
"nmap <leader>y [unite]y

"nnoremap <leader>c :Unite colorscheme -auto-preview<cr>
