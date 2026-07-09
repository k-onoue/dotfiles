" vim configuration managed by dotfiles.

syntax on
set number
set relativenumber
set mouse=a
set expandtab
set tabstop=4
set shiftwidth=4

" Keep Vim's default yank and paste registers local to Vim.
" Yanked text is synced to the external clipboard automatically.

" Copy to the local terminal clipboard over SSH by using OSC52.
function! s:Osc52Copy(text, ...) abort
  let quiet = a:0 ? a:1 : 0

  if empty(a:text)
    if !quiet
      echo "OSC52 copy: nothing selected"
    endif
    return
  endif

  if !executable('base64')
    if !quiet
      echohl WarningMsg
      echom "OSC52 copy requires the base64 command"
      echohl None
    endif
    return
  endif

  let encoded = system('base64 | tr -d "\n"', a:text)
  if v:shell_error != 0 || empty(encoded)
    if !quiet
      echohl WarningMsg
      echom "OSC52 copy failed while encoding text"
      echohl None
    endif
    return
  endif

  let sequence = "\e]52;c;" . encoded . "\x07"
  if exists('$TMUX')
    let sequence = "\ePtmux;\e" . substitute(sequence, "\e", "\e\e", 'g') . "\e\\"
  endif

  call echoraw(sequence)
  if !quiet
    echom "Copied to terminal clipboard"
  endif
endfunction

function! s:RegisterContentsToText(contents, regtype) abort
  let text = join(a:contents, "\n")
  if a:regtype ==# 'V'
    let text .= "\n"
  endif
  return text
endfunction

function! s:SyncYankToExternalClipboard() abort
  if get(v:event, 'operator', '') !=# 'y'
    return
  endif

  if get(v:event, 'regname', '') ==# '_'
    return
  endif

  let contents = get(v:event, 'regcontents', [])
  if empty(contents)
    return
  endif

  let regtype = get(v:event, 'regtype', 'v')

  if has('clipboard')
    try
      call setreg('+', contents, regtype)
    catch
    endtry
  endif

  if exists('$SSH_CONNECTION') || exists('$SSH_CLIENT') || exists('$SSH_TTY') || !has('clipboard')
    call s:Osc52Copy(s:RegisterContentsToText(contents, regtype), 1)
  endif
endfunction

augroup dotfiles_clipboard
  autocmd!
  autocmd TextYankPost * call <SID>SyncYankToExternalClipboard()
augroup END
