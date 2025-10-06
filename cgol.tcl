#!/usr/bin/env tclsh

# Constants for grid size and density
set width 50
set height 30
set density 0.2

# Global array for the grid
array set grid {}

# Initialize the grid with random alive or dead cells
proc initialize_grid {} {
    global grid width height density
    for {set y 0} {$y < $height} {incr y} {
        for {set x 0} {$x < $width} {incr x} {
            set grid($y,$x) [expr {rand() < $density ? 1 : 0}]
        }
    }
}

# Print the grid to the console
proc print_grid {} {
    global grid width height
    # ANSI escape code to clear screen and move cursor to top-left
    puts -nonewline "\033\[H\033\[2J"
    for {set y 0} {$y < $height} {incr y} {
        for {set x 0} {$x < $width} {incr x} {
            if {$grid($y,$x) == 1} {
                puts -nonewline "█"
            } else {
                puts -nonewline " "
            }
        }
        puts ""
    }
    flush stdout
}

# Count alive neighbors for a cell at (y, x) with toroidal wrapping
proc count_neighbors {y x} {
    global grid width height
    set count 0
    for {set dy -1} {$dy <= 1} {incr dy} {
        for {set dx -1} {$dx <= 1} {incr dx} {
            if {$dx == 0 && $dy == 0} continue
            set ny [expr {($y + $dy + $height) % $height}]
            set nx [expr {($x + $dx + $width) % $width}]
            if {$grid($ny,$nx)} { incr count }
        }
    }
    return $count
}

# --- Main execution loop ---
initialize_grid
while {1} {
    print_grid
    
    # Compute the next generation into a temporary array
    array set new_grid {}
    for {set y 0} {$y < $height} {incr y} {
        for {set x 0} {$x < $width} {incr x} {
            set alive $grid($y,$x)
            set neighbors [count_neighbors $y $x]
            if {($alive && ($neighbors == 2 || $neighbors == 3)) || (!$alive && $neighbors == 3)} {
                set new_grid($y,$x) 1
            } else {
                set new_grid($y,$x) 0
            }
        }
    }
    
    # Update grid for the next iteration
    array set grid [array get new_grid]
    
    # Pause between generations (100ms).
    # 'exec' is used for portability on Unix-like systems.
    exec sleep 0.1
}