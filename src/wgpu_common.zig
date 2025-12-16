const std = @import("std");
const zgpu_options = @import("zgpu_options");

const backend = zgpu_options.webgpu_backend;

const WGPU_STRLEN = std.math.maxInt(usize);

const bit_copy_src: u64 = 0x0000000000000001;
const bit_copy_dst: u64 = 0x0000000000000002;
const bit_texture_binding: u64 = 0x0000000000000004;
const bit_storage_binding: u64 = 0x0000000000000008;
const bit_render_attachment: u64 = 0x0000000000000010;
const bit_transient_attachment: u64 = 0x0000000000000020;
const bit_storage_attachment: u64 = 0x0000000000000040;

const WgpuTextureUsage = packed struct(u32) {
    copy_src: bool = false,
    copy_dst: bool = false,
    texture_binding: bool = false,
    storage_binding: bool = false,
    render_attachment: bool = false,
    transient_attachment: bool = false,
    storage_attachment: bool = false,
    _padding: u25 = 0,
};

pub const TextureUsage = if (backend == .dawn) u64 else WgpuTextureUsage;

fn withBits(bits: u64) TextureUsage {
    if (backend == .dawn) {
        return @as(TextureUsage, bits);
    } else {
        return WgpuTextureUsage{
            .copy_src = (bits & bit_copy_src) != 0,
            .copy_dst = (bits & bit_copy_dst) != 0,
            .texture_binding = (bits & bit_texture_binding) != 0,
            .storage_binding = (bits & bit_storage_binding) != 0,
            .render_attachment = (bits & bit_render_attachment) != 0,
            .transient_attachment = (bits & bit_transient_attachment) != 0,
            .storage_attachment = (bits & bit_storage_attachment) != 0,
            ._padding = 0,
        };
    }
}

fn bitsOf(value: TextureUsage) u64 {
    if (backend == .dawn) {
        return @as(u64, value);
    } else {
        const usage = @as(WgpuTextureUsage, value);
        var result: u64 = 0;
        if (usage.copy_src) result |= bit_copy_src;
        if (usage.copy_dst) result |= bit_copy_dst;
        if (usage.texture_binding) result |= bit_texture_binding;
        if (usage.storage_binding) result |= bit_storage_binding;
        if (usage.render_attachment) result |= bit_render_attachment;
        if (usage.transient_attachment) result |= bit_transient_attachment;
        if (usage.storage_attachment) result |= bit_storage_attachment;
        return result;
    }
}

pub inline fn combineUsage(a: TextureUsage, b: TextureUsage) TextureUsage {
    return withBits(bitsOf(a) | bitsOf(b));
}

pub inline fn contains(self: TextureUsage, other: TextureUsage) bool {
    const self_bits = bitsOf(self);
    const other_bits = bitsOf(other);
    return (self_bits & other_bits) == other_bits;
}

pub const WGPUStringView = extern struct {
    data: ?[*]const u8 = null,
    length: usize = WGPU_STRLEN,
};

pub const StringView = extern struct {
    data: ?[*]const u8 = null,
    length: usize = WGPU_STRLEN,

    pub inline fn fromSlice(slice: []const u8) StringView {
        return StringView{
            .data = slice.ptr,
            .length = slice.len,
        };
    }

    pub fn toSlice(self: StringView) ?[]const u8 {
        const data = self.data orelse return null;

        if (self.length == WGPU_STRLEN) {
            return std.mem.sliceTo(@as([*:0]const u8, @ptrCast(data)), 0);
        }

        return data[0..self.length];
    }
};

pub const TextureUsages = struct {
    pub const none = withBits(0);
    pub const copy_src = withBits(bit_copy_src);
    pub const copy_dst = withBits(bit_copy_dst);
    pub const texture_binding = withBits(bit_texture_binding);
    pub const storage_binding = withBits(bit_storage_binding);
    pub const render_attachment = withBits(bit_render_attachment);
    pub const transient_attachment = withBits(bit_transient_attachment);
    pub const storage_attachment = withBits(bit_storage_attachment);
};
