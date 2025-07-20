#!/usr/bin/env tclsh

# Rastergröße festlegen
set width 50
set height 30

# Zufällige Startkonfiguration
array set grid {}
for {set i 0} {$i < $height} {incr i} {
    for {set j 0} {$j < $width} {incr j} {
        set grid($i,$j) [expr {int(rand() * 3) == 0 ? 1 : 0}]
    }
}

# Anzahl der Iterationen (Generationen)
set generations 5000

# Funktion zur Anzeige des Gitters
proc display_grid {} {
    global grid width height
    # ANSI Escape Code zum Löschen des Bildschirms
    puts "\033\[2J\033\[H"
    for {set i 0} {$i < $height} {incr i} {
        for {set j 0} {$j < $width} {incr j} {
            if {$grid($i,$j) == 1} {
                puts -nonewline "█"
            } else {
                puts -nonewline " "
            }
        }
        puts ""
    }
}

# Funktion zum Zählen der Nachbarn
proc count_neighbors {x y} {
    global grid width height
    set count 0
    for {set dx -1} {$dx <= 1} {incr dx} {
        for {set dy -1} {$dy <= 1} {incr dy} {
            if {$dx == 0 && $dy == 0} {
                continue
            }
            set nx [expr {$x + $dx}]
            set ny [expr {$y + $dy}]
            if {$nx >= 0 && $nx < $height && $ny >= 0 && $ny < $width} {
                incr count $grid($nx,$ny)
            }
        }
    }
    return $count
}

# Hauptschleife
for {set gen 0} {$gen < $generations} {incr gen} {
    puts "Generation: $gen"
    display_grid

    # Nächste Generation vorbereiten
    array unset next_grid;
    for {set i 0} {$i < $height} {incr i} {
        for {set j 0} {$j < $width} {incr j} {
            set neighbors [count_neighbors $i $j]
            if {$grid($i,$j) == 1} {
                if {$neighbors == 2 || $neighbors == 3} {
                    set next_grid($i,$j) 1
                } else {
                    set next_grid($i,$j) 0
                }
            } else {
                if {$neighbors == 3} {
                    set next_grid($i,$j) 1
                } else {
                    set next_grid($i,$j) 0
                }
            }
        }
    }

    # Aktualisieren zur nächsten Generation
    array set grid [array get next_grid]

    # Pause zwischen den Generationen
    after 100
}
