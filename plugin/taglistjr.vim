" vim: ts=2 sw=2 et fdm=marker
" Plugin: TagListJr --- minimalistic tag navigation in SideBar
" Version: 0.2
" $Id: taglistjr.vim,v 1.54 2003/09/24 16:41:16 andrew Exp andrew $
"
" Author: Andrew Rodionoff <arnost AT mail DOT ru>
"
" Description:
" This is a minimalistic rewrite of plugin 'Tag List' by Yegappan Lakshmanan.
" It's main feature is minimum bloat and maximum reliance on internal regexp
" routines, so it's pretty fast. It's also supposed to work inside a SideBar,
" so its window management is simple (none, actually).
" Usage:
" SideBarSwallow TagListJr
"
" Autocommands
let s:safe = 1

augroup TagListJr "{{{
  au!
  au BufEnter * call <SID>Refresh()
augroup END "}}}

" Internals
fun! s:Create() "{{{
  if bufnr('TagListJr') != -1
    buffer TagListJr
    return
  endif
  let s:safe = 0
  edit TagListJr
  setlocal noswf nobuflisted noma nomod ro
  nmap <silent> <buffer> <CR> :call <SID>Enter()<CR>
  syn clear
  setlocal ts=100
  let s:safe = 1
endfun "}}}

fun! s:Refresh() "{{{
  if !s:safe
    return
  endif
  let s:safe = 0
  let l:w = bufwinnr('TagListJr')
  if l:w != -1 && l:w != winnr()
    let fn = expand('%:p')
    if filereadable(fn)
      exec l:w . 'wincmd w'
      call s:ReFill(fn)
      wincmd p
    endif
  endif
  let s:safe = 1
endfun "}}}

fun! s:ReFill(fn) "{{{
  setlocal ma noro
  let l:alltags = system('ctags -f - ' . a:fn)
  silent %d _
  let l:n = 1
"  let b:tags = substitute(l:alltags, '\(.\{-}\)\t.\{-}\(.\?\)\n', '\1\t\2\n', 'g')
  let b:tags = substitute(l:alltags, '\(.\{-}\)\t.\{-}\n', '\1\n', 'g')
  let b:files = substitute(l:alltags, '\(.\{-}\)\t\(.\{-}\)\t.\{-}\n', '\2\n', 'g')
  let b:exec = substitute(l:alltags, '\(.\{-}\)\t\(.\{-}\)\t\(.\{-}\)\t.\{-}\n', '\3\n', 'g')
  put =b:tags
  silent 0d _
  setlocal nomod ro noma nobuflisted
endfun "}}}

fun! s:Nth(str,n) "{{{
  if a:n > 0
    return substitute(a:str, '^\(.\{-}\n\)\{' . a:n . '}\(.\{-\}\)\n.*$', '\2', '')
  else
    return substitute(a:str, '^\(.\{-}\)\n.*', '\1', '')
  endif
endfun "}}}

fun! s:Enter() "{{{
  if !exists('b:tags')
    return
  endif
  let l:n = line('.') - 1
  let s:safe=0
  let l:fn = s:Nth(b:files, l:n)
  let l:ex = s:Nth(b:exec, l:n)
  wincmd p
  if expand('%:p') != fnamemodify(l:fn, ':p')
    exec 'edit ' . l:fn
  endif
  exec l:ex
  let s:safe=1
endfun "}}}

command! TagListJr call <SID>Create()

