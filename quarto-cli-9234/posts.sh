#!/bin/bash

# Define the author
author="Tristan O'Malley"

# Define the date
date="2024-03-28"

# Create the posts directory if it doesn't exist
mkdir -p posts

# Loop to create directories and files
for i in {1..30}
do
  # Create the directory
  mkdir -p "posts/post-$i"

  # Create the markdown file
  echo "---" > "posts/post-$i/post-$i.qmd"
  echo "title: \"Post $i\"" >> "posts/post-$i/post-$i.qmd"
  echo "author: \"$author\"" >> "posts/post-$i/post-$i.qmd"
  echo "date: \"$date\"" >> "posts/post-$i/post-$i.qmd"
  echo "categories: [post-$i]" >> "posts/post-$i/post-$i.qmd"
  echo "---" >> "posts/post-$i/post-$i.qmd"
  echo "" >> "posts/post-$i/post-$i.qmd"
  echo "This is the post $i" >> "posts/post-$i/post-$i.qmd"
done
