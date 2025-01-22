#!/usr/bin/env bash

find . -type d -name ".quarto" -exec rm -rf {} +
find . -type d -name "output" -exec rm -rf {} +
find . -type d -name "*_files" -exec rm -rf {} +
find . -type f -name ".gitignore" -exec rm -f {} +
find . -type f -name "*.html" -exec rm -f {} +

for dir in */; do
  if [ -d "${dir}" ]; then
    cd "${dir}"
    if [ -f "run.sh" ]; then
      bash run.sh
    else
      echo "run.sh not found in ${dir}"
    fi
    cd ..
  fi
done
