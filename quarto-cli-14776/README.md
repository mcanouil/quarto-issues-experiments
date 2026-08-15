<!-- markdownlint-disable MD034 -->
<!-- Bare permalinks are deliberate: GitHub expands them into code snippets. -->

# Roles and affiliation positions in the HTML title block

This example answers [quarto-dev/discussions#14776](https://github.com/orgs/quarto-dev/discussions/14776).

It shows a roles column and an affiliation position in the HTML title block.
It uses one template partial.
It adds no Lua filter, and it changes nothing in Quarto.

## Both fields already reach the template

`authors.lua` normalises the author metadata before any template runs.

`roles:` becomes `by-author[].roles[]`.
Each entry holds `role` and `degree-of-contribution`.
A CRediT term also gets `vocab-identifier`, `vocab-term`, and `vocab-term-identifier`.

- https://github.com/quarto-dev/quarto-cli/blob/abc6a78ed68f9e8bc9d54e27851093bd687a1cb7/src/resources/filters/modules/authors.lua#L719-L782

`position:` is not a known affiliation field, so it is not dropped.
An unknown key goes under `metadata`, which makes it `by-author[].affiliations[].metadata.position` in the template.

- https://github.com/quarto-dev/quarto-cli/blob/abc6a78ed68f9e8bc9d54e27851093bd687a1cb7/src/resources/filters/modules/authors.lua#L367-L383

The same fallback exists for unknown keys directly under an author.

- https://github.com/quarto-dev/quarto-cli/blob/abc6a78ed68f9e8bc9d54e27851093bd687a1cb7/src/resources/filters/modules/authors.lua#L1009-L1014

So this document renders with the partial in this repository:

```yaml
author:
  - name: Ada Lovelace
    roles:
      - original author
      - writing: lead
    affiliation:
      - name: Analytical Engine Institute
        position: Head of Research
```

## Why the default does not change

The author schema and the partial system carry the general case.
They cover journals, books, reports, and house styles that do not agree with each other.

The default title block only has to be a sensible default.
A roles column is right for a translated book and wrong for most other documents.
That makes it a good partial, not a good default.

## The partial

The example replaces `title-metadata.html`, which holds the whole author and affiliation grid.

- https://github.com/quarto-dev/quarto-cli/blob/abc6a78ed68f9e8bc9d54e27851093bd687a1cb7/src/resources/formats/html/templates/title-metadata.html#L1-L25

The heading row gains one cell, and each author row gains one cell:

```html
<div class="quarto-title-meta-heading">$if(by-author/rest)$$role-title-plural$$else$$role-title-single$$endif$</div>
```

```html
<p class="roles">$for(by-author.roles)$$it.role$$if(it.degree-of-contribution)$ ($it.degree-of-contribution$)$endif$$sep$, $endfor$</p>
```

The affiliation cell gains the position:

```html
$if(it.metadata.position)$
<span class="affiliation-position">$it.metadata.position$</span>
$endif$
```

Quarto stages format partials and user partials in one directory, user partials last, so a file with the same name wins.

- https://github.com/quarto-dev/quarto-cli/blob/abc6a78ed68f9e8bc9d54e27851093bd687a1cb7/src/command/render/template.ts#L118-L123
- https://github.com/quarto-dev/quarto-cli/blob/abc6a78ed68f9e8bc9d54e27851093bd687a1cb7/src/command/render/pandoc.ts#L832-L834

## Localised and plural labels

The author and affiliation headings need no work.
`computeLabels` picks the singular or the plural form from the language files and gives them to the template as `$labels.authors$` and `$labels.affiliations$`.

- https://github.com/quarto-dev/quarto-cli/blob/abc6a78ed68f9e8bc9d54e27851093bd687a1cb7/src/resources/filters/modules/authors.lua#L853-L877

The role heading needs work, because Quarto has no role string.

- https://github.com/quarto-dev/quarto-cli/blob/abc6a78ed68f9e8bc9d54e27851093bd687a1cb7/src/resources/language/_language.yml#L30-L36

The plural form comes from Pandoc's `rest` pipe.
`$if(by-author/rest)$` is true only when the array holds more than one entry.
Quarto uses the same style of condition in its own partial, with `$if(by-affiliation/first)$`.

### What this example does today

The two strings come from ordinary document metadata, which is also how Quarto's own label overrides work (`author-title`, `affiliation-title`, `published-title`).

`_quarto.yml`:

```yaml
role-title-single: "Role"
role-title-plural: "Roles"
```

`title-metadata.html`:

```html
$if(by-author/rest)$$role-title-plural$$else$$role-title-single$$endif$
```

A document that needs another language sets the same two keys again, as `index-es.qmd` does.

### Why not `language:` today

An extra key under `language:` looks like the better home for these strings, and the documentation reads that way, but it does not work in Quarto 1.11.
`translationsForLang` rebuilds the language table and keeps only the keys that Quarto ships, plus `crossref-*-title` and `crossref-*-prefix`.
A custom key passes validation, then disappears, and `$quarto.language.<key>$` gives an empty string with no warning.

- https://github.com/quarto-dev/quarto-cli/blob/abc6a78ed68f9e8bc9d54e27851093bd687a1cb7/src/core/language.ts#L161-L173
- https://github.com/quarto-dev/quarto-cli/issues/14772

`$quarto.language.<key>$` does work for the strings that Quarto ships, such as `$quarto.language.section-title-abstract$`.

### After the fix

[#14773](https://github.com/quarto-dev/quarto-cli/pull/14773) keeps a custom key that holds a string, because only locale variations are objects.
With that build, both keys move under `language:` and the partial reads them through the reserved namespace.

`_quarto.yml`:

```yaml
language:
  role-title-single: "Role"
  role-title-plural: "Roles"
```

`title-metadata.html`:

```html
$if(by-author/rest)$$quarto.language.role-title-plural$$else$$quarto.language.role-title-single$$endif$
```

That form also takes locale variations, so one project file can carry every language:

```yaml
language:
  role-title-single: "Role"
  role-title-plural: "Roles"
  es:
    role-title-single: "Rol"
    role-title-plural: "Roles"
```

Both forms are tested against the branch of that pull request.
The example keeps the metadata form, because that form works on the released version as well.

If anything here belongs in core, it is a pair of `title-block-role-single` and `title-block-role-plural` keys in `_language.yml`, plus `labels.roles` next to `labels.authors`.
That is a small, general addition, and it does not change what the default title block shows.

## Do not replace `title-block.html` by accident

Quarto adds a header itself when it cannot find `header.quarto-title-block`, and it moves the first title into it.

- https://github.com/quarto-dev/quarto-cli/blob/abc6a78ed68f9e8bc9d54e27851093bd687a1cb7/src/format/html/format-html-title.ts#L198-L241

The HTML partials documentation points at `src/resources/formats/html/pandoc`, whose `title-block.html` is a copy of the Pandoc original and carries no class.
A partial copied from there gives two `header#title-block-header` elements, which is [#13841](https://github.com/quarto-dev/quarto-cli/issues/13841).

- https://github.com/quarto-dev/quarto-web/blob/fc2a5ef1312ad107fb54748624cdce5418ae5fec/docs/journals/templates.qmd#L165

The partials that Quarto uses for the HTML title block live in `src/resources/formats/html/templates`.

- https://github.com/quarto-dev/quarto-cli/blob/abc6a78ed68f9e8bc9d54e27851093bd687a1cb7/src/format/html/format-html-title.ts#L133-L184

Replace `title-metadata.html`, as this example does, and the problem cannot happen.
If you do replace `title-block.html`, keep `class="quarto-title-block"` on the header.

## Files

| File | Purpose |
| --- | --- |
| `title-metadata.html` | The partial. The only file that differs from Quarto's own. |
| `styles.css` | Three grid columns, and two when no author has an affiliation. |
| `_quarto.yml` | Registers the partial and sets the default role headings. |
| `index.qmd` | Two authors, roles, degrees of contribution, and positions. |
| `single-author.qmd` | One author, so the headings are singular. |
| `index-es.qmd` | `lang: es`, with the role heading translated. |
| `edge-cases.qmd` | Authors with no roles, no affiliation, or neither. |
| `no-affiliations.qmd` | No affiliation at all, so the grid drops to two columns. |

## Render it

```bash
quarto render
```

Rendered with Quarto 1.11.
