#!/usr/bin/env elixir

defmodule GameOfLife do
  @width 50
  @height 30
  @density 0.2

  def init_grid do
    for _ <- 1..@height do
      for _ <- 1..@width, do: (:rand.uniform() < @density)
    end
  end

  def count_neighbors(grid, x, y) do
    for dx <- [-1, 0, 1],
        dy <- [-1, 0, 1],
        not (dx == 0 and dy == 0) do
      nx = rem(x + dx + @width, @width)
      ny = rem(y + dy + @height, @height)
      if Enum.at(Enum.at(grid, ny), nx), do: 1, else: 0
    end
    |> Enum.sum()
  end

  def next_generation(grid) do
    for y <- 0..(@height - 1) do
      for x <- 0..(@width - 1) do
        alive = Enum.at(Enum.at(grid, y), x)
        neighbors = count_neighbors(grid, x, y)
        cond do
          alive and (neighbors == 2 or neighbors == 3) -> true
          (not alive) and neighbors == 3 -> true
          true -> false
        end
      end
    end
  end

  def print_grid(grid) do
    # Clear screen using ANSI escape codes
    IO.write("\e[H\e[2J")
    Enum.each(grid, fn row ->
      row_str = row |> Enum.map(fn cell -> if cell, do: "█", else: " " end) |> Enum.join("")
      IO.puts(row_str)
    end)
  end

  def loop(grid) do
    print_grid(grid)
    :timer.sleep(100)
    loop(next_generation(grid))
  end

  def start do
    :rand.seed(:exsplus, :os.timestamp())
    grid = init_grid()
    loop(grid)
  end
end

GameOfLife.start()
