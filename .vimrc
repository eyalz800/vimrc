function! InstallVimrc()
    if empty($SUDO_USER)
        echo "Please run as sudo."
        exec ":q"
    endif
    if !executable('brew')
        silent !DEBIAN_FRONTEND=noninteractive apt install -y curl silversearcher-ag exuberant-ctags cscope global git clang-tools-8 make autoconf automake pkg-config libc++-8-dev openjdk-8-jre python3 python-pip python3-pip gdb
        silent exec "!curl -sL https://deb.nodesource.com/setup_10.x | bash -"
        silent !DEBIAN_FRONTEND=noninteractive apt install -y nodejs
        silent !update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-8 800
    else
        silent !sudo -u $SUDO_USER brew install curl ag ctags cscope global git llvm make autoconf automake pkg-config python3 nodejs gnu-sed
        silent !sudo -u $SUDO_USER brew link python3
        silent !sudo -u $SUDO_USER brew tap AdoptOpenJDK/openjdk
        silent !sudo -u $SUDO_USER brew cask install adoptopenjdk8
        silent !sudo -u $SUDO_USER curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        silent !sudo -u $SUDO_USER python get-pip.py
        silent !sudo -u $SUDO_USER python3 get-pip.py
        if !executable('clangd')
            silent exec "!echo export PATH=\\$PATH:/usr/local/opt/llvm/bin >> ~/.bashrc"
        endif
    endif
    if executable('pip')
        silent !pip install python-language-server pylint compiledb setuptools
    elseif executable('python')
        silent !sudo -u $SUDO_USER python -m pip install python-language-server pylint compiledb setuptools
    endif
    if executable('pip3')
        silent !pip3 install python-language-server pylint compiledb setuptools
    elseif executable('python3')
        silent !sudo -u $SUDO_USER python3 -m pip install python-language-server pylint compiledb setuptools
    endif
    silent !mkdir -p ~/.vim
    silent !mkdir -p ~/.vim/tmp
    silent !mkdir -p ~/.config
    silent !mkdir -p ~/.config/coc
    if !filereadable($HOME . '/.vim/autoload/plug.vim')
        silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
          \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    endif
    if !filereadable($HOME .'/.vim/bin/opengrok/lib/opengrok.jar')
        silent !curl -fLo ~/.vim/bin/opengrok.tar.gz --create-dirs
          \ https://github.com/oracle/opengrok/releases/download/1.0/opengrok-1.0.tar.gz
        silent exec "!cd ~/.vim/bin; tar -xzvf opengrok.tar.gz"
        silent !rm ~/.vim/bin/opengrok.tar.gz
        silent !mv ~/.vim/bin/opengrok* ~/.vim/bin/opengrok
    endif
    if !filereadable($HOME . '/.vim/tmp/ctags/Makefile')
        silent exec "!cd ~/.vim/tmp; git clone https://github.com/universal-ctags/ctags.git; cd ./ctags; ./autogen.sh; ./configure; make; make install"
    endif
    if !executable('ctags-exuberant') && !filereadable('~/.vim/bin/ctags-exuberant/ctags/ctags')
        silent !curl -fLo ~/.vim/bin/ctags-exuberant/ctags.tar.gz --create-dirs
          \ http://prdownloads.sourceforge.net/ctags/ctags-5.8.tar.gz
        silent exec "!cd ~/.vim/bin/ctags-exuberant; tar -xzvf ctags.tar.gz"
        silent exec "!mv ~/.vim/bin/ctags-exuberant/ctags-5.8 ~/.vim/bin/ctags-exuberant/ctags"
        silent exec "!cd ~/.vim/bin/ctags-exuberant/ctags; ./configure; make"
    endif
    if !filereadable($HOME . '/.vim/bin/lf/lf')
        if !executable('brew')
            silent !curl -fLo ~/.vim/bin/lf/lf.tar.gz --create-dirs
              \ https://github.com/gokcehan/lf/releases/download/r16/lf-linux-amd64.tar.gz
        else
            silent !curl -fLo ~/.vim/bin/lf/lf.tar.gz --create-dirs
              \ https://github.com/gokcehan/lf/releases/download/r16/lf-darwin-amd64.tar.gz
        endif
        silent exec "!cd ~/.vim/bin/lf; tar -xzvf lf.tar.gz"
    endif
    silent !chown -R $SUDO_USER:$SUDO_GID ~/.vim
    silent !chown -R $SUDO_USER:$SUDO_GID ~/.vim/tmp
    silent !chown -R $SUDO_USER:$SUDO_GID ~/.config
    silent !chown -R $SUDO_USER:$SUDO_GID ~/.cache
    silent !chown $SUDO_USER:$SUDO_GID ~/.vimrc
    silent !sudo -u $SUDO_USER INSTALL_VIMRC_PLUGINS=1 INSTALL_VIMRC= vim +qa
    silent !sudo -u $SUDO_USER python3 ~/.vim/plugged/vimspector/install_gadget.py --sudo --enable-c --enable-python
    call CustomizePlugins()
endfunction

let s:sed = 'sed'
if executable('brew')
    let s:sed = 'gsed'
endif

function! CustomizePlugins()
    silent exec "!" . s:sed . " -i 's/ autochdir/ noautochdir/' ~/.vim/plugged/SrcExpl/plugin/srcexpl.vim"
    silent exec "!" . s:sed . " -i 's@ . redraw\\!@ . \" > /dev/null\"@' ~/.vim/plugged/cscope_dynamic/plugin/cscope_dynamic.vim"
    silent exec "!" . s:sed . " -i 's@silent execute \"perl system.*@silent execute \"\\!\" . a:cmd . \" > /dev/null\"@' ~/.vim/plugged/cscope_dynamic/plugin/cscope_dynamic.vim"
    silent exec "!" . s:sed . " -i \"s/'String',[ \\t]*s:green/'String', \\['\\#d78787', 174\\]/\" ~/.vim/plugged/gruvbox/colors/gruvbox.vim"
    silent exec "!" . s:sed . " -i \"s/'String',[ \\t]*s:gb\.green/'String', \\['\\#d78787', 174\\]/\" ~/.vim/plugged/gruvbox/colors/gruvbox.vim"
    silent exec "!" . s:sed . " -i 's/s:did_snips_mappings/g:did_snips_mappings/' ~/.vim/plugged/snipMate-acp/after/plugin/snipMate.vim"
