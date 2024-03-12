const std = @import("std");

// These are all the errors this program can return
// The only ones that should be able to happen are ProgramExit, OutOfMemory and maybe InputError
// ProgramExit happens when the user inputs q into an equation and is used to gracefully exit
const errors = error{
    ProgramExit,
    InputError,
    OutOfMemory,
    DiskQuota,
    FileTooBig,
    InputOutput,
    NoSpaceLeft,
    DeviceBusy,
    InvalidArgument,
    AccessDenied,
    BrokenPipe,
    SystemResources,
    OperationAborted,
    NotOpenForWriting,
    LockViolation,
    WouldBlock,
    ConnectionResetByPeer,
    Unexpected,
};

fn getInput(buf: anytype) ![]u8 {
    const stdin = std.io.getStdIn().reader();
    const input = (try stdin.readUntilDelimiterOrEof(buf.*[0..], '\n')).?;
    return input;
}

fn evaluateInputAndCount(input: anytype) errors!i512 {
    var numbers = std.ArrayList(i512).init(std.heap.page_allocator);
    defer numbers.deinit();
    var symbols = std.ArrayList(u8).init(std.heap.page_allocator);
    defer symbols.deinit();

    const possible_numbers = [_]u8{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' };
    const possible_symbols = [_]u8{ '+', '-', '*', '/' };
    var same_number: bool = undefined;
    var tmp_number: i512 = 0;
    for (input) |letter| {
        same_number = false;
        for (possible_numbers) |possible_number| {
            if (possible_number == letter) {
                same_number = true;
                break;
            }
        }
        if (!same_number) {
            for (possible_symbols) |possible_symbol| {
                if (possible_symbol == letter) {
                    try numbers.append(tmp_number);
                    tmp_number = 0;
                    try symbols.append(letter);
                    break;
                }
            }
        } else {
            tmp_number *= 10;
            tmp_number += letter - 48;
        }

        if (letter == 'q') return errors.ProgramExit;
    }
    try numbers.append(tmp_number);

    // ! This is just for debugging!
    // const stdout = std.io.getStdOut().writer();
    // try stdout.writeAll("numbers: ");
    // for (numbers.items) |number| try stdout.print("{d} ", .{number});
    // try stdout.writeAll("\n");
    // try stdout.writeAll("symbols: ");
    // for (symbols.items) |symbol| try stdout.print("{c} ", .{symbol});
    // try stdout.writeAll("\n");

    tmp_number = 0;
    for (symbols.items) |symbol| {
        if (symbol == '+') {
            tmp_number = numbers.items[0] + numbers.items[1];
            _ = numbers.orderedRemove(0);
            _ = numbers.orderedRemove(0);
            try numbers.insert(0, tmp_number);
        } else if (symbol == '-') {
            tmp_number = numbers.items[0] - numbers.items[1];
            _ = numbers.orderedRemove(0);
            _ = numbers.orderedRemove(0);
            try numbers.insert(0, tmp_number);
        } else if (symbol == '*') {
            tmp_number = numbers.items[0] * numbers.items[1];
            _ = numbers.orderedRemove(0);
            _ = numbers.orderedRemove(0);
            try numbers.insert(0, tmp_number);
        } else if (symbol == '/') {
            tmp_number = @divFloor(numbers.items[0], numbers.items[1]);
            _ = numbers.orderedRemove(0);
            _ = numbers.orderedRemove(0);
            try numbers.insert(0, tmp_number);
        }
    }

    return numbers.items[0];
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var buf: [500]u8 = undefined;
    while (true) {
        buf = undefined;
        const input = try getInput(&buf);
        const result = evaluateInputAndCount(input) catch |err| {
            if (err == errors.ProgramExit) break else return err;
        };
        try stdout.print("Result: {}\n", .{result});
    }
}
