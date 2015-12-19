" Path of java source and class files
let g:java_import_path=""
let g:java_import_path_file=".java_import_path"

"The file that contains our script output
let g:java_import_index=".java_import_index"

"The dictionary that contains the index information for displaying posible
"  imports
let g:java_import_dictionary={}
let g:java_import_dictionary_was_loaded=0

function! GenerateIndex()
    call java_import#PerlBootstrap()

    echo 'Generating Index...'
    perl JavaImport::generate_index()
    redraw!
endfunction

function! LoadIndex()
  if !filereadable(g:java_import_index)
      call GenerateIndex()
  endif

  let loaded_index_raw=system("cat " . g:java_import_index)

  let index_dictionary={}
  for line in split(loaded_index_raw, '\n')
    let kv = split(line, ':')
    let value_list = split(kv[1], ',')
    let index_dictionary[kv[0]] = value_list
  endfor

  " Save the data structure for future queries
  let g:java_import_dictionary=index_dictionary
  let g:java_import_dictionary_was_loaded=1
endfunction

function! PrintImportOptions()
  if g:java_import_dictionary_was_loaded == 0
    call LoadIndex()
  endif
  let cword=expand("<cWORD>")
  if has_key(g:java_import_dictionary, cword)
    echo join(g:java_import_dictionary[cword], "\n")
  else
    echo cword "is not a known java Class"
  endif
endfunction

function! AddImport()
  if g:java_import_dictionary_was_loaded == 0
    call LoadIndex()
  endif
  let cword=expand("<cWORD>")
  if has_key(g:java_import_dictionary, cword)
    let import = g:java_import_dictionary[cword][0]
    execute "normal 1GOimport ".import."\<Esc>"
  else
    echo cword "is not a known java Class"
  endif
endfunction
