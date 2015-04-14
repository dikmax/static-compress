# static_compress

Tool for precompressing static assets (`.html` -> `.html.gz`). All original files are left intact. 
Only updates changed files.

Installing:

```
pub global activate static_compress
```

Running

```
pub global run static_compress --dir <dir_to_process> [--meta <dir_to_store_meta>]
```
