# Timer

A simple TUI stopwatch that uses [rawterm](https://github.com/ttibsi/rawterm) v4.0.9 via 
swift's C++ FFI bridge.

### How to use
Requirements: `swift 6.3+`

For compilation, use any of the following commands:
```console
$ swift build               # To compile the binary
$ swift run                 # Execute
$ swift run timer --wiggle  # Enable digit wiggle animation
```

The binary is built to `.build/debug/timer`

While running, the following keybinds are available:
* `r`   - reset the timer
* `c`   - manually reload caption message 
* `SPC` - start/stop the timer
* `q`   - quit timer app

A caption is read from the file `caption.txt` at the top of this repo. An 
example is provided. While this can be manually reloaded with the `c` keybind,
we re-read the caption file on every clock tick to hot-reload the caption. 
No manual reload should be required during everyday operation

### Modifications in vendored rawterm
* `void draw(Cursor&, const std::string*, std::size_t) const` overload added to
facilitate using a swift Array in `CRawterm/rawterm/extras/border.h`
* `CRawterm/rawterm/extras/menu.h` tweaked relative includes to satisfy swift/clang
