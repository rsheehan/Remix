Red [
	Title: "The Remix Lex Output"
]

do %lexer.red

filename: system/options/args/1
rem-file: to-file filename
print ["input file:" rem-file]

print "SOURCE CODE"
print read rem-file
print newline

; N.B. remember to include the standard-lib eventually
; source: append append "^/" read %standard-lib.rem "^/"
source: "^/"
append append source read rem-file "^/"

first-pass: parse source split-words
print [first-pass newline]
clean-lex: tidy-up first-pass
lex-symbols: spit-out-symbols clean-lex

?? lex-symbols