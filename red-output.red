Red [
	Title: "The Remix Interpreter Red Output"
	Needs: view
]

#include %lexer.red
#include %ast.red
#include %function-functions.red
#include %built-in-functions.red
#include %remix-grammar-AST.red
#include %transpiler.red

filename: trim system/options/args/1
rem-file: to-file filename
print ["input file:" rem-file]

print "SOURCE CODE"
print read rem-file

; N.B. Can include the standard-lib
print "^/Without the standard library most remix programs will not transpile."
print "With the standard library there is a lot of output."
yes-set: charset "yY"
either parse (ask "Include the standard library? y/n ") [yes-set] [
	source: rejoin ["^/" read %standard-lib.rem "^/"]
][
	source: "^/"
]
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

print "^/IGNORING BUILT-IN FUNCTIONS"
built-in-fncs: keys-of function-map

successful-parse: false
ast: parse/trace lex-symbols [collect program] :call-back
if not successful-parse [
	print "Error: parsing failed."
	quit
]

; probe ast

do %transpiler.red

print "^/TRANSPILED FUNCTIONS"
transpile-functions function-map
user-fncs: exclude (keys-of function-map) built-in-fncs
foreach fnc user-fncs [
	the-fnc: select function-map fnc
	prin "^/" print fnc
	either the-fnc/red-code [
		probe get first the-fnc/red-code
	][
		probe the-fnc/fnc-def
	]
]

print "^/TRANSPILED MAIN SEQUENCE"
red-code: transpile-main ast
print []
probe red-code