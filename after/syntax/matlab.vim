" Extend the built-in syntax while MATLAB's semantic tokens identify real
" functions versus array indexing (both use name(...) in MATLAB).
syntax match matlabFunctionCall "\<\h\w*\ze\s*("
syntax match matlabFunctionName "\%(^\s*function\s\+\%(\[[^]]*\]\s*=\s*\|\h\w*\s*=\s*\)\?\)\@<=\h\w*"
syntax match matlabSection "^\s*%%.*$"
syntax keyword matlabRepeat parfor spmd
syntax keyword matlabStatement arguments enumeration
syntax match matlabAssignment "="

highlight default link matlabFunctionCall Function
highlight default link matlabFunctionName Function
highlight default link matlabSection Title
highlight default link matlabAssignment Operator
