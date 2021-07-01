Red [Title: "Function helper functions"
	Author: "Robert Sheehan"
	Version: 0.3
	Purpose: "Red functions to help with Remix functions."
]

function-map: make map! [] ; all functions (no nesting of functions yet)
comment {
 The keys are the function names as strings e.g. "put_|_into_|".
 The values are function objects.
 Function objects have:
	a template of the name e.g. ["display" "|"]
	the list of formal parameters (if not a built-in function)
		could include them for built-ins for help purposes
	whether this function returns or passes returns higher
		this is useful for control structures
	a block of Remix code (if not a built-in function)
	the transpiled code if it is a function with reference variables
	the red-code to call if not a reference function
}

function-object: object [
	template: [] ; filled in when defined
	formal-parameters: [] ; For a Remix code function, this provides the parameter names. Strings.
	return-higher: false
	block: none ; filled in when defined - this is Remix AST code
	fnc-def: [] ; if a reference function, filled in when transpiled
	red-code: none ; filled in if not a reference function
] 

; even though not necessary here, included because of similarity to function-object

method-list: copy [] ; all methods, so we can check if a function name is unique
; it is possible for the same method name to be used by different objects
; The list contains names followed by the position of the object variable.

add-to-method-list: function [
	{ Add new-method to the method list. 
	  Currently an error if a function exists with the same name. }
	new-method
][
	name: to-function-name new-method/template
	position: select method-list name
	either position = none [
		append append method-list name new-method/self-position
	][
		if position <> new-method/self-position [
			print [{Error: method "} name {" inconsistent object positions.}]
			quit
		]
	]
]

method-object: object [
	template: [] ; filled in when defined
	formal-parameters: []
	self-position: 0 ; which parameter is the object reference
	block: none ; filled in when defined - this is Remix AST code
]

; ********* function functions ********

function-name: [                            ; parse block
	any ["|_" (append name-list "|")]
	any ["_|" (append name-list "|")]
	opt "_"
	copy part some characters
	(if part <> "" [append name-list part])
	function-name
]

pluralised: function [
	{ Attempt all plural versions of function name to find an existing function. 
	  Returns none or the reference to the function object which matches. }
	fnc-name [string!]
	/extern name-list
][
	name-list: copy []
	parse fnc-name function-name
	forall name-list [
		full-name: copy head name-list
		next-part: copy first name-list
		if next-part <> "|" [
			poke full-name index? name-list append next-part "s"
			full-name: to-function-name full-name
			the-fnc: select function-map full-name
			if the-fnc <> none [
				return the-fnc
			]
		]
	]
	none
]

join-name: function [
	"Add the next part of a function name."
	so-far  [string!]   "The function name so far"
	part    [string!]   "The next part of the name to add"
][
	if (length? so-far) > 0 [
		append so-far "_"
	]
	append so-far part
]

to-function-name: function [
	{ Convert a template, a block of name parts and parameter calls, into a string }
	block [block!]  "The block of parts and parameter blocks"
][
	name: copy ""
	foreach part block [
		join-name name part
	]
	name
]

insert-function: function [
	{ Insert a function into the function map table }
	func-object [object!]   {the function object}
][
	name: to-function-name func-object/template
	case [
		find method-list name [
			print [{Error: existing method with function name "} name {".}]
			quit 
		]
		select function-map name [
			print [{Error: "} name {"function is already defined.}]
			quit
		]
	]
	put function-map name func-object
]

create-function-call: function [
	{ Create a function object which can be evaluated.
	  All parameters are stored with their expressions }
	the-name [string!]
	actual-parameters [block!]
][
	make function-call-stmt [
		fnc-name: the-name
		actual-params: actual-parameters
	]
]

assist-create-function-call: function [
	{ Take a parsed function call block and create a function call from it.
	  The block looks like:
	  [name1 | [value object for param1] name2 | [value object for param2]]
	}
	components [block!]
][
	template: copy []
	actual-parameters: copy []
	follows-|: false
	foreach item components [
		either follows-| [
			append actual-parameters item
		][
			append template item
		]
		follows-|: item = "|"
	]
	name: to-function-name template
	create-function-call 
		name
		actual-parameters
]
