/*
#!/bin/bash
# The below line will compile and run the Java program
javac cgol.java && java cgol;
rm cgol.class
exit
*/
import java.util.Random;

// Main class to simulate Conway's Game of Life
public class cgol {

    // Constants for the grid size and density of alive cells
    private static final int WIDTH = 50;
    private static final int HEIGHT = 30;
    private static final double DENSITY = 0.2;

    // Function to initialize the grid with random alive or dead cells
    public static boolean[][] initializeGrid() {
        boolean[][] grid = new boolean[HEIGHT][WIDTH];
        Random random = new Random();

        for (int y = 0; y < HEIGHT; y++) {
            for (int x = 0; x < WIDTH; x++) {
                // Randomly assign alive cells based on the density constant
                grid[y][x] = random.nextDouble() < DENSITY;
            }
        }
        return grid;
    }

    // Function to count the number of alive neighbors around a given cell
    public static int countNeighbors(boolean[][] grid, int x, int y) {
        int count = 0;

        for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
                if (dx == 0 && dy == 0) {
                    // Skip the cell itself
                    continue;
                }

                // Calculate neighbor coordinates with wrapping (toroidal)
                int nx = (x + dx + WIDTH) % WIDTH;
                int ny = (y + dy + HEIGHT) % HEIGHT;

                // Count alive neighbors
                if (grid[ny][nx]) {
                    count++;
                }
            }
        }
        return count;
    }

    // Function to compute the next state of the grid based on the Game of Life rules
    public static boolean[][] computeNextState(boolean[][] grid) {
        boolean[][] newGrid = new boolean[HEIGHT][WIDTH];

        for (int y = 0; y < HEIGHT; y++) {
            for (int x = 0; x < WIDTH; x++) {
                boolean alive = grid[y][x];
                int neighbors = countNeighbors(grid, x, y);

                // Apply Game of Life rules:
                // - A live cell with 2 or 3 neighbors survives.
                // - A dead cell with exactly 3 neighbors becomes alive.
                // - Otherwise, the cell dies or remains dead.
                newGrid[y][x] = (alive && neighbors == 2) || neighbors == 3;
            }
        }

        return newGrid;
    }

    // Function to print the grid to the console
    public static void printGrid(boolean[][] grid) {
        for (int y = 0; y < HEIGHT; y++) {
            for (int x = 0; x < WIDTH; x++) {
                if (grid[y][x]) {
                    System.out.print("█"); // Print alive cell
                } else {
                    System.out.print(" "); // Print dead cell
                }
            }
            System.out.println();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        boolean[][] grid = initializeGrid(); // Initialize the grid

        while (true) {
            printGrid(grid); // Print the current grid
            grid = computeNextState(grid); // Compute the next generation
            Thread.sleep(100); // Pause for 100ms

            // Clear the console screen using ANSI escape codes
            System.out.print("\033[H\033[2J");
            System.out.flush();
        }
    }
}
