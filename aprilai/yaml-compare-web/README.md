# YAML Compare Web (React)

Web UI for comparing 2+ YAML files by key path.

## Features

- Upload or paste multiple YAML files.
- Parse validation per file.
- Baseline selection.
- Diff classification by key path:
  - `match`
  - `missing`
  - `typeMismatch`
  - `valueMismatch`
  - `arrayOrderMismatch`
- Filters and key-path search.
- CSV/JSON export of results.

## Run locally

```bash
npm install
npm run dev
```

Then open the URL shown by Vite.

## Build

```bash
npm run build
npm run preview
```
