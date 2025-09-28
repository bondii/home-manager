{
  config,
  pkgs,
  lib,
  ...
}: let
  sharedMaps = ''
    " ~/.config/vim/shared-maps.vim

    " Set leader iff not already set (Nixvim sets it as well)
    if !exists('mapleader') | let mapleader = ' ' | endif
    if !exists('maplocalleader') | let maplocalleader = ' ' | endif

    " jk -> Esc (insert -> normal)
    inoremap jk <Esc>

    " Tab buffer jump
    nnoremap <Tab>   :bnext<CR>
    nnoremap <S-Tab> :bprevious<CR>
    " New empty buffer
    nnoremap <leader>T :enew<CR>
    " Close buffer, jump to previous
    nnoremap <leader>bq :bp <BAR> bd #<CR>
    " List buffers
    nnoremap <leader>bl :ls<CR>

    " Clear search highlight
    nnoremap <silent> <leader><space> :nohlsearch<Bar>:echo<CR>

    " Go to start of row
    nnoremap 00 ^

    " Reload config
    nnoremap <F2> :source $MYVIMRC<CR>
  '';
in {
  xdg.configFile."vim/shared-maps.vim".text = sharedMaps;
}
