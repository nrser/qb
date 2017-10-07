//bin Directory
========================================================================

Development executables: stubs, scripts, etc.

Usually this stuff would live in `//dev/bin`, but when this repo was created using Bundler's gem initializer, gem executables were placed in `//exe` and `//bin` was being used for development stuff (or, at least that's what it seemed like).

Bundler is a very widely-used tool, so I went along with it.

Executables that ship with the gem live in `//exe`.
