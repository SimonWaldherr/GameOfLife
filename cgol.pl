#!/usr/bin/env perl

use strict;
use warnings;
use Time::HiRes qw(usleep);
use List::Util qw(shuffle);

# Constants for the grid size and density of alive cells
my $width = 50;
my $height = 30;
my $density = 0.2;

# Function to initialize the grid with random alive or dead cells
sub initializeGrid {
    my @grid;
    for my $y (0 .. $height-1) {
        for my $x (0 .. $width-1) {
            $grid[$y][$x] = rand() < $density ? 1 : 0;
        }
    }
    return \@grid;
}

# Function to count the number of alive neighbors around a given cell
sub countNeighbors {
    my ($grid, $x, $y) = @_;
    my $count = 0;

    for my $dx (-1 .. 1) {
        for my $dy (-1 .. 1) {
            next if $dx == 0 && $dy == 0;  # Skip the cell itself
            my $nx = ($x + $dx + $width) % $width;
            my $ny = ($y + $dy + $height) % $height;
            $count++ if $grid->[$ny][$nx];
        }
    }
    return $count;
}

# Function to compute the next state of the grid based on the Game of Life rules
sub computeNextState {
    my ($grid) = @_;
    my @newGrid;

    for my $y (0 .. $height-1) {
        for my $x (0 .. $width-1) {
            my $alive = $grid->[$y][$x];
            my $neighbors = countNeighbors($grid, $x, $y);

            # Apply Game of Life rules:
            # - Any live cell with 2 or 3 neighbors survives.
            # - Any dead cell with exactly 3 neighbors becomes alive.
            # - All other cells die or stay dead.
            $newGrid[$y][$x] = ($alive && $neighbors == 2) || $neighbors == 3 ? 1 : 0;
        }
    }
    return \@newGrid;
}

# Function to print the grid to the console
sub printGrid {
    my ($grid) = @_;
    for my $row (@$grid) {
        for my $cell (@$row) {
            print $cell ? '█' : ' ';
        }
        print "\n";
    }
}

# Main loop
my $grid = initializeGrid();

while (1) {
    printGrid($grid);
    $grid = computeNextState($grid);
    usleep(100000);  # Pause for 100 milliseconds

    # Clear the screen
    print "\033[H\033[2J";
}
