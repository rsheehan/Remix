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

; code for writing to a file

write-file: function [/extern memory-list] [
	; save %Code.red memory-list/(length? memory-list)

	either (length? memory-list) = 0 [
		print "No Versions Saved"
	] [
		save %Code.red memory-list/(length? memory-list)	
		write/append %Code.red "TEST"
		; attempt [
		; 	run-remix commands/text 
		; ]
	]
]


; code for version manipulation

new-line: 1
detection-rate: 5
save-mode: true

memory-list: []

save-text: function [text][
	append memory-list (copy text)
	exit
]

version-selection: function [] [
	either version-select/selected = none [
		print "Nothing selected"
	] [
		commands/text: copy (memory-list/(to-integer (version-select/selected))) ; allows non-integer values
	
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
			if (to-integer (version-select/selected)) < (length? memory-list) [
				version-select/selected: ((version-select/selected) + 1)
			]
		] [
			if (to-integer (version-select/selected)) > 1 [
				version-select/selected: ((version-select/selected) - 1)
			]
		]
		commands/text: copy (memory-list/(to-integer (version-select/selected) ))
		attempt [
			run-remix commands/text 
		]
	]
]

count-enters: function[text /extern new-line /extern detection-rate /extern save-mode] [
	print detection-rate

	length: (length? split text newline)
	if save-mode = true [
		if (length >= (new-line + detection-rate)) [
			new-line: length
			return true
		] 
	]
	return false
]

change-detection-rate: function[/extern detection-rate /extern save-mode][
	either save-rate/text = "Never" [
		save-mode: false
	] [
		save-mode: true
		attempt [
			detection-rate: to-integer save-rate/text
		]
	]
	
]

view/tight [
	title "Live"
	commands: area 
		400x300 
		on-key-up [
			if count-enters commands/text [
				attempt [
					save-text commands/text
					append version-select/data (to-string (length? memory-list))
				]
			]
			attempt [
				run-remix commands/text 
			]

		]

	output-area: area 
		400x300
	version-area: panel
		1x300
		below 
		save-rate: drop-down 120 "Save Rate" data ["5" "10" "15" "20" "Never"] on-change [
			print "change"
			change-detection-rate
		]
		version-select: drop-down 120 "Code Versions" data []
		show-version: button 120 "Show" [version-selection]


		new-name: area 120x20
		rename-name: button 120 "Name Version" [
			save-text commands/text
			append version-select/data (copy new-name/text)
			]
		latest: button 120 "Latest" [latest-version]
		next: button 120 "(Next)" [version-change "+"]
		previous: button 120 "(Previous)" [version-change "-"]
		write: button 120 "Write to File" [write-file]
]
