Red [
	Title: "The Remix Interpreter Runner"
	Needs: view
]

do %remix-grammar-AST.red

filename: trim system/options/args/1
rem-file: to-file filename
print ["input file:" rem-file]

; print "SOURCE CODE"
; print read rem-file

; N.B. remember to include the standard-lib
source: rejoin ["^/" read %standard-lib.rem "^/"]
append append source read rem-file "^/"

first-pass: parse source split-words
clean-lex: tidy-up first-pass
lex-symbols: spit-out-symbols clean-lex

call-back: function [
	event [word!] 
	match? [logic!] 
	rule [block!] 
	input [series!] 
	stack [block!]
	/extern successful-parse
][
	if all [event = 'end match?][
		successful-parse: true
	]
	true
]

successful-parse: false
ast: parse/trace lex-symbols [collect program] :call-back
if not successful-parse [
	print "Error: parsing failed."
	quit
]
; probe ast

; print "^/FUNCTIONS"
; probe function-map

do %transpiler.red

; print "^/TRANSPILED OUTPUT"

transpile-functions function-map
; probe function-map
red-code: transpile-main ast
; print []
; probe red-code

print "^/PROGRAM OUTPUT"
recycle/off ; turn garbage collector off - this is not good but stops crashes in the short term
do red-code