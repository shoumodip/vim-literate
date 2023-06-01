let g:literate#file_path = "<!-- vim-literate \\f\\+ -->"
let g:literate#block_end = "^```$"
let g:literate#block_start = "^```\\w\\+"
let g:literate#block_comment = "<!-- vim-literate -->"

function! literate#get(value)
  if exists("b:literate_".a:value)
    return eval("b:literate_".a:value)
  else
    return eval("g:literate#".a:value)
  endif
endfunction

function! literate#save()
  let bufnr = b:literate_bufnr
  let block = b:literate_block
  let cursor = getpos(".")
  let source = getline(1, "$")
  bdelete!

  execute "buffer " . bufnr
  call deletebufline(bufnr, block[0] + 1, block[1] - 1)
  call appendbufline(bufnr, block[0], source)

  let cursor[0] = bufnr
  let cursor[1] += block[0]
  call setpos(".", cursor)
endfunction

function! literate#block()
  let init = line(".")
  let head = search(literate#get("block_start"), "bcnW")
  if head == 0
    return []
  endif

  let tail = search(literate#get("block_end"), "cnW")
  if tail == 0
    return []
  endif

  if tail < init
    return []
  endif

  return [head, tail]
endfunction

function! literate#export()
  let file = getline(1)
  let form = literate#get("file_path")
  if file !~# form
    echohl ErrorMsg
    echom "error: export file not specified (set first line to `".substitute(form, "\\\\f\\\\+", "FILE", "")."`)"
    echohl None
    return
  endif
  let file = file[18:-5]

  let save = winsaveview()
  let output = []

  normal! gg
  while v:true
    let line = search(literate#get("block_start"), "cW")
    if line == 0
      break
    endif

    let block = literate#block()
    if block != [] && getline(block[0] - 1) !=# literate#get("block_comment")
      call extend(output, getline(block[0] + 1, block[1] - 1))
    endif

    normal! j
  endwhile

  call winrestview(save)
  call writefile(output, file)
endfunction

function! literate#source()
  let bufnr = bufnr()
  let block = literate#block()
  if block == []
    return
  endif
  let cursor = getpos(".")
  let source = getline(block[0], block[1])

  new
  let b:literate_bufnr = bufnr
  let b:literate_block = block
  let &l:buftype = "nofile"
  let &l:filetype = trim(source[0], "`")

  call setline(1, source[1:-2])
  echo "Press ZZ to save changes"

  let cursor[0] = bufnr()
  let cursor[1] -= block[0]
  call setpos(".", cursor)

  nnoremap <buffer> <silent> ZZ :call literate#save()<cr>
endfunction

function! literate#toggle()
  let block = literate#block()
  if block == []
    return
  endif

  let bufnr = bufnr()
  let start = block[0] - 1
  let comment = literate#get("block_comment")
  if getline(start) == comment
    call deletebufline(bufnr, start)
  else
    call appendbufline(bufnr, start, comment)
  endif
endfunction
