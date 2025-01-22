#!/usr/bin/env bash

for dir in */; do
  if [ -d "$dir" ]; then
    cd "$dir"
    if [ -f "run.sh" ]; then
      bash run.sh
    else
      echo "run.sh not found in $dir"
    fi
    cd ..
  fi
done
