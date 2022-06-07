Red [
	Title: "The Remix Interpreter Runner"
	Needs: view
]

do %remix-grammar-AST.red

; include the standard-lib
source: rejoin ["^/" read %standard-lib.rem "^/"]

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
	if all [event = 'end not match?][
		probe input
	]
	true
]

successful-parse: false
ast: parse/trace lex-symbols [collect program] :call-back
if not successful-parse [
	print "Error: parsing failed."
	quit
]

call-names: []

print "^/FUNCTIONS"
foreach name keys-of function-map [
    append/only call-names split name "_"
]

print "^/METHODS"
foreach name extract method-list 2 [
    append/only call-names split name "_"
]

extract-all-words: function [
    { Go through all function names and collect the constituent words. }
    all-names [block!]
][
    all-words: []
    foreach name-list all-names [
        all-words: union all-words name-list
    ]
]

extract-all-words call-names

display-matches: function [
    matches
][
    foreach collection matches [
        foreach func-call collection [
            ; probe func-call
            print func-call
        ]
        print []
    ]
]

user-name: ""
forever [
    chars: ask append copy ">" user-name
    if chars = "quit" [quit]
    append user-name chars
    matches: copy []
    foreach name-list call-names [ ; name-list is a list of the parts of one function call
        pos: 0
        foreach part-from-name name-list [ ; goes throught each part
            pos: pos + 1
            part: find/part part-from-name user-name (length? user-name)
            if part [
                while [(length? matches) < pos][
                    append/only matches copy []
                ]
                append/only (pick matches pos) name-list
                break
            ]
        ]
    ]
    ; matches is ordered by the position of the matching work
    foreach collection matches [
        sort/compare collection func [a b][(length? a) < (length? b)]
    ]
    ; now each group of matches is ordered by number of parts in the function call
    print []
    display-matches matches
]
