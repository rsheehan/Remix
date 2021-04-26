# Remix

Remix is a flexible programming language based around the idea of mix-fix (as opposed to post-fix) function names, with as many space separated words and parameters as you want. This means that there is a very straightforward path from designing a program in natural language pseudocode and transitioning it to running Remix code.

Here is the rainfall problem in Remix.

    The rainfall problem.  
    =====================

    rain-fall : {-1, -3, 0, 5, -2, 1.0, 0, -1, 6, 7, 999, -2, 0, 10}

    { "Original data: ", (rain-fall) as list } ⮐

    positive-rain-fall : filter (rain-fall) by (x) where [ x ≥ 0 ]
    valid-rain-fall : keep (x) from (positive-rain-fall) until [ x = 999 ]

    { "Clean data: ", (valid-rain-fall) as list } ⮐

    count : length of (valid-rain-fall)
    if (count = 0) [
    	"No valid data." ⮐
    ] otherwise [
    	{ "The average rainfall is ", sum (valid-rain-fall) ÷ count } ⮐
    ]
