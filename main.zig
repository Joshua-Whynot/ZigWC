const std = @import("std");

pub fn main() !void {
    // get command line args
    var args_no_alloc = std.process.args(); // this allocator will not work on windows because we do not have an allocator.

    // skip first item in args (binary being executed)
    _ = args_no_alloc.next(); // assign to _ to ignore

    // get second item as file name
    const file_name = args_no_alloc.next() orelse return std.debug.print("No file name provided\n", .{});

    // Allocator preparation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // prepare hashmap as a string to u32
    var map = std.StringArrayHashMap(u32).init(allocator);
    defer map.deinit();

    // open file
    var file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    //setup buffered reader
    var buffered = std.io.bufferedReader(file.reader());
    var bufreader = buffered.reader();

    // make buffer equal to filesize
    const file_size = file.getEndPos() catch unreachable;
    var buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);
    @memset(buffer, 0);

    // read entire file into buffer
    _ = try bufreader.read(buffer[0..]);

    // split buffer into lines
    var lines = std.mem.splitSequence(u8, buffer, "\n");

    // total word count incrementer
    var total_word_count: u32 = 0;
    // loop through lines and pass each line into line parser
    while (lines.next()) |line| {
        //check if line contains only spaces, if it does continue
        if (std.mem.trim(u8, line, " ").len == 0) continue;

        // tokenize based on white space only
        var tokens = std.mem.splitSequence(u8, line, " ");

        // loop through tokens and add each token to hashmap.
        while (tokens.next()) |token| {
            // Skip token if it's empty or only whitespace.
            if (std.mem.trim(u8, token, " ").len == 0) continue;

            // check if token is in hashmap
            const entry = map.get(token);
            if (entry) |e| {
                // if it is, increment the value
                try map.put(token, e + 1);
                total_word_count += 1;
            } else {
                // if it is not, add it to the hashmap with a value of 1
                try map.put(token, 1);
                total_word_count += 1;
            }
        }
    }

    // print hashmap
    var it = map.iterator();
    const stdout = std.io.getStdOut().writer(); //standard output

    while (it.next()) |map_entry| {
        //if a word has less than 2 occurrences, do not print it
        if (map_entry.value_ptr.* < 2) continue;
        try stdout.print("{s} {d}\n", .{ map_entry.key_ptr.*, map_entry.value_ptr.* });
    }

    //final output
    try stdout.print("\n", .{});
    try stdout.print("{s} {d}\n", .{ file_name, total_word_count });
}
