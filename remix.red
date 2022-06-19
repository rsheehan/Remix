Red [
	Title: "The compilable Remix program runner"
	Needs: view
]

#include %lexer.red
#include %ast.red
#include %function-functions.red
#include %built-in-functions.red
#include %remix-grammar-AST.red
#include %transpiler.red

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
	if all [event = 'end not match?][
		probe input
	]
	true
]

; Get the file name
filename: trim system/options/args/1
rem-file: to-file filename
print ["input file:" rem-file]

; N.B. Include the standard-lib
; and add the file on to the end of it.
source: rejoin ["^/" read %standard-lib.rem "^/"]
append append source read rem-file "^/"

; Produce the tokens from the source.
first-pass: parse source split-words
clean-lex: tidy-up first-pass
lex-symbols: spit-out-symbols clean-lex

; Produce the AST
successful-parse: false
ast: parse/trace lex-symbols [collect program] :call-back
if not successful-parse [
	print "Error: parsing failed."
	quit
]

; Generate the Red equivalent code for all functions.
transpile-functions function-map

; And the top level code.
red-code: transpile-main ast

print "^/PROGRAM OUTPUT"
recycle/off ; turn garbage collector off -
; this is not good but stops crashes in the short term

; Run the 
do red-code