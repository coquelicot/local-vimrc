let s:util_path = fnameescape(expand('<sfile>:p:h') . '/utils/digest.py')

if !exists("g:lvimrc_ignore_dirs")
    let g:lvimrc_ignore_dirs = []
endif

function! s:EnsureTrailingSlash(dir)
    if a:dir =~ '/$'
        return a:dir
    endif
    return a:dir . '/'
endfunction

function! LocalVimrcUpdateDigest(file)
    call system(s:util_path . ' update ' . fnameescape(a:file))
    return v:shell_error == 0
endfunction

function! LocalVimrcVerifyDigest(file)
    call system(s:util_path . ' verify ' . fnameescape(a:file))
    return v:shell_error == 0
endfunction

function! LocalVimrcShouldIgnoreDir(dir)
    let dir = s:EnsureTrailingSlash(a:dir)
    let ignore_dirs = get(b:, "lvimrc_ignore_dirs", g:lvimrc_ignore_dirs)
    for ignore_dir in ignore_dirs
        let ignore_prefix = s:EnsureTrailingSlash(ignore_dir)
        if dir[0:len(ignore_prefix)-1] ==# ignore_prefix
            return 1
        endif
    endfor
    return 0
endfunction

function! LocalVimrcLoadRcs(rcs)
    for file in split(a:rcs, "\n")
        if filereadable(file)
            if LocalVimrcVerifyDigest(file)
                execute 'source ' . fnameescape(file)
            else
                echoerr 'Ignore lvimrc: ' . file
            endif
        endif
    endfor
endfunction

function! LocalVimrcLoadRcsOnPath(path)
    let current_path = ''
    for dir in [''] + split(a:path, '/')
        let current_path = current_path . dir . '/'
        if LocalVimrcShouldIgnoreDir(current_path)
            break
        endif
        call LocalVimrcLoadRcs(glob(current_path . '*lvimrc'))
        call LocalVimrcLoadRcs(glob(current_path . '.*lvimrc'))
    endfor
endfunction

function! LocalVimrcCheckAutoUpdate(force_auto)
    if a:force_auto || LocalVimrcVerifyDigest(expand('%'))
        let b:lvimrc_auto_update = 1
    else
        let b:lvimrc_auto_update = 0
    endif
endfunction

function! LocalVimrcUpdateSelfDigest()
    if ! b:lvimrc_auto_update
        call confirm("This lvimrc was invalid, do you want to fix it?")
        let b:lvimrc_auto_update = 1
    endif
    execute ':%!' . s:util_path . ' update'
endfunction


augroup LocalVimrc
    autocmd!
    autocmd BufRead *lvimrc call LocalVimrcCheckAutoUpdate(0)
    autocmd BufNewFile *lvimrc call LocalVimrcCheckAutoUpdate(1)
    autocmd BufWritePre *lvimrc call LocalVimrcUpdateSelfDigest()
    autocmd BufReadPre * call LocalVimrcLoadRcsOnPath(expand('%:p:h'))
    autocmd BufNewFile * call LocalVimrcLoadRcsOnPath(expand('%:p:h'))
augroup END

call LocalVimrcLoadRcsOnPath(expand('%:p:h'))
