-module(cgol).
-export([start/0]).

-define(W, 50).
-define(H, 30).
-define(D, 0.3).

start() ->
    rand:seed(exsplus, os:timestamp()),
    loop(init()).

init() ->
    [ [ rand:uniform() < ?D || _ <- lists:seq(1, ?W) ] || _ <- lists:seq(1, ?H) ].

loop(Grid) ->
    io:format("\033[H\033[2J"),
    lists:foreach(fun(R) -> print_row(R) end, Grid),
    timer:sleep(100),
    loop(step(Grid)).

print_row(Row) ->
    lists:foreach(fun(C) -> io:put_chars(if C -> "█"; true -> " " end) end, Row),
    io:nl().

step(Grid) ->
    [ [ evolve(Grid, X, Y) || X <- lists:seq(0, ?W - 1) ] || Y <- lists:seq(0, ?H - 1) ].

evolve(Grid, X, Y) ->
    Alive = get(Grid, X, Y),
    N = count(Grid, X, Y),
    (Alive andalso (N == 2 orelse N == 3)) orelse (not Alive andalso N == 3).

count(Grid, X, Y) ->
    D = [{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}],
    lists:sum([ bool_to_int(get(Grid, X+DX, Y+DY)) || {DX, DY} <- D ]).

get(Grid, X, Y) ->
    X1 = (X + ?W) rem ?W,
    Y1 = (Y + ?H) rem ?H,
    Row = lists:nth(Y1 + 1, Grid),
    lists:nth(X1 + 1, Row).

bool_to_int(true) -> 1;
bool_to_int(false) -> 0.
