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

memory: ""
save: function [saveText][
	memory: saveText
	print memory
]

; show: function [][
; 	[commands/text: "memory"]
; ]

view/tight [
	title "Live"
	commands: area 
		400x600 
		on-key-up [
			attempt [
				run-remix commands/text 
			]
		]
	output-area: area 
		400x600
	version-area: panel
		1x600
		below button "Old" [commands/text: "Hello!"]
		below button "Save" [save commands/text]
		below button "Show" [show]
		button "latest"
]
