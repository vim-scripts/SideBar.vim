" vim: ts=2 sw=2 et fdm=marker
" Plugin: BufExplorerJr --- minimalistic buffer explorer in SideBar
" Version: 0.1
" $Id: bufexpljr.vim,v 1.7 2003/09/24 18:31:47 andrew Exp andrew $
"
" Author: Andrew Rodionoff <arnost AT mail DOT ru>
"
" Description: manages buffer list in SideBar. Credits to guys who came up
" with the idea, I don't know who was the first. Personally I liked
" BufExplorer by Jeff Lanzarotta and MiniBufExplorer by Bindu Wavell.
"
" Usage: :SideBarSwallow BufExplorerJr
" press <CR> on buffer to visit
"
" Tip: Try including following autocommand in your setup:
" au BufAdd * SideBarAddCmd BufExplorerJr
"
" Autocommands
let s:safe = 1

augroup BufExplorerJr "{{{
  au!
  au BufEnter * call <SID>Refresh()
augroup END "}}}

" Internals
fun! s:Create() "{{{
  if bufnr('BufExplorerJr') != -1
    buffer BufExplorerJr
    return
  endif
  let s:safe = 0
  edit BufExplorerJr
  setlocal noswf nobuflisted noma nomod ro
  nmap <silent> <buffer> <CR> :call <SID>Enter()<CR>
  syn clear
  setlocal ts=4
  let s:safe = 1
endfun "}}}

fun! s:Refresh() "{{{
  if !s:safe
    return
  endif
  let s:safe = 0
  let l:w = bufwinnr('BufExplorerJr')
  if l:w != -1 && l:w != winnr()
    let l:bnum = bufnr('%')
    exec l:w . 'wincmd w'
    call s:ReFill(l:bnum)
    wincmd p
  endif
  let s:safe = 1
endfun "}}}

fun! s:ReFill(bnum) "{{{
  setlocal ma noro
  silent %d _
  let l:n = 1
  let l:last = bufnr('$')
  while l:n <= l:last
    if bufexists(l:n) && buflisted(l:n)
      let l:bn = bufname(l:n)
      let l:bn_tail = fnamemodify(l:bn, ':t')
      if l:bn_tail == ''
        let l:bn_tail = '[No File]'
      endif
      let l:a = l:n . "\t" . l:bn_tail .
            \ ' (' . fnamemodify(l:bn, ':p:~:h') .')'
      silent put =l:a
    endif
    let l:n = l:n + 1
  endwhile
  silent 0d _
  setlocal nomod ro noma nobuflisted
  syn clear Search
  exec 'syn match Search +^' . a:bnum . '\t.*$+'
  silent! exec '0;/^' . a:bnum . '\t/;'
endfun "}}}

fun! s:Enter() "{{{
  let l:cl = getline('.')
  let s:safe=0
  let l:bn = strpart(l:cl, 0, stridx(l:cl, "\t")) + 0
  call s:ReFill(l:bn)
  wincmd p
  exec 'buffer ' . l:bn
  let s:safe=1
endfun "}}}

command! BufExplorerJr call <SID>Create()

