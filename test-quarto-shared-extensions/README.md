# Shared Extensions Experiment

This repository contains the code for the shared extensions experiment.
The idea is to use a `default` project type which has several single-file projects as subprojects/subdirectories.

You can install the "shared extensions" alongside the `_quarto.yml` file in the root of the project and render each subproject as a separate document:

```sh
quarto render module1
quarto render module2
```
