#!/bin/bash

for pid in $(ps aux | grep '[c]gol' | awk '{print $2}'); do cmd=$(ps -p $pid -o comm=); echo "Kill process $cmd with PID $pid? (y/n)"; read ans; if [ "$ans" = "y" ]; then kill "$pid"; fi; done