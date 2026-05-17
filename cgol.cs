using System;
using System.Text;
using System.Threading;

public static class Cgol
{
    private const int Width = 50;
    private const int Height = 30;
    private const double Density = 0.2;
    private static readonly Random Random = new Random();

    private static bool[,] InitializeGrid()
    {
        var grid = new bool[Height, Width];

        for (var y = 0; y < Height; y++)
        {
            for (var x = 0; x < Width; x++)
            {
                grid[y, x] = Random.NextDouble() < Density;
            }
        }

        return grid;
    }

    private static int CountNeighbors(bool[,] grid, int x, int y)
    {
        var count = 0;

        for (var dy = -1; dy <= 1; dy++)
        {
            for (var dx = -1; dx <= 1; dx++)
            {
                if (dx == 0 && dy == 0) continue;

                var nx = (x + dx + Width) % Width;
                var ny = (y + dy + Height) % Height;
                if (grid[ny, nx]) count++;
            }
        }

        return count;
    }

    private static bool[,] ComputeNextState(bool[,] grid)
    {
        var next = new bool[Height, Width];

        for (var y = 0; y < Height; y++)
        {
            for (var x = 0; x < Width; x++)
            {
                var alive = grid[y, x];
                var neighbors = CountNeighbors(grid, x, y);
                next[y, x] = (alive && (neighbors == 2 || neighbors == 3)) || (!alive && neighbors == 3);
            }
        }

        return next;
    }

    private static void PrintGrid(bool[,] grid)
    {
        var output = new StringBuilder();
        output.Append("\x1B[H\x1B[2J");

        for (var y = 0; y < Height; y++)
        {
            for (var x = 0; x < Width; x++)
            {
                output.Append(grid[y, x] ? '█' : ' ');
            }
            output.AppendLine();
        }

        Console.Write(output.ToString());
    }

    public static void Main()
    {
        var grid = InitializeGrid();

        while (true)
        {
            PrintGrid(grid);
            grid = ComputeNextState(grid);
            Thread.Sleep(100);
        }
    }
}
