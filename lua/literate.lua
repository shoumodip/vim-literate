-- My favourite literate programming features of Org Mode ported to Vim.
-- Includes tangling of code blocks, filetype edit windows and comment blocks.
-- A.K.A     C-c C-v t     C-c '     C-c ;
-- Used with a Markdown file.
-- autocmd FileType markdown lua require('literate')

-- Variables -{{{
local tangle_comment = '<!-- no-tangle -->' -- The string recognised as a code block ignorer for tangle
local api = vim.api -- Prevent RSI
local startline -- The starting line of a code block
local endline -- The ending line of a code block
-- }}}
-- Get the limits of a code block -{{{
local function CodeBlockRange()

  -- The starting line of the code block
  if not string.match(api.nvim_get_current_line(), '^```.+') then
    api.nvim_call_function('search', {'^```\\S', 'W'})
  end
  startline = api.nvim_win_get_cursor(0)[1] + 1

  -- The ending line of the code block
  api.nvim_call_function('search', {'^```$', 'W'})
  endline = api.nvim_win_get_cursor(0)[1] - 1
end
-- }}}
-- Export all the 'non-comment' code blocks in the markdown file -{{{
local function ExportCode()

  local initpos = api.nvim_win_get_cursor(0) -- The initial cursor position
  api.nvim_win_set_cursor(0, {1, 0}) -- Same as 'gg'
  local firstline = api.nvim_get_current_line() -- The first line of the file

  if string.match(firstline, '<.-- tangle: .* -->') then -- Only tangle if asked

    -- The output file name
    local parentdir = string.gsub(api.nvim_eval('expand("%:p:h")'), '^/$', '') .. '/'
    local targetfile = string.gsub(string.gsub(string.gsub(firstline, '.* tangle: ', ''), ' +-->', ''), '"', '\"')
    local outputfile = parentdir .. targetfile

    if api.nvim_call_function('glob', {outputfile}) == '' then
      os.execute('touch ' .. outputfile) -- Create the output file if nonexistant
    end

    -- Don't tangle if the output file is actually a directory
    if api.nvim_call_function('isdirectory', {outputfile}) == 0 and api.nvim_call_function('filereadable', {outputfile}) == 1 then
      local codeblocks = 0 -- The number of code blocks tangled

      os.execute('>' .. outputfile) -- Clear the output file

      CodeBlockRange()

      while endline < api.nvim_call_function('line', {'$'}) - 1 do

        if endline + 1 > startline then -- Prevent infinite looping
          if api.nvim_call_function('getline', {startline - 2}) ~= tangle_comment then -- Don't tangle if marked as a 'comment'
            codeblocks = codeblocks + 1
            api.nvim_command("silent! " .. startline .. "," .. endline .. "write! >> " .. outputfile) -- Tangle the code block
            os.execute('echo "" >> ' .. outputfile)
          end
        end

        CodeBlockRange()
      end

      -- If there is one more code block, tangle it
      if endline + 1 > startline then

        if api.nvim_call_function('getline', {startline - 2}) ~= tangle_comment then
          api.nvim_command("silent! " .. startline .. "," .. endline .. "write! >> " .. outputfile)
          codeblocks = codeblocks + 1
        end

      end

      -- Display a message
      if codeblocks > 0 then
        api.nvim_command('unsilent echon "Tangled ' .. codeblocks .. ' code ' .. (codeblocks > 1 and 'blocks' or 'block') .. ' to `"')
        api.nvim_command('echohl Identifier')
        api.nvim_command('unsilent echon "' .. targetfile .. '"')
        api.nvim_command('echohl Normal')
        api.nvim_command('unsilent echon "`"')
      end
    else

      -- Couldn't tangle the code blocks, show error message
      api.nvim_command('echohl WarningMsg')
      api.nvim_command('echon "ERROR: Couldn\'t tangle code blocks. Make sure output file is not a directory and is readable!"')
      api.nvim_command('echohl Normal')
    end
  end

  api.nvim_win_set_cursor(0, initpos) -- Reposition the cursor to its original position
end
-- }}}
-- 'Comment' out a code block (or if it is already 'commented', 'uncomment' it) -{{{
-- A 'commented' code block will not get tangled. It DOES NOT refer to comment in
-- the actual code. It is actually a markdown comment in the line above the code
-- block
local function CommentBlock()

  -- Only toggle code blocks if it has a valid tangle property
  if string.match(api.nvim_call_function('getline', {1}), '<.-- tangle: .* -->') then

    local initpos = api.nvim_win_get_cursor(0) -- The initial cursor position

    if not string.match(api.nvim_get_current_line(), '^```.+') then
      api.nvim_call_function('search', {'^```', 'bW'}) -- Beginning of the code block
    end

    if string.match(api.nvim_get_current_line(), '^```.+') then -- Only toggle comment if it is a valid code block
      api.nvim_command('normal! k') -- Go up a line

      if api.nvim_get_current_line() == tangle_comment then

        -- Remove the comment
        api.nvim_command('silent! normal! "_dd')
        initpos[1] = initpos[1] - 1

      else

        -- Add a comment
        api.nvim_command('silent! normal! o' .. tangle_comment)
        initpos[1] = initpos[1] + 1
      end
    end

    api.nvim_win_set_cursor(0, initpos) -- Reposition the cursor to its original position

  else

    -- Tangle is not used in the file, inform user
    api.nvim_command("echohl WarningMsg | echon 'ERROR: Tangle is not used in this file!' | echohl Normal")
  end
end
-- }}}
-- Open a code block in its filetype in a new tab -{{{
-- Like C-c ' in Emacs Org mode
local function EditWindow()
  local initpos = api.nvim_win_get_cursor(0)

  if not string.match(api.nvim_get_current_line(), '^```.+') then
    api.nvim_call_function('search', {'^```\\S', 'bW'}) -- Beginning of the code block
  end

  local defline = api.nvim_get_current_line() -- The initialization line of the code block

  if string.match(defline, '^```.+') then -- Only open edit window if it is a valid code block
    local filetype = string.gsub(defline, '^```', '') -- The filetype

    api.nvim_command('normal! j')

    -- Don't work on the ending line of the codeblock
    if api.nvim_get_current_line() ~= '```' then

      api.nvim_command('normal! k0')
      CodeBlockRange() -- Get the range

      local code = api.nvim_eval('join(getline(' .. startline .. ',' .. endline .. '), "\\n")') -- Copy the code block
      api.nvim_command('tabnew Edit-Window | setlocal buftype=nofile') -- New tab

      local autoindent_save = api.nvim_buf_get_option(0, 'autoindent') -- The autoindent setting
      api.nvim_buf_set_option(0, 'autoindent', false) -- Don't autoindent
      api.nvim_command('normal! i' .. code) -- Paste it in
      api.nvim_buf_set_option(0, 'autoindent', autoindent_save) -- Reset autoindent

      api.nvim_command('setlocal filetype=' .. filetype .. ' | filetype detect') -- Set the filetype

      -- Close the edit window
      api.nvim_buf_set_keymap(0, 'n', '<Leader>es', ':lua require"literate".EditClose()<CR>', { noremap = true, silent = true })

    end
  end
end
-- }}}
-- Close the Edit window -{{{
local function EditWindowClose()
  if api.nvim_call_function('expand', {'%'}) == 'Edit-Window' then
    local code = api.nvim_eval('join(getline(1, "$"), "\\n")') -- The code block
    api.nvim_command('silent! bdelete!') -- Kill the buffer
    api.nvim_call_function('search', {'^```\\S', 'bW'}) -- Beginning of the code block

    CodeBlockRange() -- Get the range

    -- Replace the existing code with the new code
    api.nvim_command('silent! normal! ' .. startline .. 'GV' .. endline .. 'G"_dk')
    local autoindent_save = api.nvim_buf_get_option(0, 'autoindent') -- The autoindent setting
    api.nvim_buf_set_option(0, 'autoindent', false) -- Don't autoindent
    api.nvim_command('silent! normal! o' .. code)
    api.nvim_buf_set_option(0, 'autoindent', autoindent_save) -- Reset autoindent
  end
end
-- }}}
-- Mappings -{{{
api.nvim_buf_set_keymap(0, 'n', '<Leader>ec', ':lua require"literate".Comment()<CR>', { noremap = true, silent = true })
api.nvim_buf_set_keymap(0, 'n', '<Leader>ee', ':lua require"literate".Tangle()<CR>',  { noremap = true, silent = true })
api.nvim_buf_set_keymap(0, 'n', '<Leader>es', ':lua require"literate".Edit()<CR>',    { noremap = true, silent = true })
api.nvim_command('iabbrev <buffer> <silent> <s ```<CR><CR>```<Up><Up><End>')
-- }}}

return {
  Tangle = ExportCode,
  Comment = CommentBlock,
  Edit = EditWindow,
  EditClose = EditWindowClose
}
