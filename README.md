# Remix
<img width="410" alt="Landscape" src="https://user-images.githubusercontent.com/3459269/118350983-80372780-b5ad-11eb-80ba-7072962a29ef.png">

Remix is a flexible programming language based around the idea of mix-fix (as opposed to post-fix) function names, with as many space separated words and parameters as you want. This means that there is a very straightforward path from designing a program in natural language pseudocode and transitioning it to running Remix code.

Here is an animated random landscape program in Remix.

    Generate a landscape with mountains and drifting clouds.
    -------------------------------------------------------
    
    randomize

    on standard (sky) paper
    draw the landscape
    animate the clouds

    ==================

    draw the landscape :
        draw the back mountains
        draw the front mountains

    draw the back mountains :
        draw on layer 2
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
        mountain : make shape of {
            { centre, peak },
            { centre + width ÷ 2, std-height - level },
            { centre - width ÷ 2, std-height - level }
        } with size 1
        mountain [colour] : colour
        fill (mountain)

    ==================

    the-clouds : apply [create a cloud] 10 times

    animate the clouds :
        animate 10 times per sec
            clear layer 1
            no outline
            for each (cloud) in (the-clouds)
                cloud [move]
                cloud [draw]

    create a cloud :
        base : random (std-height)
        across : random (std-width)
        radius1 : random 10 + 30
        radius2 : random 10 + 20
        distance : 10
        if (heads)
            (radius1) ⇆ (radius2)
        {
            radius1 : radius1,
            radius2 : radius2,
            x1 : (across - radius1) + distance,
            x2 : (across + radius2) - distance,
            y1 : base - radius1,
            y2 : base - radius2,
            draw : [ draw cloud of (radius1) and (radius2) at {x1, y1} and {x2, y2} ],
            move : [ advance cloud positions (x1) and (x2) ]
        }

    draw cloud of (radius1) and (radius2) at (pos1) and (pos2) :
        draw (white) circle of (radius1) at (pos1)
        draw (white) circle of (radius2) at (pos2)
        draw (white) box from {pos1 [1], pos1 [2] + radius1} to (pos2)

    advance cloud positions (#x1) and (#x2) :
        inc (x1)
        inc (x2)
        
    ==================

    show paper
