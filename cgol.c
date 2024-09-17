#!/bin/bash

gcc -x c -o "$TMPDIR/myprog" - <<EOF

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>
#include <unistd.h>

#define WIDTH 50
#define HEIGHT 30
#define DENSITY 0.2

// Initialisiert das Gitter mit zufällig lebenden oder toten Zellen
void initializeGrid(bool grid[HEIGHT][WIDTH]) {
    srand(time(NULL));
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            grid[y][x] = ((double)rand() / RAND_MAX) < DENSITY;
        }
    }
}

// Zählt die Anzahl der lebenden Nachbarn einer Zelle
int countNeighbors(bool grid[HEIGHT][WIDTH], int x, int y) {
    int count = 0;
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            int nx = (x + dx + WIDTH) % WIDTH;
            int ny = (y + dy + HEIGHT) % HEIGHT;
            if (grid[ny][nx]) count++;
        }
    }
    return count;
}

// Berechnet den nächsten Zustand des Gitters
void computeNextState(bool grid[HEIGHT][WIDTH], bool newGrid[HEIGHT][WIDTH]) {
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            int neighbors = countNeighbors(grid, x, y);
            if (grid[y][x]) {
                newGrid[y][x] = (neighbors == 2 || neighbors == 3);
            } else {
                newGrid[y][x] = (neighbors == 3);
            }
        }
    }
}

// Gibt das Gitter in der Konsole aus
void printGrid(bool grid[HEIGHT][WIDTH]) {
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            printf("%s", grid[y][x] ? "█" : " ");
        }
        printf("\n");
    }
}

// Kopiert ein Gitter in ein anderes
void copyGrid(bool source[HEIGHT][WIDTH], bool dest[HEIGHT][WIDTH]) {
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            dest[y][x] = source[y][x];
        }
    }
}

int main() {
    bool grid[HEIGHT][WIDTH];
    bool newGrid[HEIGHT][WIDTH];
    initializeGrid(grid);

    while (1) {
        printGrid(grid);
        computeNextState(grid, newGrid);
        copyGrid(newGrid, grid);
        usleep(100000); // 100 ms Pause
        // Konsole leeren
        printf("\033[H\033[2J");
    }
    return 0;
}
EOF

"$TMPDIR/myprog"