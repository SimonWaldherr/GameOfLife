/**
 * Conway's Game of Life in OpenSCAD
 *
 * To generate images of different generations:
 *   openscad -o gen0.png -Dgen=0 cgol.scad
 *   openscad -o gen1.png -Dgen=1 cgol.scad
 *   ...
 *   openscad -o gen25.png -Dgen=25 cgol.scad
 *
 * This version dynamically computes any requested generation.
 */

gen = 0; // generation can be overridden by -Dgen=N

// Grid dimensions
width = 190;
height = 190;

// Initial grid (Generation 0)
gen0 = [
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
];


// Function to count alive neighbors
function count_neighbors(grid, x, y) =
    grid[(y-1 + height) % height][(x-1 + width) % width] +
    grid[(y-1 + height) % height][x] +
    grid[(y-1 + height) % height][(x+1) % width] +
    grid[y][(x-1 + width) % width] +
    grid[y][(x+1) % width] +
    grid[(y+1) % height][(x-1 + width) % width] +
    grid[(y+1) % height][x] +
    grid[(y+1) % height][(x+1) % width];

// Function to compute the next generation from a given grid
function next_grid(grid) =
    [
        for (y = [0:height-1]) [
            for (x = [0:width-1]) (
                (grid[y][x] == 1 && (count_neighbors(grid, x, y) == 2 || count_neighbors(grid, x, y) == 3)) ||
                (grid[y][x] == 0 && count_neighbors(grid, x, y) == 3) ? 1 : 0
            )
        ]
    ];

// Recursive function to compute the nth generation from the initial grid
function compute_generation(grid, n) =
    n == 0 ? grid : compute_generation(next_grid(grid), n-1);

// Compute the current generation grid dynamically
current_grid = compute_generation(gen0, gen);

// Module to render the grid
module render_grid(g) {
    // Draw a cube for each alive cell
    for (y = [0:height-1]) {
        for (x = [0:width-1]) {
            if (g[y][x] == 1)
                translate([x, y, 0]) cube([1,1,1], center=false);
        }
    }
}

// Render the current grid
render_grid(current_grid);
