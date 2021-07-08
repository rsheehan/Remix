Red [
	Title: "test-grammar"
	Needs: view
]

files: [
	"ex/factorial.rem"
	"ex/factorial2.rem"
	"ex/primes.rem"
	"ex/test1.rem"
	"ex/test2.rem"
	"ex/test3.rem"
	"ex/test4.rem"
	"ex/test5.rem"
	"ex/test6.rem"
	"ex/test7.rem"
	"ex/test8.rem"
	"ex/test9.rem"
	"ex/test10.rem"
	"ex/test11.rem"
	"ex/test12.rem"
	"ex/test13.rem"
	"ex/test14.rem"
	"ex/test15.rem"
	"ex/test16.rem"
	"ex/test17.rem"
	"ex/test18.rem"
	"ex/test19.rem"
	"ex/test20.rem"
	"ex/test21.rem"
	"ex/test22.rem"
	"ex/test23.rem"
	"ex/test24.rem"
	"ex/test25.rem"
	"ex/test26.rem"
	"ex/test27.rem"
	"ex/test28.rem"
	"ex/test29.rem"
	"ex/test29b.rem"
	"ex/test30.rem"
	"ex/test31.rem"
	"ex/test32.rem"
	"ex/test33.rem"
	"ex/test34.rem"
	; "ex/drawing.rem"
]

foreach file files [
	command: append copy "remix " file ;"red remix-test.red " file
	call/console/shell command
	print "DONE^/"
]