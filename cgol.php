#!/usr/bin/env php
<?php

$width = 50;
$height = 30;
$density = 0.2;

// Function to initialize the grid with random alive (true) or dead (false) cells
function initializeGrid() {
    global $width, $height, $density;
    $grid = [];
    for ($y = 0; $y < $height; $y++) {
        $grid[$y] = [];
        for ($x = 0; $x < $width; $x++) {
            $grid[$y][$x] = mt_rand() / mt_getrandmax() < $density;
        }
    }
    return $grid;
}

// Function to count the alive neighbors around a given cell
function countNeighbors($grid, $x, $y) {
    global $width, $height;
    $count = 0;
    for ($dx = -1; $dx <= 1; $dx++) {
        for ($dy = -1; $dy <= 1; $dy++) {
            if ($dx == 0 && $dy == 0) continue;
            $nx = ($x + $dx + $width) % $width;
            $ny = ($y + $dy + $height) % $height;
            if ($grid[$ny][$nx]) {
                $count++;
            }
        }
    }
    return $count;
}

// Function to compute the next generation of the grid
function computeNextState($grid) {
    global $width, $height;
    $newGrid = [];
    for ($y = 0; $y < $height; $y++) {
        $newGrid[$y] = [];
        for ($x = 0; $x < $width; $x++) {
            $neighbors = countNeighbors($grid, $x, $y);
            if ($grid[$y][$x]) {
                $newGrid[$y][$x] = ($neighbors == 2 || $neighbors == 3);
            } else {
                $newGrid[$y][$x] = ($neighbors == 3);
            }
        }
    }
    return $newGrid;
}

// Function to print the grid to the console
function printGrid($grid) {
    global $width, $height;
    for ($y = 0; $y < $height; $y++) {
        for ($x = 0; $x < $width; $x++) {
            echo $grid[$y][$x] ? '█' : ' ';
        }
        echo PHP_EOL;
    }
}

$grid = initializeGrid();
while (true) {
    printGrid($grid);
    $grid = computeNextState($grid);
    usleep(100000);  // Sleep for 100 ms
    system('clear'); // Clear the console (Linux/macOS) or use 'cls' on Windows
}

?>