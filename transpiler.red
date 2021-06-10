Red [
	Title: "The Remix Red code generator"
	Author: "Robert Sheehan"
	Version: 0.2
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
		append seq-list statement ;first list-of-statements
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
			sequence: reduce [ ;compose/deep [ ; and forever not quoted
				'forever compose [(seq-list)]
			]
		][
			sequence: reduce [ ;compose/deep [
				'catch/name reduce [
					'forever compose [(seq-list)]
				] quote 'return
			]
		]
	][ ; doesn't need a loop
		either return-higher [
			sequence: compose [ ;compose/deep [
				(seq-list)
			]
		][
			sequence: reduce [ ;compose/deep [
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
		string? expression
		logic? expression
		none? expression
	][
		return expression
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
			; probe to-paren create-red-function-call expression
			return to-paren create-red-function-call expression
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
				either list-type = "map" [ ; object
					if not attempt [
						if item/type = "key-value" [
							list: append copy [extend] list
							; append/only list compose [(to-set-word item/key) (create-red-expression item/value)]
							append list 'compose
							append/only list compose [(to-set-word item/key) (create-red-expression item/value)]

						]
					][
						print "Error: Cannot add item to object."
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
			obj: object [] ; really does make a red object!
			foreach field expression/fields [
				obj: make obj compose [(to-set-word field/name) (create-red-expression field/expression)]
			]
			; now set the obj for each of its methods
			foreach method expression/methods [
				; transpile each of the methods
				body: create-method-body method
				name: to-function-name method/template
				fnc: reduce [to-set-word name]
				append fnc body
				obj: make obj fnc
			]
			return obj
		]
	]
]

create-method-body: function [
	{ Return the transpiled body of the method. }
	the-method [object!]
][
	method-params: copy []
	foreach name the-method/formal-parameters [
		unless name = "_" [
			append method-params to-word name
		]
	]
	statements: create-red-statements the-method/block/list-of-stmts
	body-sequence: create-sequence statements false
	compose/deep [function [(method-params)] [(body-sequence)]]
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
	remix-call "Includes the name and parameter list"
][
	; this needs to be changed to deal with method calls
	the-fnc: select function-map remix-call/fnc-name
	if the-fnc = none [
		; check if the name can be pluralised.
		either (the-fnc: pluralised remix-call/fnc-name) [
			print ["Careful:" remix-call/fnc-name "renamed." ]
		][
			print ["Error:" remix-call/fnc-name "not declared."]
			quit ; change to return for live coding
		]
	]
	if all [ ; check if it is a recursive call
		the-fnc/red-code = none
		the-fnc/fnc-def = []
	][ ; at the moment no reference parameters in recursive calls
		red-stmt: to-word remix-call/fnc-name
		red-params: create-red-parameters remix-call/actual-params
		return compose [(red-stmt) (red-params)]
	]
	either the-fnc/red-code [ ; an ordinary function call
		red-stmt: first the-fnc/red-code
		either (red-stmt = 'get-item) or (red-stmt = 'set-item) [
			red-params: deal-with-word-key remix-call/actual-params
		][
			red-params: create-red-parameters remix-call/actual-params
		]
		return compose [(red-stmt) (red-params)]
	][ ; a reference function call
		copy-fnc: copy/deep the-fnc/fnc-def
		formals: the-fnc/formal-parameters
		actual-parameters: copy []
		bind-word: none
		forall formals [
			formal-param: first formals
			actual-param: pick remix-call/actual-params (index? formals)
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
; I need to carefully work out if we know that "dup" is not required.
; It is required if we assign a "literal" string.
; Is it required if we assign a literal list or map?
					either string? red-expression [
						either (first statement/name) = #"#" [ ; ref vars are always "set" explicitly
							append/only red-statements compose [set quote (to-word statement/name) copy (red-expression)]
						][
							repend/only red-statements [to-set-word statement/name 'copy red-expression]
						]
					][
						either (first statement/name) = #"#" [ ; ref vars are always "set" explicitly
							append/only red-statements compose [set quote (to-word statement/name) (red-expression)]
						][
							repend/only red-statements [to-set-word statement/name red-expression]
						]
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
	{ Transpile this normal function. }
	fnc-name [string!]
	the-fnc [object!]
	fnc-params [block!]
][
	body: create-function-body the-fnc fnc-params
	name: to-word fnc-name
	set name do body ; this is where the red equivalent function is defined
	the-fnc/red-code: reduce [name]
]

transpile-reference-function: function [
	{ Transpile this reference function. }
	the-fnc [object!]
	fnc-params [block!]
	ref-params [block!]
][
	body: create-function-body the-fnc fnc-params
	the-fnc/fnc-def: body
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
				print ["Error:" fnc "is not a sequence."]
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