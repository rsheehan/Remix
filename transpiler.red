Red [
	Title: "The Remix Red code generator"
	Author: "Robert Sheehan"
	Version: 0.3
	Purpose: "Converts an AST of Remix code into Red code."
]

primitive!: make typeset! [
	integer! float! string! logic! none!
]

create-sequence: function [
	{ Create a sequence block of red statements. }
	list-of-statements [block!]
	return-higher [logic!] "Whether the function should throw returns higher."
][
	length: length? list-of-statements
	need-a-loop: false
	seq-list: copy []
	loop length - 1 [
		statement: first list-of-statements
		if all [
			block? statement
			(first statement) = 'continue
		][
			need-a-loop: true
		]
		append seq-list statement
		list-of-statements: next list-of-statements
	]
	last-statement: first list-of-statements

	either all [
		block? last-statement 
		(first last-statement) = 'continue
	][ ; we need a loop
		need-a-loop: true
	][ ; no loop so do the last statement
		append seq-list last-statement
	]

	either need-a-loop [
		either return-higher [
			sequence: reduce [
				'forever compose [(seq-list)]
			]
		][
			sequence: reduce [
				'catch/name reduce [
					'forever compose [(seq-list)]
				] quote 'return
			]
		]
	][ ; doesn't need a loop
		either return-higher [
			sequence: compose [
				(seq-list)
			]
		][
			sequence: reduce [
				'catch/name compose [
					(seq-list)
				] quote 'return
			]
		]
	]
	sequence
]

create-red-parameters: function [
	{ Convert the parameters into red code.}
	remix-params [block!]
][
	red-params: copy []
	foreach param remix-params [
		red-param: create-red-expression param
		either hash? red-param [ ; appending a hash converts it to a list
			append/only red-params red-param ; so have to use only
		][
			append red-params red-param
		]
	]
	red-params
]

determine-list-type: function [
	{ Determine the type of element and hence set the list type. 
	  If there is no first element we choose a hash!. }
	element
][
	result: attempt [
		if element/type = "key-value" [
			true
		]
	]
	either result [
		"map"
	][
		"list"
	]
]

