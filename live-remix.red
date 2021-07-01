Red [needs: view]

do %remix-grammar-AST.red
do %transpiler.red

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

prin: function [
	{ Replace the standard "prin" function, which used in the built-in show functions. }
	output [string!]
][
	append output-area/text output
]

run-remix: function [
	{ Execute the remix code in "code". 
	  Put the output in the output area. }
	code [string!]
	/extern successful-parse
][
	; N.B. remember to include the standard-lib
	; source: append (append (copy "^/") (read %standard-lib.rem)) "^/"
	source: copy "^/"
	source: append (append source code) "^/"
	; get the lexer output
	first-pass: parse source split-words
	clean-lex: tidy-up first-pass
	lex-symbols: spit-out-symbols clean-lex
	; parse
	successful-parse: false
	ast: parse/trace lex-symbols [collect program] :call-back
	if not successful-parse [
		return
	]
	; transpile
	transpile-functions function-map
	red-code: transpile-main ast
	; run
	output-area/text: copy ""
	do red-code
]

; memory:	"Empty"
memory-list: []


save-text: function [text /extern memory][
	; memory: copy text
	append memory-list (copy text)
	exit
]

version-selection: function [] [
	either drop-down/selected = none [
		print "Nothing selected"
	] [
		; print ["Selected: " mold pick drop-down/data drop-down/selected]
		commands/text: copy (memory-list/(to-integer (pick drop-down/data drop-down/selected)))
	
		; update output of associated code
		run-remix commands/text 
	]
]

view/tight [
	title "Live"

	; on-key [
	; 	print event/type
	; 	print event/offset
	; 	print event/key
	; ]
	commands: area 
		400x300 
		on-key-up [
			attempt [
				run-remix commands/text 
			]

		]
	output-area: area 
		400x300
	version-area: panel
		1x300
		below 
		drop-down: drop-down 120 "Choose Code" data []
		add-version: button 120 "Save New Version" [
				attempt [
					save-text commands/text
					append drop-down/data (to-string (length? memory-list))
				]
			]
		show-version: button 120 "Show" [version-selection]



		;  for testing
		test: button 120 "Print memory list" [print memory-list]
]
