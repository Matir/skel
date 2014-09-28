" Allow full use of vim options
set nocompatible

" Enable Vundle if installed
if filereadable(glob("~/.vim/bundle/Vundle.vim/README.md"))
  filetype off
  set rtp+=~/.vim/bundle/Vundle.vim
  call vundle#begin()
  Plugin 'gmarik/Vundle.vim'
  call vundle#end()
endif

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

" Mediocre Hex editing in vim
" Source: http://vim.wikia.com/wiki/Improved_hex_editing
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

" Include a .vimrc.local if it exists
if filereadable(glob("~/.vimrc.local"))
  source ~/.vimrc.local
endif
