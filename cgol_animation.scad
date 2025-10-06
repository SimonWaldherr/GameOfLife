// cgol_animation.scad — fast preview animation in OpenSCAD
// Usage: enable OpenSCAD’s Design → Animate (e.g. FPS=8, Steps=80)

// Parameters
fps        = 10;     // Preview frames per second
max_steps  = 80;     // How many generations to cycle through
cell       = 3;      // Cell edge length (mm)
width      = 30;     // Grid width
height     = 30;     // Grid height

// Helper functions

// Sum of a list (tail-recursive)
function sum(v, i=0, acc=0) = (i == len(v)) ? acc : sum(v, i+1, acc + v[i]);

// Count neighbors via list comprehension (toroidal wrap)
function count_n(g, x, y) =
    let(
        terms = [
            for (dy = [-1:1], dx = [-1:1])
                if (!(dx == 0 && dy == 0))
                    g[(y+dy+height)%height][(x+dx+width)%width]
        ]
    )
    sum(terms);

// Compute next generation
function next_grid(g) =
    [
        for (y = [0:height-1]) [
            for (x = [0:width-1])
                let(n = count_n(g, x, y))
                ((g[y][x] == 1 && (n == 2 || n == 3)) || (g[y][x] == 0 && n == 3)) ? 1 : 0
        ]
    ];

// Recursively get the nth generation
function gen_at(g, n) = (n == 0) ? g : gen_at(next_grid(g), n-1);

// List of all alive-cell coordinates (for sparse rendering)
function alive_coords(g) = [
    for (y = [0:height-1], x = [0:width-1])
        if (g[y][x] == 1) [x, y]
];

// Render only living cells as cubes
module render_alive(coords) {
    for (p = coords)
        translate([p[0]*cell, p[1]*cell, 0])
            cube(cell, center=false);
}

// Initial pattern (seed)

function gen0_cell(x,y) =
    let(gx = floor(width/2)-2, gy = floor(height/2)-2)
    (
        // Glider
        (x==gx+1 && y==gy) ||
        (x==gx+2 && y==gy+1) ||
        (x==gx   && y==gy+2) ||
        (x==gx+1 && y==gy+2) ||
        (x==gx+2 && y==gy+2)
    ) ? 1 : 0;

gen0 = [ for (y=[0:height-1]) [ for (x=[0:width-1]) gen0_cell(x,y) ] ];


// Animate via $t

gen_idx  = floor($t * fps) % max_steps;
current  = gen_at(gen0, gen_idx);
coords   = alive_coords(current);

// Output
render_alive(coords);
