Red [Title: "Built-in functions"
	Author: "Robert Sheehan"
	Version: 0.3
	Purpose: "Red built-in functions for Remix."
]

; ********* built-in functions ********

based-on-fnc: make function-object [
	template: ["based" "on" "|"]
	; formal-parameters ["original"]
	red-code: [copy/deep]
]

range-string: function [
	{ Create a string from a range. }
	range [hash!]
][
	str: copy ""
	value: range/_start
	direction: 1
	if range/_start > range/_finish [direction: -1]
	loop (absolute range/_finish - range/_start) + 1 [
		append append str value " "
		value: value + direction
	]
	str
]

list-string: function [
	{ Create a string from a list or map. }
	list [hash! map!]
][
	str: copy ""
	either map? list [
		keys: keys-of list
		remove find keys '_iter
		foreach key keys [
			append append str key ":"
			append append str list/:key " "
		]
	][
		list: at list 3
		foreach item reduce to-block list [
			append str item-string item
		]
	]
	str
]

item-string: function [
	{ Create a string from a single item. 
	  If the item is a word evaluate it. }
	item
][
	case [
		none? item [
			"none"
		]
		word? item [ ; possibly a variable
			to-string reduce item
		]
		map? item [ ; an object
			list-string item
		]
		hash? item [ ; a list
			either item/_start [
				range-string item
			][
				list-string item
			]
		]
		block? item [
			str: next mold item
			str: copy/part str ((length? str) - 1)
		]
		true [
			if none? item [item: ""]
			to-string reduce item
		]
	]
]

show-range: function [
	{ Display a range. }
	range [hash!]
][
	prin range-string range
]

show-block: function [
	{ Display a list or map. }
	list [hash! map!]
][
	prin list-string list
]

show-item: function [
	{ Display any item. }
	item
][
	prin item-string item
	none
]

show-fnc: make function-object [
	template: ["show" "|"]
	; formal-parameters: ["output"]
	red-code: [show-item]
]

ask-fnc: make function-object [
	template: ["ask" "|"]
	; formal-parameters: ["description"]
	red-code: [ask]
]

if-remix: function [
	{ The remix "if" function.
	  This must call "do" on the condition in case it is block. }
	condition
	consequence
][
	if do condition [
		do consequence
	]
]

if-fnc: make function-object [
	template: ["if" "|" "|"]
	; formal-parameters: ["condition" "consequence"]
	return-higher: true
	red-code: [if-remix]
]

if-else-remix: function [
	{ The remix "if otherwise" function.
	  This must call "do" on the condition in case it is block. }
	condition
	consequence
	alternative
][
	either do condition [
		do consequence
	][
		do alternative
	]
]

if-else-fnc: make function-object [
	template: ["if" "|" "|" "otherwise" "|"]
	; formal-parameters: ["condition" "consequence" "alternative"]
	return-higher: true
	red-code: [if-else-remix]
]

do-fnc: make function-object [
	template: ["do" "|"]
	; formal-parameters: ["executable"]
	return-higher: true
	red-code: [do] ;[do-remix]
]

type: function [
	thing
][
	case [
		hash? thing [
			"list"
		]
		map? thing [
			"map"
		]
		object? thing [
			"object"
		]
		block? thing [
			"deferred"
		]
		number? thing [
			"number"
		]
		string? thing [
			"string"
		]
		logic? thing [
			"boolean"
		]
		none? thing [
			"none"
		]
	]    
]

type-fnc: make function-object [
	template: ["type" "of" "|"]
	; formal-parameters: ["thing"]
	red-code: [type]
]

integer-fnc: make function-object [
	template: ["convert" "|" "to" "integer"]
	; formal-parameters: ["string-input"]
	red-code: [to-integer]
]

string-fnc: make function-object [
	template: ["convert" "|" "to" "string"]
	; formal-parameters ["item-input"]
	red-code: [item-string]
]

remix-probe: function [
	item
][
	prin "Red value: "
	probe item
]

probe-fnc: make function-object [
	template: ["probe" "|"]
	; formal-parameters ["thing"]
	red-code: [remix-probe]
]

insert-function based-on-fnc
insert-function show-fnc
insert-function ask-fnc
insert-function if-fnc
insert-function if-else-fnc
insert-function do-fnc
insert-function type-fnc
insert-function integer-fnc
insert-function string-fnc
insert-function probe-fnc

; ********* list and range functions ********

