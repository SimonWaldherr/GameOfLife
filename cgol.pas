program ConwayGameOfLife;

{$mode objfpc}{$H+}
{$codepage UTF8}

uses
  SysUtils, Crt;

const
  WIDTH = 50;
  HEIGHT = 30;
  DENSITY = 0.2;

type
  TGrid = array[0..HEIGHT-1, 0..WIDTH-1] of Boolean;

var
  grid, newGrid: TGrid;

procedure InitializeGrid(var g: TGrid);
var
  i, j: Integer;
begin
  Randomize;
  for i := 0 to HEIGHT - 1 do
    for j := 0 to WIDTH - 1 do
      g[i, j] := Random < DENSITY;
end;

function CountNeighbors(const g: TGrid; x, y: Integer): Integer;
var
  count, dx, dy, nx, ny: Integer;
begin
  count := 0;
  for dy := -1 to 1 do
  begin
    for dx := -1 to 1 do
    begin
      if not ((dx = 0) and (dy = 0)) then
      begin
        nx := (x + dx + WIDTH) mod WIDTH;
        ny := (y + dy + HEIGHT) mod HEIGHT;
        if g[ny, nx] then
          Inc(count);
      end;
    end;
  end;
  Result := count;
end;

procedure ComputeNextState(const current: TGrid; var next: TGrid);
var
  x, y, neighbors: Integer;
  isAlive: Boolean;
begin
  for y := 0 to HEIGHT - 1 do
  begin
    for x := 0 to WIDTH - 1 do
    begin
      isAlive := current[y, x];
      neighbors := CountNeighbors(current, x, y);
      if (isAlive and ((neighbors = 2) or (neighbors = 3))) or (not isAlive and (neighbors = 3)) then
        next[y, x] := True
      else
        next[y, x] := False;
    end;
  end;
end;

procedure PrintGrid(const g: TGrid);
var
  x, y: Integer;
begin
  for y := 0 to HEIGHT - 1 do
  begin
    for x := 0 to WIDTH - 1 do
    begin
      if g[y, x] then
        Write('█')
      else
        Write(' ');
    end;
    WriteLn;
  end;
end;

begin
  InitializeGrid(grid);
  while not KeyPressed do
  begin
    Write(#27'[H'#27'[2J'); // ANSI code to clear screen
    PrintGrid(grid);
    ComputeNextState(grid, newGrid);
    grid := newGrid;
    Delay(100);
  end;
end.