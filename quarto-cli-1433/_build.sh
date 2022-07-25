#!/bin/bash

function render_book_slides() {
  quarto render .
  mv _quarto.yml _quarto_book.yml
  mv _quarto_revealjs.yml _quarto.yml
  quarto render .
  mv _quarto.yml _quarto_revealjs.yml
  mv _quarto_book.yml _quarto.yml
  return 0
}

render_book_slides
