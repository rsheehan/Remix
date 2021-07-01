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

memory-list: []

save-text: function [text /extern memory][
	append memory-list (copy text)
	exit
]

version-selection: function [] [
	either drop-down/selected = none [
		print "Nothing selected"
	] [
		commands/text: copy (memory-list/(to-integer (drop-down/selected))) ; allows non-integer values
	
		; update output of associated code
		attempt [
			run-remix commands/text 
		]
	]
]

rename-version: function [] [
	either drop-down/selected = none [
		print "No Version Selected"
	] [
		; print new-name/text
		; print (to-integer (drop-down/selected))
		print drop-down/data
		print (drop-down/selected)
		print (copy new-name/text)

		replace drop-down/data (to-string(drop-down/selected)) (to-string(copy new-name/text))
		; replace drop-down/data "1" 5
		print drop-down/data
	]
]

; Allow naming of certain versions (might need to change)
; Up down buttons
; Latest version
; Play, pause, speed control.
; Output file 


view/tight [
	title "Live"
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

		; drop-down: drop-down 120 "Choose Code" data []
		drop-down: drop-down 120 "Choose Code" data []

		add-version: button 120 "Save Version" [
				attempt [
					save-text commands/text
					append drop-down/data (to-string (length? memory-list))
				]
			]
		show-version: button 120 "Show" [version-selection]

		space: text
		space: text
		new-name: area 120x20
		rename-name: button 120 "Rename" [rename-version]
		space: text
		space: text

		;  for testing
		test2: button 120 "Print memory naming" [print drop-down/data]
		test: button 120 "Print memory list" [print memory-list]
]
