const std = @import("std");

// ProgramExit happens when the user inputs q into an equation and is used to gracefully exit
const errors = error{
    ProgramExit,
    InputError,
    MathError,
    OutOfMemory,
};

const possible_numbers = [_]u8{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' };
const possible_symbols = [_]u8{ '+', '-', '*', '/', '%', '^' };

fn evaluateInputAndCount(input: *std.ArrayList(u8)) errors!i512 {
    var numbers = std.ArrayList(i512).init(std.heap.page_allocator);
    defer numbers.deinit();
    var symbols = std.ArrayList(u8).init(std.heap.page_allocator);
    defer symbols.deinit();

    var same_number: bool = undefined;
    var tmp_number: i512 = 0;
    for (input.*.items) |letter| {
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
            tmp_number *%= 10;
            tmp_number +%= letter - 48;
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

    var x: i512 = undefined;
    tmp_number = 0;
    for (symbols.items) |symbol| {
        if (symbol == '+') {
            tmp_number = numbers.items[0] +% numbers.items[1];
            _ = numbers.orderedRemove(0);
            _ = numbers.orderedRemove(0);
            try numbers.insert(0, tmp_number);
        } else if (symbol == '-') {
            tmp_number = numbers.items[0] -% numbers.items[1];
            _ = numbers.orderedRemove(0);
            _ = numbers.orderedRemove(0);
            try numbers.insert(0, tmp_number);
        } else if (symbol == '*') {
            tmp_number = numbers.items[0] *% numbers.items[1];
            _ = numbers.orderedRemove(0);
            _ = numbers.orderedRemove(0);
            try numbers.insert(0, tmp_number);
        } else if (symbol == '/') {
            if (numbers.items[1] == 0) return errors.MathError;
            tmp_number = @divFloor(numbers.items[0], numbers.items[1]);
            _ = numbers.orderedRemove(0);
            _ = numbers.orderedRemove(0);
            try numbers.insert(0, tmp_number);
        } else if (symbol == '%') {
            if (numbers.items[1] == 0) return errors.MathError;
            tmp_number = @mod(numbers.items[0], numbers.items[1]);
            _ = numbers.orderedRemove(0);
            _ = numbers.orderedRemove(0);
            try numbers.insert(0, tmp_number);
        } else if (symbol == '^') {
            if (numbers.items[1] != 0) {
                x = numbers.items[1] - 1;
                tmp_number = numbers.items[0];

                while (x > 0) : (x -= 1) {
                    tmp_number = tmp_number *% numbers.items[0];
                }
            } else tmp_number = 1;

            _ = numbers.orderedRemove(0);
            _ = numbers.orderedRemove(0);
            try numbers.insert(0, tmp_number);
        }
    }

    return numbers.items[0];
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var input = std.ArrayList(u8).init(std.heap.page_allocator);
    while (true) {
        try stdin.streamUntilDelimiter(input.writer(), '\n', null);
        defer input.clearAndFree();
        const result = evaluateInputAndCount(&input) catch |err| {
            if (err == errors.ProgramExit) {
                return;
            } else if (err == errors.MathError) {
                try stdout.writeAll("Error: MathError\n");
                continue;
            } else return err;
        };
        try stdout.print("Result: {}\n", .{result});
    }
}
