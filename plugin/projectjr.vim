" vim: ts=2 sw=2 et fdm=marker cms=\ \"%s
" Plugin: ProjectJr --- simplistic rewrite of Aric Blumer's Project plugin
" Version: 0.2
" $Id: projectjr.vim,v 1.33 2003/08/13 06:59:16 andrew Exp andrew $
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
"
" New in v0.2:
" - Pressing <Enter> on directory name opens or collapses its contents
"   listing. Note that 'wildignore' and 'suffixes' options are in effect here. 
"
" - New command :Refresh <regexp-pattern>
"   Use it in project buffer to re-scan entry at current line and leave only
"   sub-entries that match <regexp-pattern>

" - You can control placement of subdirectories in newly-opened listing using
"   variable g:ProjectJr_dirs_first. See also g:ProjectJr_show_dotfiles and
"   g:ProjectJr_dotfiles_first below.
"
if !exists('g:ProjectJr_dirs_first')
  let g:ProjectJr_dirs_first = 0 " looks better to me
endif

" You can control whether to show or hide .* filenames using variable
" g:ProjectJr_show_dotfiles
"
if !exists('g:ProjectJr_show_dotfiles')
  let g:ProjectJr_show_dotfiles = 1
endif

" Will we put dotfiles before or after main file listing?
if !exists('g:ProjectJr_dotfiles_first')
  let g:ProjectJr_dotfiles_first = 1
endif

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
    command! -buffer -nargs=1 Refresh call <SID>RefreshEntry(line('.'), <f-args>)
  endif
endfun "}}}

fun! s:Strip(str) "{{{
  let l:left = substitute(a:str, '^\s*\(.*\)', '\1', '')
  let l:right = substitute(l:left, '\(.\{-}\)\s*$', '\1', '')
  return l:right
endfun "}}}

fun! s:PathAtLine(line) "{{{
  let l:line = a:line
  let l:idt = indent(l:line)
  let l:fname = s:Strip(getline(l:line))
  if l:fname =~ '^\s*\($\|"\)'
    return ''
  endif

  while l:line > 1 && l:idt > 0
    let l:line = l:line - 1
    let l:str = s:Strip(getline(l:line))
    if l:str !~ '^\s*\($\|"\)' && indent(l:line) < l:idt
      let l:idt = indent(l:line)
      let l:fname = l:str . l:fname
    endif
  endwhile
  return l:fname
endfun "}}}

fun! s:CloseEntry(line) "{{{
  let l:n = s:EntrySize(a:line)
  if l:n
    exec (a:line + 1) . ',' . (a:line + l:n) . 'delete _'
    exec a:line . ';'
  endif
endfun "}}}

fun! s:OpenEntry(line, mask) "{{{
  let l:basepath = s:PathAtLine(a:line)
  let l:entries = glob(l:basepath . '*')
  if g:ProjectJr_show_dotfiles
    if g:ProjectJr_dotfiles_first
      let l:entries = glob(l:basepath . '.*') . "\n" . l:entries
    else
      let l:entries = l:entries . "\n" . glob(l:basepath . '.*')
    endif
  endif
  let l:line = a:line
  let l:idt = indent(a:line)
  let l:l1 = a:line
  let l:n = 0
  while l:entries != ''
    let l:pos = stridx(l:entries, "\n")
    if l:pos == -1
      let l:pos = strlen(l:entries)
    endif
    let l:entry = strpart(l:entries, 0, l:pos)
    let l:entries = strpart(l:entries, l:pos + 1)
    if l:entry =~ a:mask
      let l:tail = fnamemodify(l:entry, ':t')
      if l:tail =~ '^\.\.\?$'
        continue
      endif
      if isdirectory(l:entry)
        let l:tail = l:tail . '/'
        exec l:l1 . 'put =l:tail'
        let l:l1 = l:l1 + 1
        if g:ProjectJr_dirs_first
          let l:line = l:line + 1
        endif
      else
        exec l:line . 'put =l:tail'
        let l:line = l:line + 1
        if !g:ProjectJr_dirs_first
          let l:l1 = l:l1 + 1
        endif
      endif
      let l:n = l:n + 1
    endif
  endwhile
  if l:n
    exec (a:line + 1) . ',' . (a:line + l:n) . 'left ' . (l:idt + &sw)
    exec a:line . ';'
  endif
endfun "}}}

fun! s:EntrySize(line) "{{{
  let l:n = 1
  let l:idt = indent(a:line)
  while (indent(a:line + l:n) > l:idt
        \ || getline(a:line + l:n) =~ '^\s*\($\|"\)')  && (a:line + l:n) <= line('$')
    let l:n = l:n + 1
  endwhile
  let l:n = l:n - 1
  if l:n && getline(a:line + l:n) =~ '^\s*\($\|"\)'
    let l:n = l:n - 1
  endif
  return l:n
endfun "}}}

fun! s:RefreshEntry(line, mask) "{{{
  let l:line = a:line
  while (getline(l:line) =~ '^\s*\($\|"\)'
        \ || !isdirectory(fnamemodify(s:PathAtLine(l:line), ':p'))) 
        \ && l:line > 0
    let l:line = l:line - 1
  endwhile
  if l:line == 0
    return
  endif
  call s:CloseEntry(l:line)
  call s:OpenEntry(l:line, a:mask)
endfun "}}}

fun! s:Enter() "{{{
  let l:line = line('.')
  let l:fname = s:PathAtLine(l:line)
  if l:fname == ''
    return
  elseif foldclosed(l:line) != -1
    normal zO
  elseif isdirectory(fnamemodify(l:fname, ':p'))
    if s:EntrySize(l:line) > 0
      call s:CloseEntry(l:line)
    else
      call s:OpenEntry(l:line, '.*')
    endif
  else
    exec 'normal ' . indent(l:line) . 'zl'
    wincmd p
    exec 'edit ' . escape(l:fname, "\"' ")
  endif
endfun "}}}

" Exported commands
command! -nargs=1 -complete=file ProjectJr call <SID>Project(<f-args>)

