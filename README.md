# Conway's Game of Life Implementations

[![DOI](https://zenodo.org/badge/852361755.svg)](https://zenodo.org/doi/10.5281/zenodo.13685438)

This Repository contains multiple implementations of Conway's Game of Life, each written in different programming languages. Each implementation follows the same basic logic for simulating the cellular automaton but demonstrates how different languages can approach the problem.

## Files

- **`cgol.c`**: Game of Life in C
- **`cgol.dart`**: Dart language implementation.
- **`cgol.go`**: Implementation using the Go programming language. You can find a Version which runs on a Hub75-RGB-LED-Matrix at [github.com/SimonWaldherr/RGB-LED-Matrix](https://github.com/SimonWaldherr/RGB-LED-Matrix).
- **`cgol.java`**: Java-based Game of Life simulation.
- **`cgol.js`**: Node.js implementation.
    - there are also three implementations for the browser: [canvas](https://simonwaldherr.github.io/GameOfLife/cgol.js.canvas.html), [webgl](https://simonwaldherr.github.io/GameOfLife/cgol.js.webgl.html) and [wasm](https://simonwaldherr.github.io/GameOfLife/cgol.js.wasm.html) 
- **`cgol.lua`**: Lua script implementation.
- **`cgol.php`**: PHP implementation. You can find a PyGame variant at [github.com/SimonWaldherr/RGB-CGOL](https://github.com/SimonWaldherr/RGB-CGOL).
- **`cgol.pl`**: Perl language implementation.
- **`cgol.py`**: Python script for simulating the Game of Life.
- **`cgol.R`**: R script implementation of the Game of Life.
- **`cgol.rb`**: Ruby script implementation.
- **`cgol.rs`**: Rust-based Game of Life simulation.
- **`cgol.sh`**: Bash shell script implementation.
- **`cgol.swift`**: Swift programming language implementation.
- **`stop.sh`**: some implementations can't be stopped with ctrl+c, use this tool in such cases.

## Logic

Each file contains the necessary logic to run a basic Game of Life simulation. The grid is a 2D array of cells, which are either "alive" or "dead." The simulation follows these rules for cell evolution:

1. Any live cell with two or three live neighbors survives.
2. Any dead cell with exactly three live neighbors becomes a live cell.
3. All other live cells die in the next generation, and all other dead cells stay dead.

## Running Each Script

To run each script, ensure the necessary runtime or interpreter for the specific language is installed on your system. 
Each script can be executed directly from the terminal as they contain the necessary [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) line to specify the interpreter. 
Below are the commands to run the scripts in your terminal:

Language | run with | or
---------|----------|-----
**C** | `./cgol.c` |  
**Dart** | `./cgol.dart` | `dart cgol.dart`
**Go** | `./cgol.go` | `go run cgol.go`
**Java** | `./cgol.java` | ```javac cgol.java && java cgol; rm cgol.class; exit```
**JavaScript (Node.js)** | `./cgol.js` | `node cgol.js`
**PHP** | `./cgol.php` | `php cgol.php`
**Lua** | `./cgol.lua` | `lua cgol.lua`
**Perl** | `./cgol.pl` | `perl cgol.pl`
**Python** | `./cgol.py` | `python3 cgol.py`
**R** | `./cgol.R` | `Rscript cgol.R`
**Ruby** | `./cgol.rb` | `ruby cgol.rb`
**Rust** | `./cgol.rs` | `cargo script cgol.rs`
**Shell/Bash** | `./cgol.sh` | `sh cgol.sh`
**Swift** | `./cgol.swift` | `swift cgol.swift`


if you encounter any permission issues, you may need to make the script executable by running `chmod +x <script_name>` before executing the script.

i only tested on macOS, but it should work on any Unix-based system. If not, you are invited to contribute to the repository.

## Features

- **Toroidal Grid**: All implementations use a toroidal grid where the edges wrap around, meaning cells on the edges have neighbors on the opposite edges.
- **Random Initialization**: The grid is initialized randomly with alive cells based on a specified density (default: 20% alive cells).
- **ANSI Escape Sequences**: To create the animation effect, most implementations use ANSI escape sequences to clear the console screen between frames.
- **Simulation Loop**: The simulation runs in an infinite loop, with each iteration updating the grid based on the rules of Conway's Game of Life and displaying the result.

## Contribution

Feel free to add more implementations or improve the existing ones.
