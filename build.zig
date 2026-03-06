const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(std.builtin.LinkMode, "linkage", "Linkage type (static or dynamic)") orelse .static;

    const webview = b.dependency("webview", .{});
    const webview_raw = b.addTranslateC(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = webview.path("core/include/webview/webview.h"),
    }).createModule();

    const webview_module = b.addModule("webview", .{
        .root_source_file = b.path("src/WebView.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "raw", .module = webview_raw },
        },
    });

    const lib = b.addLibrary(.{
        .name = "webview",
        .root_module = b.createModule(.{
            .link_libcpp = true,
            .target = target,
            .optimize = optimize,
        }),
    });
    lib.root_module.addIncludePath(webview.path("core/include"));
    lib.root_module.addCMacro(if (linkage == .static) "WEBVIEW_STATIC" else "WEBVIEW_BUILD_SHARED", "");
    switch (target.query.os_tag orelse builtin.os.tag) {
        .windows => {
            lib.root_module.addCSourceFile(.{
                .file = webview.path("core/src/webview.cc"),
                .flags = &.{"-std=c++14"},
                .language = .cpp,
            });
            lib.root_module.addIncludePath(b.path("vendor/WebView2/"));
            lib.root_module.addIncludePath(webview.path("compatibility/mingw/include"));
            lib.root_module.linkSystemLibrary("ole32", .{});
            lib.root_module.linkSystemLibrary("shlwapi", .{});
            lib.root_module.linkSystemLibrary("version", .{});
            lib.root_module.linkSystemLibrary("advapi32", .{});
            lib.root_module.linkSystemLibrary("shell32", .{});
            lib.root_module.linkSystemLibrary("user32", .{});
        },
        .macos => {
            lib.root_module.addCSourceFile(.{
                .file = webview.path("core/src/webview.cc"),
                .flags = &.{"-std=c++11"},
                .language = .cpp,
            });
            lib.root_module.linkFramework("WebKit", .{});
        },
        else => {
            lib.root_module.addCSourceFile(.{
                .file = webview.path("core/src/webview.cc"),
                .flags = &.{"-std=c++11"},
                .language = .cpp,
            });
            lib.root_module.linkSystemLibrary("gtk+-3", .{});
            lib.root_module.linkSystemLibrary("webkit2gtk-4.1", .{});
        },
    }
    b.installArtifact(lib);

    const tests = b.addTest(.{
        .name = "webview_test",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "webview", .module = webview_module },
            },
        }),
    });
    tests.root_module.linkLibrary(lib);
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run webview tests");
    test_step.dependOn(&run_tests.step);
}
