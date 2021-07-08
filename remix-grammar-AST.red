Red [
	Title: "The Remix Grammar"
	Author: "Robert Sheehan"
	Version: 0.3
	Purpose: "The grammar of Remix creating AST. This is used by the transpiler. "
]

do %lexer.red
do %ast.red
do %function-functions.red
do %built-in-functions.red

END-OF-LINE: [<LINE> | <*LINE>]

END-OF-FN-CALL: [
	END-OF-LINE | <RBRACKET> | <rparen>  | <rbrace> | <comma> | <operator>
]

; should never remove <RBRACKET> or <rparen> except with matching left hand term.
END-OF-STATEMENT: [
	[end | END-OF-LINE] | ahead [<RBRACKET> | <rparen>]
]

program: [
	(
		; the function-map is in %built-in-functions.red
		program-statements: make sequence-stmt []
		object-stack: copy [] ; to included nested objects
	)
	some [
		<LINE> | end
		| function-definition
		| collect set next-statement statement 
		(append program-statements/list-of-stmts first next-statement)
	]
	keep (program-statements)
]

; e.g. 
;say if (a) equals (b):
;	a = b
function-definition: [
	(
		new-function: make function-object [] ; safe, as no nested function defs
	)
	function-signature ; fills in new-function/template
	<colon> opt [<colon> (new-function/return-higher: true)]
	function-statements ; fills in new-function/block
	END-OF-LINE
	(
		insert-function new-function
	)
]

; e.g. from (start) to (finish) do (block)
; now includes multiple names
function-signature: [
	some [
		<word> set name-part string!
		(
			append new-function/template name-part
		)
		|
		<multi-word> set multi-name-part string!
		(
			; split the multi-name-part into its two strings
			multi-names: split multi-name-part "/"
			append/only new-function/template multi-names
		)
		|
		<lparen> <word> set param-name string! <rparen> 
		(
			append new-function/template "|"
			append new-function/formal-parameters param-name
		)
	]
]

function-statements: [
	ahead block! 
	collect set fnc-block into block-of-statements
	(
		new-function/block: first fnc-block
	)
]

block-of-statements: [
	collect set stmt-block any statement
	keep (
		make sequence-stmt [
			list-of-stmts: stmt-block
		]
	)
]

deferred-block-of-statements: [
	collect set sequence block-of-statements
	keep (
		sequence: first sequence
		sequence/type: "deferred"
		sequence
	)
]

; functions and blocks can return an expression without the return call
statement: [
	[
		assignment-statement ; this keeps an "assignment-stmt"
		| return-statement ; this keeps a "return-stmt"
		| redo-statement ; this keeps a "redo-stmt"
		| setter-call ; this keeps the function call to a setter method
		| expression ; this keeps an expression - a variety of statements
	]
	END-OF-STATEMENT
]

; e.g. abc : something
assignment-statement: [
	collect set parts [
		<word> keep string! 
		<colon> 
		keep expression
	]
	keep (
		var-name: first parts
		expr: second parts
		make assignment-stmt [
			name: var-name
			expression: expr
		]
	)
]

; e.g. return a + b
return-statement: [
	<word> "return" collect set expr opt expression
	keep (
		make return-stmt [
			expression: first expr
		]
	)
]

; e.g redo
redo-statement: [
	<word> "redo"
	keep (
		redo-stmt
	)
] 

expression: [ ; keeps an expression
	collect set expr unary-expression not ahead <operator>
	keep (first expr)
	|
	collect set expr binary-expression
	keep (
		left-operand: first expr
		op: second expr
		right-operand: third expr
		make get op [ ; e.g addition
			left: left-operand
			right: right-operand
		]
	)
]

; e.g. 4 + a
binary-expression: [
	collect set operand1 unary-expression
	keep (first operand1)
	<operator> keep word!
	collect set operand2 expression
	keep (first operand2)
]

unary-expression: [
	simple-expression
	|
	<lparen> expression <rparen> 
]

; at the moment a single word is a function call
; after finding the function call we need to see if it should be a variable call instead
simple-expression: [
	list-element-assignment
	|
	list-element
	|
	create-call
	|  
	function-call
	|
	<word> set var-name string!
	keep (
		; only get here because of the heuristic rejecting a single word function if not declared
		make variable [
			name: var-name
		]
	)
	| 
	<string> keep string! 
	| 
	<number> keep number! 
	| 
	<boolean> keep logic!
	|
	literal-list
]

; e.g. a-list [ any ] : value
; This is really a function call with name: "|_|_|"
list-element-assignment: [
	collect set fnc-template [
		keep ("|")
		<word> set list-name string!
		keep (
			make variable [
				name: list-name
			]
		)
		keep ("|")
		<LBRACKET> collect set expr expression <RBRACKET>
		keep (expr)
		<colon>
		keep ("|")
		collect set expr expression
		keep (expr)
	]
	keep (
		assist-create-function-call fnc-template
	)
]

; e.g. a-list [3]
; This is really a function call with name: "|_|"
; It could be a mistaken "name block" function call so this needs to be checked for.
list-element: [
	collect set fnc-template [
		keep ("|")
		<word> set list-name string!
		keep (
			make variable [
				name: list-name
			]
		)
		keep ("|")
		<LBRACKET> collect set expr expression <RBRACKET>
		[end | ahead END-OF-FN-CALL]
		keep (expr)
	]
	keep (
		name: copy get in second fnc-template 'name
		name: append name "_|"
		if select function-map name [ ; this is the check
			print ["Warning: There is a function with this name -" name]
		]
		result-fnc: assist-create-function-call fnc-template
	)
]

