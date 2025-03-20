#!/usr/bin/env ocaml
#directory "+unix";;
#load "unix.cma";;

open Unix

(* Conway's Game of Life *)

let width = 50
let height = 30
let density = 0.2

(* Initialize the grid with random values *)
let init_grid () =
  Array.init height (fun _ ->
    Array.init width (fun _ -> Random.float 1.0 < density)
  )

(* Count the number of alive neighbors of a cell *)
let count_neighbors grid x y =
  let count = ref 0 in
  for dx = -1 to 1 do
    for dy = -1 to 1 do
      if dx <> 0 || dy <> 0 then (* Ignore the cell itself *)
        let nx = (x + dx + width) mod width in
        let ny = (y + dy + height) mod height in
        if grid.(ny).(nx) then incr count
    done
  done;
  !count

(* Compute the next generation *)
let next_generation grid =
  Array.init height (fun y ->
    Array.init width (fun x ->
      let alive = grid.(y).(x) in
      let neighbors = count_neighbors grid x y in
      (alive && (neighbors = 2 || neighbors = 3)) || ((not alive) && neighbors = 3)
    )
  )

(* Print the grid to the console *)
let print_grid grid =
  Printf.printf "\027[H\027[2J"; (* ANSI escape code to clear the screen *)
  Array.iter (fun row ->
    Array.iter (fun cell ->
      Printf.printf "%s" (if cell then "█" else " ")
    ) row;
    Printf.printf "\n"
  ) grid;
  flush Stdlib.stdout (* Ensure output is displayed immediately *)

(* Main game loop *)
let rec game_loop grid =
  print_grid grid;
  sleepf 0.1;  (* Sleep for 0.1 seconds *)
  game_loop (next_generation grid)

(* Entry point of the script *)
let () =
  Random.self_init ();
  let grid = init_grid () in
  game_loop grid;;
