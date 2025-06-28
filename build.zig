const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });
    const lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
        .link_libc = true,
    });
    const lib = b.addLibrary(.{
        .name = "lib",
        .root_module = lib_mod,
    });
    const exe = b.addExecutable(.{
        .name = "sternenstaub",
        .root_module = exe_mod,
    });

    const sdl3 = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
    });
    const sdl3_lib = sdl3.artifact("SDL3");
    const sdl3_test_lib = sdl3.artifact("SDL3_test");

    exe.linkLibrary(lib);
    lib.linkLibrary(sdl3_lib);
    lib.linkLibrary(sdl3_test_lib);
    b.installArtifact(exe);
    //   ===================================================//
    const obj = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    obj.addCSourceFile(.{
        .file = b.path("src/main.cpp"),
        .language = .cpp,
    });
    obj.linkLibrary(sdl3_lib);
    obj.linkLibrary(sdl3_test_lib);

    const t = b.addExecutable(.{
        .name = "1234",
        .root_module = obj,
    });
    t.linkLibrary(sdl3_lib);
    t.linkLibrary(sdl3_test_lib);
    b.installArtifact(t);

    // =======================================================//

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
