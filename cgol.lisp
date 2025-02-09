#!/usr/bin/env sbcl --script
;; cgol.lisp: Conway's Game of Life in Common Lisp

(defparameter *width* 50)
(defparameter *height* 30)
(defparameter *density* 20)  ;; percentage chance a cell is alive

(defun make-grid ()
  "Create a new grid with random live (1) or dead (0) cells."
  (let ((grid (make-array (list *height* *width*) :initial-element 0)))
    (loop for y from 0 below *height* do
          (loop for x from 0 below *width* do
                (setf (aref grid y x)
                      (if (< (random 100) *density*) 1 0))))
    grid))

(defun count-neighbors (grid x y)
  "Count live neighbors around cell (x,y) with toroidal wrapping."
  (let ((count 0))
    (loop for dy from -1 to 1 do
          (loop for dx from -1 to 1 do
                (unless (and (= dx 0) (= dy 0))
                  (let* ((nx (mod (+ x dx) *width*))
                         (ny (mod (+ y dy) *height*)))
                    (incf count (aref grid ny nx))))))
    count))

(defun next-generation (grid)
  "Compute the next generation from the current grid."
  (let ((new-grid (make-array (list *height* *width*) :initial-element 0)))
    (loop for y from 0 below *height* do
          (loop for x from 0 below *width* do
                (let* ((alive (aref grid y x))
                       (neighbors (count-neighbors grid x y)))
                  (setf (aref new-grid y x)
                        (if (or (and (= alive 1) (or (= neighbors 2) (= neighbors 3)))
                                (and (= alive 0) (= neighbors 3)))
                            1 0)))))
    new-grid))

(defun print-grid (grid)
  "Print the grid using '█' for live cells and ' ' for dead cells."
  (format t "~c[H" #\Escape)  ;; Move cursor to top-left.
  (loop for y from 0 below *height* do
        (loop for x from 0 below *width* do
              (princ (if (= (aref grid y x) 1) "█" " ")))
        (terpri))
  (finish-output))

(defun game-loop (grid)
  "Main loop to repeatedly update and display the grid."
  (loop
    (print-grid grid)
    (setf grid (next-generation grid))
    (sleep 0.1)))  ;; Pause for 100ms. (Fractional seconds work in SBCL.)

(defun main ()
  "Entry point for the Game of Life."
  (format t "~c[?25l" #\Escape)  ;; Hide the cursor.
  (let ((grid (make-grid)))
    (game-loop grid))
  (format t "~c[?25h" #\Escape)) ;; Restore cursor on exit.

(main)

