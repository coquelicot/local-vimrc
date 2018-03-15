LocalVimrc
=====

A plugin that enable local vimrc (lvimrc) for files.

## What will be loaded

Currently, all files (including hidden files) end with "lvimrc" are recognized.

* ~/lvimrc
* ~/.lvimrc
* ~/\_lvimrc
* ~/my-proj/purpose-a.lvimrc
* ~/my-proj/purpose-b.lvimrc
* ~/my-proj/.purpose-c.lvimrc

## When will it be loaded

When a file is opened, all lvimrcs on the path will be loaded.

## How to write lvimrc

Lvimrcs are just normal vim scripts signed by our plugin,
you may edit it directly with vim and our plugin will update the signagure automatically.
