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

save-text: function [text][
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

latest-version: function [] [
	either (length? memory-list) = 0 [
		print "No Versions Made"
	] [
		commands/text: copy (memory-list/(to-integer (length? memory-list))) ; allows non-integer values
	
		; update output of associated code
		attempt [
			run-remix commands/text 
		]
	]
]

version-change: function [change] [
	either (length? memory-list) = 0 [
		print "No Versions Made"
	] [
		either change = "+" [
			if (to-integer (drop-down/selected)) < (length? memory-list) [
				drop-down/selected: ((drop-down/selected) + 1)
			]
		] [
			if (to-integer (drop-down/selected)) > 1 [
				drop-down/selected: ((drop-down/selected) - 1)
			]
		]
		commands/text: copy (memory-list/(to-integer (drop-down/selected) ))
		attempt [
			run-remix commands/text 
		]
	]
]

write-file: function [/extern memory-list] [
	; save %Code.red memory-list/(length? memory-list)

	either (length? memory-list) = 0 [
		print "No Versions Saved"
	] [
		save %Code.red memory-list/(length? memory-list)	
		
		; attempt [
		; 	run-remix commands/text 
		; ]
	]
]
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


		new-name: area 120x20
		rename-name: button 120 "Name Version" [
			save-text commands/text
			append drop-down/data (copy new-name/text)
			]
		latest: button 120 "Latest" [latest-version]
		next: button 120 "/\ (Next)" [version-change "+"]
		previous: button 120 "\/ (Previous)" [version-change "-"]
		write: button 120 "Write to File" [write-file]

		;  for testing
		; test2: button 120 "Print memory naming" [print drop-down/data]
		; test: button 120 "Print memory list" [print memory-list]
]