endfunction

if !empty($INSTALL_VIMRC)
    call InstallVimrc()
    exec ":q"
endif

let g:lsp_choice = 'coc'
if filereadable($HOME . '/.vim/.nococ')
    let g:lsp_choice = 'vim-lsp'
endif

nnoremap <silent> <leader>tl :call ToggleLspPersistent()<CR>:source ~/.vimrc<CR>
function! ToggleLspPersistent()
    if filereadable($HOME . "/.vim/.nococ")
        call system("rm ~/.vim/.nococ")
    else
        call system("touch ~/.vim/.nococ")
    endif
endfunction

call plug#begin()
Plug 'puremourning/vimspector'
Plug 'wesleyche/SrcExpl'
Plug 'vim-scripts/taglist.vim'
Plug 'preservim/nerdtree'
Plug 'wesleyche/Trinity'
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'tomtom/tlib_vim'
Plug 'rdolgushin/snipMate-acp'
Plug 'ludovicchabant/vim-gutentags'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'vim-scripts/a.vim'
Plug 'ervandew/supertab'
Plug 'vim-airline/vim-airline'
Plug 'skywind3000/asyncrun.vim'
Plug 'justinmk/vim-sneak'
Plug 'tmsvg/pear-tree'
Plug 'majutsushi/tagbar'
Plug 'terryma/vim-multiple-cursors'
Plug 'gruvbox-community/gruvbox'
Plug 'vim-scripts/TagHighlight'
Plug 'erig0/cscope_dynamic'
Plug 'octol/vim-cpp-enhanced-highlight'
Plug 'airblade/vim-gitgutter'
Plug 'gotcha/vimpdb'
Plug 'tpope/vim-fugitive'
if !empty($INSTALL_VIMRC_PLUGINS) || g:lsp_choice == 'vim-lsp'
    Plug 'prabirshrestha/async.vim'
    Plug 'prabirshrestha/vim-lsp'
    Plug 'prabirshrestha/asyncomplete.vim'
    Plug 'prabirshrestha/asyncomplete-lsp.vim'
    Plug 'prabirshrestha/asyncomplete-tags.vim'
endif
if !empty($INSTALL_VIMRC_PLUGINS) || g:lsp_choice == 'coc'
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
endif
if g:lsp_choice != 'coc'
    Plug 'vim-scripts/AutoComplPop'
    Plug 'vim-scripts/OmniCppComplete'
endif
Plug 'mbbill/undotree'
Plug 'thezeroalpha/vim-lf'
Plug 'tpope/vim-commentary'
Plug 'bfrg/vim-cpp-modern'
Plug 'tomasiser/vim-code-dark'
Plug 'joeytwiddle/sexy_scroller.vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'troydm/zoomwintab.vim'
Plug 'wincent/terminus'
Plug 'jreybert/vimagit'
call plug#end()

if !empty($INSTALL_VIMRC_PLUGINS)
    let g:coc_disable_startup_warning = 1
    if $INSTALL_VIMRC_PLUGINS != 'post'
        exec ":PlugInstall --sync"
        silent !INSTALL_VIMRC_PLUGINS=post vim +'CocInstall -sync coc-json coc-clangd coc-sh coc-python coc-vimlsp' +qa
        exec ":q"
    endif
endif

