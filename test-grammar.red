Red [Title: "test-grammar"]

do %remix-grammar.red

files: [
	; %standard-lib.rem
	; %ex/factorial.rem
	; %ex/factorial2.rem
	; %ex/primes.rem
	; %ex/test1.rem
	; %ex/test2.rem
	; %ex/test3.rem
	; %ex/test4.rem
	; %ex/test5.rem
	; %ex/test6.rem
	; %ex/test7.rem
	; %ex/test8.rem
	; %ex/test9.rem
	; %ex/test10.rem
	; %ex/test11.rem
	; %ex/test12.rem
	; %ex/test13.rem
	; %ex/test14.rem
	; %ex/test15.rem
	; %ex/test16.rem
	; %ex/test17.rem
	; %ex/test18.rem
	; %ex/test19.rem
	; %ex/test20.rem
	; %ex/test21.rem
	; %ex/test22.rem
	; %ex/test23.rem
	; %ex/test24.rem
	; %ex/test25.rem
	; %ex/test26.rem
	; %ex/test27.rem
	; %ex/test28.rem
	; %gr/drawing.rem
	; %gr/arrows.rem
	; %gr/squares.rem
	; %gr/bounce.rem
	%temp.rem
	; %ob/obj-demo.rem
]

foreach file files [
	print ["FILENAME:" file]

	; print "SOURCE CODE"
	; print read file

	first-pass: parse (append append copy "^/" read file copy "^/") split-words
	clean-lex: tidy-up first-pass
	lex-symbols: spit-out-symbols clean-lex

	; print "^/LEX OUTPUT"
	; ?? lex-symbols

	print "^/PARSE"
	; parse-trace lex-symbols program
	result: parse lex-symbols program
	?? result
	print ""
	if not result [quit]
]