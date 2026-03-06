//! ZigWebView - A Zig wrapper for the WebView library (https://github.com/webview/webview)
const WebView = @This();
const raw = @import("raw");

webview: raw.webview_t,
const ErrorUnion = Error!void;
const WebViewVersionInfo = raw.webview_version_info_t;
pub const DispatchCallback = *const fn (?*anyopaque, ?*anyopaque) callconv(.c) void;
pub const BindCallback = *const fn ([*:0]const u8, [*:0]const u8, ?*anyopaque) callconv(.c) void;

pub const WindowSizeHint = enum(c_uint) {
    NONE,
    MIN,
    MAX,
    FIXED,
};
pub const NativeHandle = enum(c_uint) {
    UI_WINDOW,
    UI_WIDGET,
    BROWSER_CONTROLLER,
};

pub fn create(debug: bool, window: ?*anyopaque) WebView {
    return .{ .webview = raw.webview_create(@intFromBool(debug), window) };
}
pub fn run(self: WebView) ErrorUnion {
    return error_helper(raw.webview_run(self.webview));
}
pub fn terminate(self: WebView) ErrorUnion {
    return error_helper(raw.webview_terminate(self.webview));
}
pub fn dispatch(self: WebView, @"fn": DispatchCallback, arg: ?*anyopaque) ErrorUnion {
    return error_helper(raw.webview_dispatch(self.webview, @"fn", arg));
}
pub fn getWindow(self: WebView) ?*anyopaque {
    return raw.webview_get_window(self.webview);
}
pub fn getNativeHandle(self: WebView, kind: NativeHandle) ?*anyopaque {
    return raw.webview_get_native_handle(self.webview, @intFromEnum(kind));
}
pub fn setTitle(self: WebView, title: [:0]const u8) ErrorUnion {
    return error_helper(raw.webview_set_title(self.webview, title.ptr));
}
/// WindowSizeHint FIXED does NOT work on Wayland. To achieve a fixed size on Wayland, you need to set a minimum and maximum size that are the same
pub fn setSize(self: WebView, width: i32, height: i32, hint: WindowSizeHint) ErrorUnion {
    return error_helper(raw.webview_set_size(self.webview, width, height, @intFromEnum(hint)));
}
pub fn navigate(self: WebView, url: [:0]const u8) ErrorUnion {
    return error_helper(raw.webview_navigate(self.webview, url.ptr));
}
pub fn setHtml(self: WebView, html: [:0]const u8) ErrorUnion {
    return error_helper(raw.webview_set_html(self.webview, html.ptr));
}
pub fn init(self: WebView, js: [:0]const u8) ErrorUnion {
    return error_helper(raw.webview_init(self.webview, js.ptr));
}
pub fn eval(self: WebView, js: [:0]const u8) ErrorUnion {
    return error_helper(raw.webview_eval(self.webview, js.ptr));
}
pub fn bind(self: WebView, name: [:0]const u8, @"fn": BindCallback, arg: ?*anyopaque) ErrorUnion {
    return error_helper(raw.webview_bind(self.webview, name.ptr, @"fn", arg));
}
pub fn unbind(self: WebView, name: [:0]const u8) ErrorUnion {
    return error_helper(raw.webview_unbind(self.webview, name));
}
pub fn ret(self: WebView, seq: [:0]const u8, status: i32, result: [:0]const u8) ErrorUnion {
    return error_helper(raw.webview_return(self.webview, seq.ptr, status, result.ptr));
}
pub fn destroy(self: WebView) ErrorUnion {
    return error_helper(raw.webview_destroy(self.webview));
}
pub fn version() *const WebViewVersionInfo {
    return raw.webview_version();
}

pub const Error = error{
    MissingDependency,
    Canceled,
    InvalidState,
    InvalidArgument,
    Unspecified,
    Duplicate,
    NotFound,
};
fn error_helper(err: raw.webview_error_t) Error!void {
    return switch (err) {
        -5 => Error.MissingDependency,
        -4 => Error.Canceled,
        -3 => Error.InvalidState,
        -2 => Error.InvalidArgument,
        -1 => Error.Unspecified,
        0 => {},
        1 => Error.Duplicate,
        2 => Error.NotFound,
        else => unreachable,
    };
}
