" vim: ts=2 sw=2 et fdm=marker cms=\ \"%s
" Plugin: ProjectJr --- simplistic rewrite of Aric Blumer's Project plugin
" Version: 0.1
" $Id: projectjr.vim,v 1.11 2003/07/23 19:45:39 andrew Exp andrew $
"
" Author: Andrew Rodionoff <arnost AT mail DOT ru>
"
" Description:
" This mini-plugin provides jump-list to often-used files. There can be many
" such lists saved in files with .prj extension, each one may be loaded
" separately with command :ProjectJr <filename>. Here's example of such
" jump-list file, I hope it's self-explanatory
"
"~/
"  .Xdefaults
"  .Xclients-default
"  .ctags
"
"~/vim/
"  _vimrc
"  plugin/
"    SideBar.vim
"    projectjr.vim
"    taglistjr.vim
"    rcs.vim
"    latex-make.vim
"    latexmaps.vim
"    xmmsctrl.vim
"    vimexec.vim
"  ftplugin/
"    tex.vim
"  latex/
"    auctex.vim
"  indent/
"    tex.vim
"
" Lines with no indent provide base directory to construct full path to file.
" Sub-projects are constructed using indentation. Lines with the same indent
" level are considered separate entries. You can press <Enter> on any line to
" load corresponding file into editor. Blank lines and lines, starting with
" '"' are ignored.

" Internals
fun! PRJ_FoldText() "{{{
  let l:l = v:foldstart
  let l:idt = indent(l:l)
  let l:res = ''
  while l:l <= v:foldend
    if l:idt == indent(l:l)
      let l:res = l:res . "[" . s:Strip(getline(l:l)) . "]"
    endif
    let l:l = l:l + 1
  endwhile
  return substitute(getline(v:foldstart), '^\(\s*\).*', '\1', '') . l:res
endfun "}}}

fun! s:Project(file) "{{{
  if bufexists(a:file)
    exec 'buffer ' . a:file
  else
    exec 'edit ' . a:file
    setlocal sw=2 ts=2 et nobl noswf ar
    setlocal fdm=expr fde=indent(v:lnum) fdt=PRJ_FoldText()
    syn match PrjComment '^\s*".*'
    syn match PrjSubdir '.*/\s*$'
    hi link PrjSubdir Statement
    hi link PrjComment Comment
    nmap <silent> <buffer> <CR> :call <SID>Enter()<CR>
  endif
endfun "}}}

fun! s:Strip(str) "{{{
  let l:left = substitute(a:str, '^\s*\(.*\)', '\1', '')
  let l:right = substitute(l:left, '\(.\{-}\)\s*$', '\1', '')
  return l:right
endfun "}}}

fun! s:Enter() "{{{
  let l:line = line('.')
  if foldclosed(l:line) != -1
    normal zO
    return
  endif

  let l:idt = indent('.')
  normal 0
  silent exec 'normal ' . l:idt . 'zl'
  let l:fname = s:Strip(getline(l:line))
  if l:fname =~ '^".*' || l:fname =~ '^\s*$'
    return
  endif

  while l:line > 1 && l:idt > 0
    let l:line = l:line - 1
    if indent(l:line) < l:idt
      let l:idt = indent(l:line)
      let l:fname = s:Strip(getline(l:line)) . l:fname
    endif
  endwhile
  wincmd p
  exec 'edit ' . escape(l:fname, "\"' ")
endfun "}}}

" Exported commands
command! -nargs=1 -complete=file ProjectJr call <SID>Project(<f-args>)

