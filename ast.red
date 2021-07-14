Red [
	Title: "Abstact Syntax Tree"
	Author: "Robert Sheehan"
	Version: 0.3
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

remix-object: object [
    type: "object"
    fields: [] ; list of key-value pairs?
    methods: [] ; list of method-objects
    extend-obj: none ; the object to extend
    extend-fields: [] ; fields of an extended object which could be referenced in new methods
]

assignment-stmt: object [
    type: "assignment"
    name: ""
    expression: none ; the expression to evaluate and assign
]

field-initializer: object [
    type: "field"
    name: ""
    expression: none ; the initial value of the field
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