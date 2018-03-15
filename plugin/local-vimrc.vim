let s:util_path = fnameescape(expand('<sfile>:p:h') . '/utils/digest.py')

function! LocalVimrcUpdateDigest(file)
    call system(s:util_path . ' update ' . fnameescape(a:file))
    return v:shell_error
endfunction

function! LocalVimrcVerifyDigest(file)
    call system(s:util_path . ' verify ' . fnameescape(a:file))
    return v:shell_error
endfunction

function! LocalVimrcLoadRcs(rcs)
    for file in split(a:rcs, "\n")
        if filereadable(file)
            if LocalVimrcVerifyDigest(file)
                echoerr 'Ignore lvimrc: ' . file
            else
                execute 'source ' . fnameescape(file)
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

function! LocalVimrcUpdateSelfDigest()
    execute ':%!' . s:util_path . ' update'
endfunction


augroup LocalVimrc
    autocmd BufWritePre *lvimrc call LocalVimrcUpdateSelfDigest()
    autocmd BufWinEnter * call LocalVimrcLoadRcsOnPath(expand('%:p:h'))
augroup END
