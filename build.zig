const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "my-project",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .use_lld = false,
    });


    // Add Raylib include path (adjust if your path differs)
    exe.addIncludePath(b.path("raylib/build/raylib/include"));

    // Link the static Raylib library
    exe.addObjectFile(b.path("raylib/build/raylib/libraylib.a"));

    // Link C standard library
    exe.linkLibC();

    // Link required system libraries (for Linux)
    //exe.linkSystemLibrary("GL");
    //exe.linkSystemLibrary("m");
    //exe.linkSystemLibrary("X11");
    //exe.linkSystemLibrary("pthread");
    //exe.linkSystemLibrary("dl");
    //exe.linkSystemLibrary("rt");
    //exe.linkSystemLibrary("Xrandr");
    //exe.linkSystemLibrary("Xi");
    //exe.linkSystemLibrary("Xxf86vm");
    //exe.linkSystemLibrary("Xinerama");
    //exe.linkSystemLibrary("Xcursor");

    b.installArtifact(exe);

    // Optional: Add a run step
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
}
