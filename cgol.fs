#!/usr/bin/env dotnet fsi

open System
open System.Threading

let width = 50
let height = 30
let density = 0.2

let initializeGrid () =
    let rand = Random()
    Array.init height (fun _ -> 
        Array.init width (fun _ -> rand.NextDouble() < density))

let countNeighbors (grid: bool[][]) x y =
    let mutable count = 0
    for dx in -1 .. 1 do
        for dy in -1 .. 1 do
            if dx <> 0 || dy <> 0 then
                let nx = (x + dx + width) % width
                let ny = (y + dy + height) % height
                if grid.[ny].[nx] then count <- count + 1
    count

let computeNextState (grid: bool[][]) =
    Array.init height (fun y ->
        Array.init width (fun x ->
            let alive = grid.[y].[x]
            let neighbors = countNeighbors grid x y
            if alive then neighbors = 2 || neighbors = 3 else neighbors = 3))

let printGrid (grid: bool[][]) =
    Console.Clear()
    grid |> Array.iter (fun row ->
        row |> Array.iter (fun cell -> printf "%c" (if cell then '█' else ' '))
        printfn "")

let rec mainLoop grid =
    printGrid grid
    Thread.Sleep(100)
    mainLoop (computeNextState grid)

let grid = initializeGrid()
mainLoop grid
