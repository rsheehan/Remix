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
	/running-first-time
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
	; use output-area only after it has been defined
	if not running-first-time [
		output-area/text: copy ""
	]
	do red-code
]

; run (load into Red runtime) the standard remix library
stdlib: read %standard-lib.rem
run-remix/running-first-time stdlib

; Setting up the graphics area by overriding the associated func
setup-paper: func [
    { Prepare the paper and drawing instructions.
      At the moment I am using a 2x resolution background for the paper. }
    colour [tuple!]
    width [integer!]
    height [integer!]
][
    paper-size: as-pair width height
    background-template: reduce [paper-size * 2 colour]
    background: make image! background-template
		paper/color: colour
		do [
				all-layers/1: compose [image background 0x0 (paper-size)]
				paper/draw: all-layers
				paper/rate: none
		]
    none
]

; Allowing functions to be redefined temporarily so that re-execution of code
; does not create trouble
insert-function: function [
    { Insert a function into the function map table }
    func-object [object!]   {the function object}
][
    name: to-function-name func-object/template
    put function-map name func-object
]

; loading the graphics statements which should be executed everytime
precursor-statements: read %precusor-graphics-statements.rem

; Block containing the points clicked on in graphics area
; Each element inside is a representation of a coordinate
; like: {0, 0}
points-clicked-on: make block! 0

refresh-panels: func [
		{ Clears the input text and graphics panels and then executes the remix 
		code in the input panel }
][
		; first execute the necessary graphics related statements
		run-remix precursor-statements
		; clean the graphics area
		draw-command-layers: copy/deep [[]]
		all-layers/2: draw-command-layers
		; run the code
		run-remix commands/text 
]

visualize-clicked-points: func [
		{ Visualize the points based on the number of points clicked }
		x [integer!]   {x-coordinate clicked on}
		y [integer!]   {y-coordinate clicked on}
	][
		append points-clicked-on rejoin ["{" x ", " y "}"]
		clear commands/text ; clear the input text panel
		point-clicked-on-radius: 2
		case [
			; plot a point
			(length? points-clicked-on) = 1 [
				commands/text: rejoin ["draw circle of (" point-clicked-on-radius ") at (" points-clicked-on/1 ")"]
			]
			; draw a line by joining two points
			(length? points-clicked-on) = 2 [
				commands/text: rejoin ["draw line from (" points-clicked-on/1 ") to (" points-clicked-on/2 ")"]
			]
			; draw a polygon
			(length? points-clicked-on) > 2 [
				; format the points as remix code
				points-of-shape: replace/all (rejoin points-clicked-on) "}" "},^/"
				; remove the last comma in the `points-of-shape` string (the newline
				; following the comma is unaffected)
				remove at points-of-shape ((length? points-of-shape) - 1)
				commands/text: rejoin ["shape1 : make shape of {^/" points-of-shape "}^/^/" "shape1 [size] : 1^/" "draw (shape1)"]
			]
		]
		refresh-panels
]

view/tight [
	title "Live"
	commands: area 
		400x600 
		on-key-up [
			attempt [
				refresh-panels 
			]
		]
	output-area: area 
		400x600
	paper: base 400x600 on-time [do-draw-animate]
	on-down [
		visualize-clicked-points event/offset/x event/offset/y
	]
	do [setup-paper 255.255.255 400 600]
]
