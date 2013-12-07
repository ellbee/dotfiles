" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle
" required! 
Bundle 'gmarik/vundle'

Bundle 'davidhalter/jedi-vim'
Bundle 'klen/python-mode'
Bundle 'scrooloose/nerdcommenter'
Bundle 'scrooloose/nerdtree'
Bundle 'kien/ctrlp.vim'
Bundle 'bling/vim-airline'
Bundle 'tpope/vim-fugitive'
Bundle 'jakar/vim-json'
Bundle 'honza/vim-snippets'
Bundle 'tpope/vim-surround'
Bundle 'tpope/vim-unimpaired'
Bundle 'mattn/emmet-vim'
Bundle 'altercation/vim-colors-solarized'
Bundle 'marijnh/tern_for_vim'

"snipmate needs vim-addon-mw-utils and tlib_vim
Bundle 'garbas/vim-snipmate'
Bundle 'MarcWeber/vim-addon-mw-utils'
Bundle 'tomtom/tlib_vim'

filetype plugin indent on     " required!

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

map <leader>n :execute 'NERDTreeToggle ' . getcwd()<CR>
map <leader>. :nohlsearch<CR>
imap kj <Esc>

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

