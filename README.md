# notifire

Notification launcher command for macOS (inspired from Confetti by [Raycast](https://www.raycast.com/))

## Build

```sh
./build.sh [output path]
```

Compiles `notifire.swift` with `swiftc -O`. The output path defaults to `./notifire`, is resolved relative to the current directory, and missing parent directories are created.

```sh
./build.sh                          # -> ./notifire
./build.sh ~/.local/bin/notifire    # install anywhere
```

## Usage

```sh
./notifire     # colored paper
./notifire ✅  # emoji (only the first argument is used)
```
