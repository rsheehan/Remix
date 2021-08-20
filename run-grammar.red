Red [Title: "run-grammar"]

do %remix-grammar.red

file: to-file trim system/options/args/1

print ["FILENAME:" file]

; print "SOURCE CODE"
; print read file

first-pass: parse (rejoin [copy "^/" read file copy "^/"]) split-words
clean-lex: tidy-up first-pass
lex-symbols: spit-out-symbols clean-lex

; print "^/LEX OUTPUT"
; ?? lex-symbols

print "^/PARSE"
; parse-trace lex-symbols program
result: parse lex-symbols program
?? result
print ""
either result [
	print "Parsing succeeded."
][
	print "Parsing failed."
]