" unite-gradle.vim
let s:save_cpo = &cpo
set cpo&vim

" define unite source
function! unite#sources#gradle#define()
  return executable('gradle') && unite#util#has_vimproc() 
              \ ? [s:source]
              \ : []
endfunction

" source object
let s:source = {
      \ 'name' : 'gradle',
      \ 'description' : 'candidates for gradle',
      \ 'action_table' : {},
      \ 'hooks' : {},
      \ }

" start for async
function! s:source.hooks.on_init(args, context) "{{{

  let a:context.is_async = 1

  let cmdline = "gradle -q tasks"

  call unite#print_source_message('Command-line: ' . cmdline, s:source.name)

  let save_term = $TERM
  try
    " Disable colors.
    let $TERM = 'dumb'

    let a:context.source__proc = vimproc#plineopen3(
          \ vimproc#util#iconv(cmdline, &encoding, 'char'), 1)
  finally
    let $TERM = save_term
  endtry

  return []
endfunction "}}}

" async get source
function! s:source.async_gather_candidates(args, context)"{{{

  if !has_key(a:context, 'source__proc')
    return []
  endif

  let stderr = a:context.source__proc.stderr
  if !stderr.eof
    " Print error.
    let errors = filter(stderr.read_lines(-1, 100),
          \ "v:val !~ '^\\s*$'")
    if !empty(errors)
      call unite#print_source_error(errors, s:source.name)
    endif
  endif

  let stdout = a:context.source__proc.stdout
  if stdout.eof
    " Disable async.
    call unite#print_source_message('Completed.', s:source.name)
    let a:context.is_async = 0
  endif

  let candidates = map(stdout.read_lines(-1, 100),
          \ "unite#util#iconv(v:val, 'char', &encoding)")


  let _ = []
  for candidate in candidates
    let matches = matchlist(candidate,'^\(\S*\)\s-\s\(.*\)$')

    if len(matches) == 0
      continue
    endif

    let dict = {
          \ "word": matches[1],
          \ "abbr": unite#util#truncate(matches[1], 25).(matches[2] != '' ? ' -- ' . matches[2] : ''),
          \ }

    call add(_, dict)
  endfor

  return _

endfunction"}}}

" close
function! s:source.hooks.on_close(args, context) "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.waitpid()
  endif
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
