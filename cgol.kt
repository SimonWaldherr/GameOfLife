import kotlin.random.Random

const val WIDTH = 50
const val HEIGHT = 30
const val DENSITY = 0.2

typealias Grid = Array<BooleanArray>

fun initializeGrid(): Grid =
    Array(HEIGHT) { BooleanArray(WIDTH) { Random.nextDouble() < DENSITY } }

fun countNeighbors(grid: Grid, x: Int, y: Int): Int {
    var count = 0

    for (dy in -1..1) {
        for (dx in -1..1) {
            if (dx == 0 && dy == 0) continue

            val nx = (x + dx + WIDTH) % WIDTH
            val ny = (y + dy + HEIGHT) % HEIGHT
            if (grid[ny][nx]) count++
        }
    }

    return count
}

fun computeNextState(grid: Grid): Grid =
    Array(HEIGHT) { y ->
        BooleanArray(WIDTH) { x ->
            val alive = grid[y][x]
            val neighbors = countNeighbors(grid, x, y)
            (alive && (neighbors == 2 || neighbors == 3)) || (!alive && neighbors == 3)
        }
    }

fun printGrid(grid: Grid) {
    val output = StringBuilder()
    output.append("\u001B[H\u001B[2J")

    for (row in grid) {
        for (cell in row) {
            output.append(if (cell) '█' else ' ')
        }
        output.append('\n')
    }

    print(output.toString())
}

fun main() {
    var grid = initializeGrid()

    while (true) {
        printGrid(grid)
        grid = computeNextState(grid)
        Thread.sleep(100)
    }
}