create-red-expression: function [
	{ Return a red expression matching the expression. }
	expression
][
	if any [
		number? expression
		logic? expression
		none? expression
		expression = 'self
	][
		return expression
	]
	if string? expression [
		; currently only necessary if a literal string is appended to repeatedly
		return to-paren compose [copy (expression)]
	]
	switch expression/type [
		"variable" [
			return to-paren to-word expression/name
		]
		"binary" [
			left: create-red-expression expression/left
			right: create-red-expression expression/right
			return to-paren reduce [left expression/operator right]
		]
		"deferred" [
			statements: create-red-statements expression/list-of-stmts
			sequence: create-sequence statements true
			return append/only copy [] sequence
		]
		"function" [
			return to-paren create-red-function-or-method-call expression
		]
		"list" [
			list-type: determine-list-type first expression/value
			list: switch list-type [
				"map" [
					[copy #(_iter: 0)]
				]
				"list" [
					[copy make hash! [_iter 0]]
				]
			]
			foreach item expression/value [
				either list-type = "map" [ ; map
					if not attempt [
						if item/type = "key-value" [
							list: append copy [extend] list
							append list 'compose
							append/only list compose [(to-set-word item/key) (create-red-expression item/value)]

						]
					][
						print "Error: Cannot add item to map."
						quit
					]	
				][ ; list
					attempt [
						if item/type = "key-value" [
							print "Error: Cannot add key-value item to list."
							quit
						]
					]
					list-item: create-red-expression item
					attempt [
						if block? first list-item [ ; a fudge for deferred blocks
							list-item: first list-item
						]
					]
					list: append copy [append/only] list
					append/only list list-item
				]
			]
			return to-paren list
		]
		"object" [
			; can't fill the fields in until called
			object-code: copy []
			field-names: copy []
			foreach field expression/fields [
				; collect field assignments
				field-name: to-word field/name
				append field-names field-name
				append object-code compose [(to-set-word field-name) (create-red-expression field/expression)]
			]
			; now the methods
			foreach method expression/methods [
				; transpile each of the methods
				body: create-method-body method field-names
				names: to-function-def-names method/template
				foreach name names [
					fnc: reduce [to-set-word name]
					append fnc body
					append object-code fnc
				]
			]
			either expression/extend-obj [ ; extending an object
				object-name: to-word expression/extend-obj/name
				object-code: compose/deep [make (object-name) [(object-code)]]
				; we need the new functions to treat extended fields as /extern
				add-fields: reduce ['find-fields object-name]
				object-code: compose/deep [do replace/all/deep [(object-code)] /extern append copy [/extern] (add-fields)]
			][
				object-code: append/only copy [object] object-code
			]
			return to-paren object-code
		]
	]
]

find-fields: function [
	{ Return a block of the fields of the object. 
	  A field is here defined as not a function. }
	obj [object!]
][
	fields: copy []
	foreach field words-of obj [
		unless (type? select obj field) = function! [
			append fields field
		]
	]
	return fields
]

create-method-body: function [
	{ Return the transpiled body of the method.
	  Need to take into account a self reference (). name = "_" }
	the-method [object!]
	field-names ; these must be object scope/context
][
	method-params: copy []
	foreach name the-method/formal-parameters [
		unless name = "_" [
			append method-params to-word name
		]
	]
	statements: create-red-statements the-method/block/list-of-stmts
	body-sequence: create-sequence statements false
	compose/deep [function [(method-params) /extern (field-names)] [(body-sequence)]]
]

create-method-call: function [
	{ Return the code to indirectly call the correct method. }
	name			"the name of the method"
	actual-params	"the parameters to evaluate and pass"
][
	; don't currently handle recursive or reference method calls
	unless find method-list name [
		return false
	]
	; is the call from a method to a method of the same object?
	; if so generate a simple method call
	self-location: find actual-params 'self
	if self-location [
		unless (index? self-location) = (select method-list name) [
			return false
		]
		remove self-location
		method-call: reduce [to-word name]
		actual-params: create-red-parameters actual-params
		append method-call actual-params
		return method-call
	]
	; otherwise have to dynamically dispatch
	; this could now be dynamic dispatch of an ordinary function call
	actual-params: create-red-parameters actual-params
	compose/deep [
		call-method (name) [(actual-params)] 
	]
]

call-method: function [
	{ Call the correct method. 
	  This is only called at runtime. }
	name 			[string!]	"the method name"
	parameters		[block!]	"the actual parameters"
][
	; currently finds the first parameter with a matching method
	method: to-word name
	the-object: none
	method-parameters: reduce parameters ;find the values, one should be the receiver
	parameter-number: 0
	forall method-parameters [
		parameter-number: parameter-number + 1
		the-object: first method-parameters
		if all [
			object? the-object
			select the-object method
		][
			if (select method-list name) = parameter-number [
				remove method-parameters
				break
			]			
		]
		the-object: none
	]
	method-parameters: head method-parameters
	either the-object [
		the-call: append copy [the-object/:method] method-parameters
	][
		; we either have an error or a function call
		; doesn't currently deal with reference functions
		the-fnc: select function-map name
		unless the-fnc [
			print rejoin [{Error: on method or function call "} name {".} ]
			quit
		]
		the-call: append copy the-fnc/red-code method-parameters
	]
	do the-call
]

deal-with-word-key: function [
	{ A hack to pass a word rather than a value to the get and set-item functions. }
	params
][
	red-params: copy []
	append red-params create-red-expression params/1
	red-params: attempt [
		; the second parameter in both set and get is the index/key
		var-name: params/2/name
		append red-params to-lit-word var-name
	]
	if red-params [
		if (length? params) = 3 [ ; 'set-item
			append/only red-params create-red-expression params/3
		]
		return red-params
	]
	create-red-parameters params
]

create-red-function-call: function [
	{ Return the red equivalent of a function call. }
	name			"the name of the function"
	the-fnc			"the function-object to call"
	actual-params	"the parameters to evaluate and pass"
][
	if all [ ; check if it is a recursive call
		the-fnc/red-code = none
		the-fnc/fnc-def = []
	][ ; at the moment no reference parameters in recursive calls
	   ; also currently don't handle recursive method calls
		red-stmt: to-word name
		red-params: create-red-parameters actual-params
		return compose [(red-stmt) (red-params)]
	]

	either the-fnc/red-code [ ; an ordinary function call
		red-stmt: first the-fnc/red-code
		either (red-stmt = 'get-item) or (red-stmt = 'set-item) [
			red-params: deal-with-word-key actual-params
		][
			red-params: create-red-parameters actual-params
		]
		return compose [(red-stmt) (red-params)]
	][ ; a reference function call
		copy-fnc: copy/deep the-fnc/fnc-def
		formals: the-fnc/formal-parameters
		actual-parameters: copy []
		bind-word: none
		forall formals [
			formal-param: first formals
			actual-param: pick actual-params (index? formals)
			either (first formal-param) = #"#" [
				if actual-param/type <> "variable" [
					print "Error: The actual parameter for a reference parameter must be a variable."
					quit
				]
				bind-word: to-word actual-param/name ; doesn't matter if more than one
				replace/all/deep copy-fnc (to-word formal-param) bind-word
				; there is a potential problem here
				; an existing variable in the function code could have the same name
				; as the actual parameter
			][
				append actual-parameters actual-param
			]
		]
		red-params: create-red-parameters actual-parameters
		compose/deep [do reduce [do bind [(copy-fnc)] quote (bind-word) (red-params)]]
	]
]

create-red-function-or-method-call: function [
	{ Return the red equivalent of a function or method call. }
	remix-call "Includes the name and parameter list"
][
	name: remix-call/fnc-name
	method-call: create-method-call name remix-call/actual-params 
	if method-call [
		return method-call
	]
	; possibly a function call
	the-fnc: select function-map name
	if the-fnc [
		return create-red-function-call name the-fnc remix-call/actual-params
	]
	print rejoin [{Error: no method or function "} name {".} ]
	quit
]

create-red-statements: function [
	{ Return a block of red statements matching the statement objects.}
	statements [block!]
][
	red-statements: copy []
	foreach statement statements [
		if none = attempt [
			switch/default statement/type [
				"assignment" [
					red-expression: create-red-expression statement/expression
					either (first statement/name) = #"#" [ ; ref vars are always "set" explicitly
						append/only red-statements compose [set quote (to-word statement/name) (red-expression)]
					][
						repend/only red-statements [to-set-word statement/name red-expression]
					]
				]
				"return" [
					red-expression: create-red-expression statement/expression
					append/only red-statements compose [throw/name (red-expression) 'return]
				]
				"redo" [
					append/only red-statements [continue]
				]
			][
				append/only red-statements create-red-expression statement
			]
		][ ; for simple expressions of numbers, logic, strings
			append/only red-statements create-red-expression statement
		]
	]
	red-statements
]

create-param-lists: function [
	{ Convert a string of parameter names into equivalent words. }
	parameters [block!]
][
	param-words: copy []
	ref-param-words: copy []
	foreach word parameters [
		either (first word) = #"#" [
			append ref-param-words to-word word
		][
			append param-words to-word word
		]
	]
	reduce [param-words ref-param-words]
]

