# static_compress

Tool for precompressing static assets (`.html` -> `.html.gz`). All original files (except `.webp` and `.gz` are left 
intact. Only updates changed files.

# Prerequisites

zopfli, cwebp

If any of these commands not available then correspondent files won't be processed.

# Installing

```
pub global activate static_compress
```

# Running

```
pub global run static_compress --dir <dir_to_process> [--meta <dir_to_store_meta>] [--threads <max_threads>]
```
