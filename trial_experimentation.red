Red [needs: view]



; ======================================================================================================

; {if you uncomment the next line

; you will have to click on "Show" after

; clicking on "Hello" to turn it into "Good bye"}



; ;system/view/auto-sync?: off



; view/no-wait [

; a: button "Hello" [a/text: "Good bye"]

; button "Show" [show a]

; do [
;   print "Waiting started for first view"
;   wait 10
;   print "Waiting ended for first view"
; ]
; ]

;   print "Waiting started for in-between"
;   wait 10
;   print "Waiting ended for in-between"

; view/no-wait [

; b: button "Hello" [b/text: "Good bye"]

; button "Show" [show b]

; do [
;   print "Waiting started for second view"
;   wait 10
;   print "Waiting ended for second view"
; ]
; ]

; do-events

; Lesson - Faces will not be updated until 'do-events' is called because other
; code is being executed and the event loop is not running.

; =======================================================================================================

; view [
;   a: base 
;   do [
;     a/draw: [[[line 60x10 10x60]]]
;   ]
; ]

; Lesson: 'draw' is a field of the 'a' 'object'/'face'. So it can be changed using the path
; notation. Also, the 'draw' command can execute commands from blocks inside blocks.

; ======================================================================================================


; command: [pen red fill-pen blue]



; view/no-wait [                

;    canvas: base 100x100

; ]

; {the "no-wait" refinement above allows the

; script do create the view (base) and then keep

; going, to the nested "repeats" below.

; Without "no-wait" the script would stay in the

; "view" block}



; repeat x 8 [

;    repeat y 8 [

;        position:(x * 11x0) + (y * 0x11)

;        append command reduce ['circle position 4]

;    ]

; ]



; canvas/draw:  command

; probe command {just to show you what was sent to draw.

; you must use probe instead of print, because print

; tries to evaluate things, and "pen" and "circle" have

; no value}

; wait 3

; do-events

; Learning: Solidifies learning from the program above the one immediately above

; ======================================================================================================

; view/no-wait [

;    canvas: base 100x100

; ]

; wait 2
; canvas/color: yellow

; do-events
; wait 2

; Learning: the options passed to a face are actually fields of the face (like fields of objects)

; ======================================================================================================


