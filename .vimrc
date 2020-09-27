set nocompatible

function! InstallCommand(command)
    silent exec "!" . a:command
    if v:shell_error
        silent exec "!echo Installation failed, error: " . string(v:shell_error)
        throw "Error: installation failed."
    endif
endfunction

function! InstallVimrc()
    if empty($SUDO_USER)
        echo "Please run as sudo."
        exec ":q"
    endif
    call InstallCommand("mkdir -p ~/.vim")
    call InstallCommand("mkdir -p ~/.vim/tmp")
    call InstallCommand("mkdir -p ~/.vim/bin/python")
    call InstallCommand("mkdir -p ~/.vim/bin/llvm")
    call InstallCommand("mkdir -p ~/.config")
    call InstallCommand("mkdir -p ~/.config/coc")
    call InstallCommand("mkdir -p ~/.cache")
    if !executable('brew')
        call InstallCommand("DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:lazygit-team/release")
        call InstallCommand("curl -sL https://deb.nodesource.com/setup_10.x | bash -")
        call InstallCommand("curl -fLo ~/.vim/tmp/llvm-install/llvm.sh --create-dirs
            \ https://apt.llvm.org/llvm.sh
            \ ; cd ~/.vim/tmp/llvm-install; chmod +x ./llvm.sh; ./llvm.sh 11")
        call InstallCommand("DEBIAN_FRONTEND=noninteractive apt install -y curl silversearcher-ag exuberant-ctags cscope git
            \ make autoconf automake pkg-config openjdk-8-jre python3 python3-pip gdb golang nodejs lazygit libc++-11-dev libc++abi-11-dev")
        call InstallCommand("rm -rf ~/.vim/bin/llvm/clangd && ln -s $(command -v clangd-11) ~/.vim/bin/llvm/clangd")
        let lazygit_config_path = '~/.config/jesseduffield/lazygit'
    else
        call InstallCommand("sudo -u $SUDO_USER brew install curl ag ctags cscope git
            \ llvm make autoconf automake pkg-config python3 nodejs gnu-sed bat ripgrep lazygit golang pandoc || true")
        call InstallCommand("sudo -u $SUDO_USER brew link python3")
        call InstallCommand("sudo -u $SUDO_USER brew tap AdoptOpenJDK/openjdk")
        call InstallCommand("sudo -u $SUDO_USER brew cask install adoptopenjdk8")
        call InstallCommand("sudo -u $SUDO_USER curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py")
        call InstallCommand("sudo -u $SUDO_USER python3 get-pip.py")
        if !executable('clangd') && executable('/usr/local/opt/llvm/bin/clangd')
            call InstallCommand("echo export PATH=\\$PATH:/usr/local/opt/llvm/bin >> ~/.bashrc")
        endif
        let lazygit_config_path = '~/Library/Application\ Support/jesseduffield/lazygit'
    endif
    if 0 == system('python3 -c "import sys; print(1 if sys.version_info.major >= 3 and sys.version_info.minor >= 6 else 0)"') && executable('python3.6')
        call InstallCommand("rm -rf ~/.vim/bin/python/python3 && ln -s $(command -v python3.6) ~/.vim/bin/python/python3")
        let $PATH = expand('~/.vim/bin/python') . ':' . $PATH
        let python3_command = 'python3.6'
    endif
    if executable('pip3')
        call InstallCommand("pip3 install compiledb")
    endif
    if executable('python3')
        call InstallCommand("sudo -u $SUDO_USER " . python3_command . " -m pip install python-language-server pylint compiledb setuptools jedi")
    endif
    if !filereadable(expand('~/.vim/autoload/plug.vim'))
        call InstallCommand("curl -fLo ~/.vim/autoload/plug.vim --create-dirs
          \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim")
    endif
    if !filereadable(expand('~/.vim/bin/opengrok/lib/opengrok.jar'))
        call InstallCommand("curl -fLo ~/.vim/bin/opengrok.tar.gz --create-dirs
          \ https://github.com/oracle/opengrok/releases/download/1.0/opengrok-1.0.tar.gz")
        call InstallCommand("cd ~/.vim/bin; tar -xzvf opengrok.tar.gz")
        call InstallCommand("rm ~/.vim/bin/opengrok.tar.gz")
        call InstallCommand("mv ~/.vim/bin/opengrok* ~/.vim/bin/opengrok")
    endif
    if !filereadable(expand('~/.vim/tmp/ctags/Makefile'))
        call InstallCommand("cd ~/.vim/tmp; git clone https://github.com/universal-ctags/ctags.git; cd ./ctags; ./autogen.sh; ./configure; make; make install")
    endif
    if !executable('ctags-exuberant') && !filereadable(expand('~/.vim/bin/ctags-exuberant/ctags/ctags'))
        call InstallCommand("curl -fLo ~/.vim/bin/ctags-exuberant/ctags.tar.gz --create-dirs
          \ http://prdownloads.sourceforge.net/ctags/ctags-5.8.tar.gz")
        call InstallCommand("cd ~/.vim/bin/ctags-exuberant; tar -xzvf ctags.tar.gz")
        call InstallCommand("mv ~/.vim/bin/ctags-exuberant/ctags-5.8 ~/.vim/bin/ctags-exuberant/ctags")
        call InstallCommand("cd ~/.vim/bin/ctags-exuberant/ctags; ./configure; make")
    endif
    if !filereadable(expand('~/.vim/bin/lf/lf'))
        if !executable('brew')
            call InstallCommand("curl -fLo ~/.vim/bin/lf/lf.tar.gz --create-dirs
              \ https://github.com/gokcehan/lf/releases/download/r16/lf-linux-amd64.tar.gz")
        else
            call InstallCommand("curl -fLo ~/.vim/bin/lf/lf.tar.gz --create-dirs
              \ https://github.com/gokcehan/lf/releases/download/r16/lf-darwin-amd64.tar.gz")
        endif
        call InstallCommand("cd ~/.vim/bin/lf; tar -xzvf lf.tar.gz")
    endif
    if !executable('bat') && !executable('brew')
        if !empty(system('apt-cache search --names-only ^bat\$'))
            call InstallCommand("DEBIAN_FRONTEND=noninteractive apt install -y bat")
        else
            call InstallCommand("curl -fLo ~/.vim/tmp/bat --create-dirs
                \ https://github.com/sharkdp/bat/releases/download/v0.15.1/bat_0.15.1_amd64.deb")
            call InstallCommand("dpkg -i ~/.vim/tmp/bat")
        endif
    endif
    if !executable('rg') && !executable('brew')
        if !empty(system('apt-cache search --names-only ^ripgrep\$'))
            call InstallCommand("DEBIAN_FRONTEND=noninteractive apt install -y ripgrep")
        else
            call InstallCommand("curl -fLo ~/.vim/tmp/ripgrep --create-dirs
                \ https://github.com/BurntSushi/ripgrep/releases/download/11.0.2/ripgrep_11.0.2_amd64.deb")
            call InstallCommand("dpkg -i ~/.vim/tmp/ripgrep")
        endif
    endif
    call InstallCommand("
        \ sudo -u $SUDO_USER mkdir -p " . lazygit_config_path . "
        \ && sudo -u $SUDO_USER touch " . lazygit_config_path . "/config.yml
        \ && echo 'startuppopupversion: 1' > " . lazygit_config_path . "/config.yml
        \ && echo 'gui:' >> " . lazygit_config_path . "/config.yml
        \ && echo '  theme:' >> " . lazygit_config_path . "/config.yml
        \ && echo '    selectedLineBgColor:' >> " . lazygit_config_path . "/config.yml
        \ && echo '      - reverse' >> " . lazygit_config_path . "/config.yml
    \ ")
    if !executable('brew') && !filereadable(expand('~/.vim/tmp/pandoc.deb'))
        call InstallCommand("curl -fLo ~/.vim/tmp/pandoc.deb --create-dirs
            \ https://github.com/jgm/pandoc/releases/download/2.10.1/pandoc-2.10.1-1-amd64.deb")
        call InstallCommand("dpkg -i ~/.vim/tmp/pandoc.deb")
    endif
    call InstallCommand("chown -R $SUDO_USER:$SUDO_GID ~/.vim")
    call InstallCommand("chown -R $SUDO_USER:$SUDO_GID ~/.vim/tmp")
    call InstallCommand("chown -R $SUDO_USER:$SUDO_GID ~/.config")
    call InstallCommand("chown -R $SUDO_USER:$SUDO_GID ~/.cache")
    call InstallCommand("chown $SUDO_USER:$SUDO_GID ~/.vimrc")
    call InstallCommand("sudo -u $SUDO_USER INSTALL_VIMRC_PLUGINS=1 INSTALL_VIMRC= vim +qa")
    call InstallCommand("sudo -u $SUDO_USER " . python3_command . " ~/.vim/plugged/vimspector/install_gadget.py --sudo --enable-c --enable-python")
    call CustomizePlugins()
endfunction

let s:sed = 'sed'
if executable('brew')
    let s:sed = 'gsed'
endif

function! CustomizePlugins()
    call InstallCommand(s:sed . " -i 's@ . redraw\\!@ . \" > /dev/null\"@' ~/.vim/plugged/cscope_dynamic/plugin/cscope_dynamic.vim")
    call InstallCommand(s:sed . " -i 's@silent execute \"perl system.*@silent execute \"\\!\" . a:cmd . \" > /dev/null\"@' ~/.vim/plugged/cscope_dynamic/plugin/cscope_dynamic.vim")
endfunction

if !empty($INSTALL_VIMRC)
    call InstallVimrc()
    exec ":q"
endif

let g:lsp_choice = 'coc'
if filereadable(expand('~/.vim/.nococ'))
    let g:lsp_choice = 'vim-lsp'
endif

nnoremap <silent> <leader>tl :call ToggleLspPersistent()<CR>:source ~/.vimrc<CR>
function! ToggleLspPersistent()
    if filereadable(expand('~/.vim/.nococ'))
        call system("rm ~/.vim/.nococ")
    else
        call system("touch ~/.vim/.nococ")
    endif
endfunction

call plug#begin()
Plug 'puremourning/vimspector'
Plug 'preservim/nerdtree', {'on': 'NERDTreeToggle'}
Plug 'majutsushi/tagbar', {'on': 'TagbarToggle'}
Plug 'ludovicchabant/vim-gutentags'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'vim-scripts/a.vim'
Plug 'ervandew/supertab'
Plug 'vim-airline/vim-airline'
Plug 'skywind3000/asyncrun.vim'
Plug 'justinmk/vim-sneak'
Plug 'mg979/vim-visual-multi'
Plug 'gruvbox-community/gruvbox'
Plug 'erig0/cscope_dynamic'
Plug 'octol/vim-cpp-enhanced-highlight'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
if !empty($INSTALL_VIMRC_PLUGINS) || g:lsp_choice == 'vim-lsp'
    Plug 'prabirshrestha/async.vim'
    Plug 'prabirshrestha/vim-lsp'
    Plug 'prabirshrestha/asyncomplete.vim'
    Plug 'prabirshrestha/asyncomplete-lsp.vim'
    Plug 'prabirshrestha/asyncomplete-tags.vim'
endif
if !empty($INSTALL_VIMRC_PLUGINS) || g:lsp_choice == 'coc'
    Plug 'neoclide/coc.nvim', { 'branch': 'release' }
    Plug 'antoinemadec/coc-fzf', { 'branch': 'release' }
endif
if !empty($INSTALL_VIMRC_PLUGINS) || g:lsp_choice != 'coc'
    Plug 'vim-scripts/AutoComplPop'
    Plug 'vim-scripts/OmniCppComplete'
endif
Plug 'tmsvg/pear-tree'
Plug 'jackguo380/vim-lsp-cxx-highlight', { 'for': 'cpp' }
Plug 'mbbill/undotree'
Plug 'thezeroalpha/vim-lf'
Plug 'tpope/vim-commentary'
Plug 'bfrg/vim-cpp-modern'
Plug 'tomasiser/vim-code-dark'
Plug 'joeytwiddle/sexy_scroller.vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'troydm/zoomwintab.vim'
if !empty($INSTALL_VIMRC_PLUGINS) || empty($INSIDE_VIM)
    Plug 'wincent/terminus'
endif
Plug 'jreybert/vimagit', { 'on': ['Magit', 'MagitOnly'] }
Plug 'tpope/vim-obsession'
Plug 'haya14busa/incsearch.vim'
Plug 'haya14busa/incsearch-fuzzy.vim'
Plug 'joshdick/onedark.vim'
Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }
call plug#end()

if empty($INSIDE_VIM)
    let $INSIDE_VIM = 1
endif

if !empty($INSTALL_VIMRC_PLUGINS)
    let g:coc_disable_startup_warning = 1
    if $INSTALL_VIMRC_PLUGINS != 'post'
        exec ":PlugInstall --sync"
        call InstallCommand("
            \ echo '{' > ~/.vim/coc-settings.json
            \ && echo '    \"clangd.semanticHighlighting\": true,' >> ~/.vim/coc-settings.json
            \ && echo '    \"python.jediEnabled\": true,' >> ~/.vim/coc-settings.json
            \ && echo '    \"coc.preferences.formatOnType\": true' >> ~/.vim/coc-settings.json
            \ && echo '}' >> ~/.vim/coc-settings.json")
        call InstallCommand("INSTALL_VIMRC_PLUGINS=post vim +'CocInstall -sync coc-json coc-clangd coc-python coc-vimlsp' +qa")
    endif
endif

" Generic
syntax on
filetype plugin indent on
nnoremap <silent> ` :noh<CR>
set expandtab
set ignorecase
set smartcase
set shellslash
set autoindent
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
set wildmenu
set completeopt=longest,menuone,preview
set nowrap
nnoremap <silent> <C-q> <C-v>
set shellslash
map <C-w>w :q<CR>
noremap <F1> <C-w><C-p>
noremap <F2> <C-w><C-w>
set noerrorbells visualbell t_vb=
augroup filetype_indentation
    autocmd!
    autocmd filetype cpp setlocal cindent
    autocmd filetype c setlocal cindent
    autocmd filetype make setlocal noexpandtab autoindent
augroup end

" Clipboard
vnoremap <silent> <C-c> "*y
inoremap <silent> <C-v> <ESC>"*gpa
nnoremap <silent> <C-v> "*p
if empty($SSH_CONNECTION)
    set clipboard=unnamed
else
    set clipboard=exclude:.*
endif

" Gui colors
if has('termguicolors') && !filereadable(expand('~/.vim/.notermguicolors'))
    set termguicolors
endif
nnoremap <leader>tg :call ToggleGuiColorsPersistent()<CR>
function! ToggleGuiColorsPersistent()
    if has('termguicolors')
        if filereadable(expand('~/.vim/.notermguicolors'))
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
function! ZToggleSignColumn()
    if !exists("b:signcolumn_on") || b:signcolumn_on
        set signcolumn=no
        let b:signcolumn_on = 0
    else
        set signcolumn=yes
        let b:signcolumn_on = 1
    endif
endfunction

" Updatetime
set updatetime=300
set shortmess+=c

" Path
let $PATH =
    \ ':' . expand('~/.vim/bin/lf')
    \ . ':' . expand('~/.vim/bin/llvm')
    \ . ':' . expand('~/.vim/bin/python')
    \ . ':' . $PATH
if !executable('clangd') && filereadable('/usr/local/opt/llvm/bin/clangd')
    let $PATH .= ':/usr/local/opt/llvm/bin'
endif

" Ignore no write since last change errors
set hidden

" Copy / Paste Mode
nnoremap <silent> <F7> :set paste!<CR>:set number!<CR>:call ZToggleSignColumn()<CR>:call ZToggleMouse()<CR>

" Resize splits
nnoremap <silent> L :vertical resize +1<CR>
nnoremap <silent> H :vertical resize -1<CR>
nnoremap <silent> <C-w>= :resize +1<CR>

" Zoom
noremap <silent> <C-w>z :ZoomWinTabToggle<CR>

" Generation Parameters
let g:ctagsFilePatterns = '-g "*.c" -g "*.cc" -g "*.cpp" -g "*.cxx" -g "*.h" -g "*.hh" -g "*.hpp"'
let g:otherFilePatterns = '-g "*.py" -g "*.te" -g "*.S" -g "*.asm" -g "*.mk" -g "*.md" -g "makefile" -g "Makefile"'
let g:sourceFilePatterns = '-g "*.c" -g "*.cc" -g "*.cpp" -g "*.cxx" -g "*.h" -g "*.hh" -g "*.hpp" -g "*.py" -g "*.te" -g "*.S" -g "*.asm" -g "*.mk" -g "*.md" -g "makefile" -g "Makefile"'
let g:opengrokFilePatterns = "-I '*.cpp' -I '*.c' -I '*.cc' -I '*.cxx' -I '*.h' -I '*.hh' -I '*.hpp' -I '*.S' -I '*.s' -I '*.asm' -I '*.py' -I '*.java' -I '*.cs' -I '*.mk' -I '*.te' -I makefile -I Makefile"
let g:ctagsOptions = '--languages=C,C++ --c++-kinds=+p --fields=+iaSn --extra=+q --sort=foldcase --tag-relative --recurse=yes'
let g:ctagsEverythingOptions = '--c++-kinds=+p --fields=+iaSn --extra=+q --sort=foldcase --tag-relative --recurse=yes'

" Generate C++
nnoremap <silent> <leader>zp :call ZGenerateCpp()<CR>

" Generate tags.
nnoremap <silent> <leader>zt :call ZGenerateTags()<CR>
nnoremap <silent> <leader>zT :call ZGenerateEveryTags()<CR>

" Generate Files Cache
nnoremap <silent> <leader>zh :call ZGenerateSourceFilesCache()<CR>
nnoremap <silent> <leader>zH :call ZGenerateFilesCache()<CR>

" Generate Flags
nnoremap <silent> <leader>zf :call ZGenerateFlags()<CR>

" Generate Opengrok
nnoremap <silent> <leader>zk :call ZGenerateOpengrok()<CR>

" Terminal
nnoremap <silent> <leader>zb :below terminal ++rows=10<CR>
nnoremap <silent> <leader>zv :vert rightb terminal<CR>
tnoremap <silent> <C-w>w <C-w>:q<CR>
tnoremap <silent> <C-w>n <C-w>N
tnoremap <silent> <C-w>m <C-w>:call TerminalToggleScrolling()<CR>
augroup terminal_whitespace
    autocmd!
    autocmd TerminalOpen * DisableWhitespace
    autocmd TerminalOpen * tnoremap <silent> <buffer> <ScrollWheelUp> <C-w>:call TerminalEnterNormalMode()<CR>
augroup end

function! TerminalExitNormalMode()
    call feedkeys("a")
endfunction

function! TerminalEnterNormalMode()
    if &buftype == 'terminal' && mode('') == 't'
        call feedkeys("\<c-w>N")
        call feedkeys("\<c-y>")
    endif
endfunction

function! TerminalToggleScrolling()
    if !exists('b:terminal_scrolling_enabled') || b:terminal_scrolling_enabled == 1
        tunmap <silent> <buffer> <ScrollWheelUp>
        let b:terminal_scrolling_enabled = 0
    else
        tnoremap <silent> <buffer> <ScrollWheelUp> <C-w>:call TerminalEnterNormalMode()<CR>
        let b:terminal_scrolling_enabled = 1
    endif
endfunction

" Vim-better-whitespace
let g:better_whitespace_filetypes_blacklist = ['diff', 'gitcommit', 'git', 'unite', 'qf', 'help', 'VimspectorPrompt', 'xxd']
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
let g:opengrok_jar = expand('~/.vim/bin/opengrok/lib/opengrok.jar')
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

" NERDTree and TagBar
let g:NERDTreeWinSize = 23
let g:NERDTreeAutoCenter = 0
let g:tagbar_width = 23
nnoremap <silent> <C-l> :NERDTreeToggle<CR>:wincmd w<CR>:TagbarToggle<CR>
nnoremap <silent> <leader>nf :NERDTreeFind<CR>

" Git
nnoremap <silent> <leader>gb :Git blame<CR>
nnoremap <silent> <leader>gm :MagitOnly<CR>
nnoremap <silent> <leader>gc :BCommits!<CR>
nnoremap <silent> <leader>gl :call PopTerminal('lazygit -p ' .  expand('%:p:h'))<CR>

" Pop Terminal
function! PopTerminal(command)
    let buf = term_start(a:command, #{hidden: 1, term_finish: 'close'})
    let winid = popup_dialog(buf, #{minheight: 40, minwidth: 150})
    let bufn = winbufnr(winid)
endfunction

" GutenTags
let g:gutentags_modules = ['ctags']

" Gruvbox
let g:gruvbox_contrast_datk = 'medium'

" Color
if !filereadable(expand('~/.vim/.color'))
    call system('echo onedark > ~/.vim/.color')
endif
" Onedark color overrides
let g:onedark_color_overrides = {
    \ "special_grey": { "gui": "#5C6370", "cterm": "59", "cterm16": "15" }
\ }
let s:vim_color = readfile(expand('~/.vim/.color'))[0]
if s:vim_color == 'codedark'
    color onedark
endif
exec ':color ' . s:vim_color
command! -nargs=1 ZColor call system('echo ' . <f-args> . ' > ~/.vim/.color') | source ~/.vimrc

" Supertab
let g:SuperTabDefaultCompletionType = "<c-n>"

" Incsearch
map / <Plug>(incsearch-forward)
map ? <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)
map z/ <Plug>(incsearch-fuzzy-/)
map z? <Plug>(incsearch-fuzzy-?)
map zg/ <Plug>(incsearch-fuzzy-stay)

" Hexokinase
let g:Hexokinase_highlighters = ['backgroundfull']

" Fzf
let g:fzf_files_nocache_command = "rg --files --no-ignore-vcs --hidden"
let g:fzf_files_cache_command = "
    \ if [ -f .files ]; then
    \     cat .files;
    \ else
    \     rg --files --no-ignore-vcs --hidden;
    \ fi
\ "

if filereadable(expand('~/.vim/.fzf-files-cache')) || filereadable('.fzf-files-cache')
    let $FZF_DEFAULT_COMMAND = g:fzf_files_cache_command
    let g:fzf_files_cache = 1
else
    let $FZF_DEFAULT_COMMAND = g:fzf_files_nocache_command
    let g:fzf_files_cache = 0
endif

set rtp+=~/.fzf
nnoremap <silent> <C-p> :call ZSwitchToRoot()<CR>:Files<CR>
nnoremap <silent> <C-n> :call ZSwitchToRoot()<CR>:Tags<CR>
nnoremap <silent> <leader>b :Buf<CR>
nnoremap <silent> <leader>fh :call ZFzfToggleFilesCache()<CR>
nnoremap <silent> <leader>fH :call ZFzfToggleGlobalFilesCache()<CR>
nnoremap <silent> // :BLines!<CR>

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

function! ZFzfToggleFilesCache()
    if filereadable(expand('~/.vim/.fzf-files-cache'))
        let $FZF_DEFAULT_COMMAND = g:fzf_files_cache_command
        if filereadable('.fzf-files-cache')
            call system("rm .fzf-files-cache")
        else
            call system("touch .fzf-files-cache")
        endif
    else
        if filereadable('.fzf-files-cache')
            call system("rm .fzf-files-cache")
            let $FZF_DEFAULT_COMMAND = g:fzf_files_nocache_command
        else
            call system("touch .fzf-files-cache")
            let $FZF_DEFAULT_COMMAND = g:fzf_files_cache_command
        endif
    endif
endfunction

function! ZFzfToggleGlobalFilesCache()
    if filereadable(expand('~/.vim/.fzf-files-cache'))
        call system("rm -rf ~/.vim/.fzf-files-cache")
        if filereadable('.fzf-files-cache')
            let $FZF_DEFAULT_COMMAND = g:fzf_files_cache_command
        else
            let $FZF_DEFAULT_COMMAND = g:fzf_files_nocache_command
        endif
    else
        call system("touch ~/.vim/.fzf-files-cache")
        let $FZF_DEFAULT_COMMAND = g:fzf_files_cache_command
    endif
endfunction

" Sneak
let g:sneak#use_ic_scs = 1
let g:sneak#s_next = 0
let g:sneak#label = 1
let g:sneak#target_labels = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789?/'

" Cscope
let g:cscopedb_big_file = 'cscope.out'
let g:cscopedb_small_file = 'cscope_small.out'
let g:cscopedb_auto_files = 0

" Visual Multi
" Mappings - (See https://github.com/mg979/vim-visual-multi/wiki/Mappings)
" Tutorial - ~/.vim/plugged/vim-visual-multi/doc/vm-tutorial
let g:VM_theme = 'iceblue'
let g:VM_leader = '<leader>m'
let g:VM_maps = {
    \ 'Find Under': '<C-m>',
    \ 'Find Subword Under': '<C-m>',
    \ 'Add Cursor At Pos': '<leader>mm',
    \ 'Start Regex Search': 'm/',
    \ 'Merge Regions': '<leader>mM',
    \ 'Toggle Multiline': '<leader>mL',
\ }
nmap <C-j> <plug>(VM-Add-Cursor-Down)
nmap <C-k> <plug>(VM-Add-Cursor-Up)
if g:lsp_choice == 'coc'
    augroup visual_multi_coc
        autocmd!
        autocmd User visual_multi_start call ZVisualMultiCocBefore()
        autocmd User visual_multi_exit call ZVisualMultiCocAfter()
    augroup end
endif
function! ZVisualMultiCocBefore()
    if g:coc_enabled
        let g:visual_multi_coc_before = 1
        silent exec ":CocDisable"
    else
        let g:visual_multi_coc_before = 0
    endif
endfunction
function! ZVisualMultiCocAfter()
    if g:visual_multi_coc_before
        silent exec ":CocEnable"
    endif
endfunction

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

" Tag stack
nnoremap <silent> <leader>o :pop<CR>
nnoremap <silent> <leader>i :tag<CR>

function! TagstackPushCurrent(name)
    return TagstackPush(a:name, getcurpos(), bufnr())
endfunction

function! TagstackPush(name, pos, buf)
    let curpos = a:pos
    let curpos[0] = a:buf
    let item = {'tagname': a:name, 'from': curpos}
    let tagstack = gettagstack()
    let curidx = tagstack['curidx']

    if curidx == (tagstack['length'] + 1)
        call add(tagstack['items'], item)
        let tagstack['length'] = curidx
    else
        let tagstack['items'][curidx - 1] = item
    endif
    let tagstack['curidx'] = curidx + 1

    call settagstack(winnr(), tagstack, 'r')
endfunction

" Go to definition
nnoremap <silent> <leader>zd :call ZGoToSymbol(expand('<cword>'), 'definition')<CR>
nnoremap <silent> <leader>zD :call ZGoToSymbol(expand('<cword>'), 'declaration')<CR>
nnoremap <silent> <leader>zg :call ZGoToDefinition()<CR>
nnoremap <silent> <leader><leader>zd :call ZGoToSymbolInput('definition')<CR>
nnoremap <silent> <leader><leader>zD :call ZGoToSymbolInput('declaration')<CR>

function! ZGoToSymbolInput(type)
    call inputsave()
    let symbol = input('Symbol: ')
    call inputrestore()
    normal :<ESC>
    call ZGoToSymbol(symbol, a:type)
endfunction

function! ZGoToDefinition()
    if g:lsp_jump_function && ZLspJump('definition')
        return 1
    endif
    return ZGoToSymbol(expand('<cword>'), 'definition')
endfunction

function! ZFzfStringPreview(string)
    let name = expand('<cword>')
    let pos = getcurpos()
    let buf = bufnr()

    let result = fzf#vim#grep('echo -e ' . shellescape(a:string),
        \ 0, fzf#vim#with_preview({ 'options': split(fzf#wrap()['options'])[0] . ' --prompt "> "'}), 0)

    if len(result) != 0
        if buf == bufnr() && pos[1] == getcurpos()[1]
            return 1
        endif
        call TagstackPush(name, pos, buf)
        return 1
    endif
    return 0
endfunction

function! ZGoToSymbol(symbol, type)
    if a:symbol == ''
        echom "Empty symbol!"
        return 0
    endif

    let overall_limit = 2000
    let limit = 200
    let ctags_tag_types = []
    let opengrok_query_type = 'f'
    let cscope_query_type = '0'
    let cscope_file_line_separator = ': '
    let opengrok_file_line_separator = '['
    if a:type == 'definition'
        let ctags_tag_types = ['f', 'c', 's', 't', 'd']
        let opengrok_query_type = 'd'
    elseif a:type == 'declaration'
        let ctags_tag_types = ['p', 'd']
        let opengrok_query_type = 'f'
    endif

    " Cscope
    if filereadable('cscope.out')
        let awk_program =
            \    '{ x = $1; $1 = ""; z = $3; $3 = ""; ' .
            \    'printf "%s:%s:%s\n", x,z,$0; }'
        let cscope_command =
            \    'cscope -dL' . cscope_query_type . " " . shellescape(a:symbol) .
            \    " | awk '" . awk_program . "'"
        let results = split(system(cscope_command), '\n')

        if len(results) > overall_limit
            return Cscope(cscope_query_type, a:symbol, 1)
        endif

        let files_to_results = {}

        for result in results
            let file_line = split(trim(split(result, cscope_file_line_separator)[0]), ':')
            if has_key(files_to_results, file_line[0])
                call add(files_to_results[file_line[0]][0], file_line[1])
                call add(files_to_results[file_line[0]][1], result)
            else
                let files_to_results[file_line[0]] = [[file_line[1]], [result]]
            endif
        endfor

        if len(files_to_results) > limit
            return Cscope(cscope_query_type, a:symbol, 1)
        endif

        let valid_results = []
        let valid_jumps = []

        for [file_path, file_results] in items(files_to_results)
            let [file_lines, results] = file_results
            for [target_line, target_column] in ZGetTargetSymbolJumpIfCtagType(a:symbol, file_path, file_lines, ctags_tag_types)
                call add(valid_jumps, [file_path, target_line, target_column])
                call add(valid_results, results[index(file_lines, target_line)])
            endfor
        endfor

        if len(valid_jumps) == 1
            call TagstackPushCurrent(a:symbol)
            call ZJumpToLocation(valid_jumps[0][0], valid_jumps[0][1], valid_jumps[0][2])
            return 1
        elseif len(valid_jumps) > 1
            return ZFzfStringPreview(join(valid_results, '\r\n'))
        endif
    endif

    " Opengrok
    if filereadable('.opengrok/configuration.xml') && filereadable(g:opengrok_jar)
        let results = split(system("java -Xmx2048m -cp ~/.vim/bin/opengrok/lib/opengrok.jar
            \ org.opensolaris.opengrok.search.Search -R .opengrok/configuration.xml -" . opengrok_query_type
            \ . " ". shellescape(a:symbol) . "| grep \"^/.*\""), '\n')

        if len(results) > overall_limit
            return OgQuery(opengrok_query_type, a:symbol, 1)
        endif

        let files_to_results = {}

        for result in results
            let file_line = split(trim(split(result, opengrok_file_line_separator)[0]), ':')
            if has_key(files_to_results, file_line[0])
                call add(files_to_results[file_line[0]][0], file_line[1])
                call add(files_to_results[file_line[0]][1], result)
            else
                let files_to_results[file_line[0]] = [[file_line[1]], [result]]
            endif
        endfor

        if len(files_to_results) > limit
            return Cscope(cscope_query_type, a:symbol, 1)
        endif

        let valid_results = []
        let valid_jumps = []

        for [file_path, file_results] in items(files_to_results)
            let [file_lines, results] = file_results
            for [target_line, target_column] in ZGetTargetSymbolJumpIfCtagType(a:symbol, file_path, file_lines, ctags_tag_types)
                call add(valid_jumps, [file_path, target_line, target_column])
                call add(valid_results, results[index(file_lines, target_line)])
            endfor
        endfor

        if len(valid_jumps) == 1
            call TagstackPushCurrent(a:symbol)
            call ZJumpToLocation(valid_jumps[0][0], valid_jumps[0][1], valid_jumps[0][2])
            return 1
        elseif len(valid_jumps) > 1
            return ZFzfStringPreview(join(valid_results, '\r\n'))
        endif
    endif

    echom "Could not find " . a:type . " of '" . a:symbol . "'"
    return 0
endfunction

function! ZGetTargetSymbolJumpIfCtagType(symbol, file, lines, ctags_tag_types)
    let ctags = split(system("ctags -o - " . g:ctagsOptions . " " . shellescape(a:file)
        \ . " 2>/dev/null | grep " . shellescape(a:symbol)), '\n')
    let lines_and_columns = []
    for ctag in ctags
        let ctag = split(ctag, '\t')
        let ctag_field_name = ctag[0]
        if ctag_field_name != a:symbol
            continue
        endif
        let ctag_field_type = ''
        let ctag_field_line = ''
        let ctag_field_column = 0
        for ctag_field in ctag
            if ctag_field_type == '' && len(ctag_field) == 1
                let ctag_field_type = ctag_field
            elseif ctag_field_line == '' && stridx(ctag_field, 'line:') == 0
                let ctag_field_line = split(ctag_field, ':')[1]
            elseif ctag_field_column == 0 && stridx(ctag_field, '/^') == 0 && stridx(ctag_field, a:symbol) != -1
                let ctag_field_column = stridx(ctag_field, a:symbol) - 1
            endif
        endfor

        if index(a:ctags_tag_types, ctag_field_type) != -1 && ctag_field_line != '' && index(a:lines, ctag_field_line) != -1
            call add(lines_and_columns, [ctag_field_line, ctag_field_column])
        endif
    endfor
    return lines_and_columns
endfunction

" Cscope
nnoremap <silent> <leader>cA :call Cscope('9', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cC :call Cscope('3', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cD :call Cscope('2', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cE :call Cscope('6', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cF :call Cscope('7', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cG :call Cscope('1', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cI :call Cscope('8', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cS :call Cscope('0', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cT :call Cscope('4', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader><leader>fA :call CscopeQuery('9', 0)<CR>
nnoremap <silent> <leader><leader>fC :call CscopeQuery('3', 0)<CR>
nnoremap <silent> <leader><leader>fD :call CscopeQuery('2', 0)<CR>
nnoremap <silent> <leader><leader>fE :call CscopeQuery('6', 0)<CR>
nnoremap <silent> <leader><leader>fF :call CscopeQuery('7', 0)<CR>
nnoremap <silent> <leader><leader>fG :call CscopeQuery('1', 0)<CR>
nnoremap <silent> <leader><leader>fI :call CscopeQuery('8', 0)<CR>
nnoremap <silent> <leader><leader>fS :call CscopeQuery('0', 0)<CR>
nnoremap <silent> <leader><leader>cT :call CscopeQuery('4', 0)<CR>
nnoremap <silent> <leader><leader>cA :call CscopeQuery('9', 0, 1)<CR>
nnoremap <silent> <leader><leader>cC :call CscopeQuery('3', 0, 1)<CR>
nnoremap <silent> <leader><leader>cD :call CscopeQuery('2', 0, 1)<CR>
nnoremap <silent> <leader><leader>cE :call CscopeQuery('6', 0, 1)<CR>
nnoremap <silent> <leader><leader>cF :call CscopeQuery('7', 0, 1)<CR>
nnoremap <silent> <leader><leader>cG :call CscopeQuery('1', 0, 1)<CR>
nnoremap <silent> <leader><leader>cI :call CscopeQuery('8', 0, 1)<CR>
nnoremap <silent> <leader><leader>cS :call CscopeQuery('0', 0, 1)<CR>
nnoremap <silent> <leader><leader>cT :call CscopeQuery('4', 0, 1)<CR>

nnoremap <silent> <leader>ca :call Cscope('9', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>cc :call Cscope('3', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>cd :call Cscope('2', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>ce :call Cscope('6', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>cf :call Cscope('7', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>cg :call Cscope('1', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>ci :call Cscope('8', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>cs :call Cscope('0', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>ct :call Cscope('4', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader><leader>fa :call CscopeQuery('9', 1)<CR>
nnoremap <silent> <leader><leader>fc :call CscopeQuery('3', 1)<CR>
nnoremap <silent> <leader><leader>fd :call CscopeQuery('2', 1)<CR>
nnoremap <silent> <leader><leader>fe :call CscopeQuery('6', 1)<CR>
nnoremap <silent> <leader><leader>ff :call CscopeQuery('7', 1)<CR>
nnoremap <silent> <leader><leader>fg :call CscopeQuery('1', 1)<CR>
nnoremap <silent> <leader><leader>fi :call CscopeQuery('8', 1)<CR>
nnoremap <silent> <leader><leader>fs :call CscopeQuery('0', 1)<CR>
nnoremap <silent> <leader><leader>ct :call CscopeQuery('4', 1)<CR>
nnoremap <silent> <leader><leader>ca :call CscopeQuery('9', 1, 1)<CR>
nnoremap <silent> <leader><leader>cc :call CscopeQuery('3', 1, 1)<CR>
nnoremap <silent> <leader><leader>cd :call CscopeQuery('2', 1, 1)<CR>
nnoremap <silent> <leader><leader>ce :call CscopeQuery('6', 1, 1)<CR>
nnoremap <silent> <leader><leader>cf :call CscopeQuery('7', 1, 1)<CR>
nnoremap <silent> <leader><leader>cg :call CscopeQuery('1', 1, 1)<CR>
nnoremap <silent> <leader><leader>ci :call CscopeQuery('8', 1, 1)<CR>
nnoremap <silent> <leader><leader>cs :call CscopeQuery('0', 1, 1)<CR>
nnoremap <silent> <leader><leader>ct :call CscopeQuery('4', 1, 1)<CR>

function! Cscope(option, query, preview, ...)
    let l:ignorecase = get(a:, 2, 0)
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
    if a:preview
        let opts = fzf#vim#with_preview(opts)
    endif

    let name = expand('<cword>')
    let pos = getcurpos()
    let buf = bufnr()

    let result = fzf#vim#grep(grep_command, 0, opts, 0)

    if len(result) != 0
        if buf == bufnr() && pos[1] == getcurpos()[1]
            return 1
        endif
        call TagstackPush(name, pos, buf)
        return 1
    endif
    return 0
endfunction

function! CscopeQuery(option, preview, ...)
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
    let l:ignorecase = get(a:, 2, 0)
    if l:ignorecase
      call Cscope(a:option, query, a:preview, 1)
    else
      call Cscope(a:option, query, a:preview)
    endif
  else
    echom "Cancelled Search!"
  endif
endfunction

" Opengrok Search
nnoremap <silent> <leader>zo :call OgQuery('f', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader><leader>zo :call OgQuery('f', input('Text: '), 1)<CR>
nnoremap <silent> <leader>zO :call OgQuery('f', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader><leader>zO :call OgQuery('f', input('Text: '), 0)<CR>

function! OgQuery(option, query, preview)
    let awk_program =
        \    '{ x = $1; $1 = ""; z = $3; $3 = ""; ' .
        \    'printf "%s:%s:%s\n", x,z,$0; }'
    let grep_command =
        \    "java -Xmx2048m -cp ~/.vim/bin/opengrok/lib/opengrok.jar org.opensolaris.opengrok.search.Search -R .opengrok/configuration.xml -" .
        \    a:option . " " . shellescape(a:query) . "| grep \"^/.*\" | " . s:sed . " 's@</\\?.>@@g' | " . s:sed . " 's/&amp;/\\&/g' | " . s:sed . " 's/-\&gt;/->/g'" .
        \    " | awk '" . awk_program . "'"

    let fzf_color_option = split(fzf#wrap()['options'])[0]
    let opts = { 'options': fzf_color_option . ' --prompt "> "'}
    if a:preview
        let opts = fzf#vim#with_preview(opts)
    endif

    let name = expand('<cword>')
    let pos = getcurpos()
    let buf = bufnr()

    let result = fzf#vim#grep(grep_command, 0, opts, 0)

    if len(result) != 0
        if buf == bufnr() && pos[1] == getcurpos()[1]
            return 1
        endif
        call TagstackPush(name, pos, buf)
        return 1
    endif
    return 0
endfunction

" Cursor Line
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

" Lsp Jump
let g:lsp_jump_function = 0

" vim-lsp configuration
if g:lsp_choice == 'vim-lsp'
    let g:asyncomplete_remove_duplicates = 1
    let g:asyncomplete_smart_completion = 1

    inoremap <silent> <C-@> <plug>(asyncomplete_force_refresh)

    highlight clear LspWarningLine
    highlight clear LspErrorHighlight
    highlight link LspErrorText None
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
        autocmd!
        " call s:on_lsp_buffer_enabled only for languages that has the server registered.
        autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
    augroup end
endif

" Coc
if g:lsp_choice == 'coc'
    let g:coc_global_extensions = ['coc-clangd', 'coc-python', 'coc-json', 'coc-vimlsp']
    let g:coc_fzf_preview = 'right:50%'

    "nmap <silent> gd <Plug>(coc-definition)
    nmap <silent> gd :call ZLspJump('Definition')<CR>

    "nmap <silent> gi <Plug>(coc-implementation)
    nmap <silent> gi :call ZLspJump('Implementation')<CR>

    "nmap <silent> gr <Plug>(coc-references)
    nmap <silent> gr :call ZLspJump('References')<CR>

    nmap <silent> gy <Plug>(coc-type-definition)
    nmap <silent> go :CocCommand clangd.switchSourceHeader<CR>
    nnoremap <silent> K :call <SID>show_documentation()<CR>
    nmap <silent> [g <Plug>(coc-diagnostic-prev)
    nmap <silent> ]g <Plug>(coc-diagnostic-next)
    nmap <silent> <leader>rn <Plug>(coc-rename)
    xmap <silent> <leader>lf <Plug>(coc-format-selected)
    nnoremap <silent> <leader>ld :CocDiagnostics<CR>
    inoremap <silent> <expr> <CR> "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"")"))

    highlight clear CocErrorSign
    highlight link CocErrorSign None
    highlight clear CocErrorFloat
    highlight link CocErrorFloat None
    highlight clear CocWarningFloat
    highlight link CocWarningFloat None
    highlight clear CocInfoSign
    highlight link CocInfoSign None
    highlight clear CocInfoFloat
    highlight link CocInfoFloat None

    function! s:show_documentation()
      if (index(['vim','help'], &filetype) >= 0)
        execute 'h '.expand('<cword>')
      else
        call CocAction('doHover')
      endif
    endfunction

    let g:lsp_jump_function = 1
    function! ZLspJump(jump_type)
        if a:jump_type == 'definition'
            let jump_type = 'Definition'
        else
            let jump_type = a:jump_type
        endif
        let name = expand('<cword>')
        let pos = getcurpos()
        let buf = bufnr()
        call setpos('.', [pos[0], pos[1], pos[2]+1, pos[3]])
        if CocAction('jump' . jump_type)
            let newpos = getcurpos()
            if buf == bufnr() && pos[1] == newpos[1]
                if pos[2]+1 != newpos[2]
                    return 0
                endif
                call setpos('.', pos)
                call TagstackPush(name, pos, buf)
                return 1
            endif
            if name != expand('<cword>') && &ft != 'python'
                execute "normal \<C-o>"
                call setpos('.', pos)
                return 0
            endif
            call TagstackPush(name, pos, buf)
            return 1
        else
            call setpos('.', pos)
        endif
        return 0
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
let g:pear_tree_smart_openers = 1
let g:pear_tree_smart_closers = 1
let g:pear_tree_smart_backspace = 1

" If enabled, smart pair functions timeout after 60ms:
let g:pear_tree_timeout = 60

" Don't automatically map <BS>, <CR>, and <Esc>
let g:pear_tree_map_special_keys = 0

" Peer tree mappings:
imap <BS> <Plug>(PearTreeBackspace)

" Vimspector
nnoremap <silent> <leader>dl :call ZDebugLaunchSettings()<CR>
nnoremap <silent> <leader>dd :if !filereadable('.vimspector.json') \| call ZDebugLaunchSettings() \| endif \| call vimspector#Launch()<CR>
nmap <leader>dc <plug>VimspectorContinue
nmap <F5> <plug>VimspectorContinue
nmap <leader>dr <plug>VimspectorRestart
nmap <S-F5> <plug>VimspectorRestart
nmap <leader>dp <plug>VimspectorPause
nmap <F6> <plug>VimspectorPause
nmap <leader>ds <plug>VimspectorStop
nmap <S-F6> <plug>VimspectorStop
nmap <leader>db <plug>VimspectorToggleBreakpoint
nmap <F9> <plug>VimspectorToggleBreakpoint
nmap <leader><leader>db <plug>VimspectorToggleConditionalBreakpoint
nmap <S-F9> <plug>VimspectorToggleConditionalBreakpoint
nmap <leader>df <plug>VimspectorAddFunctionBreakpoint
nmap <leader><F9> <plug>VimspectorAddFunctionBreakpoint
nnoremap <silent> <leader>dB :call vimspector#ClearBreakpoints()<CR>
nnoremap <silent> <leader><leader><F9> :call vimspector#ClearBreakpoints()<CR>
nmap <leader>dn <plug>VimspectorStepOver
nmap <F10> <plug>VimspectorStepOver
nmap <leader>di <plug>VimspectorStepInto
nmap <S-F10> <plug>VimspectorStepInto
nmap <F11> <plug>VimspectorStepInto
nmap <leader>do <plug>VimspectorStepOut
nmap <S-F11> <plug>VimspectorStepOut
nnoremap <silent> <leader>dq :VimspectorReset<CR>
nnoremap <silent> <leader>dm :call InitializeVimspectorCommandHistoryMaps()<CR>
let g:vimspector_sign_priority = {
  \    'vimspectorBP':         300,
  \    'vimspectorBPCond':     200,
  \    'vimspectorBPDisabled': 100,
  \    'vimspectorPC':         999,
  \    'vimspectorPCBP':       999,
  \ }
augroup vimspector_custom_mappings
    autocmd!
    autocmd FileType VimspectorPrompt call InitializeVimspectorPrompt()
    autocmd BufEnter *
        \   if index(['vimspector.StackTrace', 'vimspector.Watches', 'vimspector.Variables'], bufname()) != -1
        \ |     nnoremap <silent> <buffer> <2-LeftMouse> :call VimspectorSelectLine()<CR>
        \ | endif
augroup end
function! InitializeVimspectorPrompt()
    nnoremap <silent> <buffer> x i-exec<space>
    if !exists('b:vimspector_command_history')
        call InitializeVimspectorCommandHistoryMaps()
        let b:vimspector_command_history = []
        let b:vimspector_command_history_pos = 0
    endif
endfunction
function! InitializeVimspectorCommandHistoryMaps()
    inoremap <silent> <buffer> <CR> <C-o>:call VimspectorCommandHistoryAdd()<CR>
    inoremap <silent> <buffer> <Up> <C-o>:call VimspectorCommandHistoryUp()<CR>
    inoremap <silent> <buffer> <Down> <C-o>:call VimspectorCommandHistoryDown()<CR>
endfunction
function! VimspectorSelectLine()
    call feedkeys("\<CR>", 't')
endfunction
function! VimspectorCommandHistoryAdd()
    call add(b:vimspector_command_history, getline('.'))
    let b:vimspector_command_history_pos = len(b:vimspector_command_history)
    call feedkeys("\<CR>", 'tn')
endfunction
function! VimspectorCommandHistoryUp()
    if len(b:vimspector_command_history) == 0 || b:vimspector_command_history_pos == 0
        return
    endif
    call setline('.', b:vimspector_command_history[b:vimspector_command_history_pos - 1])
    call feedkeys("\<C-o>A", 'tn')
    let b:vimspector_command_history_pos = b:vimspector_command_history_pos - 1
endfunction
function! VimspectorCommandHistoryDown()
    if b:vimspector_command_history_pos == len(b:vimspector_command_history)
        return
    endif
    call setline('.', b:vimspector_command_history[b:vimspector_command_history_pos - 1])
    call feedkeys("\<C-o>A", 'tn')
    let b:vimspector_command_history_pos = b:vimspector_command_history_pos + 1
endfunction
augroup visual_multi_vimspector
    autocmd!
    autocmd User visual_multi_exit if &ft == 'VimspectorPrompt' | call InitializeVimspectorCommandHistoryMaps() | endif
augroup end

" Binary
augroup binary_file
    autocmd!
    autocmd BufReadPost * if &bin | set ft=xxd | exec "%!xxd" | endif
    autocmd BufWritePre * if &bin | set ft=xxd | exec "%!xxd -r" | endif
    autocmd BufWritePost * if &bin | set ft=xxd | exec "%!xxd" | endif
augroup end

" Zip
let g:zipPlugin_ext= '*.zip,*.jar,*.xpi,*.ja,*.war,*.ear,*.celzip,
    \ *.oxt,*.kmz,*.wsz,*.xap,*.docm,*.dotx,*.dotm,*.potx,*.potm,
    \ *.ppsx,*.ppsm,*.pptx,*.pptm,*.ppam,*.sldx,*.thmx,*.xlam,*.xlsx,*.xlsm,
    \ *.xlsb,*.xltx,*.xltm,*.xlam,*.crtx,*.vdw,*.glox,*.gcsx,*.gqsx,*.epub'

" Pandoc
augroup pandoc_group
    autocmd!
    autocmd BufReadPost *.doc,*.docx,*.rtf,*.odp,*.odt if !&bin |
        \ silent exec "\%!pandoc \"%\" -tmarkdown -o /dev/stdout" | set ft=markdown | set ro | endif
augroup end
command! -complete=file -nargs=1 PandocEdit
    \ call system("pandoc -f " .  split(<f-args>, '\.')[-1] . " -t markdown " .
    \ <f-args> . "> " . <f-args> . ".md")
    \ | exec "edit " . <f-args> . ".md"
command! -nargs=0 PandocWrite
    \ exec ":w" |
    \ call system("pandoc -f markdown -t " .  split(expand('%:p'), '\.')[-2] .
    \ " " .  expand('%:p') . "> " . split(expand('%:p'), '\.md')[0])

" Fix function keys for tmux.
if !empty($TMUX)
    exec "set <S-F1>=\<ESC>[25~"
    exec "set <S-F2>=\<ESC>[26~"
    exec "set <S-F3>=\<ESC>[28~"
    exec "set <S-F4>=\<ESC>[29~"
    exec "set <S-F5>=\<ESC>[31~"
    exec "set <S-F6>=\<ESC>[32~"
    exec "set <S-F7>=\<ESC>[33~"
    exec "set <S-F8>=\<ESC>[34~"
endif

" Vimspector functions.
function! ZGenerateVimspectorCpp()
    call inputsave()
    let target = input('Target (Executable/IP): ')
    call inputrestore()
    let debugger = 'gdb'
    if !executable('gdb') && executable('lldb')
        let debugger = 'lldb'
    endif
    if stridx(target, ':') != -1 && !filereadable(target)
        call inputsave()
        let main_file = input('Main File: ')
        call inputrestore()
        call system("
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
            \ echo '}' >> .vimspector.json")
    else
        call system("
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
            \ echo '                \"cwd\": \"${workspaceRoot}\",' >> .vimspector.json &&
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
            \ echo '}' >> .vimspector.json")
    endif
endfunction

function! ZGenerateVimspectorPy()
    call inputsave()
    let program = input('Python main file: ')
    let python = 'python3'
    call inputrestore()
    call system("
        \ echo '{' > .vimspector.json &&
        \ echo '    \"configurations\": {' >> .vimspector.json &&
        \ echo '        \"Launch\": {' >> .vimspector.json &&
        \ echo '            \"adapter\": \"debugpy\",' >> .vimspector.json &&
        \ echo '            \"breakpoints\": {\"exception\": {\"raised\": \"N\", \"uncaught\": \"Y\"}},' >> .vimspector.json &&
        \ echo '            \"configuration\": {' >> .vimspector.json &&
        \ echo '                \"request\": \"launch\",' >> .vimspector.json &&
        \ echo '                \"type\": \"python\",' >> .vimspector.json &&
        \ echo '                \"program\": \"" . program . "\",' >> .vimspector.json &&
        \ echo '                \"python\": \"" . python . "\",' >> .vimspector.json &&
        \ echo '                \"cwd\": \"${workspaceRoot}\",' >> .vimspector.json &&
        \ echo '                \"externalConsole\": true,' >> .vimspector.json &&
        \ echo '                \"stopAtEntry\": true' >> .vimspector.json &&
        \ echo '            }' >> .vimspector.json &&
        \ echo '        }' >> .vimspector.json &&
        \ echo '    }' >> .vimspector.json &&
        \ echo '}' >> .vimspector.json")
endfunction

function ZDebugLaunchSettings()
    let debug_type = &filetype
    if debug_type != 'cpp' && debug_type != 'c' && debug_type != 'python'
        call inputsave()
        let debug_type = input('Debugger type (cpp/python): ')
        call inputrestore()
    endif

    if debug_type == 'cpp' || debug_type == 'c'
        call ZGenerateVimspectorCpp()
    elseif debug_type == 'python'
        call ZGenerateVimspectorPy()
    else
        normal :<ESC>
        echom 'Invalid debug type.'
    endif
endfunction

" Generate Flags
function! ZGenerateFlags()
    let cpp_include_1 = system("rg --files -g string_view /usr/lib 2> /dev/null | grep -v tr1 | grep -v experimental | sort | tail -n 1")
    if empty(cpp_include_1)
        let cpp_include_1 = system("rg --files -g string_view /usr/local 2> /dev/null | grep -v tr1 | grep -v experimental | sort | tail -n 1")
    endif
    if empty(cpp_include_1)
        let cpp_include_1 = '/usr/include'
    else
        let cpp_include_1 = system("dirname " . cpp_include_1)
    endif

    let cpp_include_2 = system("rg --files -g cstdlib /usr/include/c++ 2> /dev/null | grep -v tr1 | grep -v experimental | sort | tail -n 1")
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
    \ && set +e ; find . -type d -name inc -or -name include -or -name Include | grep -v \"/\\.\" | " . s:sed . " s@^@-isystem\\\\n@g >> compile_flags.txt ; set -e
    \ && echo -x >> compile_flags.txt
    \ && echo c++ >> compile_flags.txt"
endfunction

" Generate Tags
function! ZGenerateTags()
    copen
    exec ":AsyncRun echo '" . g:ctagsOptions . "' > .gutctags && " . s:sed . " -i 's/ /\\n/g' .gutctags && ctags " . g:ctagsOptions
endfunction

function! ZGenerateEveryTags()
    copen
    exec ":AsyncRun echo '" . g:ctagsEverythingOptions . "' > .gutctags && " . s:sed . " -i 's/ /\\n/g' .gutctags && ctags " . g:ctagsEverythingOptions
endfunction

" Generate Files
function! ZGenerateSourceFilesCache()
    copen
    exec ":AsyncRun rg --files " . g:sourceFilePatterns . " > .files"
endfunction

function! ZGenerateFilesCache()
    copen
    exec ":AsyncRun " . g:fzf_files_nocache_command . " > .files"
endfunction

" Generate C++
function! ZGenerateCpp()
    copen
    if !filereadable('compile_commands.json')
        let cpp_include_1 = system("rg --files -g string_view /usr/lib 2> /dev/null | grep -v tr1 | grep -v experimental | sort | tail -n 1")
        if empty(cpp_include_1)
            let cpp_include_1 = system("rg --files -g string_view /usr/local 2> /dev/null | grep -v tr1 | grep -v experimental | sort | tail -n 1")
        endif
        if empty(cpp_include_1)
            let cpp_include_1 = '/usr/include'
        else
            let cpp_include_1 = system("dirname " . cpp_include_1)
        endif

        let cpp_include_2 = system("rg --files -g cstdlib /usr/include/c++ 2> /dev/null | grep -v tr1 | grep -v experimental | sort | tail -n 1")
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
        \ && set +e ; find . -type d -name inc -or -name include -or -name Include | grep -v \"/\\.\" | " . s:sed . " s@^@-isystem\\\\n@g >> compile_flags.txt ; set -e
        \ && echo -x >> compile_flags.txt
        \ && echo c++ >> compile_flags.txt
        \ && echo '" . g:ctagsOptions . "' > .gutctags
        \ && " . s:sed . " -i 's/ /\\n/g' .gutctags
        \ && rg --files " . g:ctagsFilePatterns . " > cscope.files
        \ && if ! [ -f .files ]; then cp cscope.files .files; rg --files " . g:otherFilePatterns . " >> .files; fi
        \ && cscope -bq"
    else
        exec ":AsyncRun
        \ echo '" . g:ctagsOptions . "' > .gutctags
        \ && " . s:sed . " -i 's/ /\\n/g' .gutctags
        \ && rg --files " . g:ctagsFilePatterns . " > cscope.files
        \ && if ! [ -f .files ]; then cp cscope.files .files; rg --files " . g:otherFilePatterns . " >> .files; fi
        \ && cscope -bq"
    endif
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

" Jump to location
function! ZJumpToLocation(file, line, column)
    silent exec ":edit " . fnameescape(a:file) . ""
    silent exec ":" . a:line
    if a:column
        silent exec ":normal! " . a:column . "|"
    endif
    normal! zz
endfunction

" Additional highlighting
function! ZSyntaxInfo()
    let l:s = synID(line('.'), col('.'), 1)
    echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
endfun

if g:colors_name == 'codedark'
    " Terminal colors (base16):
    let s:cterm00 = "00"
    let s:cterm03 = "08"
    let s:cterm05 = "07"
    let s:cterm07 = "15"
    let s:cterm08 = "01"
    let s:cterm0A = "03"
    let s:cterm0B = "02"
    let s:cterm0C = "06"
    let s:cterm0D = "04"
    let s:cterm0E = "05"
    if exists('base16colorspace') && base16colorspace == "256"
      let s:cterm01 = "18"
      let s:cterm02 = "19"
      let s:cterm04 = "20"
      let s:cterm06 = "21"
      let s:cterm09 = "16"
      let s:cterm0F = "17"
    else
      let s:cterm01 = "00"
      let s:cterm02 = "08"
      let s:cterm04 = "07"
      let s:cterm06 = "07"
      let s:cterm09 = "06"
      let s:cterm0F = "03"
    endif

    function! ZHighLight(group, fg, bg, attr, sp)
        if !empty(a:fg)
            exec "hi " . a:group . " guifg=" . a:fg.gui . " ctermfg=" . (g:codedark_term256 ? a:fg.cterm256 : a:fg.cterm)
        endif
        if !empty(a:bg)
            exec "hi " . a:group . " guibg=" . a:bg.gui . " ctermbg=" . (g:codedark_term256 ? a:bg.cterm256 : a:bg.cterm)
        endif
        if a:attr != ""
            exec "hi " . a:group . " gui=" . a:attr . " cterm=" . a:attr
        endif
        if !empty(a:sp)
            exec "hi " . a:group . " guisp=" . a:sp.gui
        endif
    endfunction

    let s:cdLightBlue = {'gui': '#9CDCFE', 'cterm': s:cterm0C, 'cterm256': '117'}
    let s:cdBlue = {'gui': '#569CD6', 'cterm': s:cterm0D, 'cterm256': '75'}
    let s:cdYellow = {'gui': '#DCDCAA', 'cterm': s:cterm0A, 'cterm256': '187'}
    let s:cdPink = {'gui': '#C586C0', 'cterm': s:cterm0E, 'cterm256': '176'}
    let s:cdBlueGreen = {'gui': '#4EC9B0', 'cterm': s:cterm0F, 'cterm256': '43'}
    let s:cdGreen = {'gui': '#6A9955', 'cterm': s:cterm0B, 'cterm256': '65'}
    let s:cdRed = {'gui': '#F44747', 'cterm': s:cterm08, 'cterm256': '203'}
    let s:cdFront = {'gui': '#D4D4D4', 'cterm': s:cterm05, 'cterm256': '188'}

    " C++
    call ZHighLight('cCustomAccessKey', s:cdBlue, {}, 'none', {})
    call ZHighLight('cppModifier', s:cdBlue, {}, 'none', {})
    call ZHighLight('cppExceptions', s:cdBlue, {}, 'none', {})
    call ZHighLight('cppSTLType', s:cdBlueGreen, {}, 'none', {})
    call ZHighLight('cppSTLnamespace', s:cdBlueGreen, {}, 'none', {})
    call ZHighLight('cCustomClassName', s:cdBlueGreen, {}, 'none', {})
    call ZHighLight('cppSTLexception', s:cdBlueGreen, {}, 'none', {})
    call ZHighLight('cppSTLconstant', s:cdLightBlue, {}, 'none', {})
    call ZHighLight('cppSTLvariable', s:cdLightBlue, {}, 'none', {})
    call ZHighLight('cppSTLfunction', s:cdYellow, {}, 'none', {})
    call ZHighLight('cCustomOperator', s:cdYellow, {}, 'none', {})
    call ZHighLight('cConstant', s:cdPink, {}, 'none', {})
    "call ZHighLight('cRepeat', s:cdPink, {}, 'none', {})
    "call ZHighLight('cConditional', s:cdPink, {}, 'none', {})
    "call ZHighLight('cStatement', s:cdPink, {}, 'none', {})
    "call ZHighLight('cppStatement', s:cdPink, {}, 'none', {})

    " Python
    call ZHighLight('pythonBuiltin', s:cdLightBlue, {}, 'none', {})
    call ZHighLight('pythonBuiltinFunc', s:cdLightBlue, {}, 'none', {})
    call ZHighLight('pythonBuiltinObj', s:cdLightBlue, {}, 'none', {})
    call ZHighLight('pythonRepeat', s:cdPink, {}, 'none', {})
    call ZHighLight('pythonConditional', s:cdPink, {}, 'none', {})
    call ZHighLight('pythonOperator', s:cdPink, {}, 'none', {})
    call ZHighLight('pythonException', s:cdPink, {}, 'none', {})
    call ZHighLight('pythonExceptions', s:cdLightBlue, {}, 'none', {})
    call ZHighLight('pythonImport', s:cdBlue, {}, 'none', {})
    call ZHighLight('pythonInclude', s:cdBlue, {}, 'none', {})
    call ZHighLight('pythonFunction', s:cdYellow, {}, 'none', {})
    call ZHighLight('pythonDecorator', s:cdYellow, {}, 'none', {})

    " Gitgutter
    call ZHighLight('GitGutterAdd', s:cdGreen, {}, 'none', {})
    call ZHighLight('GitGutterChange', s:cdFront, {}, 'none', {})
    call ZHighLight('GitGutterDelete', s:cdRed, {}, 'none', {})

    " NERD Tree
    call ZHighLight('NERDTreeOpenable', s:cdPink, {}, 'none', {})
    call ZHighLight('NERDTreeClosable', s:cdPink, {}, 'none', {})
    call ZHighLight('NERDTreeHelp', s:cdPink, {}, 'none', {})
    call ZHighLight('NERDTreeDir', s:cdLightBlue, {}, 'none', {})
    call ZHighLight('NERDTreeDirSlash', s:cdBlue, {}, 'none', {})
    call ZHighLight('NERDTreeCWD', s:cdYellow, {}, 'none', {})
    call ZHighLight('NERDTreeUp', s:cdBlue, {}, 'none', {})
    call ZHighLight('NERDTreeFile', s:cdFront, {}, 'none', {})
    call ZHighLight('NERDTreeExecFile', s:cdFront, {}, 'none', {})
    call ZHighLight('NERDTreeLinkFile', s:cdBlueGreen, {}, 'none', {})

    " Vim
    call ZHighLight('VimOperError', s:cdRed, {}, 'none', {})

    " Cursor line
    highlight CursorLine ctermbg=235 guibg=#2b2b2b
elseif g:colors_name == 'onedark'
    let s:group_colors = {} " Cache of default highlight group settings, for later reference via `onedark#extend_highlight`
    function! ZHighLight(group, style, ...)
        if (a:0 > 0) " Will be true if we got here from onedark#extend_highlight
            let s:highlight = s:group_colors[a:group]
            for style_type in ["fg", "bg", "sp"]
                if (has_key(a:style, style_type))
                    let l:default_style = (has_key(s:highlight, style_type) ? s:highlight[style_type] : { "cterm16": "NONE", "cterm": "NONE", "gui": "NONE" })
                    let s:highlight[style_type] = extend(l:default_style, a:style[style_type])
                endif
            endfor
            if (has_key(a:style, "gui"))
                let s:highlight.gui = a:style.gui
            endif
        else
            let s:highlight = a:style
            let s:group_colors[a:group] = s:highlight " Cache default highlight group settings
        endif

        if g:onedark_terminal_italics == 0
            if has_key(s:highlight, "cterm") && s:highlight["cterm"] == "italic"
                unlet s:highlight.cterm
            endif
            if has_key(s:highlight, "gui") && s:highlight["gui"] == "italic"
                unlet s:highlight.gui
            endif
        endif

        if g:onedark_termcolors == 16
            let l:ctermfg = (has_key(s:highlight, "fg") ? s:highlight.fg.cterm16 : "NONE")
            let l:ctermbg = (has_key(s:highlight, "bg") ? s:highlight.bg.cterm16 : "NONE")
        else
            let l:ctermfg = (has_key(s:highlight, "fg") ? s:highlight.fg.cterm : "NONE")
            let l:ctermbg = (has_key(s:highlight, "bg") ? s:highlight.bg.cterm : "NONE")
        endif

        execute "highlight" a:group
            \ "guifg="     (has_key(s:highlight, "fg")        ? s:highlight.fg.gui     : "NONE")
            \ "guibg="     (has_key(s:highlight, "bg")        ? s:highlight.bg.gui     : "NONE")
            \ "guisp="     (has_key(s:highlight, "sp")        ? s:highlight.sp.gui     : "NONE")
            \ "gui="         (has_key(s:highlight, "gui")     ? s:highlight.gui            : "NONE")
            \ "ctermfg=" . l:ctermfg
            \ "ctermbg=" . l:ctermbg
            \ "cterm="     (has_key(s:highlight, "cterm") ? s:highlight.cterm        : "NONE")
    endfunction

    let s:onedarkWhite = { "gui": "#ABB2BF", "cterm": "145", "cterm16": "7" }

    " Tagbar Highlights
    call ZHighLight('TagbarSignature', {"fg": s:onedarkWhite})
endif
