" vim: ts=2 sw=2 et fdm=marker cms=\ \"%s
" Plugin: SideBar --- auto-shrinking container of vertically aligned material
" Version: 0.3
" $Id: SideBar.vim,v 1.216.1.20 2003/09/22 14:53:19 andrew Exp $
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
" New in v0.3:
" - New behaviour: SideBar tries harder to keep out of your way on creation
"   and startup.  When last working window is closed and SideBar becomes
"   'only', SideBar disappears and next buffer gets focus.
"
"   Note: second 'close' command on Calendar swallow is no longer nessessary.
"   Note: global 'winwidth' option is now updated on sidebar creation, to
"   prevent unneeded (and annoying) resizing in certain situations.
"
" - Last 'cycled to' buffer is remembered and selected when SideBar is
"   re-created.
"
" - Included two new mini-plugins: TagListJr and BufExplorerJr
"
" New in v0.2:
"
" - Some stability enhancements
"
" - New configuration variables: g:SideBar_max_width, g:SideBar_min_width.
"   See source comments for explanation.
"
" - New :SideBarSwallow command takes current buffer into SideBar and removes
"   it from main buffer list.
"
"   e.g. you can put these lines in .vimrc:
"
"augroup SideBarInit
"  au!
"  au VimEnter * call <SID>SetupSbar()
"augroup END
"
"fun! s:SetupSbar()
"  Calendar
"  let l:newwidth=winwidth('.') 
"  SideBarSwallow
"  close                                " get rid of split windows
"  let g:SideBar_max_width = l:newwidth " ensure that Calendar is fully
"                                       " visible in maximized state
"  SideBarAddCmd TagListJr
"  SideBarAddCmd BufExplorerJr
"  SideBarAddCmd ProjectJr ~/vim/global.prj
"endfun
"
" Configuration variables
"
" Set g:SideBar_max_width to desired width in 'maximized' mode
  if !exists('g:SideBar_max_width')
    let g:SideBar_max_width = &tw / 4
  endif
"
" Set g:SideBar_min_width to desired width in 'minimized' mode
  if !exists('g:SideBar_min_width')
    let g:SideBar_min_width = &columns - &tw - 2
  endif

let s:winnr = -1
let s:safe = 0
let s:active_buffer = -1

" Autocommands
augroup SideBar "{{{
  au!
  au WinEnter * call <SID>OnEnter()
  au BufAdd * call <SID>Bounce()
"  au BufDelete * call <SID>Resplit(expand('<afile>'))
augroup END "}}}

" Internals
"
"fun! s:Resplit(buf) " Attempt to resplit window if needed. {{{
"  if winwidth(2) == -1 && exists('w:this_is_SideBar_window')
"    vsplit
"    silent! unlet w:this_is_SideBar_window
"    call s:OnEnter()
"    exec 'buffer ' . bufnr(a:buf)
"    bnext
"  endif
"endfun "}}}

fun! s:Bounce() " Do not allow casual buffer creation in SideBar {{{
  if exists('w:this_is_SideBar_window') && !s:safe 
    wincmd w
    call s:OnEnter()
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
    if getwinvar(l:w, 'this_is_SideBar_window') != ''
      if winwidth(2) == -1 " we are 'only'
        unlet w:this_is_SideBar_window
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
    call s:OnEnter()
    if bufnr(s:active_buffer) != -1
      exec "buffer " . s:active_buffer
    else
      call s:Cycle()
    endif
  else
    exec l:w . 'wincmd w'
  endif
endfun "}}}

fun! s:Create() " Initialize SideBar window{{{
  if &winwidth > g:SideBar_min_width
    let &winwidth = g:SideBar_min_width
  endif
  exec g:SideBar_min_width . "vsplit"
  let w:this_is_SideBar_window=1
endfun "}}}

fun! s:EnterToggle() " see above {{{
  if exists('w:this_is_SideBar_window') && winwidth(2) != -1
    silent wincmd p
  else
    call s:Enter()
  endif
endfun "}}}

fun! s:OnEnter() " Ensure SideBar placement and size {{{
  if winwidth(2) == -1 && exists('w:this_is_SideBar_window')
    silent! unlet w:this_is_SideBar_window
    bnext
    return
  endif
  if exists('w:this_is_SideBar_window')
    wincmd H
    exec g:SideBar_max_width . 'wincmd |'
  else
    call s:ExecInside('wincmd H | ' . g:SideBar_min_width . 'wincmd |')
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
    elseif bufexists(l:i) && s:IsManaged(l:i)
      exec 'buffer ' . l:i
      let s:active_buffer = l:i
      return
    endif
  endwhile
endfun "}}}

fun! s:IsManaged(buf) " Check if buffer is managed by SideBar {{{
  return (getbufvar(a:buf, 'this_is_SideBar_managed_buffer') != '')
endfun "}}}

fun! s:ManageBuffer(buf) " Introduce 'buf' to SideBar {{{
  if !s:IsManaged(a:buf) && bufexists(a:buf)
    call setbufvar(a:buf, 'this_is_SideBar_managed_buffer', 1)
  endif
  let s:active_buffer = a:buf
  call s:ExecInside('buffer ' . a:buf)
endfun "}}}

fun! s:CycleManaged() " Use command with the same name {{{
  if s:FindSelf() == -1
    call s:Create()
    wincmd p
  endif
  call s:ExecInside('call s:Cycle()')
endfun "}}}

fun! s:Manage(command) " Use command :SideBarAddCmd {{{
  if s:FindSelf() == -1
    call s:Create()
    wincmd p
  endif
  let s:safe = 1
  call s:ExecInside(a:command)
  call s:ExecInside('setlocal nobuflisted bufhidden=hide')
  call s:ExecInside('call s:ManageBuffer(expand("%:p"))')
  call s:ExecInside('wincmd H | ' . g:SideBar_min_width . 'wincmd |')
  let s:safe = 0
endfun "}}}

fun! s:Swallow() " Grab current buffer. {{{
  setlocal nobuflisted bufhidden=hide
  if s:FindSelf() == -1
    call s:Create()
    wincmd p
  endif
  let s:safe = 1
  call s:ManageBuffer(bufnr('%'))
  let s:safe = 0
  let l:bufn = 1
  let l:nlisted = 0
  while l:bufn <= bufnr('$')
    if buflisted(l:bufn)
      let l:nlisted = 1
      break
    endif
    let l:bufn = l:bufn + 1
  endwhile
  if l:nlisted > 0
    bnext
  else
    enew
  endif
endfun "}}}


" Exported commands
"
command! SideBarEnter call <SID>Enter()
command! SideBarEnterToggle call <SID>EnterToggle()
command! SideBarCycle call <SID>CycleManaged()
command! SideBarSwallow call <SID>Swallow()
command! -nargs=1 -complete=command SideBarExec call <SID>ExecInside(<f-args>)
command! -nargs=1 -complete=command SideBarAddCmd call <SID>Manage(<f-args>)


