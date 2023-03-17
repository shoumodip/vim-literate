# literate.vim
Some literate programming features for Vim

## Installation
```vim
Plug 'shoumodip/vim-literate'
```

## Export
Export the code blocks in the file into the target file

```vim
call literate#export()
```

Make sure the first line of the file is of the format `<!-- vim-literate FILE -->`

## Source
Edit the code block under the cursor in its own buffer

```vim
call literate#source()
```

## Toggle
Toggle the code block under the cursor from the exporting system

```vim
call literate#toggle()
```

This can also be done manually by prepending the code block with `<!-- vim-literate -->`
