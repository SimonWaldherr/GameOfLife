#!/usr/bin/env dart

import 'dart:async';
import 'dart:io';
import 'dart:math';

const int width = 50;
const int height = 30;
const double density = 0.2;

/// Initializes the grid with random alive or dead cells based on the specified density.
List<List<bool>> initializeGrid() {
  final random = Random();
  return List.generate(
    height,
    (_) => List.generate(width, (_) => random.nextDouble() < density),
  );
}

/// Counts the number of alive neighbors around a given cell with wrapping.
int countNeighbors(List<List<bool>> grid, int x, int y) {
  int count = 0;
  final directions = [-1, 0, 1];

  for (var dx in directions) {
    for (var dy in directions) {
      if (dx == 0 && dy == 0) continue; // Skip the cell itself

      // Calculate neighbor coordinates with wrapping
      final nx = (x + dx + width) % width;
      final ny = (y + dy + height) % height;

      if (grid[ny][nx]) count++;
    }
  }

  return count;
}

/// Computes the next state of the grid based on Conway's Game of Life rules.
List<List<bool>> computeNextState(List<List<bool>> grid) {
  final newGrid = List.generate(height, (_) => List.generate(width, (_) => false)); // Create empty new grid
  
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alive = grid[y][x];
      final neighbors = countNeighbors(grid, x, y);

      // Apply Game of Life rules
      newGrid[y][x] = (alive && (neighbors == 2 || neighbors == 3)) || (!alive && neighbors == 3);
    }
  }

  return newGrid;
}

/// Prints the grid to the console, using Unicode block characters to represent alive cells.
void printGrid(List<List<bool>> grid) {
  stdout.write('\x1B[2J\x1B[H'); // Clear screen and move cursor to top-left
  for (var row in grid) {
    for (var cell in row) {
      stdout.write(cell ? '█' : ' '); // Use block character for alive cells
    }
    stdout.writeln();
  }
}

/// Main function to run the simulation, handling Ctrl+C interruptions.
Future<void> main() async {
  var grid = initializeGrid();  // Change `final` to `var` to allow grid updates

  // Set up to listen for Ctrl+C to stop the simulation
  final stopSignal = StreamController<void>();
  final signalSubscription = ProcessSignal.sigint.watch().listen((_) {
    stopSignal.add(null); // Trigger stop signal
  });

  // Main simulation loop
  try {
    while (true) {
      printGrid(grid);
      await Future.delayed(Duration(milliseconds: 100)); // Pause for 100 milliseconds
      grid = computeNextState(grid);  // Update the grid in each iteration

      // Check for stop signal
      if (stopSignal.hasListener) {
        break;
      }
    }
  } finally {
    // Cleanup: Cancel signal subscription and close StreamController
    signalSubscription.cancel();
    stopSignal.close();
    print('\nSimulation stopped.');
  }
}
