" pathogen / plugin setup
execute pathogen#infect()
syntax on
filetype plugin indent on

" Show line numbers
set number
" Set tab width to 2
set tabstop=2

" autocmd vimenter * NERDTree
" automatically open nerdtree on start
"
" open nerdtree on start if no file specified
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
" Show files with Ctrl-n
map <C-n> :NERDTreeToggle<CR>

