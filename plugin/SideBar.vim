" vim: ts=2 sw=2 et fdm=marker cms=\ \"%s
" Plugin: SideBar --- auto-shrinking container of vertically aligned material
" Version: 0.1
" $Id: SideBar.vim,v 1.55 2003/07/23 19:12:14 andrew Exp $
"
" Author: Andrew Rodionoff <arnost AT mail DOT ru>
"
" Description:
" There are many fine plugins that use persistent windows to display useful
" information (e.g. TagList plugin) or to provide bookmark-like portal to
" other files and buffers (e.g. Project or Buffer explorers etc.). There is
" one major drawback to using them: you have to sacrifice precious screen real
" estate. One way to compensate is to put those auxillary windows in
" 'side-pocket', and to open and close it when needed. So here comes SideBar.
"
" Usage:
" As a stand-alone plugin it's pretty useless. It's really a framework that
" allows easy creation of SideBar-contained plugins. As an example I've
" included my very simplistic rewrite of excellent Project plugin by Aric
" Blumer. Note that it doesn't even try to manage its window. Just 'register'
" it in SideBar with following command (to learn more of ProjectJr, read its
" comments):
" :SideBarAddCmd ProjectJr ~/main.prj
"
" Now you have mini-project in your side-pocket. Use :SideBarEnter or
" :SideBarEnterToggle to quickly enter/leave it. If you close its window
" (without destroying its buffer), or make it 'only', next invocation of one
" of those commands will bring SideBar back. Of course, it's best to map these
" commands to some handy keys, e.g. <Tab>.
"
" You can have as many projects/other buffers managed by SideBar as you wish.
" Register these buffers with :SideBarAddCmd <any ex command> and switch
" between them with :SideBarCycle
"
" To hack deep inside SideBar, another command is provided:
" :SideBarExec <any ex command> will execute <any ex command> in SideBar
" context without buffer registration. Note that you can use 's:' prefix to
" call plugin-local functions and modify its variables, so proceed with
" caution. To call functions local to your script, use <SID> prefix as
" usual.
"

let s:managed = ''
let s:winnr = -1
let s:safe = 0

" Autocommands
augroup SideBar "{{{
  au!
  au WinEnter * call <SID>OnEnter()
  au BufAdd * call <SID>Bounce()
augroup END "}}}

" Internals
fun! s:Bounce() " Do not allow casual buffer creation in SideBar {{{
  if exists('w:this_is_sidebar_window') && !s:safe 
    wincmd w
  endif
endfun "}}}

fun! s:ExecInside(cmd) " Execute 'cmd' in SideBar context {{{
  let l:w = s:FindSelf()
  if l:w != -1
    if l:w != winnr()
      silent! exec l:w . 'wincmd w'
      exec a:cmd
      wincmd p
    else
      exec a:cmd
    endif
  endif
endfun "}}}

fun! s:FindSelf() " Returns window number of SideBar or -1 {{{
  let l:w = 1
  while winwidth(l:w) != -1
    if getwinvar(l:w, 'this_is_sidebar_window') != ''
      if winwidth(2) == -1 " we are 'only'
        unlet w:this_is_sidebar_window
        return -1
      else
        return l:w
      endif
    endif
    let l:w = l:w + 1
  endwhile
  return -1
endfun "}}}

fun! s:Enter() " Switch to SideBar {{{
  let l:w = s:FindSelf()
  if l:w == -1
    call s:Create()
    call s:Cycle()
  else
    exec l:w . 'wincmd w'
  endif
endfun "}}}

fun! s:Create() " Initialize SideBar window{{{
  vsplit
  let w:this_is_sidebar_window=1
  call s:OnEnter()
endfun "}}}

fun! s:EnterToggle() " see above {{{
  if exists('w:this_is_sidebar_window') && winwidth(2) != -1
    silent wincmd p
  else
    call s:Enter()
  endif
endfun "}}}

fun! s:OnEnter() " Ensure SideBar placement and size {{{
  if !exists('g:sidebar_max_width')
    let l:maxw = &tw / 4
  else
    let l:maxw = g:sidebar_max_width
  endif
  if !exists('g:sidebar_min_width')
    let l:minw = &columns - &tw - 2
  else
    let l:minw = g:sidebar_min_width
  endif
  if exists('w:this_is_sidebar_window')
    call s:ExecInside('wincmd H | ' . l:maxw . 'wincmd |')
  else
    call s:ExecInside('wincmd H | ' . l:minw . 'wincmd |')
  endif
endfun "}}}

fun! s:Cycle() " Auxillary cycling function {{{
  let l:curbuf = bufnr('%')
  let l:i = l:curbuf
  let l:lastbuf = bufnr('$')
  while 1
    let l:i = l:i + 1
    if l:i > l:lastbuf
      let l:i = 1
    endif
    if l:i == l:curbuf
      return
    elseif bufexists(l:i) && s:IsManaged(fnamemodify(bufname(l:i), ':p'))
      exec 'buffer ' . l:i
      return
    endif
  endwhile
endfun "}}}

fun! s:IsManaged(buf) " Check if buffer is managed by SideBar {{{
  return (stridx(s:managed,  "\n " . a:buf .  "\n ") != -1)
endfun "}}}

fun! s:ManageBuffer(buf) " Introduce 'buf' to SideBar {{{
  if !s:IsManaged(a:buf)
    let s:managed = s:managed .  "\n " . a:buf .  "\n "
  endif
endfun "}}}

fun! s:CycleManaged() " Use command with the same name {{{
  if s:FindSelf() == -1
    call s:Create()
  endif
  call s:ExecInside('call s:Cycle()')
endfun "}}}

fun! s:Manage(command) " Use command :SideBarAddCmd {{{
  if s:FindSelf() == -1
    call s:Create()
  endif
  let s:safe = 1
  call s:ExecInside(a:command)
  call s:ExecInside('call s:ManageBuffer(expand("%:p"))')
  let s:safe = 0
endfun "}}}

" Exported commands
command! SideBarEnter call <SID>Enter()
command! SideBarEnterToggle call <SID>EnterToggle()
command! SideBarCycle call <SID>CycleManaged()
command! -nargs=1 -complete=command SideBarExec call <SID>ExecInside(<f-args>)
command! -nargs=1 -complete=command SideBarAddCmd call <SID>Manage(<f-args>)


