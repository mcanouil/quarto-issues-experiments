#!/usr/bin/env Rscript

render_book_slides <- function(...) {
  quarto::quarto_render(..., as_job = FALSE)
  file.rename("_quarto.yml", "_quarto_book.yml")
  file.rename("_quarto_revealjs.yml", "_quarto.yml")
  on.exit(file.rename("_quarto.yml", "_quarto_revealjs.yml"))
  on.exit(file.rename("_quarto_book.yml", "_quarto.yml"), add = TRUE)
  quarto::quarto_render(..., as_job = FALSE)
}

render_book_slides()