create-function-body: function [
	{ Return the transpiled body of the function. }
	the-fnc [object!]
	fnc-params [block!]
][
	statements: create-red-statements the-fnc/block/list-of-stmts
	body-sequence: create-sequence statements the-fnc/return-higher
	compose/deep [function [(fnc-params)] [(body-sequence)]]
]

transpile-normal-function: function [
	{ Transpile this normal function. 
	  Now handles multi-named functions. }
	fnc-name [string!]
	the-fnc [object!]
	fnc-params [block!]
][
	name: to-word fnc-name
	unless the-fnc/red-code [
		body: create-function-body the-fnc fnc-params
		set name do body ; this is where the red equivalent function is defined
		the-fnc/red-code: reduce [name]
	]
]

transpile-reference-function: function [
	{ Transpile this reference function. 
	  Now handles multi-name ref functions. }
	the-fnc [object!]
	fnc-params [block!]
	ref-params [block!]
][
	if (length? the-fnc/fnc-def) = 0 [
		body: create-function-body the-fnc fnc-params
		the-fnc/fnc-def: body
	]
]

transpile-functions: function [
	{ Transpile all of the Remix code functions.
	  Now deals with all reference functions first to prevent ordering issues.
	  Still have to be careful if a reference function calls another reference function.
	  	In this case ordering is still important.
	  The resulting Red statements get stored in the red-code path. }
	function-map [map!]
][
	normal-functions: copy []
	reference-functions: copy []
	foreach fnc keys-of function-map [
		the-fnc: select function-map fnc
		if the-fnc/red-code = none [ ; built-in functions have a value here
			if the-fnc/block/type <> "sequence" [
				print rejoin [{Error:"} fnc {"is not a sequence.}]
				quit
			]
			param-lists: create-param-lists the-fnc/formal-parameters
			fnc-params: first param-lists
			ref-params: second param-lists
			either ref-params = [] [
				repend/only normal-functions [fnc the-fnc fnc-params]
			][
				repend/only reference-functions [the-fnc fnc-params ref-params]
			]
		]
	]
	foreach fnc-info reference-functions [
		the-fnc: first fnc-info
		fnc-params: second fnc-info
		ref-params: third fnc-info
		transpile-reference-function the-fnc fnc-params ref-params
	]
	foreach fnc-info normal-functions [
		fnc-name: first fnc-info
		the-fnc: second fnc-info
		fnc-params: third fnc-info
		transpile-normal-function fnc-name the-fnc fnc-params
	]
]

transpile-main: function [
	ast [block!]
][	; the main program is a sequence-stmt
	ast: first ast
	if ast/type <> "sequence" [
		print "Error: The main program is not a sequence."
		quit
	]
	statements: create-red-statements ast/list-of-stmts
	create-sequence statements false
]