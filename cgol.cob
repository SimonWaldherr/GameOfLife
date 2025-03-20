       IDENTIFICATION DIVISION.
       PROGRAM-ID. GAME-OF-LIFE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01 WIDTH PIC 9(3) VALUE 50.
       01 HEIGHT PIC 9(2) VALUE 30.
       01 BOARD-SIZE PIC 9(4) VALUE 1500.

       01 CELLS-TABLE.
           05 CELLS-A PIC 9 OCCURS 5000 TIMES.
           05 CELLS-B PIC 9 OCCURS 5000 TIMES.

       01 SEED PIC 9(9) VALUE 24680.
       01 RAND PIC 9(9).

       01 F PIC 9(4).
       01 G PIC 9(4).
       01 I PIC 9(3).
       01 J PIC 9(3).
       01 N PIC 9(3).
       01 M PIC 9(3).
       01 K PIC 9(3).
       01 L PIC 9(3).

       01 RESULT PIC 9.
       01 CELL PIC 9.
       01 ADJ PIC 9.

       01 ESC PIC X VALUE X"1B".

       PROCEDURE DIVISION.

       MAIN-PROCESS.
           PERFORM INITIALIZE-BOARD.
           PERFORM RUN-GAME UNTIL 1 = 2. *> Infinite loop
           STOP RUN.

       INITIALIZE-BOARD.
           PERFORM VARYING F FROM 1 BY 1 UNTIL F > BOARD-SIZE
               COMPUTE SEED = SEED * 4848 + 1
               COMPUTE RAND = FUNCTION MOD(SEED, 90) + 2
               IF RAND > 50
                   MOVE 1 TO CELLS-A(F)
               ELSE
                   MOVE 0 TO CELLS-A(F)
               END-IF
           END-PERFORM.

       RUN-GAME.
           PERFORM DISPLAY-BOARD
           CONTINUE AFTER 0.1 SECONDS
           DISPLAY ESC "[30A" WITH NO ADVANCING
           PERFORM COPY-BOARD
           PERFORM UPDATE-BOARD.

       DISPLAY-BOARD.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > HEIGHT
               PERFORM VARYING J FROM 1 BY 1 UNTIL J > WIDTH
                   IF CELLS-A((I - 1) * WIDTH + J) = 1
                       DISPLAY "█" WITH NO ADVANCING
                   ELSE
                       DISPLAY " " WITH NO ADVANCING
                   END-IF
               END-PERFORM
               DISPLAY " "
            END-PERFORM.


       COPY-BOARD.
           PERFORM VARYING G FROM 1 BY 1 UNTIL G > BOARD-SIZE
               MOVE CELLS-A(G) TO CELLS-B(G)
           END-PERFORM.

       UPDATE-BOARD.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > HEIGHT
               PERFORM VARYING J FROM 1 BY 1 UNTIL J > WIDTH
                   MOVE I TO N
                   MOVE J TO M
                   PERFORM GET-CELL
                   MOVE RESULT TO CELL
                   MOVE 0 TO ADJ
                   PERFORM COMPUTE-ADJACENT
                   PERFORM APPLY-RULES
                   MOVE CELL TO CELLS-A((I - 1) * WIDTH + J)
               END-PERFORM
           END-PERFORM.

       APPLY-RULES.
           IF CELL = 1
               IF ADJ < 2
                   MOVE 0 TO CELL
               END-IF
               IF ADJ > 3
                   MOVE 0 TO CELL
               END-IF
           ELSE
               IF ADJ = 3
                   MOVE 1 TO CELL
               END-IF
           END-IF.

       GET-CELL.
           COMPUTE RESULT = CELLS-B((N - 1) * WIDTH + M).

       COMPUTE-ADJACENT.
           PERFORM VARYING K FROM 0 BY 1 UNTIL K > 2
               PERFORM VARYING L FROM 0 BY 1 UNTIL L > 2
                   IF K <> 1 OR L <> 1
                       COMPUTE N = I + K - 1
                       IF N = 0
                           MOVE HEIGHT TO N
                       END-IF
                       IF N > HEIGHT
                           MOVE 1 TO N
                       END-IF

                       COMPUTE M = J + L - 1
                       IF M = 0
                           MOVE WIDTH TO M
                       END-IF
                       IF M > WIDTH
                           MOVE 1 TO M
                       END-IF

                       PERFORM GET-CELL
                       IF RESULT = 1
                           COMPUTE ADJ = ADJ + 1
                       END-IF
                   END-IF
               END-PERFORM
           END-PERFORM.

