" Allow full use of vim options
set nocompatible

" Enable Vundle if installed
if filereadable(glob("~/.vim/bundle/Vundle.vim/README.md"))
  filetype off
  set rtp+=~/.vim/bundle/Vundle.vim
  call vundle#begin()
  Plugin 'gmarik/Vundle.vim'
  Plugin 'eistaa/vim-flake8'
  Plugin 'tpope/vim-fugitive'
  Plugin 'mileszs/ack.vim'
  Plugin 'tpope/vim-unimpaired'
  Plugin 'scrooloose/syntastic'
  Plugin 'mattn/webapi-vim'
  Plugin 'mattn/gist-vim'
  Plugin 'fatih/vim-go'
  Plugin 'altercation/vim-colors-solarized'
  call vundle#end()
endif

" Setup paths
set backupdir=~/.cache/vim/backup//
set directory=~/.cache/vim/swap//
set undodir=~/.cache/vim/undo//
if !isdirectory($HOME . '/.cache/vim/swap')
  silent !mkdir -p ~/.cache/vim/{backup,swap,undo}
endif

" Make sure files get completely written, but don't write backups
set nobackup
set writebackup

" Whitespace/indent options
set autoindent
set copyindent
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set shiftround
set backspace=indent,eol,start
" Shift-tab to go backwards in insert mode
imap <S-Tab> <Esc><<A

" Line numbering, ruler
set number
set ruler
set cursorline

" File options
set encoding=utf-8
" Syntax highlighting, look and feel
syntax on
set background=dark
if has('gui_running')
  set guifont=Inconsolata\ 11
else
  let g:solarized_termcolors=256
endif
colorscheme solarized
" Enable filetype support
filetype plugin indent on
" Allow file modelines
set modeline
" Automatically re-read changed files
set autoread
" fsync() after writing files
set fsync
" Text width 80
set textwidth=80
" Write via sudo
cnoremap sudow w !sudo tee % >/dev/null

" Search options
set incsearch
set ignorecase
set smartcase
" Optional highlighting
nmap <leader>hs :set hlsearch! hlsearch?<CR>

" Toggle paste mode
nmap <silent> <F4> :set invpaste<CR>:set paste?<CR>
imap <silent> <F4> <ESC>:set invpaste<CR>:set paste?<CR>

" Mediocre Hex editing in vim
" Source: http://vim.wikia.com/wiki/Improved_hex_editing
" TODO: move to an include
nnoremap <C-H> :Hexmode<CR>
command -bar Hexmode call ToggleHex()
function ToggleHex()
  " hex mode should be considered a read-only operation
  " save values for modified and read-only for restoration later,
  " and clear the read-only flag for now
  let l:modified=&mod
  let l:oldreadonly=&readonly
  let &readonly=0
  let l:oldmodifiable=&modifiable
  let &modifiable=1
  if !exists("b:editHex") || !b:editHex
    " save old options
    let b:oldft=&ft
    let b:oldbin=&bin
    " set new options
    setlocal binary " make sure it overrides any textwidth, etc.
    let &ft="xxd"
    " set status
    let b:editHex=1
    " switch to hex editor
    %!xxd
  else
    " restore old options
    let &ft=b:oldft
    if !b:oldbin
      setlocal nobinary
    endif
    " set status
    let b:editHex=0
    " return to normal editing
    %!xxd -r
  endif
  " restore values for modified and read only state
  let &mod=l:modified
  let &readonly=l:oldreadonly
  let &modifiable=l:oldmodifiable
endfunction

" Options for syntastic
let g:syntastic_enable_signs = 1
let g:syntastic_auto_loc_list = 2
" Have F5 run the tests and display errors
nnoremap <silent> <F5> :SyntasticCheck<CR> :Errors<CR>

" Include a .vimrc.local if it exists
if filereadable(glob("~/.vimrc.local"))
  source ~/.vimrc.local
endif
