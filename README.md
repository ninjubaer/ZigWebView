# ZigWebview

Zig bindings for the C/C++ [webview](https://github.com/webview/webview) library

## Usage
```bash
zig fetch --save git+https://github.com/ninjubaer/ZigWebView.git
```

```zig
//build.zig
const webview = b.dependency("ZigWebview", .{
    .target = target,
    .optimize = optimize,
    .linkage = .dynamic, // or .static depending on your needs
});
exe.root_module.addImport("webview", webview.module("webview"));
exe.linkLibrary(webview.artifact("webview"));
```
