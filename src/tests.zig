const WebView = @import("webview");
const std = @import("std");

test "version" {
    const version = WebView.version().version;
    std.debug.print("{d}.{d}.{d}", .{version.major, version.minor, version.patch});
}
test "create a window" {
    const window = WebView.create(false, null);
    try std.testing.expect(window.webview != null);
    try std.testing.expect(window.getWindow() != null);
    try window.setSize(800, 600, .MAX);
    try window.setSize(800, 600, .FIXED);
    try window.setHtml(
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\<title>Test</title>
        \\</head>
        \\<body style="display: flex; justify-content: center; align-items: center; height: 100vh;">
        \\<h1 style="font-family: Arial, sans-serif; color: #333;">Hello, WebView!</h1>
        \\</body>
        \\</html>
    );
    try window.run();
    try window.destroy();
}