" Generic
syntax on
filetype plugin indent on
nnoremap <silent> ` :noh<CR>
set expandtab
set ignorecase
set smartcase
set nocompatible
set shellslash
set autoindent
autocmd filetype cpp setlocal cindent
autocmd filetype c setlocal cindent
set cinoptions=g0N-s
set backspace=indent,eol,start
set ruler
set showcmd
set incsearch
set hlsearch
set shiftwidth=4
set tabstop=4
set cmdheight=1
set number
set wildmode=list:longest,full
set completeopt=longest,menuone,preview
set nowrap
nnoremap <C-q> <C-v>
set shellslash
map <C-w>w :q<CR>
autocmd filetype make setlocal noexpandtab autoindent
noremap <F1> <C-w><C-p>
noremap <F2> <C-w><C-w>
noremap <F6> :bp<CR>
noremap <F7> :bn<CR>
set noerrorbells visualbell t_vb=

" Gui colors
if has('termguicolors') && !filereadable($HOME . "/.vim/.notermguicolors")
    set termguicolors
endif
nnoremap <leader>tg :call ToggleGuiColorsPersistent()<CR>
function! ToggleGuiColorsPersistent()
    if has('termguicolors')
        if filereadable($HOME . "/.vim/.notermguicolors")
            call system("rm ~/.vim/.notermguicolors")
            set termguicolors
        else
            call system("touch ~/.vim/.notermguicolors")
            set notermguicolors
        endif
    endif
endfunction

" Mouse
set mouse=a
if has('mouse_sgr')
    set ttymouse=sgr
else
    set ttymouse=xterm2
endif
nnoremap <silent> <leader>zm :call ZToggleMouse()<CR>

" Sign column
set signcolumn=yes

" Updatetime
set updatetime=300
set shortmess+=c

" Set path
let $PATH .= ':' . $HOME . '/.vim/bin/lf'
if !executable('clangd') && filereadable('/usr/local/opt/llvm/bin/clangd')
    let $PATH .= ':/usr/local/opt/llvm/bin'
endif

" Ignore no write since last change errors
set hidden

" Pasting
noremap <F5> :set nu!<CR>:set paste!<CR>i

" Resize splits
nnoremap <silent> L :vertical resize +1<CR>
nnoremap <silent> H :vertical resize -1<CR>
nnoremap <silent> <C-w>= :resize +1<CR>

" Zoom
noremap <silent> <C-w>z :ZoomWinTabToggle<CR>

" Generation Parameters
let g:ctagsFilePatterns = '\.c$|\.cc$|\.cpp$|\.cxx$|\.h$|\.hh$|\.hpp$'
let g:opengrokFilePatterns = "-I '*.cpp' -I '*.c' -I '*.cc' -I '*.cxx' -I '*.h' -I '*.hh' -I '*.hpp' -I '*.S' -I '*.s' -I '*.asm' -I '*.py' -I '*.java' -I '*.cs' -I '*.mk' -I '*.te' -I makefile -I Makefile"
let g:otherFilePatterns = '\.py$|\.te$|\.S$|\.asm$|\.mk$|\.md$makefile$|Makefile'
let g:ctagsOptions = '--languages=C,C++ --c++-kinds=+p --fields=+iaS --extra=+q --sort=foldcase --tag-relative'
let g:ctagsEverythingOptions = '--c++-kinds=+p --fields=+iaS --extra=+q --sort=foldcase --tag-relative'

" Generate All
nnoremap <silent> <leader>zg :call ZGenerateAll()<CR>
nnoremap <silent> <leader>zG :call ZGenerateEverything()<CR>

" Generate Tags and Cscope Files
nnoremap <silent> <leader>zt :call ZGenTagsAndCsFiles()<CR>

" Generate C++
nnoremap <silent> <leader>zp :call ZGenerateCpp()<CR>
nnoremap <silent> <leader>zP :call ZGenerateTagsBasedCpp()<CR>
nnoremap <silent> <leader>zc :call ZGenerateCppScope()<CR>

" Generate Flags
nnoremap <silent> <leader>zf :call ZGenerateFlags()<CR>

" Generate Opengrok
nnoremap <silent> <leader>zk :call ZGenerateOpengrok()<CR>

" Terminal
nnoremap <silent> <leader>zb :below terminal ++rows=10<CR>
nnoremap <silent> <leader>zB :below terminal ++rows=20<CR>

" Vim-better-whitespace
nnoremap <silent> <leader>zw :StripWhitespace<CR>
nnoremap <silent> <leader>zW :ToggleWhitespace<CR>

" Sexy Scroller
let g:SexyScroller_MaxTime = 250
let g:SexyScroller_EasingStyle = 2
let g:SexyScroller_ScrollTime = 5
let g:SexyScroller_CursorTime = 5
nnoremap <silent> <leader>zx :SexyScrollerToggle<CR>

" Lf
" The use of timer_start is a workaround that the lsp does not detect the file
" after open.
nmap <silent> <leader>fe :LF %:p call\ timer_start(0,{tid->execute('e!')})\|n<CR>
nmap <silent> <leader>fs :LF %:p call\ timer_start(0,{tid->execute('e!')})\|vs<CR>

" Opengrok
let g:opengrok_jar = '~/.vim/bin/opengrok/lib/opengrok.jar'
if executable('ctags-exuberant')
    let g:opengrok_ctags = '/usr/bin/ctags-exuberant'
else
    let g:opengrok_ctags = '~/.vim/bin/ctags-exuberant/ctags/ctags'
endif

" VimClang
let g:clang_c_options = '-std=c11'
let g:clang_cpp_options = '-std=c++17 -stdlib=libc++'

let g:vimroot=$PWD
function! ZSwitchToRoot()
    execute "cd " . g:vimroot
endfunction
nnoremap <silent> <leader>zr :call ZSwitchToRoot()<CR>

" Trinity
"nnoremap <C-L> :TrinityToggleNERDTree<CR>:TrinityToggleTagList<CR>
nnoremap <silent> <leader>zs :TrinityToggleSourceExplorer<CR>
nnoremap <silent> <C-w>e :TrinityUpdateWindow<CR>

" NERDTree and TagBar
let g:NERDTreeWinSize = 23
let g:NERDTreeAutoCenter = 0
let g:tagbar_width=23
nnoremap <silent> <C-l> :NERDTreeToggle<CR>:wincmd w<CR>:TagbarToggle<CR>
nnoremap <silent> <leader>nf :NERDTreeFind<CR>

" Ctrlp
let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

" Acp snipmate length
let g:did_snips_mappings = 1
let g:acp_behaviorSnipmateLength = 1

" Git
nnoremap <silent> <leader>gb :Git blame<CR>
nnoremap <silent> <leader>gm :Magit<CR>

" GutenTags
let g:gutentags_modules = ['ctags', 'gtags_cscope']
let g:gutentags_plus_nomap = 1
let g:gutentags_cache_dir = expand('~/.vim/tmp/tags')

noremap <silent> <leader>gs :GscopeFind s <C-R><C-W><cr>
noremap <silent> <leader>gg :GscopeFind g <C-R><C-W><cr>
noremap <silent> <leader>gc :GscopeFind c <C-R><C-W><cr>
noremap <silent> <leader>gt :GscopeFind t <C-R><C-W><cr>
noremap <silent> <leader>ge :GscopeFind e <C-R><C-W><cr>
noremap <silent> <leader>gf :GscopeFind f <C-R>=expand("<cfile>")<cr><cr>
noremap <silent> <leader>gi :GscopeFind i <C-R>=expand("<cfile>")<cr><cr>
noremap <silent> <leader>gd :GscopeFind d <C-R><C-W><cr>
noremap <silent> <leader>ga :GscopeFind a <C-R><C-W><cr>

" Gruvbox
let g:gruvbox_contrast_datk = 'medium'
color gruvbox

" Color
color codedark

" Fzf
let $FZF_DEFAULT_COMMAND = "if [ -f .files ]; then cat .files; else ag -l; fi"
set rtp+=~/.fzf
nnoremap <silent> <C-p> :call ZSwitchToRoot()<CR>:Files<CR>
nnoremap <silent> <C-n> :call ZSwitchToRoot()<CR>:Tags<CR>
nnoremap <silent> <leader>b :Buf<CR>
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'SpecialKey'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'String'],
  \ 'info':    ['fg', 'Comment'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'StorageClass'],
  \ 'pointer': ['fg', 'Error'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

" Sneak
let g:sneak#use_ic_scs = 1
let g:sneak#s_next = 1

" Cscope
let g:cscopedb_big_file = 'cscope.out'
let g:cscopedb_small_file = 'cscope_small.out'
let g:cscopedb_auto_files = 0

" Multi Cursor
let g:multi_cursor_use_default_mapping = 0
let g:multi_cursor_start_word_key      = '<C-k>'
"let g:multi_cursor_select_all_word_key = '<A-k>'
let g:multi_cursor_start_key           = 'g<C-k>'
"let g:multi_cursor_select_all_key      = 'g<A-k>'
let g:multi_cursor_next_key            = '<C-k>'
let g:multi_cursor_prev_key            = '<C-e>'
let g:multi_cursor_skip_key            = '<C-x>'
let g:multi_cursor_quit_key            = '<Esc>'

" Cpp Highlight
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_experimental_template_highlight = 1

" QuickFix
nnoremap <C-w>p :copen<CR>

" In some windows machines this prevents launching in REPLACE mode.
set t_u7=

" Undo Tree
nnoremap <silent> <leader>zu :UndotreeToggle<cr>

" Cscope
nnoremap <silent> <leader>cA :call Cscope('9', expand('<cword>'))<CR>
nnoremap <silent> <leader>cC :call Cscope('3', expand('<cword>'))<CR>
nnoremap <silent> <leader>cD :call Cscope('2', expand('<cword>'))<CR>
nnoremap <silent> <leader>cE :call Cscope('6', expand('<cword>'))<CR>
nnoremap <silent> <leader>cF :call Cscope('7', expand('<cword>'))<CR>
nnoremap <silent> <leader>cG :call Cscope('1', expand('<cword>'))<CR>
nnoremap <silent> <leader>cI :call Cscope('8', expand('<cword>'))<CR>
nnoremap <silent> <leader>cS :call Cscope('0', expand('<cword>'))<CR>
nnoremap <silent> <leader>cT :call Cscope('4', expand('<cword>'))<CR>
nnoremap <silent> <leader><leader>fA :call CscopeQuery('9')<CR>
nnoremap <silent> <leader><leader>fC :call CscopeQuery('3')<CR>
nnoremap <silent> <leader><leader>fD :call CscopeQuery('2')<CR>
nnoremap <silent> <leader><leader>fE :call CscopeQuery('6')<CR>
nnoremap <silent> <leader><leader>fF :call CscopeQuery('7')<CR>
nnoremap <silent> <leader><leader>fG :call CscopeQuery('1')<CR>
nnoremap <silent> <leader><leader>fI :call CscopeQuery('8')<CR>
nnoremap <silent> <leader><leader>fS :call CscopeQuery('0')<CR>
nnoremap <silent> <leader><leader>cT :call CscopeQuery('4')<CR>
nnoremap <silent> <leader><leader>cA :call CscopeQuery('9', 1)<CR>
nnoremap <silent> <leader><leader>cC :call CscopeQuery('3', 1)<CR>
nnoremap <silent> <leader><leader>cD :call CscopeQuery('2', 1)<CR>
nnoremap <silent> <leader><leader>cE :call CscopeQuery('6', 1)<CR>
nnoremap <silent> <leader><leader>cF :call CscopeQuery('7', 1)<CR>
nnoremap <silent> <leader><leader>cG :call CscopeQuery('1', 1)<CR>
nnoremap <silent> <leader><leader>cI :call CscopeQuery('8', 1)<CR>
nnoremap <silent> <leader><leader>cS :call CscopeQuery('0', 1)<CR>
nnoremap <silent> <leader><leader>cT :call CscopeQuery('4', 1)<CR>

nnoremap <silent> <leader>ca :call CscopePreview('9', expand('<cword>'))<CR>
nnoremap <silent> <leader>cc :call CscopePreview('3', expand('<cword>'))<CR>
nnoremap <silent> <leader>cd :call CscopePreview('2', expand('<cword>'))<CR>
nnoremap <silent> <leader>ce :call CscopePreview('6', expand('<cword>'))<CR>
nnoremap <silent> <leader>cf :call CscopePreview('7', expand('<cword>'))<CR>
nnoremap <silent> <leader>cg :call CscopePreview('1', expand('<cword>'))<CR>
nnoremap <silent> <leader>ci :call CscopePreview('8', expand('<cword>'))<CR>
nnoremap <silent> <leader>cs :call CscopePreview('0', expand('<cword>'))<CR>
nnoremap <silent> <leader>ct :call CscopePreview('4', expand('<cword>'))<CR>
nnoremap <silent> <leader><leader>fa :call CscopeQueryPreview('9')<CR>
nnoremap <silent> <leader><leader>fc :call CscopeQueryPreview('3')<CR>
nnoremap <silent> <leader><leader>fd :call CscopeQueryPreview('2')<CR>
nnoremap <silent> <leader><leader>fe :call CscopeQueryPreview('6')<CR>
nnoremap <silent> <leader><leader>ff :call CscopeQueryPreview('7')<CR>
nnoremap <silent> <leader><leader>fg :call CscopeQueryPreview('1')<CR>
nnoremap <silent> <leader><leader>fi :call CscopeQueryPreview('8')<CR>
nnoremap <silent> <leader><leader>fs :call CscopeQueryPreview('0')<CR>
nnoremap <silent> <leader><leader>ct :call CscopeQueryPreview('4')<CR>
nnoremap <silent> <leader><leader>ca :call CscopeQueryPreview('9', 1)<CR>
nnoremap <silent> <leader><leader>cc :call CscopeQueryPreview('3', 1)<CR>
nnoremap <silent> <leader><leader>cd :call CscopeQueryPreview('2', 1)<CR>
nnoremap <silent> <leader><leader>ce :call CscopeQueryPreview('6', 1)<CR>
nnoremap <silent> <leader><leader>cf :call CscopeQueryPreview('7', 1)<CR>
nnoremap <silent> <leader><leader>cg :call CscopeQueryPreview('1', 1)<CR>
nnoremap <silent> <leader><leader>ci :call CscopeQueryPreview('8', 1)<CR>
nnoremap <silent> <leader><leader>cs :call CscopeQueryPreview('0', 1)<CR>
nnoremap <silent> <leader><leader>ct :call CscopeQueryPreview('4', 1)<CR>

function! Cscope(option, query, ...)
    let l:ignorecase = get(a:, 1, 0)
    if l:ignorecase
        let realoption = "C" . a:option
    else
        let realoption = a:option
    endif

    let color = '{ x = $1; $1 = ""; z = $3; $3 = ""; printf "\033[36m%s\033[0m:\033[36m%s\033[0m\011\033[37m%s\033[0m\n", x,z,$0; }'
    let opts = {
    \ 'source':  "cscope -dL" . realoption . " " . shellescape(a:query) . " | awk '"
    \            . color . "' && cscope -f cscope_small.out -dL" . realoption . " " . a:query . " | awk '" . color . "'",
    \ 'options': ['--ansi', '--prompt', '> ',
    \             '--multi', '--bind', 'alt-a:select-all,alt-d:deselect-all'],
    \ 'down': '40%'
    \ }

    function! opts.sink(lines)
        let data = split(a:lines)
        let file = split(data[0], ":")
        execute 'e ' . '+' . file[1] . ' ' . file[0]
    endfunction
    call fzf#run(opts)
endfunction

function! CscopePreview(option, query, ...)
    let l:ignorecase = get(a:, 1, 0)
    if l:ignorecase
      let realoption = "C" . a:option
    else
      let realoption = a:option
    endif
    let awk_program =
        \    '{ x = $1; $1 = ""; z = $3; $3 = ""; ' .
        \    'printf "%s:%s:%s\n", x,z,$0; }'
    let grep_command =
        \    'cscope -dL' . realoption . " " . shellescape(a:query) .
        \    " | awk '" . awk_program . "'"
    let fzf_color_option = split(fzf#wrap()['options'])[0]
    let opts = { 'options': fzf_color_option . ' --prompt "> "'}
    call fzf#vim#grep(grep_command, 0, fzf#vim#with_preview(opts), 0)
endfunction

function! CscopeQuery(option, ...)
  call inputsave()
  if a:option == '9'
    let query = input('Assignments to: ')
  elseif a:option == '3'
    let query = input('Functions calling: ')
  elseif a:option == '2'
    let query = input('Functions called by: ')
  elseif a:option == '6'
    let query = input('Egrep: ')
  elseif a:option == '7'
    let query = input('File: ')
  elseif a:option == '1'
    let query = input('Definition: ')
  elseif a:option == '8'
    let query = input('Files #including: ')
  elseif a:option == '0'
    let query = input('Symbol: ')
  elseif a:option == '4'
    let query = input('Text: ')
  else
    echo "Invalid option!"
    return
  endif
  call inputrestore()
  if query != ""
    let l:ignorecase = get(a:, 1, 0)
    if l:ignorecase
      call Cscope(a:option, query, 1)
    else
      call Cscope(a:option, query)
    endif
  else
    echom "Cancelled Search!"
  endif
endfunction

function! CscopeQueryPreview(option, ...)
  call inputsave()
  if a:option == '9'
    let query = input('Assignments to: ')
  elseif a:option == '3'
    let query = input('Functions calling: ')
  elseif a:option == '2'
    let query = input('Functions called by: ')
  elseif a:option == '6'
    let query = input('Egrep: ')
  elseif a:option == '7'
    let query = input('File: ')
  elseif a:option == '1'
    let query = input('Definition: ')
  elseif a:option == '8'
    let query = input('Files #including: ')
  elseif a:option == '0'
    let query = input('Symbol: ')
  elseif a:option == '4'
    let query = input('Text: ')
  else
    echo "Invalid option!"
    return
  endif
  call inputrestore()
  if query != ""
    let l:ignorecase = get(a:, 1, 0)
    if l:ignorecase
      call CscopePreview(a:option, query, 1)
    else
      call CscopePreview(a:option, query)
    endif
  else
    echom "Cancelled Search!"
  endif
endfunction

" Opengrok Search
nnoremap <silent> <leader>zo :call OgQueryPreview('f', expand('<cword>'))<CR>
nnoremap <silent> <leader><leader>zo :call OgQueryPreview('f', input('Text: '))<CR>
nnoremap <silent> <leader>zO :call OgQuery('f', expand('<cword>'))<CR>
nnoremap <silent> <leader><leader>zO :call OgQuery('f', input('Text: '))<CR>

function! OgQuery(option, query, ...)
    let opts = {
    \ 'source': "java -Xmx2048m -cp ~/.vim/bin/opengrok/lib/opengrok.jar org.opensolaris.opengrok.search.Search -R .opengrok/configuration.xml -" .
    \           a:option . " " . a:query . "| grep \"^/.*\" | " . s:sed . " 's@</\\?.>@@g' | " . s:sed . " 's/&amp;/\\&/g' | " . s:sed . " 's/-\&gt;/->/g'",
    \ 'options': ['--ansi', '--prompt', '> ',
    \             '--multi', '--bind', 'alt-a:select-all,alt-d:deselect-all'],
    \ 'down': '40%'
    \ }

    function! opts.sink(lines)
        let data = split(a:lines)
        let file = split(data[0], ":")
        execute 'e ' . '+' . file[1] . ' ' . file[0]
    endfunction
    call fzf#run(opts)
endfunction

function! OgQueryPreview(option, query, ...)
    let awk_program =
        \    '{ x = $1; $1 = ""; z = $3; $3 = ""; ' .
        \    'printf "%s:%s:%s\n", x,z,$0; }'
    let grep_command =
        \    "java -Xmx2048m -cp ~/.vim/bin/opengrok/lib/opengrok.jar org.opensolaris.opengrok.search.Search -R .opengrok/configuration.xml -" .
        \    a:option . " " . shellescape(a:query) . "| grep \"^/.*\" | " . s:sed . " 's@</\\?.>@@g' | " . s:sed . " 's/&amp;/\\&/g' | " . s:sed . " 's/-\&gt;/->/g'" .
        \    " | awk '" . awk_program . "'"
    let fzf_color_option = split(fzf#wrap()['options'])[0]
    let opts = { 'options': fzf_color_option . ' --prompt "> "'}
    call fzf#vim#grep(grep_command, 0, fzf#vim#with_preview(opts), 0)
endfunction

" Cursor Line
highlight CursorLine ctermbg=235 guibg=#2b2b2b
set cursorline

" Lsp usage
let g:use_clangd_lsp = 1
if !executable('clangd')
    let g:use_clangd_lsp = 0
endif

let g:use_pyls_lsp = 1
if !executable('pyls')
    let g:use_pyls_lsp = 0
endif

" vim-lsp configuration
if g:lsp_choice == 'vim-lsp'
    let g:asyncomplete_remove_duplicates = 1
    let g:asyncomplete_smart_completion = 1

    inoremap <silent> <C-@> <plug>(asyncomplete_force_refresh)

    highlight clear LspWarningLine
    highlight clear LspErrorHighlight
    highlight link LspErrorText GruvboxRedSign
    nnoremap <silent> <leader>ld :LspDocumentDiagnostics<CR>
    nnoremap <silent> <leader>lh :highlight link LspErrorHighlight Error<CR>
    nnoremap <silent> <leader>ln :highlight link LspErrorHighlight None<CR>

    " clangd
    if g:use_clangd_lsp
        augroup lsp_clangd
            autocmd!
            autocmd User lsp_setup call lsp#register_server({
                        \ 'name': 'clangd',
                        \ 'cmd': {server_info->['clangd']},
                        \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp'],
                        \ })
        augroup end
    endif

    " pyls
    if g:use_pyls_lsp
        augroup lsp_pyls
            autocmd!
            autocmd User lsp_setup call lsp#register_server({
                        \ 'name': 'pyls',
                        \ 'cmd': {server_info->['pyls']},
                        \ 'whitelist': ['python'],
                        \ 'workspace_config': {'pyls': {'plugins': {'pydocstyle': {'enabled': v:true}}}}
                        \ })
        augroup end
    endif

    function! s:on_lsp_buffer_enabled() abort
        setlocal omnifunc=lsp#complete
        if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
        nmap <silent> <buffer> gd <plug>(lsp-definition)
        nmap <silent> <buffer> gr <plug>(lsp-references)
        nmap <silent> <buffer> gi <plug>(lsp-implementation)
        nmap <silent> <buffer> gy <plug>(lsp-type-definition)
        nmap <silent> <buffer> <leader>rn <plug>(lsp-rename)
        nmap <silent> <buffer> [g <plug>(lsp-previous-diagnostic)
        nmap <silent> <buffer> ]g <plug>(lsp-next-diagnostic)
        nmap <silent> <buffer> K <plug>(lsp-hover)
    endfunction
    inoremap <silent> <expr> <CR> pumvisible() ? asyncomplete#close_popup() . "\<CR>" : "\<CR>"

    augroup lsp_install
        au!
        " call s:on_lsp_buffer_enabled only for languages that has the server registered.
        autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
    augroup end
endif

" Coc
if g:lsp_choice == 'coc'
    let g:coc_global_extensions = ['coc-clangd', 'coc-python', 'coc-json', 'coc-sh', 'coc-vimlsp']
    nmap <silent> gd <Plug>(coc-definition)
    nmap <silent> gy <Plug>(coc-type-definition)
    nmap <silent> gi <Plug>(coc-implementation)
    nmap <silent> gr <Plug>(coc-references)
    nnoremap <silent> K :call <SID>show_documentation()<CR>
    nmap <silent> [g <Plug>(coc-diagnostic-prev)
    nmap <silent> ]g <Plug>(coc-diagnostic-next)
    nmap <leader>rn <Plug>(coc-rename)
    xmap <leader>lf <Plug>(coc-format-selected)
    nnoremap <silent> <leader>ld :CocDiagnostics<CR>

    function! s:show_documentation()
      if (index(['vim','help'], &filetype) >= 0)
        execute 'h '.expand('<cword>')
      else
        call CocAction('doHover')
      endif
    endfunction
endif

" Pear-tree
let g:pear_tree_pairs = {
            \ '(': {'closer': ')'},
            \ '[': {'closer': ']'},
            \ '{': {'closer': '}'},
            \ "'": {'closer': "'"},
            \ '"': {'closer': '"'}
            \ }

" Pear Tree is enabled for all filetypes by default:
let g:pear_tree_ft_disabled = []

" Pair expansion is dot-repeatable by default:
let g:pear_tree_repeatable_expand = 1

" Smart pairs are disabled by default:
let g:pear_tree_smart_openers = 0
let g:pear_tree_smart_closers = 0
let g:pear_tree_smart_backspace = 0

" If enabled, smart pair functions timeout after 60ms:
let g:pear_tree_timeout = 60

" Automatically map <BS>, <CR>, and <Esc>
let g:pear_tree_map_special_keys = 1

" Peer tree mappings:
imap <C-CR> <Plug>(PearTreeExpand)

" Vimspector
nnoremap <silent> <leader>dl :call ZDebugLaunchSettings()<CR>
nnoremap <silent> <leader>dd :call vimspector#Launch()<CR>
nnoremap <silent> <leader>dc :call vimspector#Continue()<CR>
nnoremap <silent> <leader>ds :call vimspector#Stop()<CR>
nnoremap <silent> <leader>dr :call vimspector#Restart()<CR>
nnoremap <silent> <leader>dp :call vimspector#Pause()<CR>
nnoremap <silent> <leader>db :call vimspector#ToggleBreakpoint()<CR>
nnoremap <silent> <F9> :call vimspector#ToggleBreakpoint()<CR>
nnoremap <silent> <leader>bf :call vimspector#AddFunctionBreakpoint('<cexpr>')<CR>
nnoremap <silent> <leader>dn :call vimspector#StepOver()<CR>
nnoremap <silent> <F10> :call vimspector#StepOver()<CR>
nnoremap <silent> <leader>di :call vimspector#StepInto()<CR>
nnoremap <silent> <F11> :call vimspector#StepInto()<CR>
nnoremap <silent> <leader>do :call vimspector#StepOut()<CR>
nnoremap <silent> <leader><F11> :call vimspector#StepOut()<CR>
nnoremap <silent> <leader>dq :call vimspector#Reset()<CR>

function! ZGenerateVimspectorCpp()
    call inputsave()
    let target = input('Target (Executable/IP): ')
    call inputrestore()
    let debugger = 'gdb'
    if !executable('gdb') && executable('lldb')
        let debugger = 'lldb'
    endif
    if filereadable(target)
        exec ":AsyncRun
            \ echo '{' > .vimspector.json &&
            \ echo '    \"configurations\": {' >> .vimspector.json &&
            \ echo '        \"Launch\": {' >> .vimspector.json &&
            \ echo '            \"adapter\": \"vscode-cpptools\",' >> .vimspector.json &&
            \ echo '            \"configuration\": {' >> .vimspector.json &&
            \ echo '                \"request\": \"launch\",' >> .vimspector.json &&
            \ echo '                \"type\": \"cppdbg\",' >> .vimspector.json &&
            \ echo '                \"program\": \"" . target . "\",' >> .vimspector.json &&
            \ echo '                \"args\": [],' >> .vimspector.json &&
            \ echo '                \"environment\": [],' >> .vimspector.json &&
            \ echo '                \"cwd\": \"" . g:vimroot . "\",' >> .vimspector.json &&
            \ echo '                \"externalConsole\": true,' >> .vimspector.json &&
            \ echo '                \"stopAtEntry\": true,' >> .vimspector.json &&
            \ echo '                \"setupCommands\": [' >> .vimspector.json &&
            \ echo '                    { \"text\": \"set disassembly-flavor intel\", \"description\": \"\", \"ignoreFailures\": false },' >> .vimspector.json &&
            \ echo '                    { \"text\": \"-enable-pretty-printing\", \"description\": \"\", \"ignoreFailures\": false }' >> .vimspector.json &&
            \ echo '                ],' >> .vimspector.json &&
            \ echo '                \"MIMode\": \"" . debugger . "\"' >> .vimspector.json &&
            \ echo '            }' >> .vimspector.json &&
            \ echo '        }' >> .vimspector.json &&
            \ echo '    }' >> .vimspector.json &&
            \ echo '}' >> .vimspector.json"
    elseif stridx(target, ':') != -1
        call inputsave()
        let main_file = input('Main File: ')
        call inputrestore()
        exec ":AsyncRun
            \ echo '{' > .vimspector.json &&
            \ echo '    \"configurations\": {' >> .vimspector.json &&
            \ echo '        \"Launch\": {' >> .vimspector.json &&
            \ echo '            \"adapter\": \"vscode-cpptools\",' >> .vimspector.json &&
            \ echo '            \"configuration\": {' >> .vimspector.json &&
            \ echo '                \"request\": \"launch\",' >> .vimspector.json &&
            \ echo '                \"program\": \"" . main_file . "\",' >> .vimspector.json &&
            \ echo '                \"type\": \"cppdbg\",' >> .vimspector.json &&
            \ echo '                \"setupCommands\": [' >> .vimspector.json &&
            \ echo '                    { \"text\": \"set disassembly-flavor intel\", \"description\": \"\", \"ignoreFailures\": false },' >> .vimspector.json &&
            \ echo '                    { \"text\": \"-enable-pretty-printing\", \"description\": \"\", \"ignoreFailures\": false }' >> .vimspector.json &&
            \ echo '                ],' >> .vimspector.json &&
            \ echo '                \"miDebuggerServerAddress\": \"" . target . "\",' >> .vimspector.json &&
            \ echo '                \"externalConsole\": true,' >> .vimspector.json &&
            \ echo '                \"stopAtEntry\": true,' >> .vimspector.json &&
            \ echo '                \"miDebuggerPath\": \"" . debugger . "\",' >> .vimspector.json &&
            \ echo '                \"MIMode\": \"" . debugger . "\"' >> .vimspector.json &&
            \ echo '            }' >> .vimspector.json &&
            \ echo '        }' >> .vimspector.json &&
            \ echo '    }' >> .vimspector.json &&
            \ echo '}' >> .vimspector.json"
    endif
endfunction

function! ZGenerateVimspectorPy()
    call inputsave()
    let program = input('Program: ')
    let python = input('Python: ')
    call inputrestore()
    exec ":AsyncRun
        \ echo '{' > .vimspector.json &&
        \ echo '    \"configurations\": {' >> .vimspector.json &&
        \ echo '        \"Launch\": {' >> .vimspector.json &&
        \ echo '            \"adapter\": \"debugpy\",' >> .vimspector.json &&
        \ echo '            \"configuration\": {' >> .vimspector.json &&
        \ echo '                \"request\": \"launch\",' >> .vimspector.json &&
        \ echo '                \"type\": \"python\",' >> .vimspector.json &&
        \ echo '                \"program\": \"" . program . "\",' >> .vimspector.json &&
        \ echo '                \"python\": \"" . python . "\",' >> .vimspector.json &&
        \ echo '                \"cwd\": \"" . g:vimroot . "\",' >> .vimspector.json &&
        \ echo '                \"externalConsole\": true,' >> .vimspector.json &&
        \ echo '                \"breakpoints\": {\"exception\": {\"caught\": \"N\", \"uncaught\": \"Y\"}},' >> .vimspector.json &&
        \ echo '                \"stopAtEntry\": true' >> .vimspector.json &&
        \ echo '            }' >> .vimspector.json &&
        \ echo '        }' >> .vimspector.json &&
        \ echo '    }' >> .vimspector.json &&
        \ echo '}' >> .vimspector.json"
endfunction

function ZDebugLaunchSettings()
    if empty(&filetype)
        call ZSwitchToRoot()
        exec ":Files"
    endif

    if &filetype == 'cpp' || &filetype == 'c'
        call ZGenerateVimspectorCpp()
    elseif &filetype == 'python'
        call ZGenerateVimspectorPy()
    endif
endfunction

" Generate Flags
function! ZGenerateFlags()
    let cpp_include_1 = system("ag -l -g string_view /usr/lib 2> /dev/null | grep -v tr1 | grep -v experimental | sort | tail -n 1")
    if empty(cpp_include_1)
        let cpp_include_1 = system("ag -l -g string_view /usr/local 2> /dev/null | grep -v tr1 | grep -v experimental | sort | tail -n 1")
    endif
    if empty(cpp_include_1)
        let cpp_include_1 = '/usr/include'
    else
        let cpp_include_1 = system("dirname " . cpp_include_1)
    endif

    let cpp_include_2 = system("ag -l -g cstdlib /usr/include/c++ 2> /dev/null | grep -v tr1 | grep -v experimental | sort | tail -n 1")
    if empty(cpp_include_2)
        let cpp_include_2 = '/usr/include'
    else
        let cpp_include_2 = system("dirname " . cpp_include_2)
    endif

    copen
    exec ":AsyncRun
    \ echo -std=c++1z > compile_flags.txt
    \ && echo -isystem >> compile_flags.txt
    \ && echo /usr/include >> compile_flags.txt
    \ && echo -isystem >> compile_flags.txt
    \ && echo " . trim(cpp_include_1) . " >> compile_flags.txt
    \ && echo -isystem >> compile_flags.txt
    \ && echo " . trim(cpp_include_2) . " >> compile_flags.txt
    \ && set +e ; find . -type d -name inc -or -name include | grep -v \"/\\.\" | " . s:sed . " s@^@-isystem\\\\n@g >> compile_flags.txt ; set -e
    \ && echo -x >> compile_flags.txt
    \ && echo c++ >> compile_flags.txt"
endfunction

" Generate All
function! ZGenerateAll()
    copen
    exec ":AsyncRun ctags -R " . g:ctagsOptions . " && echo '" . g:ctagsOptions . "' > .gutctags && " . s:sed . " -i 's/ /\\n/g' .gutctags && ag -l -g '" . g:ctagsFilePatterns . "' > cscope.files && cp cscope.files .files && ag -l -g '" . g:otherFilePatterns . "' >> .files && cscope -bq && gtags"
endfunction

" Generate Everything
function! ZGenerateEverything()
    copen
    exec ":AsyncRun ctags -R " . g:ctagsEverythingOptions . " && echo '" . g:ctagsEverythingOptions . "' > .gutctags && " . s:sed . " -i 's/ /\\n/g' .gutctags && ag -l > cscope.files && cp cscope.files .files && ag -l -g '" . g:otherFilePatterns . "' >> .files &&  cscope -bq && gtags"
endfunction

" Write tags options.
function! ZWriteTagsOptions()
    copen
    exec ":AsyncRun echo " . g:ctagsOptions . " > .gutctags && " . s:sed . " -i 's/ /\\n/g' .gutctags"
endfunction

" Generate Tags
function! ZGenTags()
    copen
    exec ":AsyncRun ctags -R " . g:ctagsOptions
endfunction

" Generate Cscope Files
function! ZGenCsFiles()
    copen
    exec ":AsyncRun ag -l -g '" . g:ctagsFilePatterns . "' > cscope.files && cp cscope.files .files && ag -l -g '" . g:otherFilePatterns . "' >> .files"
endfunction

" Generate Tags and Cscope Files
function! ZGenTagsAndCsFiles()
    copen
    exec ":AsyncRun ag -l -g '" . g:ctagsFilePatterns . "' > cscope.files && cp cscope.files .files && ag -l -g '" . g:otherFilePatterns . "' >> .files && ctags -R " . g:ctagsOptions
endfunction

" Generate C++
function! ZGenerateCpp()
    copen
    if !filereadable('compile_commands.json')
        let cpp_include_1 = system("ag -l -g string_view /usr/lib 2> /dev/null | grep -v tr1 | grep -v experimental | sort | tail -n 1")
        if empty(cpp_include_1)
            let cpp_include_1 = system("ag -l -g string_view /usr/local 2> /dev/null | grep -v tr1 | grep -v experimental | sort | tail -n 1")
        endif
        if empty(cpp_include_1)
            let cpp_include_1 = '/usr/include'
        else
            let cpp_include_1 = system("dirname " . cpp_include_1)
        endif

        let cpp_include_2 = system("ag -l -g cstdlib /usr/include/c++ 2> /dev/null | grep -v tr1 | grep -v experimental | sort | tail -n 1")
        if empty(cpp_include_2)
            let cpp_include_2 = '/usr/include'
        else
            let cpp_include_2 = system("dirname " . cpp_include_2)
        endif

        copen

        exec ":AsyncRun
        \ && echo -std=c++1z > compile_flags.txt
        \ && echo -isystem >> compile_flags.txt
        \ && echo /usr/include >> compile_flags.txt
        \ && echo -isystem >> compile_flags.txt
        \ && echo " . trim(cpp_include_1) . " >> compile_flags.txt
        \ && echo -isystem >> compile_flags.txt
        \ && echo " . trim(cpp_include_2) . " >> compile_flags.txt
        \ && set +e ; find . -type d -name inc -or -name include | grep -v \"/\\.\" | " . s:sed . " s@^@-isystem\\\\n@g >> compile_flags.txt ; set -e
        \ && echo -x >> compile_flags.txt
        \ && echo c++ >> compile_flags.txt
        \ && echo '" . g:ctagsOptions . "' > .gutctags && " . s:sed . " -i 's/ /\\n/g' .gutctags && ag -l -g '" . g:ctagsFilePatterns . "' > cscope.files && cp cscope.files .files && ag -l -g '" . g:otherFilePatterns . "' >> .files && cscope -bq"
    else
        exec ":AsyncRun echo '" . g:ctagsOptions . "' > .gutctags && " . s:sed . " -i 's/ /\\n/g' .gutctags && ag -l -g '" . g:ctagsFilePatterns . "' > cscope.files && cp cscope.files .files && ag -l -g '" . g:otherFilePatterns . "' >> .files && cscope -bq"
    endif
endfunction
function! ZGenerateTagsBasedCpp()
    copen
    exec ":AsyncRun ctags -R " . g:ctagsOptions . " && echo '" . g:ctagsOptions . "' > .gutctags && " . s:sed . " -i 's/ /\\n/g' .gutctags && ag -l -g '" . g:ctagsFilePatterns . "' > cscope.files && cp cscope.files .files && ag -l -g '" . g:otherFilePatterns . "' >> .files && cscope -bq"
endfunction
function! ZGenerateCppScope()
    copen
    exec ":AsyncRun echo '" . g:ctagsOptions . "' > .gutctags && " . s:sed . " -i 's/ /\\n/g' .gutctags && ag -l -g '" . g:ctagsFilePatterns . "' > cscope.files && cp cscope.files .files && ag -l -g '" . g:otherFilePatterns . "' >> .files && cscope -bq"
endfunction

" Generate Opengrok
function! ZGenerateOpengrok()
    copen
    exec ":AsyncRun java -Xmx2048m -jar ~/.vim/bin/opengrok/lib/opengrok.jar -q -c " . g:opengrok_ctags . " -s . -d .opengrok
         \ " . g:opengrokFilePatterns . "
         \ -P -S -G -W .opengrok/configuration.xml"
endfunction

" Generate compile_commands.json
function! ZGenerateCompileCommandsJson()
    call inputsave()
    let compile_command = input('Compile (make) command: ')
    call inputrestore()
    copen
    if executable('compiledb')
        exec ":AsyncRun compiledb " . compile_command
    else
        exec ":AsyncRun python3 -m compiledb " . compile_command
    endif
endfunction
nnoremap <silent> <leader>zj :call ZGenerateCompileCommandsJson()<CR>

" Toggle mouse
function! ZToggleMouse()
    if &mouse == 'a'
        set mouse=
        set ttymouse=xterm
    else
        set mouse=a
        if has('mouse_sgr')
            set ttymouse=sgr
        else
            set ttymouse=xterm2
        endif
    endif
endfunction
