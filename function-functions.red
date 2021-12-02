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
	with multi-name parts e.g. ["animate" "|", ["time" "times"] "per" "sec"]
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
	num-names: 0 ; number of names for this function
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
	  If the same name already exists we require the "me" parameter to be in the same place. }
	new-method
][
	names: to-function-def-names new-method/template
	foreach name names [
		position: select method-list name
		either position = none [
			append append method-list name new-method/self-position
		][
			if position <> new-method/self-position [
				print rejoin [{Error: method "} name {" inconsistent object positions.}]
				quit
			]
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

join-name: function [
	{ Add the next part of a function name. }
	so-far  [string!]   "The function name so far"
	part    [string!]   "The next part of the name to add"
][
	if (length? so-far) > 0 [
		append so-far "_"
	]
	append so-far part
]

to-function-name: function [
	{ Convert a template, a block of name parts and parameter calls, into a string. }
	block [block!]  "The block of parts and parameter blocks"
][
	name: copy ""
	foreach part block [
		join-name name part
	]
	name
]

to-function-def-names: function [
	{ Convert a template, a block of name parts and parameter calls, into a block of strings. 
	  This deals with multi-names. }
	block [block!]  "The block of parts and parameter blocks"
][
	names: copy reduce [ copy "" ] ; for multi-names
	foreach part block [
		case [
			string? part [
				foreach name names [
					join-name name part
				] 
			]
			block? part [ ; only two options for each word currently
				append names copy/deep names ; double the number of names so far
				first-option: first part
				i: 1
				while [i <= ((length? names) / 2)][
					if first-option <> "" [ ; only if first-option is not empty
						join-name names/(i) first-option
					]
					i: i + 1
				]
				second-option: second part
				while [i <= (length? names)][
					join-name names/(i) second-option
					i: i + 1
				]
			]
		]
	]
	names
]

insert-function: function [
	{ Insert a function into the function map table }
	func-object [object!]   {the function object}
][
	names: to-function-def-names func-object/template
	func-object/num-names: length? names
	foreach name names [
		if select function-map name [
			print rejoin [{Error: "} name {"function is already defined.}]
			quit
		]
		put function-map name func-object
	]
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
