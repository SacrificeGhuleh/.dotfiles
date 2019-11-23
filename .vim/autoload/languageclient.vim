" lightline-languageclient
" Maintainer:	Alphonse Mariya <alphonse.mariya@hotmail.com>
" Version:	0.1.0
" License:	MIT
" Location:	autoload/languageclient.vim
" Website:	https://github.com/alfunx/vim-lightline-languageclient

let s:save_cpo = &cpo
set cpo&vim

" severity codes from the LSP spec
let s:severity_error = 1
let s:severity_warning = 2
let s:severity_info = 3
let s:severity_hint = 4

" corresponding symbols to use
let s:severity = {}
let s:severity.1 = get(g:, 'languageclient#indicator_error', 'E:')
let s:severity.2 = get(g:, 'languageclient#indicator_warning', 'W:')
let s:severity.3 = get(g:, 'languageclient#indicator_info', 'I:')
let s:severity.4 = get(g:, 'languageclient#indicator_hint', 'H:')

" other options
let s:open_linenr = get(g:, 'languageclient#open_linenr', '(L')
let s:close_linenr = get(g:, 'languageclient#close_linenr', ')')
let s:show_linenr = get(g:, 'languageclient#show_linenr', 1)

" After each LanguageClient state change `s:diagnostics` will be populated with
" a map from file names to lists of errors, warnings, informational messages,
" and hints.
let s:diagnostics = {}

function! s:record_diagnostics(state) abort
    if !has_key(a:state, 'result')
        return
    endif
    let s:diagnostics = json_decode(a:state.result).diagnostics
    call lightline#update()
endfunction

function! s:get_diagnostics()
    call LanguageClient#getState(function('s:record_diagnostics'))
endfunction

function! s:diagnostics_for_buffer()
    return get(s:diagnostics, expand('%:p'), [])
endfunction

function! languageclient#get(type)
    let l:rel = filter(copy(s:diagnostics_for_buffer()),
                \ {_, v -> has_key(v, 'severity') && v.severity == a:type})
    let l:cnt = len(l:rel)
    if !l:cnt
        return ''
    endif
    let l:symbol = get(s:severity, a:type, '')
    let l:cnt = l:symbol . l:cnt
    if s:show_linenr
        let l:cnt .= s:open_linenr . (l:rel[0].range.start.line + 1) . s:close_linenr
    endif
    return l:cnt
endfunction

function! languageclient#errors()
    return languageclient#get(s:severity_error)
endfunction

function! languageclient#warnings()
    return languageclient#get(s:severity_warning)
endfunction

function! languageclient#infos()
    return languageclient#get(s:severity_info)
endfunction

function! languageclient#hints()
    return languageclient#get(s:severity_hint)
endfunction

augroup lightline_languageclient
    autocmd!
    autocmd User LanguageClientDiagnosticsChanged call <SID>get_diagnostics()
augroup END

let &cpo = s:save_cpo

" vim: et ts=4 sts=4 sw=4