; e.g. 
;create
;	a : 4
;	pr () :
;		show (a)
create-call: [
	<word> "create" 
	(
		new-object: make remix-object [] ; can nest objects
		append object-stack new-object
	)
	ahead block! into [object-body]
	[end | ahead END-OF-FN-CALL]
	keep (
		take/last object-stack
	)
]

object-body: [
	any [
		object-field END-OF-STATEMENT
		|
		object-method
	]
]

object-field: [
	collect set parts [
		<word> keep string! 
		<colon> 
		keep expression
	]
	(
		field-name: first parts
		expr: second parts
		new-object: last object-stack
		append new-object/fields make field-initializer [
			name: field-name
			expression: expr
		]
	)
]

object-method: [
	; create a method-object, safe as not nested
	(
		new-method: make method-object []
	)
	method-signature
	<colon>
	method-statements 
	END-OF-LINE
	(
		add-to-method-list new-method
		new-object: last object-stack
		append new-object/methods new-method
	)
]

method-signature: [ ; same as function-signature, but different actions
	(
		param-position: 1
		self-position: 0
	)
	some [ ; gather the signature
		<word> set name-part string!
		(
			append new-method/template name-part
		)
		|
		<multi-word> set multi-name-part string!
		(
			; split the multi-name-part into its two strings
			multi-names: split multi-name-part "/"
			append/only new-method/template multi-names
		)
		|
		[
			<lparen> <word> ["me" | "my"] <rparen> ; the object reference
			(
				if self-position <> 0 [
					print rejoin [{Error: method "} new-method/template {" more than one self reference (me/my).}]
					quit ; return if live coding
				]
				self-position: param-position
				param-name: "_"
			)
			| 
			<lparen> <word> set param-name string! <rparen>
		]
		(
			append new-method/template "|"
			append new-method/formal-parameters param-name
			param-position: param-position + 1
		) 
	]
	opt [
		<colon> <lparen> <word> set param-name string! <rparen> ; for setter methods
		(
			append new-method/template "*colon*"
			append new-method/template "|"
			append new-method/formal-parameters param-name
		) 
	]
	; check to see if one of the parameters is the object reference
	(
		either self-position = 0 [
			print rejoin [{Error: method "} new-method/template {" without (me/my) parameter.}]
			quit ; return if live coding
		][
			new-method/self-position: self-position
		]
	)
]

method-statements: [
	ahead block! 
	collect set method-block into block-of-statements ; add the block to the method-object
	(
		new-method/block: first method-block
	)
]

; e.g.
; (x) number : 7
setter-call: [
	; Not designed to allow callee to be "me" or "my".
	; Assuming if in the object we just use the field directly.
	collect set fnc-template [
		<lparen> <word> set callee string! <rparen>
		keep ("|")
		keep (
			make variable [
				name: callee
			]		
		)
		<word> keep string! 
		<colon> 
		keep ("*colon*")
		keep ("|")
		expression
		[end | ahead END-OF-FN-CALL]
	]
	keep (
		assist-create-function-call fnc-template
	)
]

function-call: [
	[
		collect set fnc-template [
			<word> keep string! [end | ahead END-OF-FN-CALL]
		]
		; Could be a variable rather than a single string function name.
		; One heuristic for checking is if the function is already defined.
		; However this means single word function names must be defined before use.
		if (select function-map first fnc-template)
		|
		collect set fnc-template [
			2 20 [
				; currently a max of 20 parts to a function call
				<word> keep string! ; part of the function name the rest are actual parameters
				| 
				[
					<lparen> <word> ["me" | "my"] <rparen> ; for a self method call
					(
						; need to record this for checking in the transpiler
						expr: 'self
					)
					| <string> set string string! 
					(
						expr: string
					)
					| <number> set num number! 
					(
						expr: num
					)
					| <boolean> set bool logic!
					(
						expr: bool
					)
					| collect set expr literal-list

					; the next 4 are block parameters

					| <LBRACKET> ahead block! collect set expr [into deferred-block-of-statements] <*LINE> <RBRACKET> 
					| ahead block! collect set expr [into deferred-block-of-statements] opt [<*LINE> <cont>]
					| <LBRACKET> collect set expr deferred-block-of-statements <RBRACKET> 
					| <lparen> <LBRACKET> collect set expr deferred-block-of-statements <RBRACKET> <rparen>

					| <lparen> collect set expr expression <rparen> 
				]
				keep ("|")
				keep (
					either block? expr [
						first expr
					][
						expr
					]
				)
			]
			[end | ahead END-OF-FN-CALL]
		]
	]
	keep (
		assist-create-function-call fnc-template
	)
]

literal-list: [
	<lbrace> collect set lit-list list <rbrace>
	keep (
		expr: make remix-list [
			value: to-hash lit-list
		]
	)
]

key-value: [
	[
		<string> keep string!
		|
		<word> set key string! keep (to-word key)
	]
	 <colon>
	[
		expression
		|
		<LBRACKET>
		deferred-block-of-statements
		<RBRACKET>
	]
]

list-item: [
	collect set key-and-value key-value
	keep (
		the-key: first key-and-value
		the-value: second key-and-value
		make key-value-pair [
			key: the-key
			value: the-value
		]
	)
	|
	expression
	|
	<LBRACKET>
	deferred-block-of-statements
	<RBRACKET>
]

list: [
	list-item any [<comma> list-item];was list-item opt [<comma> list]
	|
	none
]