comment {
	In all of these functions objects are stored as map! values
	and ordinary lists and ranges are stored as hash! values.
	I could have used block! values for ordinary lists but having them as hash! values
	currently distinguishes them from deferred blocks of code.
}

length: function [
	list [hash! map! string!]
][
	case [
		map? list [
			(length? list) - 1 ; minus _iter
		]
		string? list [
			length? list
		]
		true [
			either list/_start [
				(absolute (list/_finish - list/_start)) + 1
			][
				(length? list) - 2
			]            
		]
	]
]

length-fnc: make function-object [
	template: ["length" "of" ["" "the"] "|"]
	; formal-parameters: ["list"]
	red-code: [length]
]

start-iterator: function [
	{ Prepare a list, range or object for iterating over. }
	list [hash! map!]
][
	either map? list [
		list/_iter: 1
	][
		either list/_start [ ; a range
			list/_iter: list/_start
		][
			list/_iter: 3 ; skip over the iterator itself
		]
	]
]

start-iterator-fnc: make function-object [
	template: ["start" "|"]
	; formal-parameters: ["list"]
	red-code: [start-iterator]
]

next-iterator: function [
	{ Return the next item from the list, range or map and move on. }
	list [hash! map!]
][
	either map? list [
		; have to avoid the key _iter
		keys: keys-of list
		remove find keys '_iter
		key: pick keys list/_iter
		value: select list key
		if block? value [
			value: ['..code..]
		]
		result: reduce value ;[to-set-word key value]
		list/_iter: list/_iter + 1
	][
		either list/_start [
			result: list/_iter
			either list/_start <= list/_finish [
				if list/_iter > list/_finish [
					print "Error: access past end of range."
					quit
				]
				list/_iter: list/_iter + 1
			][
				if list/_iter < list/_finish [
					print "Error: access past end of range."
					quit
				]
				list/_iter: list/_iter - 1
			]
		][
			number: list/_iter
			result: list/:number
			list/_iter: list/_iter + 1
		]
	]
	if paren? result [result: do result]
	return result
]

next-iterator-fnc: make function-object [
	template: ["next" "|"]
	; formal-parameters: ["list"]
	red-code: [next-iterator]
]

end-of-iterator: function [
	{ Report if the iterator is at the end of the list, range or object. }
	list [hash! map!] ; object!
][
	either map? list [ ; object?
		list/_iter > length list
	][
		either list/_start [
			either list/_start <= list/_finish [
				list/_iter > list/_finish
			][
				list/_iter < list/_finish
			]
		][
			list/_iter > length? list
		]
	]
]

end-of-iterator-fnc: make function-object [
	template: ["end" "of" ["" "the"] "|"]
	; formal-parameters: ["list"]
	red-code: [end-of-iterator]
]

append-to: function [
	{ Append value onto the end of list, which may be a string. 
	  Currently doesn't throw an error if passed a range. }
	value
	list [hash! string!]
][
	; if hash? value [ ; need to evaluate before appending
	;     value: reduce to-block at value 3
	;     value: make hash! compose [_iter 0 (value)]
	; ]
	append/only list value
]

append-fnc: make function-object [
	template: [["append" "add"] ["" "the"] "|" "to" ["" "the"] "|"]
	; formal-parameters: ["value" "list"]
	red-code: [append-to]
]

create-range: function [
	start
	finish
][
	make hash! reduce [
		'_iter 0
		'_start start
		'_finish finish
		'_range true
	]
]

range-fnc: make function-object [
	template: ["|" "to" "|"]
	; formal-parameters: ["start" "finish"]
	red-code: [create-range]
]

index-to-value: function [
	{ Convert index to integer, it could be a word value. }
	index
][
	either integer? index [
		return index
	][
		return get index ; see if it is an integer
	]
]

get-item: function [
	{ Get an item from a list, range or map. 
	  The index-key can either be an index or a key. }
	list [hash! map!] ; no longer works with object!
	index-key
][
	case [
		map? list [
			result: attempt [select list index-key]
			if not result [ ; see if it could be an index
				attempt [
					index: index-to-value index-key
					if (index > length list) or (index < 1) [
						print rejoin [{Error: map "} quote list {" out of bounds}]
						quit
					]
					keys: keys-of list
					remove find keys '_iter
					key: pick keys index
					result: reduce [to-set-word key select list key]
				]
				; if key does not exist it returns none
			]
		]
		hash? list [
			either select list '_range [
				index: index-to-value index-key
				start: select list '_start
				finish: select list '_finish
				reverse: false
				if start > finish [
					temp: finish
					finish: start
					start: temp
					reverse: true
				]
				if (index > (finish - start + 1)) or (index < 1) [
					print rejoin [{Error: list "} quote list {" out of bounds}]
					quit
				]
				either reverse [
					result: finish - index + 1
				][
					result: start + index - 1
				]
			][
				list: at list 3; adjust for _iter
				index: index-to-value index-key
				if (index > length? list) or (index < 1) [
					print rejoin [{Error: list "} quote list {" out of bounds}]
					quit
				]
				result: list/:index
			]
		]
	] 
	if any [
		paren? result 
		word? result
	][result: do result] ; evaluate before returning
	return result
]

get-item-fnc: make function-object [
	template: ["|" "|"]
	; formal-parameters: ["list" "index/key"]
	red-code: [get-item]
]

set-item: function [
	{ Set a value for a list or object.
	  A list uses an index, a map or object uses a key.
	  Extends the map if the key doesn't already exist.
	  Currently doesn't throw an error if passed a range. }
	list [hash! map!]
	index-key
	value
][
	case [
		map? list [
			if integer? index-key [
				print rejoin [{Error: Can't set map "} quote list {" with an index.}]
				quit
			]
			put list index-key value
		]
		hash? list [
			list: at list 3 ; adjust for _iter
			index: index-to-value index-key
			if (index > length? list) or (index < 1) [
				print rejoin [{Error: list "} quote list {" out of bounds}]
				quit
			]
			list/:index: value
		]
	]
]

set-item-fnc: make function-object [
	template: ["|" "|" "|"]
	; formal-parameters: ["list" "index/key" "value"]
	red-code: [set-item]
]

insert-function length-fnc
insert-function start-iterator-fnc
insert-function next-iterator-fnc
insert-function end-of-iterator-fnc
insert-function append-fnc
insert-function range-fnc
insert-function get-item-fnc
insert-function set-item-fnc

; ********* drawing functions ********

draw-layer: 1 ; above the background
draw-command-layers: [[]] ; transitory draw commands for all layers but background
all-layers: reduce [[] draw-command-layers] ; will have background and command-layers
background: none ; will be an image created in setup-paper
background-template: [] ; will include size and colour
background-pen: [pen black line-width 2 line-cap round] ; commands to set the current background pens
animate-instructions: []
paper: none ; needed to enable compilation to work

change-draw-layer: function [
	{ Set the draw layer. 0 is the background. }
	layer [integer!]
	/extern draw-layer
][
	draw-layer: layer
	while [(length? draw-command-layers) < layer] [
		append/only draw-command-layers copy []
	]
	none
]

draw-layer-fnc: make function-object [
	template: ["draw" "on" "layer" "|"]
	; formal-parameters ["drawing-layer"]
	red-code: [change-draw-layer]
]

clear-layer: function [
	{ Clear the drawing from a layer. }
	layer [integer!]
	/extern background
][
	change-draw-layer layer
	either layer = 0 [
		background: make image! background-template
	][
		draw-command-layers/:layer: copy []
	]
	none
]

clear-layer-fnc: make function-object [
	template: ["clear" "layer" "|"]
	; formal-parameters ["drawing-layer"]
	red-code: [clear-layer]
]

point-to-pair: function [
	{ Convert a Remix list (hash) to a Red pair. }
	point [hash! map!]
][
	either hash? point [
		as-pair point/3 point/4
	][
		as-pair point/x point/y
	]
]

do-draw-animate: func [
	{ Executes animate instructions and then sets the paper's draw facet.
	  This causes the drawing to be performed. }
][
	do animate-instructions
]

show-paper: function [][
	; this takes over the program as it is the only thread running
	; and does not return until the view (window) is closed
	do-events
]

show-paper-fnc: make function-object [
	template: ["show" "paper"]
	red-code: [show-paper]
]

setup-paper: func [ ; has to allow paper to be global
	{ Prepare the paper and drawing instructions.
	  At the moment I am using a 2x resolution background for the paper. }
	colour [tuple!]
	width [integer!]
	height [integer!]
][
	paper-size: as-pair width height
	background-template: reduce [paper-size * 2 colour]
	background: make image! background-template
	; paper-view: compose [
	view/no-wait [
		title "Paper"
		backdrop reblue
		paper: base paper-size colour
		on-time [do-draw-animate]
		do [
			all-layers/1: compose [image background 0x0 (paper-size)]
			paper/draw: all-layers
			paper/rate: none
		]
	]
	none
]

setup-paper-fnc: make function-object [
	template: ["|" "paper" "of" "|" "by" "|"]
	; formal-parameters ["colour" "width" "height"]
	red-code: [setup-paper]
]

no-pen: function [
	{ Turns off the pen (which does outlines). }
][
	either draw-layer = 0 [
		append background-pen [pen off]
	][
		append/only draw-command-layers/:draw-layer [pen off]
	]
	none
]

no-pen-fnc: make function-object [
	template: ["no" "outline"]
	red-code: [no-pen]
]

draw-pen: function [
	{ Add a pen to the current paper drawing. }
	pen [map!]
	/extern background-pen
][
	pen-info: compose [
			pen (pen/colour) 
			line-width (pen/width)
			line-cap round       
		]
	either draw-layer = 0 [
		pen-info/4: pen-info/4 * 2
		background-pen: pen-info
	][
		append/only draw-command-layers/:draw-layer pen-info
	]
	none
]

draw-pen-fnc: make function-object [
	template: ["draw" "with" "|"]
	; formal-parameters ["pen"]
	red-code: [draw-pen]
]

no-fill: function [
	{ Turns off the fill pen. }
][
	either draw-layer = 0 [
		append background-pen [fill-pen off]
	][
		append/only draw-command-layers/:draw-layer [fill-pen off]
	]
	none
]

no-fill-pen-fnc: make function-object [
	template: ["do" "not" "fill"]
	red-code: [no-fill]
]

fill-colour: function [
	{ Set the fill colour. }
	colour [tuple!]
][
	either draw-layer = 0 [
		append background-pen reduce ['fill-pen colour]
	][
		append/only draw-command-layers/:draw-layer reduce ['fill-pen colour]
	]
	none
]

fill-colour-fnc: make function-object [
	template: ["fill" "colour" "|"]
	; formal-parameters ["colour"]
	red-code: [fill-colour]
]

draw-line: function [
	{ Draw a line from start to finish. }
	start [hash! map!] "with x and y"
	finish [hash! map!] "with x and y"
][
	start: point-to-pair start
	finish: point-to-pair finish
	either draw-layer = 0 [
		line-command: compose [line (start * 2) (finish * 2)]
		draw background append copy background-pen line-command
	][
		line-command: compose [line (start) (finish)]
		append/only draw-command-layers/:draw-layer line-command
		possibly-show-immediately
	]
	none
]

draw-line-fnc: make function-object [
	template: ["draw" "line" "from" "|" "to" "|"]
	; formal-parameters ["start" "finish"]
	red-code: [draw-line]
]

draw-box: function [
	{ Draw a rectangle. }
	top-left [hash! map!]
	bottom-right [hash! map!]
][
	top-left: point-to-pair top-left
	bottom-right: point-to-pair bottom-right
	either draw-layer = 0 [
		box-command: compose [box (top-left * 2) (bottom-right * 2)]
		draw background append copy background-pen box-command
	][
		box-command: compose [box (top-left) (bottom-right)]
		append/only draw-command-layers/:draw-layer box-command
		possibly-show-immediately
	]
	none
]

draw-box-fnc: make function-object [
	template: ["draw" "box" "from" "|" "to" "|"]
	; formal-parameters ["bottom-left" "top-right"]
	red-code: [draw-box]
]

draw-circle: function [
	{ Draw a circle. }
	radius [number!]
	centre [hash! map!] "x, y"
][
	centre: point-to-pair centre
	either draw-layer = 0 [
		circle-command: reduce ['circle centre * 2 radius * 2]
		draw background append copy background-pen circle-command
	][
		circle-command: reduce ['circle centre radius]
		append/only draw-command-layers/:draw-layer circle-command
		possibly-show-immediately
	]
	none
]

draw-circle-fnc: make function-object [
	template: ["draw" "circle" "of" "|" "at" "|"]
	; formal-parameters ["radius" "centre" ]
	red-code: [draw-circle]
]

draw-shape: function [
	{ Draw a polygon. }
	shape [object!]
][
	list-of-points: at shape/points 3
	commands: copy [polygon]
	centre: point-to-pair shape/position
	foreach point list-of-points [
		point: point-to-pair point
		point: point * shape/size + centre
		if draw-layer = 0 [
			point: point * 2
		]
		append commands point
	]
	either draw-layer = 0 [
		rotate-command: compose/deep [rotate (shape/heading) (centre * 2) [(commands)]]
		draw background append copy background-pen rotate-command
	][
		rotate-command: compose/deep [rotate (shape/heading) (centre) [(commands)]]
		append/only draw-command-layers/:draw-layer rotate-command
		possibly-show-immediately
	]
	none
]

draw-shape-fnc: make function-object [
	template: ["draw" "shape" "|"]
	; formal-parameters ["shape"]
	red-code: [draw-shape]
]

possibly-show-immediately: does [
	; Don't show immediately if animation is active.
	unless paper/rate [do-events/no-wait]
]

animate: function [
	{ Draw animation layer}
	instructions
	/extern animate-instructions
][
	animate-instructions: instructions
	none
]

animate-fnc: make function-object [
	template: ["animate" "|"]
	; formal-parameters ["animate-block"]
	red-code: [animate]
]

animation-rate: function [
	{ Set the animation rate per second. }
	rate
][
	paper/rate: rate
	none
]

animation-rate-fnc: make function-object [
	template: ["|" ["time" "times"] "per" "sec"]
	; formal-parameters ["rate"]
	red-code: [animation-rate]
]

animation-off: func [
	{ Turn the animation off. }
][
	paper/rate: none
	; quit ; uncomment for timing purposes
] 

animation-off-fnc: make function-object [
	template: ["animation" "off"]
	red-code: [animation-off]
]

hide-all-drawing: func [
	{ Hide the drawing. }
][
	system/view/auto-sync?: off
	none
]

show-all-drawing: func [
	{ Show the drawing. }
][
	system/view/auto-sync?: on
	show paper
	do-events/no-wait
	none
]

hide-drawing-fnc: make function-object [
	template: ["hide" "drawing"]
	red-code: [hide-all-drawing]
]

show-drawing-fnc: make function-object [
	template: ["show" "drawing"]
	red-code: [show-all-drawing]
]

wait-fnc: make function-object [
	template: ["wait" "|" ["secs" "sec"]]
	; formal-parameters ["seconds"]
	red-code: [wait]
]

insert-function draw-layer-fnc
insert-function clear-layer-fnc
insert-function setup-paper-fnc
insert-function show-paper-fnc
insert-function no-pen-fnc
insert-function draw-pen-fnc
insert-function no-fill-pen-fnc
insert-function fill-colour-fnc
insert-function draw-line-fnc
insert-function draw-box-fnc
insert-function draw-circle-fnc
insert-function draw-shape-fnc
insert-function animate-fnc
insert-function animation-rate-fnc
insert-function animation-off-fnc
insert-function hide-drawing-fnc
insert-function show-drawing-fnc
insert-function wait-fnc

; ********* event functions ********

; when-fnc: function [
;     { Set up a handler for a particular event. }
;     event
; ]

; ********* numeric functions ********

randomize-remix: function [
	seed [number! date!]
][
	random/seed seed
	seed
]

randomize-now: function [
][
	randomize-remix now
]

randomize-fnc: make function-object [
	template: ["randomize"]
	red-code: [randomize-now]
]

randomize-seed-fnc: make function-object [
	template: ["randomize" "with" "|"]
	; formal-parameters ["seed"]
	red-code: [randomize-remix]
]

random-fnc: make function-object [
	template: ["random" "|"]
	; formal-parameters ["max-value"]
	; Currently doesn't prevent inappropriate parameters such as lists.
	red-code: [random]
]

sine-fnc: make function-object [
	template: ["sine" "|"]
	; formal-parameters ["degrees"]
	red-code: [sine]
]

cosine-fnc: make function-object [
	template: ["cosine" "|"]
	; formal-parameters ["degrees"]
	red-code: [cosine]
]

atan2-fnc: make function-object [
	template: ["arctangent" "|" ["over" "/"] "|"]
	; formal-parameters ["change-y" "change-x"]
	red-code: [arctangent2]
]

square-root-fnc: make function-object [
	template: [["√" "sqrt"] "|"]
	; formal-parameters ["value"]
	red-code: [square-root]
]

insert-function randomize-fnc
insert-function randomize-seed-fnc
insert-function random-fnc
insert-function sine-fnc
insert-function cosine-fnc
insert-function atan2-fnc
insert-function square-root-fnc

; print "**** Installed built-in functions"