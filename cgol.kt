#!/usr/bin/env kotlin

import kotlin.random.Random

const val WIDTH = 50
const val HEIGHT = 30
const val DENSITY = 0.2

fun initializeGrid(): Array<BooleanArray> {
    return Array(HEIGHT) { BooleanArray(WIDTH) { Random.nextDouble() < DENSITY } }
}

fun countNeighbors(grid: Array<BooleanArray>, x: Int, y: Int): Int {
    var count = 0
    for (dx in -1..1) {
        for (dy in -1..1) {
            if (dx == 0 && dy == 0) continue
            val nx = (x + dx + WIDTH) % WIDTH
            val ny = (y + dy + HEIGHT) % HEIGHT
            if (grid[ny][nx]) count++
        }
    }
    return count
}

fun computeNextState(grid: Array<BooleanArray>): Array<BooleanArray> {
    return Array(HEIGHT) { y ->
        BooleanArray(WIDTH) { x ->
            val alive = grid[y][x]
            val neighbors = countNeighbors(grid, x, y)
            if (alive) neighbors == 2 || neighbors == 3 else neighbors == 3
        }
    }
}

fun printGrid(grid: Array<BooleanArray>) {
    print("\u001b[H\u001b[2J")
    grid.forEach { row ->
        println(row.map { if (it) '█' else ' ' }.joinToString(""))
    }
}

fun main() {
    var grid = initializeGrid()
    while (true) {
        printGrid(grid)
        grid = computeNextState(grid)
        Thread.sleep(100)
    }
}
