const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    if (b.args) |args| {
        for (args, 1..) |arg, index| {
            std.debug.print("arg[{d}] = {s}\n", .{ index, arg });
        }
    }

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

    const static_lib = build_library(b, webview, .{
        .name = "webview",
        .linkage = .static,
        .target = target,
        .optimize = optimize,
    });
    const shared_lib = build_library(b, webview, .{
        .name = "webview",
        .linkage = .dynamic,
        .target = target,
        .optimize = optimize,
    });
    _ = shared_lib;
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
    tests.root_module.linkLibrary(static_lib);
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run webview tests");
    test_step.dependOn(&run_tests.step);
}

const build_options = struct {
    name: []const u8,
    linkage: std.builtin.LinkMode,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};

fn build_library(b: *std.Build, webview: *std.Build.Dependency, options: build_options) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{ .name = options.name, .root_module = b.createModule(.{
        .link_libcpp = true,
        .target = options.target,
        .optimize = options.optimize,
    }) });
    lib.root_module.addIncludePath(webview.path("core/include"));
    lib.root_module.addCMacro(if (options.linkage == .static) "WEBVIEW_STATIC" else "WEBVIEW_BUILD_SHARED", "");
    switch (options.target.query.os_tag orelse builtin.os.tag) {
        .windows => {
            lib.root_module.addCSourceFile(.{
                .file = webview.path("core/src/webview.cc"),
                .flags = &.{"-std=c++14"},
                .language = .cpp,
            });
            lib.addIncludePath(b.path("vendor/WebView2/"));
            lib.addIncludePath(webview.path("compatibility/mingw/include"));
            lib.linkSystemLibrary("ole32");
            lib.linkSystemLibrary("shlwapi");
            lib.linkSystemLibrary("version");
            lib.linkSystemLibrary("advapi32");
            lib.linkSystemLibrary("shell32");
            lib.linkSystemLibrary("user32");
        },
        .macos => {
            lib.root_module.addCSourceFile(.{
                .file = webview.path("core/src/webview.cc"),
                .flags = &.{"-std=c++11"},
                .language = .cpp,
            });
            lib.linkFramework("WebKit");
        },
        else => {
            lib.root_module.addCSourceFile(.{
                .file = webview.path("core/src/webview.cc"),
                .flags = &.{"-std=c++11"},
                .language = .cpp,
            });
            lib.linkSystemLibrary("gtk+-3");
            lib.linkSystemLibrary("webkit2gtk-4.1");
        },
    }
    b.installArtifact(lib);
    return lib;
}
