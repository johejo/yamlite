const std = @import("std");

pub const Parsed = std.json.Parsed(std.json.Value);

pub const ParseError = error{
    NotImplemented,
    OutOfMemory,
};

pub fn parseFromSlice(
    allocator: std.mem.Allocator,
    slice: []const u8,
) ParseError!Parsed {
    const arena = try allocator.create(std.heap.ArenaAllocator);
    errdefer allocator.destroy(arena);
    arena.* = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    if (!isEmptyOrCommentsOnly(slice)) return error.NotImplemented;

    return .{ .arena = arena, .value = .{ .object = .empty } };
}

fn isEmptyOrCommentsOnly(slice: []const u8) bool {
    var it = std.mem.splitScalar(u8, slice, '\n');
    while (it.next()) |raw| {
        const line = if (raw.len > 0 and raw[raw.len - 1] == '\r') raw[0 .. raw.len - 1] else raw;
        var i: usize = 0;
        while (i < line.len and line[i] == ' ') : (i += 1) {}
        if (i == line.len) continue;
        if (line[i] == '#') continue;
        return false;
    }
    return true;
}

// =====================================================================
// Conformance tests against the language-agnostic corpus at <repo>/tests
// (exposed here as zig-yamlite/tests via symlink). Add a path to one of
// the allow-lists below once the corresponding spec point is implemented.
// =====================================================================

const conformance_valid = [_][]const u8{
    "empty/empty-input",
    "empty/comments-only",
};

const conformance_invalid = [_][]const u8{};

const max_corpus_bytes: std.Io.Limit = .limited(1 << 20);

test "conformance: valid" {
    const corpus_dir = @import("build_options").corpus_dir;
    const allocator = std.testing.allocator;
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var dir = try std.Io.Dir.openDirAbsolute(io, corpus_dir, .{});
    defer dir.close(io);

    inline for (conformance_valid) |name| {
        runValidCase(allocator, io, dir, name) catch |err| {
            std.debug.print("[FAIL] valid/{s}: {s}\n", .{ name, @errorName(err) });
            return err;
        };
    }
}

test "conformance: invalid" {
    const corpus_dir = @import("build_options").corpus_dir;
    const allocator = std.testing.allocator;
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var dir = try std.Io.Dir.openDirAbsolute(io, corpus_dir, .{});
    defer dir.close(io);

    inline for (conformance_invalid) |name| {
        runInvalidCase(allocator, io, dir, name) catch |err| {
            std.debug.print("[FAIL] invalid/{s}: {s}\n", .{ name, @errorName(err) });
            return err;
        };
    }
}

fn runValidCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    comptime name: []const u8,
) !void {
    const yaml_bytes = try dir.readFileAlloc(io, "valid/" ++ name ++ ".yaml", allocator, max_corpus_bytes);
    defer allocator.free(yaml_bytes);
    const json_bytes = try dir.readFileAlloc(io, "valid/" ++ name ++ ".json", allocator, max_corpus_bytes);
    defer allocator.free(json_bytes);

    var got = try parseFromSlice(allocator, yaml_bytes);
    defer got.deinit();

    var want = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer want.deinit();

    if (!deepEqual(got.value, want.value)) return error.ValueMismatch;
}

fn runInvalidCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    comptime name: []const u8,
) !void {
    const yaml_bytes = try dir.readFileAlloc(io, "invalid/" ++ name ++ ".yaml", allocator, max_corpus_bytes);
    defer allocator.free(yaml_bytes);

    var parsed = parseFromSlice(allocator, yaml_bytes) catch return;
    defer parsed.deinit();
    return error.ExpectedParseError;
}

fn deepEqual(a: std.json.Value, b: std.json.Value) bool {
    if (std.meta.activeTag(a) != std.meta.activeTag(b)) return false;
    return switch (a) {
        .null => true,
        .bool => a.bool == b.bool,
        .integer => a.integer == b.integer,
        .float => a.float == b.float,
        .number_string => std.mem.eql(u8, a.number_string, b.number_string),
        .string => std.mem.eql(u8, a.string, b.string),
        .array => arrEq(a.array, b.array),
        .object => objEq(a.object, b.object),
    };
}

fn arrEq(a: std.json.Array, b: std.json.Array) bool {
    if (a.items.len != b.items.len) return false;
    for (a.items, b.items) |x, y| if (!deepEqual(x, y)) return false;
    return true;
}

fn objEq(a: std.json.ObjectMap, b: std.json.ObjectMap) bool {
    if (a.count() != b.count()) return false;
    var it = a.iterator();
    while (it.next()) |e| {
        const o = b.get(e.key_ptr.*) orelse return false;
        if (!deepEqual(e.value_ptr.*, o)) return false;
    }
    return true;
}
