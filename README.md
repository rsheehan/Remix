# Remix
<img width="410" alt="Landscape" src="https://user-images.githubusercontent.com/3459269/118350983-80372780-b5ad-11eb-80ba-7072962a29ef.png">

Remix is a flexible programming language based around the idea of mix-fix (as opposed to pre-fix or post-fix) function names, with as many space-separated words and parameters as you want. This means that there is a very straightforward path from designing a program in natural language pseudocode and transitioning it to running Remix code.

To keep function calls as readable as possible, there can be many names for the same function. Multiple names are defined with a simple syntax. e.g.

    pause turtles/turtle for (time) secs/sec:
is the function signature for a function which can be called with any of the following statements:

    pause turtles for 5 secs
    pause turtles for 1 sec
    pause turtle for 6 secs
    pause turtle for 1 sec

Objects are created using the following syntax, and can have optional automatically generated getter and setter methods for fields (which are otherwise private). Methods must include a "me" or "my" parameter indicating the receiver.

    create
        field1 : value
        field2 : value

        getter
            field1

        setter
            field2

        (my) method1 :
            body of method

        another type of method on (me) with (param) :
            body of method

More information about Remix can be found in this presentation, [IntroToRemix.pdf](https://github.com/rsheehan/Remix/files/6872199/IntroToRemix.pdf), the first half shows how Remix can be used to develop a program from pseudocode, the second half describes the language.

Here is an animated random landscape program in Remix.

    
    randomize
    
    on standard (sky) paper
    draw together
    	draw the landscape
    
    the-clouds : apply [create a cloud] 10 times
    
    animate the clouds
    show paper
    
    ==================
    
    draw the landscape :
    	draw the back mountains
    	draw the front mountains
    
    draw the back mountains :
    	draw on layer 2
    	no outline
    	repeat 30 times
    		draw a (coal) mountain of max height 200 based at 200
    	draw (coal) box from {0, std-height} to {std-width, std-height - 200}
    
    draw the front mountains :
    	draw on layer 3
    	repeat 20 times
    		if (heads) [ no outline ] otherwise [ draw with (coal) pen ]
    		draw a (gray) mountain of max height 150 based at 150
    
    draw a (colour) mountain of max height (max-height) based at (level) :
    	centre : random (std-width)
    	height : random (max-height)
    	peak : std-height - (height + level)
    	width : random 100 + 250
    	mountain : a shape of {
    		{ centre, peak },
    		{ centre + width ÷ 2, std-height - level },
    		{ centre - width ÷ 2, std-height - level }
    	}
    	(mountain) colour : colour
    	fill (mountain)
    
    ==================
    
    animate the clouds :
    	animate 20 times per sec
    		clear layer 1
    		no outline
    		for each (cloud) in (the-clouds)
    			move (cloud)
    			draw (cloud)
    
    create a cloud :
    	base : random (std-height)
    	across : random (std-width)
    	r1 : random 10 + 30
    	r2 : random 10 + 20
    	distance : 10
    	if (heads)
    		(r1) ⇆ (r2)
    
    	create
    		a-radius : r1
    		b-radius : r2
    		x1 : (across - r1) + distance
    		x2 : (across + r2) - distance
    		y1 : base - r1
    		y2 : base - r2
    
    		draw (me) :
    			draw (white) circle of (a-radius) at {x1, y1}
    			draw (white) circle of (b-radius) at {x2, y2}
    			draw (white) box from {x1, y1 + a-radius} to {x2, y2}
    
    		move (me) :
    			inc (x1)
    			inc (x2)
    			if ((x1 - a-radius) > std-width)
    				back : 0 - b-radius
    				x1 : back - (x2 - x1)
    				x2 : back
    
