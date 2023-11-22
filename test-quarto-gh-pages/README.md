# Quarto & GitHub Pages

```sh
mkdir quarto-gh-pages
cd quarto-gh-pages
quarto create-project --type website .
echo "/_site/" > .gitignore
echo "/.quarto/" >> .gitignore
git init
git add *
git commit -m "chore: initialise project"
git remote add origin https://github.com/mcanouil/quarto-gh-pages.git
git push origin main

git checkout --orphan gh-pages
git reset --hard
git commit --allow-empty -m "chore: initialise branch"
git push origin gh-pages

git checkout main
quarto publish gh-pages
```
