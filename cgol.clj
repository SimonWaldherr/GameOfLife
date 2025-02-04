#!/usr/bin/env clojure

(def width 50)
(def height 30)
(def density 0.2)

(defn init-grid []
  (vec (for [_ (range height)]
         (vec (for [_ (range width)]
                (< (rand) density))))))

(defn count-neighbors [grid x y]
  (reduce + (for [dx [-1 0 1]
                  dy [-1 0 1]
                  :when (not (and (= dx 0) (= dy 0)))]
              (let [nx (mod (+ x dx) width)
                    ny (mod (+ y dy) height)]
                (if (get-in grid [ny nx]) 1 0)))))

(defn next-generation [grid]
  (vec (for [y (range height)]
         (vec (for [x (range width)]
                (let [alive (get-in grid [y x])
                      neighbors (count-neighbors grid x y)]
                  (or (and alive (or (= neighbors 2) (= neighbors 3)))
                      (and (not alive) (= neighbors 3)))))))))

(defn print-grid [grid]
  ;; Clear screen
  (println "\033[H\033[2J")
  (doseq [row grid]
    (println (apply str (map #(if % "█" " ") row)))))

(defn game-loop [grid]
  (loop [g grid]
    (print-grid g)
    (Thread/sleep 100)
    (recur (next-generation g))))

(defn -main []
  (game-loop (init-grid)))

(-main)
