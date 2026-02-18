# Conway's Game of Life Implementations

[![DOI](https://zenodo.org/badge/852361755.svg)](https://zenodo.org/doi/10.5281/zenodo.13685438)

## 🎵 Game of Life - The Song

Inspired by this project, I created a song also called "Game of Life"! Listen to it on your favorite platform:

[![YouTube](https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/watch?v=5i7Ki2Op5GA)
[![Spotify](https://img.shields.io/badge/Spotify-1ED760?style=for-the-badge&logo=spotify&logoColor=white)](https://open.spotify.com/album/7BpX3StCpV2qJOLESjJVWR)
[![Apple Music](https://img.shields.io/badge/Apple_Music-FA243C?style=for-the-badge&logo=apple-music&logoColor=white)](https://music.apple.com/us/album/game-of-life-single/1871753460)

---

This Repository contains multiple implementations of Conway's Game of Life, each written in different programming languages. Each implementation follows the same basic logic for simulating the cellular automaton but demonstrates how different languages can approach the problem.

## What is Conway's Game of Life?

Conway's Game of Life is a *cellular automaton* devised by the mathematician John Horton Conway in 1970. It is not a game in the traditional sense — there are no players and no moves. Instead, an initial configuration of cells on an infinite (or wrapping) two-dimensional grid evolves deterministically over discrete time steps according to four simple rules:

1. A live cell with **fewer than two** live neighbours dies (underpopulation).
2. A live cell with **two or three** live neighbours survives to the next generation.
3. A live cell with **more than three** live neighbours dies (overpopulation).
4. A dead cell with **exactly three** live neighbours becomes alive (reproduction).

Despite their simplicity these rules produce astonishing complexity: stable structures, oscillators, gliders that travel across the grid, and even universal Turing-complete constructions. Conway's Game of Life is one of the most famous examples of *emergence* in mathematics and computer science.

All implementations in this repository use a **toroidal grid** (edges wrap around), so the finite grid behaves as if it were infinite in every direction.

## Why Some Implementations are Wonderfully Absurd

Most languages in this repository were designed with general-purpose programming in mind — writing a Game of Life in Python, Go or C is perfectly natural. A few implementations, however, push tools far beyond their intended purpose, which makes them special:

### `cgol.scad` / `cgol.scad.sh` — OpenSCAD
OpenSCAD is a **CAD modelling language** for designing 3D-printable solid objects. It has no concept of a game loop, no terminal output, and no notion of time. To make GoL work here, each generation is rendered as a separate 3D scene, exported as a PNG frame via the command line, and then all frames are stitched together into an animated GIF with ImageMagick. What was meant to describe a coffee-cup holder ends up simulating cellular evolution.

### `cgol.sql.sh` — SQLite
SQL is a **query language for relational databases** — its entire purpose is to filter, join, and aggregate tabular data. The GoL implementation stores the grid in a SQLite table and computes each new generation using a single recursive SQL query with self-joins to count neighbours. The Bash wrapper drives the loop and renders the output. SQL was never meant to animate anything; it does so anyway.

### `cgol.jq` — jq
jq is a **command-line JSON processor**. Its intended use is slicing and filtering JSON documents in shell pipelines — think `curl … | jq '.name'`. It has no loop construct, no mutable state, and no I/O beyond reading stdin and writing stdout. The GoL implementation encodes the grid as a JSON 2D array, computes the next generation entirely within a single jq expression using recursive `reduce` calls, and separates the rendered frame from the next-generation JSON with an ASCII record-separator character — all in one invocation per frame, driven by a tiny Bash loop. It is perhaps the most semantically inappropriate tool in this repository for writing a game.

### Honourable mention: `cgol.lualatex.tex` — LuaLaTeX
LaTeX is a **document typesetting system**. Its job is to produce beautiful PDFs. The LuaLaTeX variant embeds Lua code directly in a `.tex` file to simulate GoL and typesets each generation as a page — producing a flip-book PDF where turning pages advances the simulation. Technically a document. Technically.

## Files

- **`cgol.awk`**: Game of Life in Awk
- **`cgol.c`**: Game of Life in C
- **`cgol.clj`**: Game of Life in Clojure
- **`cgol.cob`**: Game of Life in Cobol
- **`cgol.dart`**: Dart language implementation.
- **`cgol.erl`**: Erlang implementation of GoL.
- **`cgol.exs`**: GoL in Elixir.
- **`cgol.go`**: Implementation using the Go programming language. A version with more features can be found [here](https://github.com/SimonWaldherr/cgolGo). You can find a Version which runs on a Hub75-RGB-LED-Matrix at [github.com/SimonWaldherr/RGB-LED-Matrix](https://github.com/SimonWaldherr/RGB-LED-Matrix).
- **`cgol.java`**: Java-based Game of Life simulation.
- **`cgol.jq`**: Game of Life in jq (toroidal grid, random initialization; uses a Bash wrapper to drive the animation loop).
- **`cgol.js`**: Node.js implementation.
    - there are also three implementations for the browser: [canvas](https://simonwaldherr.github.io/GameOfLife/cgol.js.canvas.html), [webgl](https://simonwaldherr.github.io/GameOfLife/cgol.js.webgl.html) and [wasm](https://simonwaldherr.github.io/GameOfLife/cgol.js.wasm.html) 
- **`cgol.lisp`**: Game of Life in Lisp
- **`cgol.lua`**: Lua script implementation.
- **`cgol.lualatex.tex`**: LuaLaTeX to generate a [Game-of-Life-PDF](https://simonwaldherr.github.io/GameOfLife/cgol.lualatex.pdf).
- **`cgol.ml`**: CGoL in OCaml.
- **`cgol.nim`**: CGoL in Nim.
- **`cgol.pas`**: Pascal implementation.
- **`cgol.php`**: PHP implementation.
- **`cgol.pl`**: Perl language implementation.
- **`cgol.py`**: Python script for simulating the Game of Life. You can find a colorful [PyGame](https://www.pygame.org/) variant at [github.com/SimonWaldherr/RGB-CGOL](https://github.com/SimonWaldherr/RGB-CGOL).
- **`cgol.R`**: R script implementation of the Game of Life.
- **`cgol.rb`**: Ruby script implementation.
- **`cgol.rs`**: Rust-based Game of Life simulation. A very old version is [here](https://github.com/SimonWaldherr/cgol.rs).
- **`cgol.scad`**: run cgol.scad.sh to generate a Game of Life GIF with OpenSCAD.
- **`cgol.sh`**: Bash shell script implementation.
- **`cgol.sql.sh`**: calculate Game of Life with the help of a SQLite database.
- **`cgol.swift`**: Swift programming language implementation.
- **`cgol.tcl`**: Tcl (Tool command language) implementation.
- **`cgol.zig`**: Zig implementation.
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

Language | run with        | or
---------|-----------------|-----
**Awk**  | `./cgol.awk`    | `awk -f cgol.awk`
**C**    | `./cgol.c`      |   
**Clojure** | `./cgol.clj` |  
**Cobol**|                 | `cobc -x cgol.cob; ./cgol`  
**Dart** | `./cgol.dart`   | `dart cgol.dart`
**Erlang** |               | `erlc cgol.erl; erl -noshell -s cgol start -s init stop`
**Go**   | `./cgol.go`     | `go run cgol.go`
**Java** | `./cgol.java`   | `javac cgol.java && java cgol; rm cgol.class; exit`
**JavaScript (Node.js)**   | `./cgol.js` | `node cgol.js`
**jq**   | `./cgol.jq`     | `bash cgol.jq`
**Pascal** | `./cgol.pas`  | `fpc cgol.pas && ./cgol`
**PHP**  | `./cgol.php`    | `php cgol.php`
**Lua**  | `./cgol.lua`    | `lua cgol.lua`
**LuaLaTeX**  |            | `lualatex cgol.lualatex.tex`
**OCaml** | `./cgol.ml`    | 
**Perl** | `./cgol.pl`     | `perl cgol.pl`
**Python** | `./cgol.py`   | `python3 cgol.py`
**R**    | `./cgol.R`      | `Rscript cgol.R`
**Ruby** | `./cgol.rb`     | `ruby cgol.rb`
**Rust** | `./cgol.rs`     | `cargo script cgol.rs`
**Shell/Bash** | `./cgol.sh` | `sh cgol.sh`
**Swift** | `./cgol.swift` | `swift cgol.swift`
**SCAD** | `./cgol.scad.sh` | 
**SQLite** | `./cgol.sql.sh` | 
**Zig**  |                 | `zig run cgol.zig`  


In the case of OpenSCAD there is a special feature.  
Several frames are calculated as PNG and then combined to form an animated GIF.  
The cgol.scad.gif is available here:  
![cgol.scad.gif](https://simonwaldherr.github.io/GameOfLife/cgol.scad.gif)


if you encounter any permission issues, you may need to make the script executable by running `chmod +x <script_name>` before executing the script.

i only tested on macOS, but it should work on any Unix-based system. If not, you are invited to contribute to the repository.

## Features

- **Toroidal Grid**: All implementations use a toroidal grid where the edges wrap around, meaning cells on the edges have neighbors on the opposite edges.
- **Random Initialization**: The grid is initialized randomly with alive cells based on a specified density (default: 20% alive cells).
- **ANSI Escape Sequences**: To create the animation effect, most implementations use ANSI escape sequences to clear the console screen between frames.
- **Simulation Loop**: The simulation runs in an infinite loop, with each iteration updating the grid based on the rules of Conway's Game of Life and displaying the result.

## Contribution

Feel free to add more implementations or improve the existing ones.
