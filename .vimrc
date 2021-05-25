" vim:fdm=marker

" Be Improved {{{
set nocompatible
" }}}

" OS Detection {{{
if !exists('s:os')
    if has("win64") || has("win32") || has("win16")
        let s:os = "Windows"
    else
        let s:os = substitute(system('uname'), '\n', '', '')
    endif
endif
" }}}

" Installation {{{

" Clang Version
let s:clang_version = 11

" Sed program to use
let s:sed = 'sed'
if s:os == 'Darwin'
    let s:sed = 'gsed'
endif

" Install command
function! ZInstallCommand(command)
    silent exec "! echo ============================================ && echo Install command: " . shellescape(a:command)
    silent exec "!" . a:command
    if v:shell_error
        silent exec "!echo Installation failed, error: " . string(v:shell_error)
        throw "Error: installation failed."
    endif
endfunction

" Install vimrc
function! ZInstallVimrc()
    if empty($SUDO_USER)
        echo "Please run as sudo."
        exec ":q"
    endif
    try
        call ZInstallCommand("mkdir -p ~/.vim/tmp ~/.vim/bin/python ~/.vim/bin/llvm ~/.vim/undo ~/.vim/nundo ~/.config/coc ~/.cache")
        if !executable('brew')
            call ZInstallCommand("DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:lazygit-team/release")
            call ZInstallCommand("curl -sL https://deb.nodesource.com/setup_14.x | bash -")
            call ZInstallCommand("curl -fLo ~/.vim/tmp/llvm-install/llvm.sh --create-dirs
                \ https://apt.llvm.org/llvm.sh
                \ ; cd ~/.vim/tmp/llvm-install; chmod +x ./llvm.sh; ./llvm.sh " . s:clang_version)
            call ZInstallCommand("DEBIAN_FRONTEND=noninteractive apt install -y curl silversearcher-ag exuberant-ctags cscope git
                \ make autoconf automake pkg-config openjdk-8-jre python3 python3-pip gdb golang nodejs lazygit libc++-" . s:clang_version . "-dev libc++abi-" . s:clang_version . "-dev")
            call ZInstallCommand("rm -rf ~/.vim/bin/llvm/clangd && ln -s $(command -v clangd-" . s:clang_version . ") ~/.vim/bin/llvm/clangd")
            let lazygit_config_path = '~/.config/jesseduffield/lazygit'
        else
            call ZInstallCommand("sudo -u $SUDO_USER brew install curl ag ctags cscope git
                \ llvm make autoconf automake pkg-config python3 nodejs gnu-sed bat ripgrep lazygit golang pandoc || true")
            call ZInstallCommand("rm -rf /usr/local/bin/2to3")
            call ZInstallCommand("sudo -u $SUDO_USER brew link python3")
            call ZInstallCommand("sudo -u $SUDO_USER brew tap AdoptOpenJDK/openjdk")
            call ZInstallCommand("sudo -u $SUDO_USER brew install --cask adoptopenjdk/openjdk/adoptopenjdk8")
            call ZInstallCommand("sudo -u $SUDO_USER curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py")
            call ZInstallCommand("sudo -u $SUDO_USER python3 get-pip.py")
            if !executable('clangd') && executable('/usr/local/opt/llvm/bin/clangd')
                call ZInstallCommand("echo export PATH=\\$PATH:/usr/local/opt/llvm/bin >> ~/.bashrc")
            endif
            let lazygit_config_path = '~/Library/Application\ Support/jesseduffield/lazygit'
        endif
        if 0 == system('python3 -c "import sys; print(1 if sys.version_info.major >= 3 and sys.version_info.minor >= 6 else 0)"') && executable('python3.6')
            call ZInstallCommand("rm -rf ~/.vim/bin/python/python3 && ln -s $(command -v python3.6) ~/.vim/bin/python/python3")
            let $PATH = expand('~/.vim/bin/python') . ':' . $PATH
            let python3_command = 'python3.6'
        else
            let python3_command = 'python3'
        endif
        if executable(python3_command)
            call ZInstallCommand("sudo -u $SUDO_USER " . python3_command . " -m pip install setuptools")
            call ZInstallCommand("sudo -u $SUDO_USER " . python3_command . " -m pip install python-language-server pylint compiledb jedi")
        endif
        if executable('python3') && python3_command != 'python3'
            call ZInstallCommand("sudo -u $SUDO_USER python3 -m pip install --upgrade 'setuptools; python_version >= \"3.6\"' 'setuptools<51.3.0; python_version < \"3.6\" and python_version >= \"3.0\"'")
            call ZInstallCommand("sudo -u $SUDO_USER python3 -m pip install pylint compiledb jedi")
        endif
        if !filereadable(expand('~/.vim/autoload/plug.vim'))
            call ZInstallCommand("curl -fLo ~/.vim/autoload/plug.vim --create-dirs
              \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim")
        endif
        if !filereadable(expand('~/.vim/bin/opengrok/lib/opengrok.jar'))
            call ZInstallCommand("curl -fLo ~/.vim/bin/opengrok.tar.gz --create-dirs
              \ https://github.com/oracle/opengrok/releases/download/1.0/opengrok-1.0.tar.gz")
            call ZInstallCommand("cd ~/.vim/bin; tar -xzvf opengrok.tar.gz")
            call ZInstallCommand("rm ~/.vim/bin/opengrok.tar.gz")
            call ZInstallCommand("mv ~/.vim/bin/opengrok* ~/.vim/bin/opengrok")
        endif
        if !filereadable(expand('~/.vim/tmp/ctags/Makefile'))
            call ZInstallCommand("cd ~/.vim/tmp; git clone https://github.com/universal-ctags/ctags.git; cd ./ctags; ./autogen.sh; ./configure; make -j; make install")
        endif
        if !executable('ctags-exuberant') && !filereadable(expand('~/.vim/bin/ctags-exuberant/ctags/ctags'))
            call ZInstallCommand("curl -fLo ~/.vim/bin/ctags-exuberant/ctags.tar.gz --create-dirs
              \ http://prdownloads.sourceforge.net/ctags/ctags-5.8.tar.gz")
            call ZInstallCommand("cd ~/.vim/bin/ctags-exuberant; tar -xzvf ctags.tar.gz")
            call ZInstallCommand("mv ~/.vim/bin/ctags-exuberant/ctags-5.8 ~/.vim/bin/ctags-exuberant/ctags")
            call ZInstallCommand("cd ~/.vim/bin/ctags-exuberant/ctags; " . s:sed . " -i 's@\\# define __unused__  _.*@\\#define __unused__@g' ./general.h; ./configure; make -j")
        endif
        if !filereadable(expand('~/.vim/bin/lf/lf'))
            if !executable('brew')
                call ZInstallCommand("curl -fLo ~/.vim/bin/lf/lf.tar.gz --create-dirs
                  \ https://github.com/gokcehan/lf/releases/download/r16/lf-linux-amd64.tar.gz")
            else
                call ZInstallCommand("curl -fLo ~/.vim/bin/lf/lf.tar.gz --create-dirs
                  \ https://github.com/gokcehan/lf/releases/download/r16/lf-darwin-amd64.tar.gz")
            endif
            call ZInstallCommand("cd ~/.vim/bin/lf; tar -xzvf lf.tar.gz")
        endif
        if !executable('bat') && !executable('brew')
            if !empty(system('apt-cache search --names-only ^bat\$'))
                call ZInstallCommand("DEBIAN_FRONTEND=noninteractive apt install -y bat")
            else
                call ZInstallCommand("curl -fLo ~/.vim/tmp/bat --create-dirs
                    \ https://github.com/sharkdp/bat/releases/download/v0.15.1/bat_0.15.1_amd64.deb")
                call ZInstallCommand("dpkg -i ~/.vim/tmp/bat")
            endif
        endif
        if !executable('rg') && !executable('brew')
            call ZInstallCommand("curl -fLo ~/.vim/tmp/ripgrep --create-dirs
                \ https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep_12.1.1_amd64.deb")
            call ZInstallCommand("dpkg -i ~/.vim/tmp/ripgrep")
        endif
        if !executable('brew') && !filereadable(expand('~/.vim/tmp/pandoc.deb'))
            call ZInstallCommand("curl -fLo ~/.vim/tmp/pandoc.deb --create-dirs
                \ https://github.com/jgm/pandoc/releases/download/2.10.1/pandoc-2.10.1-1-amd64.deb")
            call ZInstallCommand("dpkg -i ~/.vim/tmp/pandoc.deb")
        endif
        if !filereadable(expand('~/.config/nvim/init.vim'))
            call ZInstallCommand("
                \ mkdir -p ~/.config/nvim
                \ && echo 'set untimepath^=~/.vim runtimepath+=~/.vim/after' > ~/.config/nvim/init.vim
                \ && echo 'let &packpath=&runtimepath' >> ~/.config/nvim/init.vim
                \ && echo 'source ~/.vimrc' >> ~/.config/nvim/init.vim
            \ ")
        endif
        call ZInstallCommand("touch ~/.vim/.indentlines")
        call ZInstallCommand("chown -R $SUDO_USER:$SUDO_GID ~/.vim")
        call ZInstallCommand("chown -R $SUDO_USER:$SUDO_GID ~/.config")
        call ZInstallCommand("chown -R $SUDO_USER:$SUDO_GID ~/.cache")
        call ZInstallCommand("chown $SUDO_USER:$SUDO_GID ~/.vimrc")
        call ZInstallCommand("
            \ sudo -u $SUDO_USER mkdir -p " . lazygit_config_path . "
            \ && sudo -u $SUDO_USER touch " . lazygit_config_path . "/config.yml
            \ && echo 'startuppopupversion: 1' > " . lazygit_config_path . "/config.yml
            \ && echo 'gui:' >> " . lazygit_config_path . "/config.yml
            \ && echo '  theme:' >> " . lazygit_config_path . "/config.yml
            \ && echo '    selectedLineBgColor:' >> " . lazygit_config_path . "/config.yml
            \ && echo '      - reverse' >> " . lazygit_config_path . "/config.yml
        \ ")
        call ZInstallCommand("sudo -u $SUDO_USER INSTALL_VIMRC_PLUGINS=1 INSTALL_VIMRC= vim -E -s -u ~/.vimrc +qa")
        call ZInstallCommand("sudo -u $SUDO_USER " . python3_command . " ~/.vim/plugged/vimspector/install_gadget.py --sudo --enable-c --enable-python")
        silent exec "!echo Done."
    catch
        echo v:exception
        exec ":cq"
    endtry
endfunction

if !empty($INSTALL_VIMRC)
    call ZInstallVimrc()
    exec ":q"
endif

let g:lsp_choice = 'coc'
if filereadable(expand('~/.vim/.nococ'))
    let g:lsp_choice = 'vim-lsp'
endif

nnoremap <silent> <leader>tl :call ZToggleLspPersistent()<CR>:source ~/.vimrc<CR>
function! ZToggleLspPersistent()
    if filereadable(expand('~/.vim/.nococ'))
        call system("rm ~/.vim/.nococ")
    else
        call system("touch ~/.vim/.nococ")
    endif
endfunction
" }}}

" Async Plug Load {{{
function! ZLoadPlugin(plugin, ...) abort
    call plug#load(a:plugin)
    if a:0
        silent execute a:1
    endif
endfunction

function! ZAsyncLoadPlugin(github_ref, ...) abort
    let plug_args = a:0 ? a:1 : {}
    if !has('vim_starting') || !empty($INSTALL_VIMRC_PLUGINS)
        call plug#(a:github_ref, plug_args)
        return
    endif
    if !has_key(plug_args, 'on')
        call extend(plug_args, { 'on': [] })
    endif
    call plug#(a:github_ref, plug_args)
    let plugin = a:github_ref[stridx(a:github_ref, '/') + 1:]
    let args = '"'.plugin.'"'
    if a:0 > 1
        let args .= ', "'.a:2.'"'
    endif
    call timer_start(0, {tid->execute('call ZLoadPlugin('.args.')')})
endfunction

command! -nargs=+ ZAsyncPlug call ZAsyncLoadPlugin(<args>)
" }}}

" Plugins {{{
call plug#begin()
ZAsyncPlug 'puremourning/vimspector'
ZAsyncPlug 'preservim/nerdtree'
if !empty($INSTALL_VIMRC_PLUGINS) || filereadable(expand('~/.vim/.devicons'))
    if !has('nvim')
        ZAsyncPlug 'Xuyuanp/nerdtree-git-plugin'
        ZAsyncPlug 'ryanoasis/vim-devicons'
    else
        Plug 'Xuyuanp/nerdtree-git-plugin'
        Plug 'ryanoasis/vim-devicons'
    endif
    ZAsyncPlug 'tiagofumo/vim-nerdtree-syntax-highlight'
endif
ZAsyncPlug 'majutsushi/tagbar'
ZAsyncPlug 'ludovicchabant/vim-gutentags'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
ZAsyncPlug 'junegunn/fzf.vim'
ZAsyncPlug 'vim-airline/vim-airline'
ZAsyncPlug 'skywind3000/asyncrun.vim'
ZAsyncPlug 'justinmk/vim-sneak'
ZAsyncPlug 'easymotion/vim-easymotion'
ZAsyncPlug 'mg979/vim-visual-multi'
ZAsyncPlug 'erig0/cscope_dynamic', { 'do': s:sed . " -i 's/call s:runShellCommand/call system/g' ./plugin/cscope_dynamic.vim" }
ZAsyncPlug 'octol/vim-cpp-enhanced-highlight'
ZAsyncPlug 'airblade/vim-gitgutter'
ZAsyncPlug 'tpope/vim-fugitive'
if !empty($INSTALL_VIMRC_PLUGINS) || g:lsp_choice == 'vim-lsp'
    Plug 'prabirshrestha/async.vim'
    Plug 'prabirshrestha/vim-lsp'
    ZAsyncPlug 'prabirshrestha/asyncomplete.vim'
    ZAsyncPlug 'prabirshrestha/asyncomplete-lsp.vim'
    ZAsyncPlug 'prabirshrestha/asyncomplete-tags.vim'
endif
if !empty($INSTALL_VIMRC_PLUGINS) || g:lsp_choice == 'coc'
    ZAsyncPlug 'neoclide/coc.nvim', { 'branch': 'release' }
    ZAsyncPlug 'antoinemadec/coc-fzf', { 'branch': 'release' }
endif
if !empty($INSTALL_VIMRC_PLUGINS) || g:lsp_choice != 'coc'
    ZAsyncPlug 'vim-scripts/AutoComplPop'
    ZAsyncPlug 'vim-scripts/OmniCppComplete'
    ZAsyncPlug 'SirVer/ultisnips'
endif
Plug 'tmsvg/pear-tree'
ZAsyncPlug 'mbbill/undotree'
ZAsyncPlug 'thezeroalpha/vim-lf'
ZAsyncPlug 'tpope/vim-commentary'
Plug 'tomasiser/vim-code-dark'
ZAsyncPlug 'ntpeters/vim-better-whitespace', { 'on': ['DisableWhitespace', 'EnableWhitespace'] }
ZAsyncPlug 'troydm/zoomwintab.vim'
if !empty($INSTALL_VIMRC_PLUGINS) || ((exists('g:not_inside_vim') || empty($INSIDE_VIM)) && filereadable(expand('~/.vim/.terminus')))
    Plug 'wincent/terminus'
endif
ZAsyncPlug 'jreybert/vimagit'
ZAsyncPlug 'tpope/vim-obsession'
Plug 'haya14busa/incsearch.vim'
ZAsyncPlug 'haya14busa/incsearch-fuzzy.vim'
Plug 'joshdick/onedark.vim'
Plug 'arcticicestudio/nord-vim'
Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }
ZAsyncPlug 'christoomey/vim-tmux-navigator'
ZAsyncPlug 'tpope/vim-surround'
ZAsyncPlug 'j5shi/CommandlineComplete.vim'
ZAsyncPlug 'kshenoy/vim-signature'
ZAsyncPlug 'vim-python/python-syntax'
ZAsyncPlug 'scrooloose/vim-slumlord'
ZAsyncPlug 'aklt/plantuml-syntax'
ZAsyncPlug 'skywind3000/asynctasks.vim'
ZAsyncPlug 'yaronkh/vim-winmanip'
if !empty($INSTALL_VIMRC_PLUGINS) || !has('nvim')
    Plug 'Yggdroot/indentLine'
endif
if !empty($INSTALL_VIMRC_PLUGINS) || has('nvim')
    ZAsyncPlug 'rbgrouleff/bclose.vim'
    ZAsyncPlug 'lukas-reineke/indent-blankline.nvim', { 'branch': 'lua' }
endif
ZAsyncPlug 'metakirby5/codi.vim'
Plug 'tpope/vim-abolish'
ZAsyncPlug 'wellle/targets.vim'
ZAsyncPlug 'eyalz800/vim-ultisnips'
ZAsyncPlug 'voldikss/vim-floaterm', { 'on': ['FloatermNew'] }
call plug#end()
" }}}

" Install plugins {{{
if empty($INSIDE_VIM)
    let $INSIDE_VIM = 1
    let g:not_inside_vim = 1
endif

if !empty($INSTALL_VIMRC_PLUGINS)
    let g:coc_disable_startup_warning = 1
    if $INSTALL_VIMRC_PLUGINS != 'post'
        exec ":PlugUpdate"
        call ZInstallCommand("
            \ echo '{' > ~/.vim/coc-settings.json
            \ && echo '    \"clangd.semanticHighlighting\": false,' >> ~/.vim/coc-settings.json
            \ && echo '    \"coc.preferences.formatOnType\": false' >> ~/.vim/coc-settings.json
            \ && echo '}' >> ~/.vim/coc-settings.json")
        call ZInstallCommand("INSTALL_VIMRC_PLUGINS=post vim -E -s -u ~/.vimrc +'CocInstall -sync coc-clangd coc-pyright coc-vimlsp coc-snippets' +qa")
    endif
endif
" }}}

" General configuration {{{
syntax enable " Activate syntax
filetype plugin indent on " Activates filetype plugins
set expandtab " Expands tabs to spaces
set ignorecase " Ignore case
set smartcase " Smart case
set shellslash " Use forward slash for directories
set autoindent " Automatic indentation
set cinoptions=g0N-sE-s " Do not indent namespaces/extern in cindent
set backspace=indent,eol,start " Make backspace work like in most programs
set ruler " Show line and column of cursor position
set showcmd " Show command line in the last line of the screen
set incsearch " Incrementally search words
set hlsearch " Highlight searches
set shiftwidth=4 " Shift adds 4 spaces.
set tabstop=4 softtabstop=4 " Tab is 4 columns
set cmdheight=1 " Command line height is 1.
set number " Shows line numbers
set wildmode=list:longest,full " Enhanced completion menu
set wildmenu " Enhanced completion menu
set completeopt=longest,menuone,preview " Enhanced completion menu
set nowrap " Do not wrap text
set updatetime=250 " Write swp file and trigger cursor hold events every X ms
set shortmess+=Ic " Disable splash
set hidden " Allow hidden buffers with writes
set cursorline " Activate cursor line
set noerrorbells visualbell t_vb= " Do not play bell sounds
set belloff=all " Turn off all bells
set t_u7= " Workaround for some terminals that make vim launch in relace mode
set ttyfast " Fast terminal
set lazyredraw " Redraw screen lazily
set re=1 " Regex engine 1 feels smoother most of the times
set foldmethod=marker " Marker based fold method
set keymodel=startsel " Shifted special key starts selection
set laststatus=2 " Add status line
set noshowmode " Do not show command/insert/normal status
set ttimeoutlen=10 " Responsive escape
if !has('nvim')
    set balloondelay=250 " Fast balloon popup.
endif
" }}}

" General Mappings {{{

" Yank to end of line.
nnoremap <silent> Y y$

" Jump to matching pairs.
nnoremap <silent> <Tab> %
vnoremap <silent> <Tab> %

" Common command aliases.
command! Q q
command! -bang Q q!
command! Qa qa
command! -bang Qa qa!
command! QA qa
command! -bang QA qa!

" Write as sudo.
command! ZSudoW w !sudo tee > /dev/null %

" }}}

" File indentation {{{
augroup ZFileIndentation
    autocmd!
    autocmd filetype cpp setlocal cindent
    autocmd filetype c setlocal cindent
    autocmd filetype make setlocal noexpandtab autoindent
augroup end
" }}}

" CPP Modules {{{
augroup ZCppModuleFileTypes
    autocmd!
    autocmd BufRead,BufNewFile *.cppm setlocal filetype=cpp
    autocmd BufRead,BufNewFile *.ixx setlocal filetype=cpp
augroup end
" }}}

" Turn off highlights {{{
nnoremap <silent> ` :noh<CR>
" }}}

" Visual block {{{
nnoremap <silent> <C-q> <C-v>
" }}}

" Close window {{{
nnoremap <silent> <C-w>w :q<CR>
" }}}

" Close buffer {{{
nnoremap <silent> <C-w>d :bd<CR>
" }}}

" Save file {{{
nnoremap <silent> <C-s> :w<CR>
inoremap <silent> <C-s> <C-o>:w<CR>
" }}}

" Increment and decrement {{{
nnoremap <silent> <leader>= <C-a>
vnoremap <silent> <leader>= <C-a>
nnoremap <silent> <leader>- <C-x>
vnoremap <silent> <leader>- <C-x>
" }}}

" Select all {{{
nnoremap <silent> <C-a> ggVG
vnoremap <silent> <C-a> <esc>ggVG
inoremap <silent> <C-a> <esc>ggVG
" }}}

" Clipboard {{{
if !filereadable(expand('~/.vim/.noosccopy'))
    let s:osc_clipboard = 1
    if !has('nvim')
        vnoremap <silent> <C-c> "*y:call ZOscCopy()<CR>
        vnoremap <silent> <C-x> "*d:call ZOscCopy()<CR>
        inoremap <silent> <C-v> <C-o>"*gp
        nnoremap <silent> <C-v> "*p
    else
        vnoremap <silent> <C-c> ""y:call ZOscCopyPtty()<CR>
        vnoremap <silent> <C-x> ""d:call ZOscCopyPtty()<CR>
        inoremap <silent> <C-v> <C-o>""gp
        nnoremap <silent> <C-v> ""p
    endif
else
    let s:osc_clipboard = 0
    vnoremap <silent> <C-c> "*y
    vnoremap <silent> <C-x> "*d
    inoremap <silent> <C-v> <C-o>"*gp
    nnoremap <silent> <C-v> "*p
endif
if !s:osc_clipboard && (empty($SSH_CONNECTION) || filereadable(expand('~/.vim/.forcexserver')))
    set clipboard=unnamed
elseif !has('nvim')
    set clipboard=exclude:.*
endif
command! ZToggleOscCopy call ZToggleOscCopy() | source ~/.vimrc
command! ZToggleForceXServer call ZToggleForceXServer()
function! ZOscCopy()
    let encodedText=@"
    let encodedText=substitute(encodedText, '\', '\\\\', "g")
    let encodedText=substitute(encodedText, "'", "'\\\\''", "g")
    let executeCmd="echo -n '".encodedText."' | base64 | tr -d '\\n'"
    let encodedText=system(executeCmd)
    if !empty($TMUX)
        let executeCmd='echo -en "\x1bPtmux;\x1b\x1b]52;;'.encodedText.'\x1b\x1b\\\\\x1b\\" > /dev/tty'
    else
        let executeCmd='echo -en "\x1b]52;;'.encodedText.'\x1b\\" > /dev/tty'
    endif
    call system(executeCmd)
endfunction
function! ZOscCopyPtty()
    let encodedText=@"
    let encodedText=substitute(encodedText, '\', '\\\\', "g")
    let encodedText=substitute(encodedText, "'", "'\\\\''", "g")
    let executeCmd="echo -n '".encodedText."' | base64 | tr -d '\\n'"
    let encodedText=system(executeCmd)
    if !exists('g:vim_tty')
        let g:vim_tty = system('(tty || tty </proc/$PPID/fd/0) 2>/dev/null | grep /dev/')
    endif
    if !empty($TMUX)
        let executeCmd='echo -en "\x1bPtmux;\x1b\x1b]52;;'.encodedText.'\x1b\x1b\\\\\x1b\\" > ' . g:vim_tty
    else
        let executeCmd='echo -en "\x1b]52;;'.encodedText.'\x1b\\" > ' . g:vim_tty
    endif
    call system(executeCmd)
endfunction
function! ZToggleOscCopy()
    if filereadable(expand('~/.vim/.noosccopy'))
        call system("rm ~/.vim/.noosccopy")
    else
        call system("touch ~/.vim/.noosccopy")
    endif
endfunction
function! ZToggleForceXServer()
    if filereadable(expand('~/.vim/.forcexserver'))
        call system("rm ~/.vim/.forcexserver")
    else
        call system("touch ~/.vim/.forcexserver")
    endif
endfunction
" }}}

" Tmux wrap function {{{
function! ZWrapIfTmux(s)
    if empty($TMUX)
        return a:s
    endif
    let tmux_start = "\<Esc>Ptmux;"
    let tmux_end = "\<Esc>\\"
    return tmux_start . substitute(a:s, "\<Esc>", "\<Esc>\<Esc>", 'g') . tmux_end
endfunction
" }}}

" Bracketed paste {{{
exec "set <f22>=\<Esc>[200~" | " ]
exec "set <f23>=\<Esc>[201~" | " ]
inoremap <special> <expr> <f22> ZXTermPasteBegin('')
nnoremap <special> <expr> <f22> ZXTermPasteBegin('i')
vnoremap <special> <expr> <f22> ZXTermPasteBegin('c')
cnoremap <f22> <nop>
cnoremap <f23> <nop>
let &t_ti .= ZWrapIfTmux("\<Esc>[?2004h") " ]
let &t_te = ZWrapIfTmux("\<Esc>[?2004l") . &t_te " ]
function! ZXTermPasteBegin(ret)
    setlocal pastetoggle=<f23>
    set paste
    return a:ret
endfunction
augroup ZTerminalBracketedPaste
    autocmd!
    if !has('nvim')
        autocmd TerminalOpen * exec "setlocal <f22>= | setlocal <f23>= "
    else
        autocmd TermOpen * exec "setlocal <f22>= | setlocal <f23>= "
    endif
augroup end
" }}}

" Terminus {{{
" Disable terminus bracketed paste
let g:TerminusBracketedPaste = 0

function! ZToggleTerminus()
    if filereadable(expand('~/.vim/.terminus'))
        call system("rm ~/.vim/.terminus")
    else
        call system("touch ~/.vim/.terminus")
    endif
endfunction
command! ZToggleTerminus call ZToggleTerminus()
" }}}

" Cursor shape on entry {{{
if s:os == 'Linux'
    let &t_ti .= ZWrapIfTmux("\<Esc>[2 q") " ]
endif
" }}}

" Gui colors {{{
if has('termguicolors') && !filereadable(expand('~/.vim/.notermguicolors'))
    set termguicolors
endif
nnoremap <leader>tg :call ZToggleGuiColorsPersistent()<CR>
function! ZToggleGuiColorsPersistent()
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
" }}}

" Mouse {{{
set mouse=a
if has('mouse_sgr')
    set ttymouse=sgr
elseif !has('nvim')
    set ttymouse=xterm2
endif
nnoremap <silent> <leader>zm :call ZToggleMouse()<CR>
function! ZToggleMouse()
    if &mouse == 'a'
        set mouse=
        set ttymouse=xterm
    else
        set mouse=a
        if has('mouse_sgr')
            set ttymouse=sgr
        elseif !has('nvim')
            set ttymouse=xterm2
        endif
    endif
endfunction
" }}}

" Sign column {{{
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
" }}}

" Path {{{
let $PATH =
    \ ':' . expand('~/.vim/bin/lf')
    \ . ':' . expand('~/.vim/bin/llvm')
    \ . ':' . expand('~/.vim/bin/python')
    \ . ':' . $PATH
if !executable('clangd') && filereadable('/usr/local/opt/llvm/bin/clangd')
    let $PATH .= ':/usr/local/opt/llvm/bin'
endif
" }}}

" Copy / Paste Mode {{{
nnoremap <silent> <F8> :set paste!<CR>:set number!<CR>:call ZToggleSignColumn()<CR>:call ZToggleMouse()<CR>
" }}}

" Resize splits {{{
nnoremap <silent> L :vertical resize +1<CR>
nnoremap <silent> H :vertical resize -1<CR>
nnoremap <silent> <C-w>= :resize +1<CR>
" }}}

" Zoom {{{
noremap <silent> <C-w>z :ZoomWinTabToggle<CR>
" }}}

" Special files generation {{{

" Generation Parameters
let g:ctagsFilePatterns = '-g "*.c" -g "*.cc" -g "*.cpp" -g "*.cxx" -g "*.h" -g "*.hh" -g "*.hpp"'
let g:otherFilePatterns = '-g "*.py" -g "*.te" -g "*.S" -g "*.asm" -g "*.mk" -g "*.md" -g "makefile" -g "Makefile"'
let g:sourceFilePatterns = '-g "*.c" -g "*.cc" -g "*.cpp" -g "*.cxx" -g "*.h" -g "*.hh" -g "*.hpp" -g "*.py" -g "*.go" -g "*.te" -g "*.S" -g "*.asm" -g "*.mk" -g "*.md" -g "makefile" -g "Makefile"'
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

" Generate C++ and Opengrok
nnoremap <silent> <leader>zz :call ZGenerateCppAndOpengrok()<CR>

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
    \ echo -std=c++20 > compile_flags.txt
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

        exec ":AsyncRun
        \ echo -std=c++20 > compile_flags.txt
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

" Generate Cpp and Opengrok
function! ZGenerateCppAndOpengrok()
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

        exec ":AsyncRun
        \ echo -std=c++20 > compile_flags.txt
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
        \ && cscope -bq
        \ && java -Xmx2048m -jar ~/.vim/bin/opengrok/lib/opengrok.jar -q -c " . g:opengrok_ctags . " -s . -d .opengrok
             \ " . g:opengrokFilePatterns . "
             \ -P -S -G -W .opengrok/configuration.xml"
    else
        exec ":AsyncRun
        \ echo '" . g:ctagsOptions . "' > .gutctags
        \ && " . s:sed . " -i 's/ /\\n/g' .gutctags
        \ && rg --files " . g:ctagsFilePatterns . " > cscope.files
        \ && if ! [ -f .files ]; then cp cscope.files .files; rg --files " . g:otherFilePatterns . " >> .files; fi
        \ && cscope -bq
        \ && java -Xmx2048m -jar ~/.vim/bin/opengrok/lib/opengrok.jar -q -c " . g:opengrok_ctags . " -s . -d .opengrok
             \ " . g:opengrokFilePatterns . "
             \ -P -S -G -W .opengrok/configuration.xml"
    endif
endfunction

" Generate compile_commands.json
nnoremap <silent> <leader>zj :call ZGenerateCompileCommandsJson()<CR>
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
" }}}

" Terminal {{{
if !has('nvim')
    nnoremap <silent> <leader>zb :below terminal ++rows=10<CR>
    nnoremap <silent> <leader>zs :below terminal<CR>
    nnoremap <silent> <leader>zv :vert rightb terminal<CR>
    tnoremap <silent> <C-w>w <C-w>:q<CR>
    tnoremap <silent> <C-w>n <C-w>N
    tnoremap <silent> <C-w>m <C-w>:call ZTerminalToggleScrolling()<CR>
else
    nnoremap <silent> <leader>zb :below 10new +terminal<CR>a
    nnoremap <silent> <leader>zs :below new +terminal<CR>a
    nnoremap <silent> <leader>zv :vert rightb new +terminal<CR>a
    tnoremap <silent> <C-w>w <C-\><C-n>:q<CR>
    tnoremap <silent> <C-w>n <C-\><C-n>
    tnoremap <silent> <C-w>m <C-\><C-n>:call ZTerminalToggleScrolling()<CR>a
endif
augroup ZTerminalAutoCommands
    autocmd!
    if !has('nvim')
        autocmd TerminalOpen * DisableWhitespace
        autocmd TerminalOpen * tnoremap <silent> <buffer> <ScrollWheelUp> <C-w>:call ZTerminalEnterNormalMode()<CR>
    else
        autocmd TermOpen * DisableWhitespace
        autocmd TermOpen * tnoremap <silent> <buffer> <ScrollWheelUp> <C-\><C-n>:call ZTerminalEnterNormalMode()<CR>
        autocmd TermOpen * setlocal nonumber signcolumn=no
    endif
augroup end

function! ZTerminalEnterNormalMode()
    if &buftype == 'terminal' && mode('') == 't'
        call feedkeys("\<c-w>N")
        call feedkeys("\<c-y>")
    endif
endfunction

function! ZTerminalToggleScrolling()
    if !exists('b:terminal_scrolling_enabled') || b:terminal_scrolling_enabled == 1
        tunmap <silent> <buffer> <ScrollWheelUp>
        let b:terminal_scrolling_enabled = 0
    else
        tnoremap <silent> <buffer> <ScrollWheelUp> <C-\><C-n>:call ZTerminalEnterNormalMode()<CR>
        let b:terminal_scrolling_enabled = 1
    endif
endfunction
" }}}

" Sidways scrolling {{{
nnoremap <silent> <C-l> 20zl
vnoremap <silent> <C-l> 20zl
nnoremap <silent> <C-h> 20zh
vnoremap <silent> <C-h> 20zh
" }}}

" Vim-better-whitespace {{{
let g:better_whitespace_filetypes_blacklist = ['diff', 'gitcommit', 'git', 'unite', 'qf', 'help', 'VimspectorPrompt', 'xxd']
nnoremap <silent> <leader>zw :StripWhitespace<CR>
nnoremap <silent> <leader>zW :ToggleWhitespace<CR>
" }}}

" Lf {{{
" The use of timer_start is a workaround that the lsp does not detect the file
" after open.
nmap <silent> <leader>fe :LF %:p call\ timer_start(0,{tid->execute('e!')})\|n<CR>
nmap <silent> <leader>fs :LF %:p call\ timer_start(0,{tid->execute('e!')})\|vs<CR>
" }}}

" Opengrok binaries {{{
let g:opengrok_jar = expand('~/.vim/bin/opengrok/lib/opengrok.jar')
if executable('ctags-exuberant')
    let g:opengrok_ctags = '/usr/bin/ctags-exuberant'
else
    let g:opengrok_ctags = '~/.vim/bin/ctags-exuberant/ctags/ctags'
endif
" }}}

" Root / project / file folder switching {{{
let g:vimroot=$PWD
nnoremap <silent> cr :call ZSwitchToRoot()<CR>
nnoremap <silent> cp :call ZSwitchToProjectRoot(expand('%:p:h'))<CR>
nnoremap <silent> cd :execute "cd " . expand('%:p:h')<CR>
nnoremap <silent> ca :call ZSwitchToArbitraryFolder()<CR>
nnoremap <silent> cu :execute "cd .."<CR>
function! ZSwitchToRoot()
    execute "cd " . g:vimroot
endfunction
function! ZSwitchToProjectRoot(start_path)
    let available_roots = ['.git', '.hg', '.svn', '.repo', '.files']
    let current_path = a:start_path
    let limit = 100
    let iteration = 0
    while iteration < limit
        if current_path == '/'
            echom "Project root not found!"
            return
        endif
        for available_root in available_roots
            if !filereadable(current_path . '/' . available_root)
                    \ && !isdirectory(current_path . '/' . available_root)
                continue
            endif
            execute "cd " . current_path
            return
        endfor
        let current_path = fnamemodify(current_path, ':h')
        let iteration = iteration + 1
    endwhile
    echom "Project root not found!"
endfunction
function! ZSwitchToArbitraryFolder()
    function! s:sink(result)
        exec 'cd ' . system('dirname ' . a:result)
    endfunction

    let fzf_color_option = split(fzf#wrap()['options'])[0]
    let preview = "ls -la --color \\$(dirname {})"
    let opts = { 'options': fzf_color_option . ' --prompt "> "' .
                \ ' --preview="' . preview . '"' .
                \ ' --bind "ctrl-/:toggle-preview"',
                \ 'sink': function('s:sink')}

    let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --no-ignore-vcs'
    call fzf#run(fzf#wrap('', opts, 0))
endfunction
" }}}

" NERDTree and TagBar {{{
nnoremap <silent> <leader>ll :call ZToggleNerdTreeAndTagbar()<CR>
nnoremap <silent> <leader>lc :call ZToggleNerdTreeAndTagbar()<CR>:call ZShowCurrentFile()<CR>
nnoremap <silent> <leader>nf :NERDTreeFind<CR>
nnoremap <silent> <leader>nd :NERDTreeCWD<CR>
nnoremap <silent> <leader>nt :call ZNerdTreeToggle()<CR>
nnoremap <silent> <leader>tt :call ZTagbarToggle()<CR>
nnoremap <silent> cf :call ZShowCurrentFile()<CR>
nnoremap <silent> cq :call ZShowCurrentDirectory()<CR>
let g:NERDTreeWinSize = 30
let g:NERDTreeAutoCenter = 0
let g:NERDTreeMinimalUI = 0
let NERDTreeShowHidden = 1
let NERDTreeAutoDeleteBuffer = 1
if filereadable(expand('~/.vim/.devicons'))
    let g:NERDTreeDirArrowExpandable = ''
    let g:NERDTreeDirArrowCollapsible = ''
    let g:DevIconsEnableFoldersOpenClose = 1
    let g:tagbar_iconchars = ["\uf054", "\uf078"]
endif
let g:NERDTreeDisableExactMatchHighlight = 1
let g:NERDTreeDisablePatternMatchHighlight = 1
let g:NERDTreeLimitedSyntax = 1
let g:NERDTreeSyntaxDisableDefaultExtensions = 0
let g:NERDTreeSyntaxEnabledExtensions = ['h', 'sh', 'bash', 'vim', 'md']
let g:NERDTreeGitStatusIndicatorMapCustom = {
                \ 'Modified'  :'M',
                \ 'Staged'    :'A',
                \ 'Untracked' :'U',
                \ 'Renamed'   :'➜',
                \ 'Unmerged'  :'═',
                \ 'Deleted'   :'✖',
                \ 'Dirty'     :'M',
                \ 'Ignored'   :'☒',
                \ 'Clean'     :'C',
                \ 'Unknown'   :'?',
                \ }
let g:tagbar_width = 30
let g:tagbar_indent = 0
let s:tagbar_open = 0
augroup ZNerdTree
    autocmd!
    autocmd FileType nerdtree setlocal signcolumn=no
augroup end
function! ZNerdTreeToggle()
    if exists("g:NERDTree") && g:NERDTree.IsOpen()
        NERDTreeClose
    else
        NERDTree
        wincmd w
    endif
endfunction
function! ZTagbarToggle()
    if s:tagbar_open == 0
        TagbarOpen
    else
        TagbarClose
    endif
    let s:tagbar_open = !s:tagbar_open
endfunction
function! ZToggleNerdTreeAndTagbar()
    let nerdtree_open = exists("g:NERDTree") && g:NERDTree.IsOpen()
    if (nerdtree_open == 1 && s:tagbar_open == 1) || (nerdtree_open == 0 && s:tagbar_open == 0)
        call ZNerdTreeToggle()
        call ZTagbarToggle()
    elseif !nerdtree_open
        call ZNerdTreeToggle()
    elseif s:tagbar_open == 0
        call ZTagbarToggle()
    endif
endfunction
function! ZShowCurrentFile()
    if exists("g:NERDTree") && g:NERDTree.IsOpen() && !empty(expand('%:h'))
        NERDTreeFind
        wincmd w
    endif
    echo @%
endfunction
function! ZShowCurrentDirectory()
    if exists("g:NERDTree") && g:NERDTree.IsOpen()
        silent NERDTreeCWD
        silent NERDTreeRefreshRoot
        wincmd w
    endif
    echo getcwd()
endfunction
" }}}

" Git {{{
nnoremap <silent> <leader>gb :Git blame<CR>
nnoremap <silent> <leader>gm :MagitOnly<CR>
nnoremap <silent> <leader>gc :BCommits<CR>
nnoremap <silent> <leader>gl :call ZPopTerminal($SHELL . ' -c "cd ' .  expand('%:p:h') . ' ; lazygit"')<CR>
nnoremap <silent> <leader>gL :call ZPopTerminal('lazygit')<CR>
" }}}

" Float Term {{{
let g:floaterm_title = 'terminal'
" }}}

" Pop Terminal {{{
function! ZPopTerminal(command)
    silent execute 'FloatermNew --height=0.9 --width=0.9 --autoclose=2 ' . a:command
endfunction
" }}}

" GutenTags {{{
let g:gutentags_modules = ['ctags']
let g:gutentags_project_root = ['.git', '.hg', '.svn', '.repo', '.files']
" }}}

" Color {{{
command! -nargs=1 ZColor call ZColor(<f-args>) | source ~/.vimrc | silent exec ":silent! e!"
nnoremap <silent> <leader>nc :call ZNextColor()<CR>:source ~/.vimrc<CR>:silent! e!<CR>
if !filereadable(expand('~/.vim/.color'))
    call system('echo onedark > ~/.vim/.color')
endif
let g:onedark_color_overrides = {
    \ "special_grey": { "gui": "#5C6370", "cterm": "59", "cterm16": "15" }
\ }
let s:available_colors = ['onedark', 'codedark', 'nord']
let s:vim_color = readfile(expand('~/.vim/.color'))[0]
exec ':color ' . s:vim_color
function! ZColor(color)
    call system('echo ' . a:color . ' > ~/.vim/.color')
    if !empty($TMUX)
        call system('tmux source ~/.tmux.conf')
    endif
endfunction
function! ZNextColor()
    let current_color = index(s:available_colors, s:vim_color)
    if current_color == -1
        echom "Color not found!"
        return
    endif
    let current_color += 1
    if current_color == len(s:available_colors)
        let current_color = 0
    endif
    call ZColor(s:available_colors[current_color])
endfunction
" }}}

" Supertab {{{
let g:SuperTabDefaultCompletionType = "<c-n>"
" }}}

" Incsearch {{{
if !has('nvim')
    map / <Plug>(incsearch-forward)
    map ? <Plug>(incsearch-backward)
    map g/ <Plug>(incsearch-stay)
endif
map z/ <Plug>(incsearch-fuzzy-/)
map z? <Plug>(incsearch-fuzzy-?)
map zg/ <Plug>(incsearch-fuzzy-stay)
" }}}

" Hexokinase {{{
let g:Hexokinase_highlighters = ['backgroundfull']
let g:Hexokinase_optInPatterns = 'full_hex,rgb,rgba,hsl,hsla,colour_names'
let g:Hexokinase_refreshEvents = ['BufRead', 'BufWrite', 'TextChanged', 'InsertLeave', 'InsertEnter']
let g:Hexokinase_ftOptInPatterns = {
\     'cpp': 'rgb,rgba,hsl,hsla,colour_names',
\     'c': 'rgb,rgba,hsl,hsla,colour_names',
\     'python': 'rgb,rgba,hsl,hsla,colour_names',
\ }

" Fzf
let g:fzf_files_nocache_command = "rg --files --no-ignore-vcs --hidden"
let g:fzf_files_cache_command = "
    \ if [ -f .files ]; then
    \     cat .files;
    \ else
    \     rg --files --no-ignore-vcs --hidden;
    \ fi
\ "
" }}}

" Fzf {{{
if filereadable(expand('~/.vim/.fzf-files-cache')) || filereadable('.fzf-files-cache')
    let $FZF_DEFAULT_COMMAND = g:fzf_files_cache_command
    let g:fzf_files_cache = 1
else
    let $FZF_DEFAULT_COMMAND = g:fzf_files_nocache_command
    let g:fzf_files_cache = 0
endif

set rtp+=~/.fzf
nnoremap <silent> <C-p> :call ZFiles()<CR>
nnoremap <silent> <C-]> :call ZSourceFiles()<CR>
nnoremap <silent> cz :call ZSourceFiles()<CR>
nnoremap <silent> <C-\> :Buf<CR>
nnoremap <silent> <leader>gf :GFiles<CR>
nnoremap <silent> <C-n> :Tags<CR>
nnoremap <silent> <C-g> :Rg<CR>
nnoremap <silent> <leader>fh :call ZFzfToggleFilesCache()<CR>
nnoremap <silent> <leader>fH :call ZFzfToggleGlobalFilesCache()<CR>
nnoremap <silent> // :BLines<CR>
let $BAT_THEME = 'Monokai Extended Origin'
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

function! ZFiles()
    if g:fzf_files_cache
        let $FZF_DEFAULT_COMMAND = g:fzf_files_cache_command
    else
        let $FZF_DEFAULT_COMMAND = g:fzf_files_nocache_command
    endif
    silent exec "Files"
endfunction

function! ZSourceFiles()
    let $FZF_DEFAULT_COMMAND = 'rg --files ' . g:sourceFilePatterns
    silent exec "Files"
endfunction

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
" }}}

" Easymotion {{{
let g:EasyMotion_do_mapping = 0
let g:EasyMotion_smartcase = 1
nmap <silent> s <Plug>(easymotion-overwin-f2)
vmap <silent> s <Plug>(easymotion-f2)
nmap <silent> S <Plug>(easymotion-overwin-f2)
vmap <silent> S <Plug>(easymotion-f2)
" }}}

" Sneak {{{
let g:sneak#use_ic_scs = 1
let g:sneak#s_next = 0
let g:sneak#label = 1
nmap <leader>s <Plug>Sneak_s
nmap <leader>S <Plug>Sneak_S
vmap <leader>s <Plug>Sneak_s
vmap <leader>S <Plug>Sneak_S
nmap f <Plug>Sneak_f
nmap F <Plug>Sneak_F
vmap t <Plug>Sneak_t
vmap T <Plug>Sneak_T
" }}}

" Cscope config {{{
let g:cscopedb_big_file = 'cscope.out'
let g:cscopedb_small_file = 'cscope_small.out'
let g:cscopedb_auto_files = 0
" }}}

" Visual Multi {{{
" Mappings - (See https://github.com/mg979/vim-visual-multi/wiki/Mappings)
" Tutorial - ~/.vim/plugged/vim-visual-multi/doc/vm-tutorial
let g:VM_default_mappings = 0
let g:VM_theme = 'iceblue'
let g:VM_leader = '<leader>m'
let g:VM_maps = {
    \ 'Find Under': '<leader>ms',
    \ 'Find Subword Under': '<leader>ms',
    \ 'Add Cursor At Pos': '<leader>mm',
    \ 'Start Regex Search': 'm/',
    \ 'Merge Regions': '<leader>mM',
    \ 'Toggle Multiline': '<leader>mL',
    \ 'Select All': '<leader>mA',
    \ 'Visual All': '<leader>mA',
    \ 'Visual Add': '<leader>ma',
    \ 'Visual Cursors': '<leader>mc',
    \ 'Visual Find': '<leader>mf',
    \ 'Visual Regex': '<leader>m/',
\ }
nmap <C-j> <plug>(VM-Add-Cursor-Down)
nmap <C-k> <plug>(VM-Add-Cursor-Up)
if g:lsp_choice == 'coc'
    augroup ZVisualMultiCoc
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
" }}}

" Cpp Highlight {{{
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_concepts_highlight = 1
let g:cpp_member_variable_highlight = 0
let g:cpp_no_function_highlight = 1
augroup ZCustomCppSyntax
    autocmd!
    autocmd Syntax cpp call ZApplyCppSyntax()
    autocmd Syntax c call ZApplyCppSyntax()
augroup end
function! ZApplyCppSyntax()
    syntax match cCustomDot "\." contained
    syntax match cCustomPtr "->" contained
    syntax match cCustomParen "(" contained contains=cParen contains=cCppParen " )
    syntax match cCustomBracket "\[" contained contains=cBracket " ]
    syntax match cCurlyBrace "{" contained " }

    syntax match cCustomFunc "\h\w*(" contains=cCustomParen " )
    hi def link cCustomFunc Function
    syntax keyword cIntegerType uint8_t
    syntax keyword cIntegerType uint16_t
    syntax keyword cIntegerType uint32_t
    syntax keyword cIntegerType uint64_t
    syntax keyword cIntegerType uintmax_t
    syntax keyword cIntegerType uintptr_t
    syntax keyword cIntegerType int8_t
    syntax keyword cIntegerType int16_t
    syntax keyword cIntegerType int32_t
    syntax keyword cIntegerType int64_t
    syntax keyword cIntegerType intmax_t
    syntax keyword cIntegerType intptr_t
    syntax keyword cIntegerType ptrdiff_t
    syntax keyword cIntegerType size_t
    hi def link cIntegerType cCustomClass
    syntax keyword cCharType char8_t
    syntax keyword cCharType char16_t
    syntax keyword cCharType char32_t
    hi def link cCharType cType
    syntax match cCompundObject "\h\w*\(\.\|\->\)" contains=cCustomDot,cCustomPtr
    hi def link cCompundObject cCustomMemVar
    syntax match cArrayObject "\h\w*\(\[\)" contains=cCustomBracket " ]
    hi def link cArrayObject cCompundObject
    syntax match cCustomMemVar "\(\.\|->\)\h\w*" containedin=cCompundObject contains=cCustomDot,cCustomPtr
    hi def link cCustomMemVar Function

    if &ft == 'cpp'
        syntax keyword cppNew new
        hi def link cppNew cppStatement
        syntax keyword cppDelete delete
        hi def link cppDelete cppStatement
        syntax keyword cppThis this
        hi def link cppThis cppStatement
        syntax keyword cppUsing using
        hi def link cppUsing cppStatement
        syntax match cppMemberFunction "\(\.\|\->\)\h\w*(" containedin=cCustomMemVar contains=cCustomDot,cCustomPtr,cCustomParen " )
        hi def link cppMemberFunction cCustomFunc
        syntax match cppVariable "\h\w*\({\)" contains=cCurlyBrace " }
        hi def link cppVariable cCustomMemVar
    endif
endfunction
" }}}

" Python Highlight {{{
let g:python_highlight_all = 1
let g:python_highlight_operators = 0
augroup ZCustomPySyntax
    autocmd!
    autocmd Syntax python call ZApplyPythonSyntax()
augroup end
function! ZApplyPythonSyntax()
    syntax keyword pythonLambda lambda
    hi def link pythonLambda pythonStatement
    syntax keyword pythonDef def
    hi def link pythonDef pythonStatement
    syntax keyword pythonBuiltinType type
    hi link pythonRun pythonComment
endfunction
" }}}

" QuickFix {{{
nnoremap <silent> <C-w>p :copen<CR>
nnoremap <silent> <C-w>q :cclose<CR>
" }}}

" Undo Tree {{{
nnoremap <silent> <leader>zu :UndotreeToggle<cr>
" }}}

" Tmux navigator {{{
let g:tmux_navigator_no_mappings = 1
let s:tmux_navigation_enabled = 0
nnoremap <silent> <C-w>t :call ZToggleTmuxNavitaion()<cr>
tnoremap <silent> <C-w>t <C-w>:call ZToggleTmuxNavitaion()<cr>
function! ZToggleTmuxNavitaion()
    if s:tmux_navigation_enabled == 0
        nnoremap <silent> <C-w>h :TmuxNavigateLeft<cr>
        nnoremap <silent> <C-w>j :TmuxNavigateDown<cr>
        nnoremap <silent> <C-w>k :TmuxNavigateUp<cr>
        nnoremap <silent> <C-w>l :TmuxNavigateRight<cr>
        if !has('nvim')
            tnoremap <silent> <C-w>h <C-w>:TmuxNavigateLeft<cr>
            tnoremap <silent> <C-w>j <C-w>:TmuxNavigateDown<cr>
            tnoremap <silent> <C-w>k <C-w>:TmuxNavigateUp<cr>
            tnoremap <silent> <C-w>l <C-w>:TmuxNavigateRight<cr>
        else
            tnoremap <silent> <C-w>h <C-\><C-n>:TmuxNavigateLeft<cr>
            tnoremap <silent> <C-w>j <C-\><C-n>:TmuxNavigateDown<cr>
            tnoremap <silent> <C-w>k <C-\><C-n>:TmuxNavigateUp<cr>
            tnoremap <silent> <C-w>l <C-\><C-n>:TmuxNavigateRight<cr>
        endif
        let s:tmux_navigation_enabled = 1
    else
        nunmap <C-w>h
        nunmap <C-w>j
        nunmap <C-w>k
        nunmap <C-w>l
        tunmap <C-w>h
        tunmap <C-w>j
        tunmap <C-w>k
        tunmap <C-w>l
        let s:tmux_navigation_enabled = 0
    endif
endfunction
if exists('g:not_inside_vim') && !empty($TMUX)
    call ZToggleTmuxNavitaion()
endif
" }}}

" Large files {{{
let g:large_file_size = 10 * 1024 * 1024
augroup ZLargeFiles
    autocmd!
    autocmd BufReadPre *
        \   if getfsize(expand("<afile>")) > g:large_file_size
        \ |     call ZLargeFileEnable()
        \ | endif
augroup end

function! ZLargeFileEnable()
    setlocal noswapfile
    setlocal bufhidden=unload
    setlocal noundofile
    exec ":HexokinaseTurnOff"
endfunction
" }}}

" Tag stack {{{
nnoremap <silent> <leader>o :pop<CR>
nnoremap <silent> <leader>i :tag<CR>

function! ZTagstackPushCurrent(name)
    return ZTagstackPush(a:name, getcurpos(), bufnr())
endfunction

function! ZTagstackPush(name, pos, buf)
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
" }}}

" Go to definition {{{
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
        call ZTagstackPush(name, pos, buf)
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
        let ctags_tag_types = ['f', 'c', 's', 't', 'd', 'm']
        let opengrok_query_type = 'd'
    elseif a:type == 'declaration'
        let ctags_tag_types = ['p', 'd']
        let opengrok_query_type = 'f'
    endif

    " ZCscope
    if filereadable('cscope.out')
        let awk_program =
            \    '{ x = $1; $1 = ""; z = $3; $3 = ""; ' .
            \    'printf "%s:%s:%s\n", x,z,$0; }'
        let cscope_command =
            \    'cscope -dL' . cscope_query_type . " " . shellescape(a:symbol) .
            \    " | awk '" . awk_program . "'"
        let results = split(system(cscope_command), '\n')

        if len(results) > overall_limit
            return ZCscope(cscope_query_type, a:symbol, 1)
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
            return ZCscope(cscope_query_type, a:symbol, 1)
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
            call ZTagstackPushCurrent(a:symbol)
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
            return ZOgQuery(opengrok_query_type, a:symbol, 1)
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
            return ZCscope(cscope_query_type, a:symbol, 1)
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
            call ZTagstackPushCurrent(a:symbol)
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
" }}}

" Cscope {{{
nnoremap <silent> <leader>cA :call ZCscope('9', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cC :call ZCscope('3', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cD :call ZCscope('2', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cE :call ZCscope('6', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cF :call ZCscope('7', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cG :call ZCscope('1', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cI :call ZCscope('8', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cS :call ZCscope('0', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader>cT :call ZCscope('4', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader><leader>fA :call ZCscopeQuery('9', 0)<CR>
nnoremap <silent> <leader><leader>fC :call ZCscopeQuery('3', 0)<CR>
nnoremap <silent> <leader><leader>fD :call ZCscopeQuery('2', 0)<CR>
nnoremap <silent> <leader><leader>fE :call ZCscopeQuery('6', 0)<CR>
nnoremap <silent> <leader><leader>fF :call ZCscopeQuery('7', 0)<CR>
nnoremap <silent> <leader><leader>fG :call ZCscopeQuery('1', 0)<CR>
nnoremap <silent> <leader><leader>fI :call ZCscopeQuery('8', 0)<CR>
nnoremap <silent> <leader><leader>fS :call ZCscopeQuery('0', 0)<CR>
nnoremap <silent> <leader><leader>cT :call ZCscopeQuery('4', 0)<CR>
nnoremap <silent> <leader><leader>cA :call ZCscopeQuery('9', 0, 1)<CR>
nnoremap <silent> <leader><leader>cC :call ZCscopeQuery('3', 0, 1)<CR>
nnoremap <silent> <leader><leader>cD :call ZCscopeQuery('2', 0, 1)<CR>
nnoremap <silent> <leader><leader>cE :call ZCscopeQuery('6', 0, 1)<CR>
nnoremap <silent> <leader><leader>cF :call ZCscopeQuery('7', 0, 1)<CR>
nnoremap <silent> <leader><leader>cG :call ZCscopeQuery('1', 0, 1)<CR>
nnoremap <silent> <leader><leader>cI :call ZCscopeQuery('8', 0, 1)<CR>
nnoremap <silent> <leader><leader>cS :call ZCscopeQuery('0', 0, 1)<CR>
nnoremap <silent> <leader><leader>cT :call ZCscopeQuery('4', 0, 1)<CR>

nnoremap <silent> <leader>ca :call ZCscope('9', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>cc :call ZCscope('3', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>cd :call ZCscope('2', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>ce :call ZCscope('6', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>cf :call ZCscope('7', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>cg :call ZCscope('1', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>ci :call ZCscope('8', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>cs :call ZCscope('0', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader>ct :call ZCscope('4', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader><leader>fa :call ZCscopeQuery('9', 1)<CR>
nnoremap <silent> <leader><leader>fc :call ZCscopeQuery('3', 1)<CR>
nnoremap <silent> <leader><leader>fd :call ZCscopeQuery('2', 1)<CR>
nnoremap <silent> <leader><leader>fe :call ZCscopeQuery('6', 1)<CR>
nnoremap <silent> <leader><leader>ff :call ZCscopeQuery('7', 1)<CR>
nnoremap <silent> <leader><leader>fg :call ZCscopeQuery('1', 1)<CR>
nnoremap <silent> <leader><leader>fi :call ZCscopeQuery('8', 1)<CR>
nnoremap <silent> <leader><leader>fs :call ZCscopeQuery('0', 1)<CR>
nnoremap <silent> <leader><leader>ct :call ZCscopeQuery('4', 1)<CR>
nnoremap <silent> <leader><leader>ca :call ZCscopeQuery('9', 1, 1)<CR>
nnoremap <silent> <leader><leader>cc :call ZCscopeQuery('3', 1, 1)<CR>
nnoremap <silent> <leader><leader>cd :call ZCscopeQuery('2', 1, 1)<CR>
nnoremap <silent> <leader><leader>ce :call ZCscopeQuery('6', 1, 1)<CR>
nnoremap <silent> <leader><leader>cf :call ZCscopeQuery('7', 1, 1)<CR>
nnoremap <silent> <leader><leader>cg :call ZCscopeQuery('1', 1, 1)<CR>
nnoremap <silent> <leader><leader>ci :call ZCscopeQuery('8', 1, 1)<CR>
nnoremap <silent> <leader><leader>cs :call ZCscopeQuery('0', 1, 1)<CR>
nnoremap <silent> <leader><leader>ct :call ZCscopeQuery('4', 1, 1)<CR>

function! ZCscope(option, query, preview, ...)
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
        call ZTagstackPush(name, pos, buf)
        return 1
    endif
    return 0
endfunction

function! ZCscopeQuery(option, preview, ...)
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
      call ZCscope(a:option, query, a:preview, 1)
    else
      call ZCscope(a:option, query, a:preview)
    endif
  else
    echom "Cancelled Search!"
  endif
endfunction
" }}}

" Opengrok {{{
nnoremap <silent> <leader>zo :call ZOgQuery('f', expand('<cword>'), 1)<CR>
nnoremap <silent> <leader><leader>zo :call ZOgQuery('f', input('Text: '), 1)<CR>
nnoremap <silent> <leader>zO :call ZOgQuery('f', expand('<cword>'), 0)<CR>
nnoremap <silent> <leader><leader>zO :call ZOgQuery('f', input('Text: '), 0)<CR>

function! ZOgQuery(option, query, preview)
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
        call ZTagstackPush(name, pos, buf)
        return 1
    endif
    return 0
endfunction
" }}}

" vim-lsp {{{
if g:lsp_choice == 'vim-lsp'
    let g:asyncomplete_remove_duplicates = 1
    let g:asyncomplete_smart_completion = 1
    let g:lsp_jump_function = 0

    inoremap <silent> <C-@> <plug>(asyncomplete_force_refresh)

    highlight clear LspWarningLine
    highlight clear LspErrorHighlight
    highlight link LspErrorText None
    nnoremap <silent> <leader>ld :LspDocumentDiagnostics<CR>
    nnoremap <silent> <leader>lh :highlight link LspErrorHighlight Error<CR>
    nnoremap <silent> <leader>ln :highlight link LspErrorHighlight None<CR>

    let g:use_clangd_lsp = 1
    if !executable('clangd')
        let g:use_clangd_lsp = 0
    endif

    let g:use_pyls_lsp = 1
    if !executable('pyls')
        let g:use_pyls_lsp = 0
    endif

    " clangd
    if g:use_clangd_lsp
        augroup ZLspClangd
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
        augroup ZLspPyls
            autocmd!
            autocmd User lsp_setup call lsp#register_server({
                        \ 'name': 'pyls',
                        \ 'cmd': {server_info->['pyls']},
                        \ 'whitelist': ['python'],
                        \ 'workspace_config': {'pyls': {'plugins': {'pydocstyle': {'enabled': v:true} } }}
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

    augroup ZLspInstall
        autocmd!
        " call s:on_lsp_buffer_enabled only for languages that has the server registered.
        autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
    augroup end
endif
" }}}

" Coc {{{
if g:lsp_choice == 'coc'
    let g:coc_global_extensions = ['coc-clangd', 'coc-pyright', 'coc-vimlsp', 'coc-snippets']
    let g:coc_fzf_preview = 'right:50%'

    "nmap <silent> gd <Plug>(coc-definition)
    nmap <silent> gd :call ZLspJump('Definition')<CR>

    "nmap <silent> gi <Plug>(coc-implementation)
    nmap <silent> gi :call ZLspJump('Implementation')<CR>

    "nmap <silent> gr <Plug>(coc-references)
    nmap <silent> gr :call ZLspJump('References')<CR>

    nmap <leader>qf  <Plug>(coc-fix-current)

    nmap <silent> gy <Plug>(coc-type-definition)
    nmap <silent> go :CocCommand clangd.switchSourceHeader<CR>
    nnoremap <silent> K :call <SID>show_documentation()<CR>
    nmap <silent> [g <Plug>(coc-diagnostic-prev)
    nmap <silent> ]g <Plug>(coc-diagnostic-next)
    nmap <silent> <leader>rn <Plug>(coc-rename)
    xmap <silent> <leader>lf <Plug>(coc-format-selected)
    imap <C-d> <Plug>(coc-snippets-expand)
    vmap <C-r> <Plug>(coc-snippets-select)

    nnoremap <silent> <leader>ld :CocDiagnostics<CR>
    inoremap <silent> <expr> <CR> "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"")"))

    function! s:check_back_space() abort
        let col = col('.') - 1
        return !col || getline('.')[col - 1]  =~ '\s'
    endfunction

    inoremap <silent><expr> <Tab>
                \ pumvisible() ? "\<C-n>" :
                \ <SID>check_back_space() ? "\<Tab>" :
                \ coc#refresh()
    inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

    highlight clear CocErrorSign
    highlight link CocErrorSign None
    highlight clear CocErrorFloat
    highlight link CocErrorFloat None
    highlight clear CocWarningFloat
    highlight link CocWarningFloat None
    highlight clear CocInfoSign
    highlight link CocInfoSign None
    highlight clear CocHintSign
    highlight link CocHintSign None
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
            " If on the same buffer and line.
            let newpos = getcurpos()
            if buf == bufnr() && pos[1] == newpos[1]
                " If the cursor was moved already, it means that the jump was
                " finished, and that we landed on the same line, return
                " failure.
                if pos[2]+1 != newpos[2]
                    return 0
                endif

                " The position has not changed, a popup is in front of the
                " user, assume success.
                call setpos('.', pos)
                call ZTagstackPush(name, pos, buf)
                return 1
            endif

            " Jump already occurred as we are not in the same buffer or line,
            " return success.
            call ZTagstackPush(name, pos, buf)
            return 1
        else
            call setpos('.', pos)
        endif
        return 0
    endfunction
endif
" }}}

" Pear-tree {{{
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

" If enabled, smart pair functions timeout after ms:
let g:pear_tree_timeout = 10

" Don't automatically map <BS>, <CR>, and <Esc>
let g:pear_tree_map_special_keys = 0

" Peer tree mappings:
imap <BS> <Plug>(PearTreeBackspace)
" }}}

" Binary {{{
nnoremap <silent> <leader>bf :call ZBinaryFile()<CR>
command! -nargs=0 ZBinaryFile call ZBinaryFile()
augroup ZBinaryFileAutoCommands
    autocmd!
    autocmd BufReadPost * if &bin && (!exists('b:binary_mode') || !b:binary_mode) | let b:binary_mode = 1 | set ft=xxd | silent exec "%!xxd" | endif
    autocmd BufWritePre * if &bin | set ft=xxd | silent exec "%!xxd -r" | endif
    autocmd BufWritePost * if &bin | set ft=xxd | silent exec "%!xxd" | endif
augroup end
function! ZBinaryFile()
    if &mod
        echomsg "Buffer has changes, please save or undo before proceeding."
        return
    endif
    if &bin == 0
        let &bin = 1
        let b:binary_mode = 0
        silent exec "e"
    else
        let &bin = 0
        silent exec "e"
    endif
endfunction
" }}}

" Objdump {{{
let g:objdump = 'objdump'
nnoremap <silent> <leader>dv :call ZObjdump()<CR>
command! -nargs=0 ZObjdump call ZObjdump()
function! ZObjdump()
    if exists('b:objdump_view') && b:objdump_view == 1
        set ro!
        silent exec "e!"
        let b:objdump_view = 0
    else
        if &mod
            echomsg "Buffer has changes, please save or undo before proceeding."
            return
        endif
        silent exec "%!" . g:objdump . " -M intel -s -C -D " . expand('%')
        set ro!
        DisableWhitespace
        set ft=asm
        let &mod = 0
        let b:objdump_view = 1
    endif
endfunction
" }}}

" Zip {{{
let g:zipPlugin_ext = '*.zip,*.jar,*.xpi,*.ja,*.war,*.ear,*.celzip,*.oxt,*.kmz,*.wsz,*.xap,*.docm,*.dotx,*.dotm,*.potx,*.potm,*.ppsx,*.ppsm,*.pptx,*.pptm,*.ppam,*.sldx,*.thmx,*.xlam,*.xlsx,*.xlsm,*.xlsb,*.xltx,*.xltm,*.xlam,*.crtx,*.vdw,*.glox,*.gcsx,*.gqsx,*.epub'
" }}}

" Pandoc {{{
augroup ZPandocGroup
    autocmd!
    autocmd BufReadPost *.doc,*.docx,*.rtf,*.odp,*.odt if !&bin |
        \ silent exec "\%!pandoc \"%\" -tmarkdown -o /dev/stdout" | set ft=markdown | set ro | endif
augroup end
command! -nargs=0 ZPandoc
    \ silent exec "\%!pandoc \"%\" -tmarkdown -o /dev/stdout" | set ft=markdown | set ro
command! -complete=file -nargs=1 ZPandocEdit
    \ call system("pandoc -f " .  split(<f-args>, '\.')[-1] . " -t markdown " .
    \ <f-args> . "> " . <f-args> . ".md")
    \ | exec "edit " . <f-args> . ".md"
command! -nargs=0 ZPandocWrite
    \ exec ":w" |
    \ call system("pandoc -f markdown -t " .  split(expand('%:p'), '\.')[-2] .
    \ " " .  expand('%:p') . "> " . split(expand('%:p'), '\.md')[0])
" }}}

" Tmux function keys workaround {{{
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
" }}}

" Jump to location {{{
function! ZJumpToLocation(file, line, column)
    silent exec ":edit " . fnameescape(a:file) . ""
    silent exec ":" . a:line
    if a:column
        silent exec ":normal! " . a:column . "|"
    endif
    normal! zz
endfunction
" }}}

" Syntax Information {{{
command! ZSyntaxInfo call ZSyntaxInfo()
function! ZSyntaxInfo()
    let l:s = synID(line('.'), col('.'), 1)
    echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
endfun
" }}}

" Command line complete {{{
cmap <c-k> <Plug>CmdlineCompleteBackward
cmap <c-j> <Plug>CmdlineCompleteForward
" }}}

" Wrap {{{
nnoremap <silent> - :setlocal wrap!<CR>
" }}}

" vim-signature {{{
let g:SignatureMarkTextHL = 'Normal'
let g:SignatureMap = {
    \ 'Leader'             :  "m",
    \ 'PlaceNextMark'      :  "m,",
    \ 'ToggleMarkAtLine'   :  "m.",
    \ 'PurgeMarksAtLine'   :  "m-",
    \ 'DeleteMark'         :  "dm",
    \ 'PurgeMarks'         :  "m<Space>",
    \ 'PurgeMarkers'       :  "m<BS>",
    \ 'GotoNextLineAlpha'  :  "",
    \ 'GotoPrevLineAlpha'  :  "",
    \ 'GotoNextSpotAlpha'  :  "",
    \ 'GotoPrevSpotAlpha'  :  "",
    \ 'GotoNextLineByPos'  :  "",
    \ 'GotoPrevLineByPos'  :  "",
    \ 'GotoNextSpotByPos'  :  "",
    \ 'GotoPrevSpotByPos'  :  "",
    \ 'GotoNextMarker'     :  "",
    \ 'GotoPrevMarker'     :  "",
    \ 'GotoNextMarkerAny'  :  "",
    \ 'GotoPrevMarkerAny'  :  "",
    \ 'ListBufferMarks'    :  "m/",
    \ 'ListBufferMarkers'  :  "m?"
    \ }
" }}}

" Undo file {{{
if !has('nvim')
    set undodir=~/.vim/undo
else
    set undodir=~/.vim/nundo
endif
set undolevels=10000
set undofile
command! -nargs=0 ZUndoCleanup call ZUndoCleanup()
function! ZUndoCleanup()
    copen
    AsyncRun find ~/.vim/undo -type f -mtime +90 -delete
endfunction
" }}}

" Async tasks {{{
let g:asyncrun_open = 6
let g:asyncrun_rootmarks = ['.git', '.svn', '.root', '.project', '.hg', '.files', '.repo']
let g:asynctasks_term_pos = 'bottom'
let g:asynctasks_term_rows = 10
let g:asynctasks_term_reuse = 1
noremap <silent> <F7> :call ZBuildProject()<CR>
inoremap <silent> <F7> <esc>:call ZBuildProject()<CR>
noremap <silent> <S-F7> :call ZCleanProject()<CR>
inoremap <silent> <S-F7> <esc>:call ZCleanProject()<CR>
noremap <silent> <C-F7> :call ZBuildConfig()<CR>
inoremap <silent> <C-F7> <esc>:call ZBuildConfig()<CR>
if !has('nvim')
    noremap <silent> <C-F5> :call ZRunProject()<CR>
    inoremap <silent> <C-F5> <esc>:call ZRunProject()<CR>
else
    noremap <silent> <F29> :call ZRunProject()<CR>
    inoremap <silent> <F29> <esc>:call ZRunProject()<CR>
endif
function! ZBuildProject()
    if !filereadable('.tasks')
        call ZBuildConfig()
    endif
    AsyncTask project-build
endfunction
function! ZCleanProject()
    if !filereadable('.tasks')
        call ZBuildConfig()
    endif
    AsyncTask project-clean
endfunction
function! ZRunProject()
    if !filereadable('.tasks')
        call ZBuildConfig()
    endif
    AsyncTask project-run
endfunction
function! ZBuildConfig()
    call inputsave()
    let command = input('Build command: ')
    call inputrestore()
    normal :<ESC>
    if !empty(command)
        call system("echo '[project-build]' > .tmptasks; echo -e 'command=" . command . "\n' >> .tmptasks")
    endif

    call inputsave()
    let command = input('Clean command: ')
    call inputrestore()
    normal :<ESC>
    if !empty(command)
        call system("echo '[project-clean]' >> .tmptasks; echo -e 'command=" . command . "\n' >> .tmptasks")
    endif

    call inputsave()
    let command = input('Run command: ')
    call inputrestore()
    normal :<ESC>
    if !empty(command)
        call system("echo '[project-run]' >> .tmptasks; echo -e 'command=" . command . "\n' >> .tmptasks; echo output=terminal >> .tmptasks")
    endif

    if filereadable('.tmptasks')
        call system("mv .tmptasks .tasks")
    endif
endfunction
" }}}

" Toggle fold / unfold {{{
nnoremap <silent> <leader>u :call ZToggleFold()<CR>
function! ZToggleFold()
    if &foldlevel == 0
        set foldlevel=100
    else
        set foldlevel=0
    endif
endfunction
" }}}

" Abolish {{{
let g:abolish_no_mappings = 1
nmap <leader>cr <Plug>(abolish-coerce-word)
" }}}

" Vimspector {{{
nnoremap <silent> <leader>dl :call ZVimspectorDebugLaunchSettings()<CR>
nnoremap <silent> <leader>dd :if !filereadable('.vimspector.json') \| call ZVimspectorDebugLaunchSettings() \| endif \| call vimspector#Launch()<CR>
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
nnoremap <silent> <F10> :exec "normal \<plug>VimspectorStepOver"<CR>:call vimspector#ListBreakpoints()<CR>:wincmd p<CR>
nmap <leader>di <plug>VimspectorStepInto
nnoremap <silent> <S-F10> :exec "normal \<plug>VimspectorStepInto"<CR>:call vimspector#ListBreakpoints()<CR>:wincmd p<CR>
nnoremap <silent> <F11> :exec "normal \<plug>VimspectorStepInto"<CR>:call vimspector#ListBreakpoints()<CR>:wincmd p<CR>
nmap <leader>do <plug>VimspectorStepOut
nmap <S-F11> <plug>VimspectorStepOut
nnoremap <silent> <leader>dq :VimspectorReset<CR>
let g:vimspector_install_gadgets = ['debugpy', 'vscode-cpptools']
let g:vimspector_sign_priority = {
  \    'vimspectorBP':         300,
  \    'vimspectorBPCond':     200,
  \    'vimspectorBPDisabled': 100,
  \    'vimspectorPC':         999,
  \    'vimspectorPCBP':       999,
  \ }
augroup ZVimspectorCustomMappings
    autocmd!
    autocmd FileType VimspectorPrompt call ZVimspectorInitializePrompt()
    autocmd User VimspectorUICreated call ZVimspectorSetupUi()
augroup end
function! ZVimspectorSetupUi()
    call win_gotoid(g:vimspector_session_windows.output)
    set ft=asm
    vert rightb copen
    exec ":vert resize " . winwidth(g:vimspector_session_windows.output)/3
    nnoremenu <silent> WinBar.ListBreakpoints :call vimspector#ListBreakpoints()<CR>
    call vimspector#ListBreakpoints()
    call win_gotoid(g:vimspector_session_windows.code)
endfunction
function! ZVimspectorInitializePrompt()
    nnoremap <silent> <buffer> x i-exec<space>
    if !exists('b:vimspector_command_history')
        call ZVimspectorInitializeCommandHistoryMaps()
        let b:vimspector_command_history = []
        let b:vimspector_command_history_pos = 0
    endif
endfunction
function! ZVimspectorInitializeCommandHistoryMaps()
    inoremap <silent> <buffer> <CR> <C-o>:call ZVimspectorCommandHistoryAdd()<CR>
    inoremap <silent> <buffer> <Up> <C-o>:call ZVimspectorCommandHistoryUp()<CR>
    inoremap <silent> <buffer> <Down> <C-o>:call ZVimspectorCommandHistoryDown()<CR>
endfunction
function! ZVimspectorCommandHistoryAdd()
    call add(b:vimspector_command_history, getline('.'))
    let b:vimspector_command_history_pos = len(b:vimspector_command_history)
    call feedkeys("\<CR>", 'tn')
endfunction
function! ZVimspectorCommandHistoryUp()
    if len(b:vimspector_command_history) == 0 || b:vimspector_command_history_pos == 0
        return
    endif
    call setline('.', b:vimspector_command_history[b:vimspector_command_history_pos - 1])
    call feedkeys("\<C-o>A", 'tn')
    let b:vimspector_command_history_pos = b:vimspector_command_history_pos - 1
endfunction
function! ZVimspectorCommandHistoryDown()
    if b:vimspector_command_history_pos == len(b:vimspector_command_history)
        return
    endif
    call setline('.', b:vimspector_command_history[b:vimspector_command_history_pos - 1])
    call feedkeys("\<C-o>A", 'tn')
    let b:vimspector_command_history_pos = b:vimspector_command_history_pos + 1
endfunction
augroup ZVisualMultiVimspector
    autocmd!
    autocmd User visual_multi_exit if &ft == 'VimspectorPrompt' | call ZVimspectorInitializeCommandHistoryMaps() | endif
augroup end
function! ZVimspectorGenerateCpp()
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
            \ echo '                \"cwd\": \"${workspaceRoot}\",' >> .vimspector.json &&
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
function! ZVimspectorGeneratePy()
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
        \ echo '                \"args\": [],' >> .vimspector.json &&
        \ echo '                \"python\": \"" . python . "\",' >> .vimspector.json &&
        \ echo '                \"cwd\": \"${workspaceRoot}\",' >> .vimspector.json &&
        \ echo '                \"externalConsole\": true,' >> .vimspector.json &&
        \ echo '                \"stopAtEntry\": true' >> .vimspector.json &&
        \ echo '            }' >> .vimspector.json &&
        \ echo '        }' >> .vimspector.json &&
        \ echo '    }' >> .vimspector.json &&
        \ echo '}' >> .vimspector.json")
endfunction
function! ZVimspectorDebugLaunchSettings()
    let debug_type = &filetype
    if debug_type != 'cpp' && debug_type != 'c' && debug_type != 'python'
        call inputsave()
        let debug_type = input('Debugger type (cpp/python): ')
        call inputrestore()
    endif

    if debug_type == 'cpp' || debug_type == 'c'
        call ZVimspectorGenerateCpp()
    elseif debug_type == 'python'
        call ZVimspectorGeneratePy()
    else
        normal :<ESC>
        echom 'Invalid debug type.'
    endif
endfunction
" }}}

" Toggle Powerline {{{
command! ZTogglePowerline call ZTogglePowerline()
function! ZTogglePowerline()
    if filereadable(expand('~/.vim/.powerline'))
        call system("rm ~/.vim/.powerline")
    else
        call system("touch ~/.vim/.powerline")
    endif
    if !empty($TMUX)
        call system('tmux source ~/.tmux.conf')
    endif
endfunction
" }}}

" Toggle DevIcons {{{
command! ZToggleDevIcons call ZToggleDevIcons()
function! ZToggleDevIcons()
    if filereadable(expand('~/.vim/.devicons'))
        call system("rm ~/.vim/.devicons")
    else
        call system("touch ~/.vim/.devicons")
    endif
endfunction
" }}}

" Indent Line / Blankline {{{
nnoremap <silent> <leader>zi :call ZToggleIndentLines()<CR>
if !has('nvim')
    let g:indentLine_char = '│'
    let g:indentLine_first_char = '│'
    let g:indentLine_showFirstIndentLevel = 1
    let g:indentLine_enabled = filereadable(expand('~/.vim/.indentlines'))
    let g:indentLine_color_gui = '#404040'
    let g:vim_json_conceal = 0
    if g:indentLine_enabled
        hi SpecialKey guifg='#404040' gui=nocombine
        set list lcs=tab:\│\ "
    endif
    command! ZToggleIndentLines call ZToggleIndentLines()
    function! ZToggleIndentLines()
        if filereadable(expand('~/.vim/.indentlines'))
            call system("rm ~/.vim/.indentlines")
            set list lcs=tab:\ \ "
            IndentLinesDisable
        else
            call system("touch ~/.vim/.indentlines")
            hi SpecialKey guifg='#404040' gui=nocombine
            set list lcs=tab:\│\ "
            IndentLinesEnable
        endif
    endfunction
else
    if filereadable(expand('~/.vim/.indentlines'))
        let g:indent_blankline_enabled = v:true
    else
        let g:indent_blankline_enabled = v:false
    endif
    let g:indent_blankline_char = '│'
    let g:indent_blankline_show_first_indent_level = v:true
    if empty(&colorcolumn)
        set colorcolumn=99999
    endif
    hi IndentBlanklineChar guifg=#404040 gui=nocombine
    command! ZToggleIndentLines call ZToggleIndentLines()
    function! ZToggleIndentLines()
        if filereadable(expand('~/.vim/.indentlines'))
            call system("rm ~/.vim/.indentlines")
            IndentBlanklineDisable!
        else
            call system("touch ~/.vim/.indentlines")
            IndentBlanklineEnable!
        endif
    endfunction
endif
" }}}

" Additional color settings {{{
if g:colors_name == 'codedark'
    " Terminal ansi colors
    if !has('nvim')
        let g:terminal_ansi_colors =
        \ ['#1e1e1e',
        \ '#f44747',
        \ '#6a9955',
        \ '#ffaf00',
        \ '#0a7aca',
        \ '#c586c0',
        \ '#4ec9b0',
        \ '#d4d4d4',
        \ '#303030',
        \ '#d16969',
        \ '#6a9955',
        \ '#ce9a78',
        \ '#569cd6',
        \ '#c586c0',
        \ '#4ec9b0',
        \ '#51504f']
    else
        let g:terminal_color_0 = '#1e1e1e'
        let g:terminal_color_1 = '#f44747'
        let g:terminal_color_2 = '#6a9955'
        let g:terminal_color_3 = '#ffaf00'
        let g:terminal_color_4 = '#0a7aca'
        let g:terminal_color_5 = '#c586c0'
        let g:terminal_color_6 = '#4ec9b0'
        let g:terminal_color_7 = '#d4d4d4'
        let g:terminal_color_8 = '#303030'
        let g:terminal_color_9 = '#d16969'
        let g:terminal_color_10 = '#6a9955'
        let g:terminal_color_11 = '#ce9a78'
        let g:terminal_color_12 = '#569cd6'
        let g:terminal_color_13 = '#c586c0'
        let g:terminal_color_14 = '#4ec9b0'
        let g:terminal_color_15 = '#51504f'
    endif

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

    let s:cdBack = {'gui': '#1E1E1E', 'cterm': s:cterm00, 'cterm265': '234'}
    let s:cdLightBlue = {'gui': '#9CDCFE', 'cterm': s:cterm0C, 'cterm256': '117'}
    let s:cdMidBlue = {'gui': '#519aba', 'cterm': s:cterm0D, 'cterm256': '75'}
    let s:cdBlue = {'gui': '#569CD6', 'cterm': s:cterm0D, 'cterm256': '75'}
    let s:cdDarkBlue = {'gui': '#223E55', 'cterm': s:cterm0D, 'cterm256': '73'}
    let s:cdYellow = {'gui': '#DCDCAA', 'cterm': s:cterm0A, 'cterm256': '187'}
    let s:cdYellowOrange = {'gui': '#D7BA7D', 'cterm': s:cterm0A, 'cterm256': '179'}
    let s:cdPink = {'gui': '#C586C0', 'cterm': s:cterm0E, 'cterm256': '176'}
    let s:cdBlueGreen = {'gui': '#4EC9B0', 'cterm': s:cterm0F, 'cterm256': '43'}
    let s:cdGreen = {'gui': '#6A9955', 'cterm': s:cterm0B, 'cterm256': '65'}
    let s:cdLightGreen = {'gui': '#B5CEA8', 'cterm': s:cterm09, 'cterm256': '151'}
    let s:cdOrange = {'gui': '#CE9178', 'cterm': s:cterm0F, 'cterm256': '173'}
    let s:cdVividOrange = {'gui': '#FFAF00', 'cterm': s:cterm0A, 'cterm256': '214'}
    let s:cdLightRed = {'gui': '#D16969', 'cterm': s:cterm08, 'cterm256': '167'}
    let s:cdRed = {'gui': '#F44747', 'cterm': s:cterm08, 'cterm256': '203'}
    let s:cdViolet = {'gui': '#646695', 'cterm': s:cterm04, 'cterm256': '60'}
    let s:cdVividBlue = {'gui': '#0A7ACA', 'cterm': s:cterm0D, 'cterm256': '32'}
    let s:cdFront = {'gui': '#D4D4D4', 'cterm': s:cterm05, 'cterm256': '188'}
    let s:cdWhite = {'gui': '#FFFFFF', 'cterm':  s:cterm07, 'cterm256': '15'}

    let s:cdIconGreyOrTermFront = {'gui': '#6d8086', 'cterm': s:cterm05, 'cterm256': '188'}
    let s:cdIconYellowOrTermFront = {'gui': '#cbcb41', 'cterm': s:cterm05, 'cterm256': '188'}

    " Codedark colors defined
    let s:codedark_colors_defined = 1

    " C++
    call ZHighLight('cCustomAccessKey', s:cdBlue, {}, 'none', {})
    call ZHighLight('cppModifier', s:cdBlue, {}, 'none', {})
    call ZHighLight('cppExceptions', s:cdBlue, {}, 'none', {})
    call ZHighLight('cOperator', s:cdBlue, {}, 'none', {})
    call ZHighLight('cppStatement', s:cdBlue, {}, 'none', {})
    call ZHighLight('cppSTLType', s:cdBlueGreen, {}, 'none', {})
    call ZHighLight('cppSTLnamespace', s:cdBlueGreen, {}, 'none', {})
    call ZHighLight('cCustomClassName', s:cdBlueGreen, {}, 'none', {})
    call ZHighLight('cCustomClass', s:cdBlueGreen, {}, 'none', {})
    call ZHighLight('cppSTLexception', s:cdBlueGreen, {}, 'none', {})
    call ZHighLight('cppSTLconstant', s:cdLightBlue, {}, 'none', {})
    call ZHighLight('cppSTLvariable', s:cdLightBlue, {}, 'none', {})
    call ZHighLight('cCustomMemVar', s:cdLightBlue, {}, 'none', {})
    call ZHighLight('cppSTLfunction', s:cdYellow, {}, 'none', {})
    call ZHighLight('cCustomOperator', s:cdYellow, {}, 'none', {})
    call ZHighLight('cConstant', s:cdPink, {}, 'none', {})
    call ZHighLight('cppNew', s:cdPink, {}, 'none', {})
    call ZHighLight('cppDelete', s:cdPink, {}, 'none', {})
    call ZHighLight('cppUsing', s:cdPink, {}, 'none', {})
    "call ZHighLight('cRepeat', s:cdPink, {}, 'none', {})
    "call ZHighLight('cConditional', s:cdPink, {}, 'none', {})
    "call ZHighLight('cStatement', s:cdPink, {}, 'none', {})

    " Python
    call ZHighLight('pythonBuiltin', s:cdBlueGreen, {}, 'none', {})
    call ZHighLight('pythonExceptions', s:cdBlueGreen, {}, 'none', {})
    call ZHighLight('pythonBuiltinObj', s:cdLightBlue, {}, 'none', {})
    call ZHighLight('pythonRepeat', s:cdPink, {}, 'none', {})
    call ZHighLight('pythonConditional', s:cdPink, {}, 'none', {})
    call ZHighLight('pythonException', s:cdPink, {}, 'none', {})
    call ZHighLight('pythonInclude', s:cdPink, {}, 'none', {})
    call ZHighLight('pythonImport', s:cdPink, {}, 'none', {})
    call ZHighLight('pythonStatement', s:cdPink, {}, 'none', {})
    call ZHighLight('pythonOperator', s:cdBlue, {}, 'none', {})
    call ZHighLight('pythonDef', s:cdBlue, {}, 'none', {})
    call ZHighLight('pythonLambda', s:cdBlue, {}, 'none', {})
    call ZHighLight('pythonFunction', s:cdYellow, {}, 'none', {})
    call ZHighLight('pythonDecorator', s:cdYellow, {}, 'none', {})
    call ZHighLight('pythonBuiltinFunc', s:cdYellow, {}, 'none', {})

    " Gitgutter
    call ZHighLight('GitGutterAdd', s:cdGreen, {}, 'none', {})
    call ZHighLight('GitGutterChange', s:cdFront, {}, 'none', {})
    call ZHighLight('GitGutterDelete', s:cdRed, {}, 'none', {})

    " NERDTree
    call ZHighLight('NERDTreeOpenable', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('NERDTreeClosable', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('NERDTreeHelp', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('NERDTreeDir', s:cdFront, {}, 'none', {})
    call ZHighLight('NERDTreeUp', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('NERDTreeDirSlash', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('NERDTreeFile', s:cdFront, {}, 'none', {})
    call ZHighLight('NERDTreeExecFile', s:cdFront, {}, 'none', {})
    call ZHighLight('NERDTreeLinkFile', s:cdBlueGreen, {}, 'none', {})
    call ZHighLight('NERDTreeCWD', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('NERDTreeFlags', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('WebDevIconsDefaultFolderSymbol', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('WebDevIconsDefaultOpenFolderSymbol', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('nerdtreeExactMatchIcon_makefile', s:cdIconGreyOrTermFront, {}, 'none', {})
    call ZHighLight('nerdtreeExactMatchIcon_license', s:cdIconYellowOrTermFront, {}, 'none', {})
    call ZHighLight('nerdtreeFileExtensionIcon_json', s:cdIconYellowOrTermFront, {}, 'none', {})
    call ZHighLight('nerdtreeFileExtensionIcon_h', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('nerdtreeFileExtensionIcon_c', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('nerdtreeFileExtensionIcon_cpp', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('nerdtreeFileExtensionIcon_py', s:cdMidBlue, {}, 'none', {})
    let g:NERDTreeExtensionHighlightColor = {}
    let g:NERDTreeExtensionHighlightColor['json'] = ''
    let g:NERDTreeExtensionHighlightColor['h'] = ''
    let g:NERDTreeExtensionHighlightColor['c'] = ''
    let g:NERDTreeExtensionHighlightColor['cpp'] = ''
    let g:NERDTreeExtensionHighlightColor['py'] = ''

    " Tagbar
    call ZHighLight('TagbarFoldIcon', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('TagbarKind', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('TagbarScope', s:cdMidBlue, {}, 'none', {})
    call ZHighLight('TagbarSignature', s:cdFront, {}, 'none', {})
    call ZHighLight('TagbarHelp', s:cdMidBlue, {}, 'none', {})

    " Vim
    call ZHighLight('VimOperError', s:cdRed, {}, 'none', {})
    call ZHighLight('vimFunction', s:cdYellow, {}, 'none', {})

    " Json
    call ZHighLight('jsonCommentError', s:cdGreen, {}, 'none', {})
    call ZHighLight('jsonString', s:cdOrange, {}, 'none', {})
    call ZHighLight('jsonNumber', s:cdLightGreen, {}, 'none', {})

    " Yaml
    call ZHighLight('yamlBlockCollectionItemStart', s:cdFront, {}, 'none', {})
    call ZHighLight('yamlKeyValueDelimiter', s:cdFront, {}, 'none', {})
    call ZHighLight('yamlPlainScalar', s:cdOrange, {}, 'none', {})
    call ZHighLight('yamlBlockMappingKey', s:cdLightBlue, {}, 'none', {})

    " Plant Uml
    call ZHighLight('plantumlPreviewMethodCallParen', s:cdFront, {}, 'none', {})
    call ZHighLight('plantumlPreviewMethodCall', s:cdYellow, {}, 'none', {})

    " Cursor line
    highlight CursorLine ctermbg=235 guibg=#262626
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
    let s:onedarkCyan = { "gui": "#56B6C2", "cterm": "38", "cterm16": "6" }

    " Tagbar Highlights
    call ZHighLight('TagbarSignature', {"fg": s:onedarkWhite})

    " Cpp
    call ZHighLight('cCompundObject', {"fg": s:onedarkWhite})
    call ZHighLight('cIntegerType', {"fg": s:onedarkCyan})
elseif g:colors_name == 'nord'
    function! ZHighLight(group, guifg, guibg, ctermfg, ctermbg, attr, guisp)
      if a:guifg != ""
        exec "hi " . a:group . " guifg=" . a:guifg
      endif
      if a:guibg != ""
        exec "hi " . a:group . " guibg=" . a:guibg
      endif
      if a:ctermfg != ""
        exec "hi " . a:group . " ctermfg=" . a:ctermfg
      endif
      if a:ctermbg != ""
        exec "hi " . a:group . " ctermbg=" . a:ctermbg
      endif
      if a:attr != ""
        exec "hi " . a:group . " gui=" . a:attr . " cterm=" . substitute(a:attr, "undercurl", s:underline, "")
      endif
      if a:guisp != ""
        exec "hi " . a:group . " guisp=" . a:guisp
      endif
    endfunction

    " Colors
    let s:nord8_gui = "#88C0D0"
    let s:nord8_term = "6"

    " Makefile
    call ZHighLight("makeIdent", s:nord8_gui, "", s:nord8_term, "", "", "")
endif
" }}}

" Airline {{{
let g:airline#extensions#whitespace#checks = ['indent', 'trailing', 'mixed-indent-file', 'conflicts']
let g:airline#extensions#whitespace#trailing_format = 'tr[%s]'
let g:airline#extensions#whitespace#mixed_indent_file_format = 'mi[%s]'
let g:airline#extensions#whitespace#mixed_indent_format = 'mi[%s]'
let g:airline#extensions#whitespace#conflicts_format = 'conflict[%s]'
let g:airline_theme_patch_func = 'ZAirlineThemePatch'
let g:airline#extensions#zoomwintab#enabled = 1
let g:airline#extensions#zoomwintab#status_zoomed_in = '(zoom)'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#tabs_label = ''
let g:airline#extensions#tabline#buffers_label = ''
let g:airline#extensions#tabline#show_splits = 0
let g:airline#extensions#tabline#show_close_button = 0
let g:airline#extensions#tabline#show_tab_type = 0
let g:airlie#extensions#tabline#show_tab_nr = 0
let g:airline#extensions#tabline#show_buffers = 1
let g:airline#extensions#tabline#fnamecollapse = 1
let g:airline#extensions#tabline#fnamemod = ':t'
set showtabline=2
nnoremap <silent> <f1> :bp<CR>
nnoremap <silent> <f2> :bn<CR>
if filereadable(expand('~/.vim/.powerline'))
    let g:airline_powerline_fonts = 1
else
    let g:airline_powerline_fonts = 0
endif
function! ZAirlineThemePatch(palette)
    if g:airline_theme == 'codedark' && exists('s:codedark_colors_defined') && s:codedark_colors_defined
        let airline_error = [ s:cdWhite.gui, s:cdRed.gui, s:cdWhite.cterm, s:cdRed.cterm]
        let airline_warning = [ s:cdWhite.gui, s:cdRed.gui, s:cdWhite.cterm, s:cdRed.cterm]

        let a:palette.normal.airline_warning = airline_warning
        let a:palette.normal.airline_error = airline_error
        let a:palette.normal_modified.airline_warning = airline_warning
        let a:palette.normal_modified.airline_error = airline_error
        let a:palette.insert.airline_warning = airline_warning
        let a:palette.insert.airline_error = airline_error
        let a:palette.insert_modified.airline_warning = airline_warning
        let a:palette.insert_modified.airline_error = airline_error
        let a:palette.replace.airline_warning = airline_warning
        let a:palette.replace.airline_error = airline_error
        let a:palette.replace_modified.airline_warning = airline_warning
        let a:palette.replace_modified.airline_error = airline_error
        let a:palette.visual.airline_warning = airline_warning
        let a:palette.visual.airline_error = airline_error
        let a:palette.visual_modified.airline_warning = airline_warning
        let a:palette.visual_modified.airline_error = airline_error
        let a:palette.inactive.airline_warning = airline_warning
        let a:palette.inactive.airline_error = airline_error
        let a:palette.inactive_modified.airline_warning = airline_warning
        let a:palette.inactive_modified.airline_error = airline_error
    endif
endfunction
" }}}

" vim-winmanip {{{
let g:winmanip_disable_key_mapping = 1
nmap <silent> 1<Right> <Plug>(JumpRight)
nmap <silent> 1<Left> <Plug>(JumpLeft)
nmap <silent> 1<Down> <Plug>(JumpDown)
nmap <silent> 1<Up> <Plug>(JumpUp)

nmap <silent> <C-w><C-l> <Plug>(MoveBufRight)
nmap <silent> <C-w><C-h> <Plug>(MoveBufLeft)
nmap <silent> <C-w><C-j> <Plug>(MoveBufDown)
nmap <silent> <C-w><C-k> <Plug>(MoveBufUp)

nmap <silent> 2<Right> <Plug>(MoveBufRight)
nmap <silent> 2<Left> <Plug>(MoveBufLeft)
nmap <silent> 2<Down> <Plug>(MoveBufDown)
nmap <silent> 2<Up> <Plug>(MoveBufUp)

nmap <silent> 3<Right> <Plug>(MoveJumpBufRight)
nmap <silent> 3<Left> <Plug>(MoveJumpBufLeft)
nmap <silent> 3<Down> <Plug>(MoveJumpBufDown)
nmap <silent> 3<Up> <Plug>(MoveJumpBufUp)

nmap 4<Right> <Plug>(MoveWinToNextTab)
nmap 4<Left> <Plug>(MoveWinToPrevTab)

nmap <silent> 5<Right> <Plug>(CopyBufRight)
nmap <silent> 5<Left> <Plug>(CopyBufLeft)
nmap <silent> 5<Down> <Plug>(CopyBufDown)
nmap <silent> 5<Up> <Plug>(CopyBufUp)

nmap <silent> 6<Right> <Plug>(CopyJumpBufRight)
nmap <silent> 6<Left> <Plug>(CopyJumpBufLeft)
nmap <silent> 6<Down> <Plug>(CopyJumpBufDown)
nmap <silent> 6<Up> <Plug>(CopyJumpBufUp)
nmap <silent> <C-w>C <Plug>(ClearAllWindows)
" }}}

" Transparent background support {{{
nnoremap <silent> <leader>tb :ZToggleTransparentBackground<CR>
let s:is_transparent = 0
if filereadable(expand('~/.vim/.transparent')) && g:colors_name != 'codedark'
    let s:is_transparent = 1
    hi Normal guibg=NONE ctermbg=NONE
    hi CursorLine ctermbg=NONE guibg=NONE
endif
command! ZToggleTransparentBackground call ZToggleTransparentBackground() | source ~/.vimrc
function! ZToggleTransparentBackground()
    if filereadable(expand('~/.vim/.transparent'))
        call system("rm ~/.vim/.transparent")
    else
        call system("touch ~/.vim/.transparent")
    endif
    if !empty($TMUX)
        call system('tmux source ~/.tmux.conf')
    endif
endfunction
" }}}

" UltiSnips {{{
let g:UltiSnipsSnippetDirectories = ["UltiSnips", "vim-ultisnips"]
if g:lsp_choice != 'coc'
    let g:UltiSnipsExpandTrigger = '<c-d>'
endif
" }}}
