let s:util_path = fnameescape(expand('<sfile>:p:h') . '/utils/digest.py')

function! LocalVimrcUpdateDigest(file)
    call system(s:util_path . ' update ' . fnameescape(a:file))
    return v:shell_error == 0
endfunction

function! LocalVimrcVerifyDigest(file)
    call system(s:util_path . ' verify ' . fnameescape(a:file))
    return v:shell_error == 0
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
    call LocalVimrcLoadRcs(glob('/*lvimrc'))
    call LocalVimrcLoadRcs(glob('/.*lvimrc'))
    for dir in split(a:path, '/')
        let current_path = current_path . '/' . dir
        call LocalVimrcLoadRcs(glob(current_path . '/*lvimrc'))
        call LocalVimrcLoadRcs(glob(current_path . '/.*lvimrc'))
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
    autocmd BufWinEnter * call LocalVimrcLoadRcsOnPath(expand('%:p:h'))
augroup END
