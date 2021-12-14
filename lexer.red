Red [
	Title: "Lexer revision 3"
	Author: "Robert Sheehan"
	Version: 0.3
	Purpose: "Produce the sequence of tokens and blocks for the Remix grammar."
]

token: object [
	name: <>
	value: none
]

; newline: #"^/" ; because I have a newline function in Remix
white-space: charset reduce [space tab]
special: charset "()[]{,}:—_|§@/…'’"    ; can add to this as required
; everything apart from white space, newline or special is a character
characters: complement union union special white-space charset newline
operators: charset "+-×÷%=≠<≤>≥"
digits: charset [#"0" - #"9"]
non-quote: charset [not "^""]
not-end-comment: charset [not ".^/"]
not-newline: charset [not "^/"]

comment: [
	[
		[
			newline  ; line starts or ends with "." or starts with "="s.
			[
				any tab ["." | "=" | "- " | ";"] any not-newline
				|
				some [any not-end-comment some "."]; gobble anything until a "." or a newline
				|
				any tab ; a line with only tabs
			]
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

space-in-lists: [ ; these get gobbled up if inside a list
	white-space | comment | nl ;newline | tab ; do I need to add tab?
]

left-curly-b: [
	#"{"
	keep (
		make token [
			name: <lbrace>
		]
	)
	any space-in-lists
]

comma-char: [
	#","
	any space-in-lists
	keep (
		make token [
			name: <comma>
		]
	)
]

right-curly-b: [
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
		newline any comment
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
	[#"'" | #"’"] #"s"
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
            [remix-string | comment | number | tokens | multi-word | possessive | char-sequence]
            any white-space
        ]
    ]
]

LINE: make token [
	name: <LINE>
]

LBRACKET: make token [
	name: <LBRACKET>
]

RBRACKET: make token [
	name: <RBRACKET>
]

LBRACE: make token [
	name: <lbrace>
]

RBRACE: make token [
	name: <rbrace>
]

COMMA: make token [
	name: <comma>
]

IMPLICIT: make token [ ; only used for implicit blocks
	name: <implicit>
]

set-inner-block: function [
	start-item		"start of block marker"
	finish-item		"end of block marker"
	input-block
	output-block
	indent-level
][
	append output-block start-item 	; e.g. <lbrace>
	sub-output-block: copy []
	append/only output-block sub-output-block
	block-indent: package-up-blocks finish-item input-block sub-output-block (indent-level + 1)
	input-block: first block-indent
	take input-block ; remove finish-item
	append output-block finish-item	; e.g. <rbrace>
	input-block	; return where we are up to
]

set-inner-implicit-block: function [
	input-block
	output-block
	indent-level
][
	sub-output-block: copy []
	append/only output-block sub-output-block
	return package-up-blocks IMPLICIT input-block sub-output-block (indent-level + 1)
]

package-up-blocks: function [
	terminating		[object!]	"Finish when get this input"
	input-block		[block!]	"Input block"
	output-block	[block!]	"Output block"
	indent-level	[integer!]	"Level of indent"
][
	previous: none
	while [(get in first input-block 'name) <> terminating/name] [ ; never true for implicit blocks
		; could be a list
		; could be a deferred block
		;	this could be implicit by tabs
		;	or explict with [ ... ].
		item: take input-block
		case [
			item/name = <lbrace> [ ; a list
				input-block: set-inner-block LBRACE RBRACE input-block output-block indent-level
			]

			item/name = <LBRACKET> [ ; an explicit block
				input-block: set-inner-block LBRACKET RBRACKET input-block output-block indent-level
			]

			item/name = <LINE> [
				indent: item/value
				if indent = (indent-level + 1) [ ; an implicit block
					block-indent: set-inner-implicit-block input-block output-block indent-level
					input-block: first block-indent
					indent: second block-indent
				]
				if indent < indent-level [
					return reduce [input-block indent]
				]
				if previous [ ; don't append if just inside the block
					append output-block LINE
				]
			]

			true [ ; everything else
				append output-block item
			]
		]
		previous: item
	]
	reduce [input-block indent-level]
]

tidy-up: function [
    { Turns the output into required Remix lex code.
      Removes all of the indent lines and puts consecutive same levels between brackets. }
    input-block   [block!]    "The input block with tokens, strings and characters etc"
][
	output-block: copy []
	while [not empty? input-block] [
		item: take input-block
		switch/default item/name [
			<lbrace> [
				input-block: set-inner-block LBRACE RBRACE input-block output-block 0
			]
			<LBRACKET> [
				input-block: set-inner-block LBRACKET RBRACKET input-block output-block 0
			]
			<LINE> [
				indent: item/value
				case [
					indent = 1 [
						set-inner-implicit-block input-block output-block 0
					]
					indent <> 0 [
						print "Error: Bad indentation top-level"
						quit
					]
				]
				append output-block LINE
			]
		][ ; default
			append output-block item
		]
	]
    append output-block LINE
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