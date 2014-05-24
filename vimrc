" Allow full use of vim options
set nocompatible
" Autoindentation 
set autoindent
" Use same indentation style as above file
set copyindent
" Proper tabs
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
" Display cursor position
set ruler
" Syntax highlighting and file types
syntax on
filetype plugin indent on
" Allow file modelines
set modeline
" Automatically re-read changed files
set autoread
" fsync() after writing files
set fsync
" Line numbering
set number
" Round indentation to multiple of shiftwidth
set shiftround
" Text width 80
set textwidth=80
" Write via sudo
cnoremap sudow w !sudo tee % >/dev/null
" Search options
set incsearch
set ignorecase
set smartcase
