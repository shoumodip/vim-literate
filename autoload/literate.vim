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
    let head = search("^```\\w\\+", "bcnW")
    if head == 0
        return []
    endif

    let tail = search("^```$", "cnW")
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
    if file !~# "<!-- vim-literate \\f\\+ -->"
        echo "Export file name is not specified"
        echo "Put `<!-- vim-literate FILE -->` at the first line of the file"
        return
    endif
    let file = file[18:-5]

    let save = winsaveview()
    let output = []

    normal! gg
    while v:true
        let line = search("^```\\w\\+", "cW")
        if line == 0
            break
        endif

        let block = literate#block()
        if block != [] && getline(block[0] - 1) !=# "<!-- vim-literate -->"
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
    if getline(start) == "<!-- vim-literate -->"
        call deletebufline(bufnr, start)
    else
        call appendbufline(bufnr, start, "<!-- vim-literate -->")
    endif
endfunction
