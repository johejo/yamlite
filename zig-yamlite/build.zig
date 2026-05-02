const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("yamlite", .{
        .root_source_file = b.path("yamlite.zig"),
    });

    const opts = b.addOptions();
    opts.addOption([]const u8, "corpus_dir", b.pathFromRoot("tests"));

    const test_mod = b.createModule(.{
        .root_source_file = b.path("yamlite.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "build_options", .module = opts.createModule() },
        },
    });

    const test_exe = b.addTest(.{
        .name = "conformance",
        .root_module = test_mod,
    });

    const run_tests = b.addRunArtifact(test_exe);
    const test_step = b.step("test", "Run conformance tests");
    test_step.dependOn(&run_tests.step);
}
