Red [
	Title: "Lexer revision 2"
	Author: "Robert Sheehan"
	Version: 0.3
	Purpose: "Produce the sequence of tokens for the Remix grammar."
]

token: object [
	name: <>
	value: none
]

; newline: #"^/" ; because I have a newline function in Remix
white-space: charset reduce [space tab]
special: charset "()[]{,}:—_|§@/…'"    ; can add to this as required
; everything apart from white space, newline or special is a character
characters: complement union union special white-space charset newline
operators: charset "+-×÷%=≠<≤>≥"
digits: charset [#"0" - #"9"]
non-quote: charset [not "^""]
not-end-comment: charset [not ".^/"]
not-newline: charset [not "^/"]

comments: [
	[
		newline  ; line starts or ends with "." or starts with "="s.
		[
			any tab ["." | "=" | "- " | ";"] any not-newline
			|
			some [any not-end-comment some "."]; gobble anything until a "." or a newline
			|
			any tab ; a line with only tabs
		]
		|
		";" any not-newline ; semi-colon until the end of the line
	]
	ahead newline
]

remix-string: [ ; changed from "string" for live coding
	dbl-quote copy str_value any non-quote dbl-quote
	keep (
		make token [
			name: <string>
			value: str_value
		]
	)
]

number: [
	#"π"
	keep (
		make token [
			name: <number>
			value: pi
		]
	)
	|
    copy num [opt "-" opt [some digits "."] some digits]
    keep (
        either find num "." [
            num: to-float num
        ][
            num: to-integer num
        ]
		make token [
			name: <number>
			value: num
		]
    )
]

operator: [
	set op operators
	(
	op-word: switch op [
		#"+" ['addition]
		#"-" ['subtraction]
		#"×" ['multiplication]
		#"÷" ['division]
		#"%" ['modulo]
		#"<" ['less-than]
		#">" ['greater-than]
		#"≤" ['less-equal]
		#"≥" ['greater-equal]
		#"=" ['equal]
		#"≠" ['not-equal]
	]
	)
	keep (
		make token [
			name: <operator>
			value: op-word
		]
	)
]

left-p: [
	#"(" 
	; gobble up newlines and tabs following
	opt newline
	opt any tab
	keep (
		make token [
			name: <lparen>
		]
	)
]

right-p: [
	; gobble up newlines and tabs preceding
	opt newline
	opt any tab
	#")"
	keep (
		make token [
			name: <rparen>
		]
	)
]

left-b: [
	#"[" ; no gobble
	keep (
		make token [
			name: <LBRACKET>
		]
	)
]

right-b: [
	#"]" ; no gobble
	keep (
		make token [
			name: <RBRACKET>
		]
	)
]

left-curly-b: [
	#"{"
	; gobble up newlines and tabs following
	opt newline
	opt any tab
	keep (
		make token [
			name: <lbrace>
		]
	)
]

comma-char: [
	#","
	; gobble up newlines and tabs following
	opt white-space ; and left over spaces on the end of the line
	opt [#";" any not-newline]
	opt newline
	opt any tab
	keep (
		make token [
			name: <comma>
		]
	)
]

right-curly-b: [
	; gobble up newlines and tabs preceding
	opt newline
	opt any tab
	#"}"
	keep (
		make token [
			name: <rbrace>
		]
	)
]

colon: [
	#":"
	keep (
		make token [
			name: <colon>
		]
	)
]

cont: [
	#"…"
	keep (
		make token [
			name: <cont>
		]
	)
]

nl: [
    some [
		newline opt some comments
	]
    (tabs: 0)
    any [
		tab (tabs: tabs + 1)
	]
	keep (
		make token [
			name: <LINE>
			value: tabs
		]
	)
]

tokens: [left-p | right-p | left-b | right-b | left-curly-b | right-curly-b
		| comma-char | colon | operator | cont | nl]

multi-word: [ ; used for function multiple names
	copy first-word any characters
	"/"
	copy second-word some characters
	keep (
		make token [
			name: <multi-word>
			value: rejoin [first-word "/" second-word]
		]
	)
]

possessive: [ ; used for object field access
	copy chars any characters
	"'s"
	keep (
		make token [
			name: <lparen>
		]
	)
	keep (
		make token [
			name: <word>
			value: chars
		]
	)
	keep (
		make token [
			name: <rparen>
		]
	)
]

char-sequence: [
    copy chars any characters
    [
        if (chars = "true")
		keep (
			make token [
				name: <boolean>
				value: true
			]
		)
        |
        if (chars = "false")
		keep (
			make token [
				name: <boolean>
				value: false
			]
		)
        |
		keep (
			make token [
				name: <word>
				value: chars
			]
		)
    ]
] 

split-words: [                  ; parse block
    collect [
        any [
            [remix-string | comments | number | tokens | multi-word | possessive | char-sequence]
            any white-space
        ]
    ]
]

LINE: make token [
	name: <LINE>
]

LINE-STAR: make token [
	name: <*LINE>
]

tidy-up: function [
    { Turns the output into required Remix lex code.
      Removes all of the indent lines and puts consecutive same levels between brackets. 
	  Also deals with explicit lists so commas aren't necessary if items are on different
	  lines. }
    block   [block!]    "A block with tokens, strings and characters etc"
][
    lex-output: copy []
    current-block: lex-output
    indent-stack: []
	list-depth: 0 ; keeps track if we are inside a list
    append/only indent-stack lex-output
    current-indent: 0
    forall block [
        item: first block
		case [
			item/name = <lbrace> [
				list-depth: list-depth + 1
				append current-block item
			]
			item/name = <rbrace> [
				list-depth: list-depth - 1
				append current-block item
			]
			item/name = <LINE> [
				either list-depth = 0 [ ; ordinary lines
					this-indent: item/value
					case [
						this-indent = current-indent [
							append current-block LINE
						]
						this-indent = (current-indent + 1) [ ; only one implicit level allowed
							append/only current-block copy []
							current-block: last current-block
							append/only indent-stack current-block ; push
							current-indent: this-indent
						]
						this-indent > current-indent [
							print "Error: bad indentation"
							quit
						]
						this-indent < current-indent [
							while [this-indent < current-indent] [
								take/last indent-stack ; pop
								current-block: last indent-stack ; previous one
								append current-block LINE-STAR
								current-indent: current-indent - 1
							]
						]
					]
				][ ; lines in a list
					append current-block make token [
						name: <comma>
					]
				]
			]
			true [
				append current-block item
			]
		]
    ]
    append lex-output LINE
]

spit-out-symbols: function [
	lex-input [block!]
][
	result: copy []
	foreach symbol lex-input [
		either (type? symbol) = block! [
			append/only result spit-out-symbols symbol
		][
			append result symbol/name
			if symbol/value <> none [ ; only if some non-none value
				append result symbol/value
			]
		]
	]
	result
]

; print "**** Installed lexical analyser"