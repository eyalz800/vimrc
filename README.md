vimrc
=====

Installation
------------
This is the only thing you need to do to install, it will replace any existing vimrc and perform necessary installations:
```sh
$ sudo ./install.sh
```

Highlights
----------
* Supports easy installation on a clean machine, with many useful commands (see commands below)
* Supports completion wherever possible, mainly focused around C++ code completion using clangd.
* Nice color scheme.
* Comes with a good set of plugins.
* More surprises are waiting for those who read the vimrc.

Useful Commands
---------------
* Commands to generate source index, run in the root directory - you need to run both of them.
```
<leader>zp - Generate/update C++ databases - optimized to work for large repositories.
<leader>zk - Generate/update opengrok database for common source files (see ZGenerateOpengrok)
```

* Commands to search for files:
```
<C-p> - Search for a file name.
```

* Commands to search for code:
```
<leader>zo - Search opengrok for word under cursor.
<leader><leader>zo - Search opengrok for arbitrary input text.

<leader>cs - Search cscope for word under cursor.
<leader><leader>cs - Search cscope for arbitrary input text.
```

* Commands to view directory tree and source code function pane on each side of the screen:
```
<C-L> - Turn on / off the directory tree and source code function panes.
```

* Terminal commands:
```
<leader>zb - Open small terminal window below.
<leader>zB - Open large terminal window below.
```

* Debugging commands:
```
<leader>dl - Configure debugging configuration - requires an open cpp or python file.
<leader>dd - Start debugging - search vimrc for "vimspector" for additional mapping.
```
