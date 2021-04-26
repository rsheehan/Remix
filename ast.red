Red [
	Title: "Abstact Syntax Tree"
	Author: "Robert Sheehan"
	Version: 0.2
	Purpose: "Nodes for the AST."
]

;==== set up binary operations ====
binary-op: object [
    type: "binary"
    left: none
    right: none
    operator: none
]

arithmetic-boolean: [ ; name: red value
    'addition       +
    'subtraction    -
    'multiplication *
    'division       /
    'modulo         %
    'less-than      <
    'greater-than   >
    'less-equal     <=
    'greater-equal  >=
    'equal          =
    'not-equal      <>
]

until [
    name: take arithmetic-boolean
    op: take arithmetic-boolean
    set name make binary-op [
        operator: op
    ]
    tail? arithmetic-boolean
]
;==== end of binary operations ====

variable: object [
    type: "variable"
    name: ""
]

key-value-pair: object [
    type: "key-value"
    key: ""
    value: none
]

remix-list: object [
    type: "list"
    value: [] ; *** experimental
    ; converted to a hash or a map (object) when creating red-code in the transpiler
]

assignment-stmt: object [
    type: "assignment"
    name: ""
    expression: none ; the expression to evaluate and assign
]

sequence-stmt: object [
    type: "sequence"
    list-of-stmts: []	
]

function-call-stmt: object [
    type: "function"
    fnc-name: ""
    actual-params: [] ; the values of the parameters
    return-higher: false ; if true don't catch returns here, pass them higher
]

redo-stmt: object [ ; forces a sequence-stmt to restart
    type: "redo"
]

return-stmt: object [ ; caught in the function-call-stmt
    type: "return"
    expression: none
]

; print "**** Installed AST"