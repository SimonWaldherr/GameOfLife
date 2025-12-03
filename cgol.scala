#!/usr/bin/env scala

import scala.util.Random

object GameOfLife {
  val WIDTH = 50
  val HEIGHT = 30
  val DENSITY = 0.2

  type Grid = Array[Array[Boolean]]

  def initializeGrid(): Grid = {
    Array.fill(HEIGHT, WIDTH)(Random.nextDouble() < DENSITY)
  }

  def countNeighbors(grid: Grid, x: Int, y: Int): Int = {
    var count = 0
    for (dx <- -1 to 1; dy <- -1 to 1) {
      if (dx != 0 || dy != 0) {
        val nx = (x + dx + WIDTH) % WIDTH
        val ny = (y + dy + HEIGHT) % HEIGHT
        if (grid(ny)(nx)) count += 1
      }
    }
    count
  }

  def computeNextState(grid: Grid): Grid = {
    Array.tabulate(HEIGHT, WIDTH) { (y, x) =>
      val alive = grid(y)(x)
      val neighbors = countNeighbors(grid, x, y)
      if (alive) neighbors == 2 || neighbors == 3 else neighbors == 3
    }
  }

  def printGrid(grid: Grid): Unit = {
    grid.foreach { row =>
      println(row.map(if (_) '█' else ' ').mkString)
    }
  }

  def main(args: Array[String]): Unit = {
    var grid = initializeGrid()
    while (true) {
      printGrid(grid)
      grid = computeNextState(grid)
      Thread.sleep(100)
      print("\u001b[H\u001b[2J")
    }
  }
}
