Red [
	Title: "The Remix Grammar"
	Author: "Robert Sheehan"
	Version: 0.4
	Purpose: { The grammar of Remix.
	Some <tags> are followed by the <tag>'s value. }
]

do %lexer.red

END-OF-FN-CALL: [
	<LINE> | <RBRACKET> | <rparen> | <rbrace> | <comma> | <operator>
]

; should never remove <RBRACKET> or <rparen> except with matching left hand term.
END-OF-STATEMENT: [
	end | <LINE> | ahead [<RBRACKET> | <rparen>]
]

program: [
	some [
		<LINE> | end
		| function-definition
		| statement
	]
]

; e.g.
; say if (a) equals (b): 
;	a = b
function-definition: [
	function-signature
	<colon> opt <colon>
	function-statements 
	<LINE>
]

; e.g. from (start) to (finish) do (block)
; now includes multiple names
function-signature: [
	some [
		<word> string!
		|
		<multi-word> string!
		|
		<varname> string!
		; <lparen> <word> string! <rparen> 
	]
]

function-statements: [
	ahead block! 
	into block-of-statements
]

block-of-statements: [
	any statement
]

deferred-block-of-statements: [ ; only here because of a difference in code generation
	ahead block!
	into block-of-statements
	opt <LINE>
	|
	block-of-statements
]

; functions and blocks can return an expression without the return call
statement: [
	[
		assignment-statement 
		| return-statement
		| redo-statement
		| setter-call
		| list-element-assignment
		| expression
	]
	END-OF-STATEMENT
]

; e.g. abc : something
assignment-statement: [
	<varname> string! 
	<colon> 
	expression
]

; e.g. return a + b
return-statement: [
	<word> "return" opt expression
]

; e.g redo
redo-statement: [
	<word> "redo"
] 

expression: [
	unary-expression not ahead <operator>
	|
	binary-expression
]

; e.g. 4 + a
binary-expression: [
	unary-expression 
	<operator> word!
	expression
]

unary-expression: [
	simple-expression
	|
	<lparen> expression <rparen> 
]

; at the moment a single word is a function call
; after finding the function call we need to see if it should be a variable call instead
simple-expression: [
	list-element
	| create-call
	| function-call 
	; | <word> string!
	| <varname> string!
	| <string> string! 
	| <number> number! 
	| <boolean> logic!
	| literal-list
	|
	<LBRACKET>
	deferred-block-of-statements
	<RBRACKET>
]

; e.g. a-list [ any ] : value
list-element-assignment: [
	<word> string!
	<LBRACKET> [ahead block! into expression] <RBRACKET>
	<colon>
	expression
]

; e.g. a-list [3]
list-element: [
	<word> string!
	<LBRACKET> [ahead block! into expression] <RBRACKET>
	[end | ahead END-OF-FN-CALL]
]

; e.g. 
;create
;	a : 4
;	pr (me) :
;		show (a)
create-call: [
	<word> ["create" | "extend" <lparen> simple-expression <rparen>]
	ahead block! into object-body
	[end | ahead END-OF-FN-CALL]
]

object-body: [
	some [
		[
			object-field
			|
			object-field-getter
			|
			object-field-setter
			|
			object-field-getter-setter
		]
		END-OF-STATEMENT
		|
		object-method
	]
]

object-field: [
	<word> string! <colon> expression
]

; Just a list of field names
get-fields-list: [
	any [<word> string! END-OF-STATEMENT]
]

; e.g.
; getter
; 	x
object-field-getter: [
	<word> ["getter" | "getters"] ahead block! into get-fields-list
]

; e.g.
; setter
; 	x
object-field-setter: [
	<word> ["setter" | "setters"] ahead block! into get-fields-list
]

; e.g.
; getter/setter
; 	x
object-field-getter-setter: [
	<multi-word> ["getter/setter" | "getters/setters"] ahead block! into get-fields-list
]

object-method: [
	method-signature
	<colon>
	method-statements 
	opt <LINE>
]

method-signature: [ ; almost same as function-signature, but different actions
	some [
		<word> string!
		|
		<multi-word> string!
		|
		[
			<lparen> <word> ["me" | "my"] <rparen>
			|
			<lparen> <word> string! <rparen> 
		]
	]
	opt [<colon> <lparen> <word> string! <rparen>] ; for setter methods
]

method-statements: [ ; same as function-statements, but different actions
	ahead block! 
	into block-of-statements
]

; e.g.
;	(x) number : 7
; also
;	x's number : 7 ; because of work by lexer.red
setter-call: [
	; Not designed to allow callee to be "me" or "my".
	; Assuming if in the object we just use the field directly.
	<lparen> <word> string! <rparen> <word> string! <colon> expression
	[end | ahead END-OF-FN-CALL]
]

function-call: [
	[
		<word> string! [end | ahead END-OF-FN-CALL]
		|
		2 20 [ ; currently a max of 20 parts to a function call
			<word> string!
			|
			; for a self method call
			<lparen> <word> ["me" | "my"] <rparen>
			| <varname> string!
			; a literal parameter
			| <string> string! | <number> number! | <boolean> logic! | literal-list

			; the next 4 are block parameters

			| <LBRACKET> ahead block! into deferred-block-of-statements <LINE> <RBRACKET> 
			| opt <cont> ahead block! into deferred-block-of-statements opt [<LINE> <cont>]
			| <LBRACKET> deferred-block-of-statements <RBRACKET> 
			| <lparen> <LBRACKET> deferred-block-of-statements <RBRACKET> <rparen>

			| <lparen> expression <rparen> 
		]
		[end | ahead END-OF-FN-CALL]
	]
]

literal-list: [
	<lbrace> into list <rbrace> ; "into" added for lexer 3
]

key-value: [
	[
		<string> string! 
		| 
		<word> string!
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
	key-value
	|
	expression
]

list: [
	list-item any [any [<comma> | <LINE>] list-item]
	|
	none
]