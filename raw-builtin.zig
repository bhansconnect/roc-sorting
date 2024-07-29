const std = @import("std");
const sort = @import("vendor/roc_std/sort.zig");

var allocator: std.mem.Allocator = undefined;

const LIMIT = 1000000;

const RandSeed = std.meta.Tuple(&.{ u64, u64 });

const init_rand: RandSeed = .{ 0x69B4C98CB8530805, 0xFED1DD3004688D68 };

fn next_rand_i64(r: RandSeed) std.meta.Tuple(&.{ RandSeed, i64 }) {
    const s0 = r[0];
    const s1 = r[1];
    const ns1: u64 = s0 ^ s1;
    const nr0: u64 = (((s0 << 55) | (s0 >> 9)) ^ ns1) ^ (ns1 << 14);
    const nr1: u64 = (ns1 << 36) | (ns1 >> 28);
    return .{ .{ nr0, nr1 }, @bitCast(s0 +% s1) };
}

fn build_list(size: usize) !std.ArrayList(i64) {
    var list = try std.ArrayList(i64).initCapacity(allocator, size);
    list.appendNTimesAssumeCapacity(0, size);

    var r = init_rand;
    for (0..size) |i| {
        const nr = next_rand_i64(r);
        r = nr[0];
        list.items[i] = nr[1];
    }
    return list;
}

fn test_sort(list: std.ArrayList(i64)) bool {
    for (1..list.items.len) |i| {
        if (list.items[i] < list.items[i - 1]) {
            return false;
        }
    }
    return true;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    allocator = gpa.allocator();

    var list = try build_list(LIMIT);
    defer list.deinit();

    const arr_ptr: [*]i64 = @alignCast(@ptrCast(list.items.ptr));

    var timer = try std.time.Timer.start();
    sort.fluxsort(@ptrCast(arr_ptr), LIMIT, &test_i64_compare, null, true, &test_inc_n_data, @sizeOf(i64), @alignOf(i64), &test_i64_copy);
    var elapsed_ms = timer.read() / 1_000_000;

    std.debug.print("{s}\n", .{if (test_sort(list)) "List sorted correctly!" else "Failure in sorting list!!!"});
    std.debug.print("Sorted {} interges in {} milliseconds.\n", .{ LIMIT, elapsed_ms });
}

const Opaque = ?[*]u8;
fn test_i64_compare(_: Opaque, a_ptr: Opaque, b_ptr: Opaque) callconv(.C) u8 {
    // test this with a switch that may not be branchless in the end.
    const a = @as(*i64, @alignCast(@ptrCast(a_ptr))).*;
    const b = @as(*i64, @alignCast(@ptrCast(b_ptr))).*;

    const gt = @as(u8, @intFromBool(a > b));
    const lt = @as(u8, @intFromBool(a < b));
    // Eq = 0
    // GT = 1
    // LT = 2
    return lt + lt + gt;
}

fn test_i64_copy(dst_ptr: Opaque, src_ptr: Opaque) callconv(.C) void {
    @as(*i64, @alignCast(@ptrCast(dst_ptr))).* = @as(*i64, @alignCast(@ptrCast(src_ptr))).*;
}

fn test_inc_n_data(_: Opaque, _: usize) callconv(.C) void {}

comptime {
    @export(testing_roc_alloc, .{ .name = "roc_alloc", .linkage = .Strong });
    @export(testing_roc_dealloc, .{ .name = "roc_dealloc", .linkage = .Strong });
    @export(testing_roc_panic, .{ .name = "roc_panic", .linkage = .Strong });
}

fn testing_roc_alloc(size: usize, _: u32) callconv(.C) ?*anyopaque {
    // We store an extra usize which is the size of the full allocation.
    const full_size = size + @sizeOf(usize);
    var raw_ptr = (allocator.alloc(u8, full_size) catch unreachable).ptr;
    @as([*]usize, @alignCast(@ptrCast(raw_ptr)))[0] = full_size;
    raw_ptr += @sizeOf(usize);
    return @as(?*anyopaque, @ptrCast(raw_ptr));
}

fn testing_roc_dealloc(c_ptr: *anyopaque, _: u32) callconv(.C) void {
    const raw_ptr = @as([*]u8, @ptrCast(c_ptr)) - @sizeOf(usize);
    const full_size = @as([*]usize, @alignCast(@ptrCast(raw_ptr)))[0];
    const slice = raw_ptr[0..full_size];
    allocator.free(slice);
}

fn testing_roc_panic(c_ptr: *anyopaque, tag_id: u32) callconv(.C) void {
    _ = c_ptr;
    _ = tag_id;

    @panic("Roc panicked");
}
