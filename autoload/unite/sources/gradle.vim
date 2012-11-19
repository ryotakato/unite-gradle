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
      \ }

" main process
function! s:source.gather_candidates(args, context) "{{{

  let candidates = []
  " get gradle tasks
  let result = split(vimproc#system("gradle -q tasks"), '\n')
  if empty(result)
    return []
  endif

  " set to unite candidates
  for line in result[6:]
    let matches = matchlist(line,'^\([^\s].*\)\s-\s\(.*\)$')
    if len(matches) == 0
      continue
    endif

    call add(candidates, {
          \ "word": matches[1],
          \ "abbr": unite#util#truncate(matches[1], 25).(matches[2] != '' ? ' -- ' . matches[2] : ''),
          \ })
    unlet line
  endfor

  return candidates
endfunction "}}}

" set to unite current prompt
function! s:set_prompt(str)
  let unite = unite#get_current_unite()
  let unite.prompt = a:str
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
