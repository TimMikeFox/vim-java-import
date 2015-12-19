" if compatible or too old stop
if exists('did_JavaImport_autoload') || &cp || version < 700
    finish
endif
let did_JavaImport_autoload=1

let s:PluginDir = fnamemodify(expand("<sfile>"), ':h')
let s:PerlDir   = s:PluginDir . "/../perl"

function! java_import#PerlBootstrap()
    if exists('s:did_JavaImport_bootstrap')
        return
    endif
    let s:did_JavaImport_bootstrap=1

    if !has("perl")
        echo "JavaImport requires a Vim built with Perl support"
        return
    endif

    perl use lib VIM::Eval(q(s:PerlDir))
    perl use JavaImport
endfunction

