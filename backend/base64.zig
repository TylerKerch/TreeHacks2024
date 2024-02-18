const std = @import("std");
const base64 = @import("base64.zig"); // Assume the provided code is in base64.zig

export fn decodeBase64(encoded: [*c]const u8, encoded_len: usize, decoded: [*]u8, decoded_len: *usize) c_int {
    var allocator = std.heap.page_allocator;
    const encoded_slice = std.mem.slice(u8, encoded, encoded_len);
    var buffer = try allocator.alloc(u8, base64.standard.Decoder.calcSizeForSlice(encoded_slice) catch return -1);

    defer allocator.free(buffer);

    // Attempt to decode the base64 encoded string
    try base64.standard.Decoder.decode(buffer, encoded_slice) catch return -1;

    // Ensure the decoded buffer fits in the provided output buffer
    if (buffer.len > decoded_len.*) {
        return -2; // Output buffer is too small
    }

    // Copy the decoded bytes to the output buffer
    std.mem.copy(u8, decoded, buffer);
    decoded_len.* = buffer.len;

    return 0; // Success
}
