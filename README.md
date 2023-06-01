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

## Configuration
| Variable                   | Description               | Default                      |
| -------------------------- | ------------------------- | ---------------------------- |
| `g:literate#file_path`     | Export file path          | `<!-- vim-literate \f\+ -->` |
| `g:literate#block_end`     | Code block end            | `^```$`                      |
| `g:literate#block_start`   | Code block start          | `^```\w\+`                   |
| `g:literate#block_comment` | Code block comment marker | `<!-- vim-literate -->`      |

## Buffer Local Configuration
| Variable                   | Buffer Local               |
| -------------------------- | -------------------------- | 
| `g:literate#file_path`     | `b:literate_file_path`     |
| `g:literate#block_end`     | `b:literate_block_end`     |
| `g:literate#block_start`   | `b:literate_block_start`   |
| `g:literate#block_comment` | `b:literate_block_comment` |
