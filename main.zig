const std = @import("std");

// ProgramExit happens when the user inputs q into an equation and is used to gracefully exit
const errors = error{
    ProgramExit,
    InputError,
    MathError,
    OutOfMemory,
};

const possible_numbers = [_]u8{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' };
const possible_symbols = [_]u8{ '+', '-', '*', '/', '%', '^', '_' };

fn evaluateInputAndCount(input: *std.ArrayList(u8)) errors!i512 {
    var numbers = std.ArrayList(i512).init(std.heap.page_allocator);
    defer numbers.deinit();
    var symbols = std.ArrayList(u8).init(std.heap.page_allocator);
    defer symbols.deinit();

    var same_number: bool = undefined;
    var tmp_number: i512 = 0;
    var index: u64 = 0;
    while (index < input.*.items.len) {
        // std.debug.print("{d}\n", .{index});
        if (input.*.items[index] == '(') {
            var inp_in_parenth = std.ArrayList(u8).init(std.heap.page_allocator);
            defer inp_in_parenth.deinit();
            if (input.*.items.len == 1) return errors.MathError;
            var additional_parenths: u16 = 0;
            while (input.*.items[index + 1] != ')' or additional_parenths > 0) : (index += 1) {
                if (input.*.items[index + 1] == '(') additional_parenths += 1 else if (input.*.items[index + 1] == ')') additional_parenths -= 1;
                try inp_in_parenth.append(input.*.items[index + 1]);
                if (input.*.items.len <= index + 2) return errors.MathError;
            }
            index += 2;
            tmp_number = try evaluateInputAndCount(&inp_in_parenth);
            continue;
        }
        same_number = false;
        for (possible_numbers) |possible_number| {
            if (possible_number == input.*.items[index]) {
                same_number = true;
                break;
            }
        }
        if (!same_number) {
            for (possible_symbols) |possible_symbol| {
                if (possible_symbol == input.*.items[index]) {
                    if (!(possible_symbol == '_')) {
                        try numbers.append(tmp_number);
                    }
                    tmp_number = 0;
                    try symbols.append(input.*.items[index]);
                    break;
                }
            }
        } else {
            tmp_number *%= 10;
            tmp_number +%= input.*.items[index] - 48;
        }
        if (input.*.items[index] == 'q') return errors.ProgramExit;

        index += 1;
    }
    try numbers.append(tmp_number);

    // ! This is just for debugging!
    // std.debug.print("numbers: ", .{});
    // for (numbers.items) |number| std.debug.print("{d} ", .{number});
    // std.debug.print("\n", .{});
    // std.debug.print("symbols: ", .{});
    // for (symbols.items) |symbol| std.debug.print("{c} ", .{symbol});
    // std.debug.print("\n", .{});

    var i: u64 = 0;
    var x: i512 = undefined;
    tmp_number = 0;
    var tmp_unsigned_number: u512 = 0;
    while (symbols.items.len > i) {
        if (symbols.items[i] == '^') {
            if (numbers.items[i + 1] != 0) {
                x = numbers.items[i + 1] - 1;
                tmp_number = numbers.items[i];

                while (x > 0) : (x -= 1) {
                    tmp_number = tmp_number *% numbers.items[i];
                }
            } else tmp_number = 1;

            _ = numbers.orderedRemove(i);
            _ = numbers.orderedRemove(i);
            _ = symbols.orderedRemove(i);
            try numbers.insert(i, tmp_number);
        } else if (symbols.items[i] == '_') {
            if (numbers.items[i] >= 0) {
                tmp_unsigned_number = std.math.sqrt(@as(u512, @intCast(numbers.items[i])));
            }
            _ = numbers.orderedRemove(i);
            _ = symbols.orderedRemove(i);
            try numbers.insert(i, @as(i512, @intCast(tmp_unsigned_number)));
        } else {
            i += 1;
        }
    }
    i = 0;
    while (symbols.items.len > i) {
        if (symbols.items[i] == '*') {
            tmp_number = numbers.items[i] *% numbers.items[i + 1];
            _ = numbers.orderedRemove(i);
            _ = numbers.orderedRemove(i);
            _ = symbols.orderedRemove(i);
            try numbers.insert(i, tmp_number);
        } else if (symbols.items[i] == '/') {
            if (numbers.items[i + 1] == 0) return errors.MathError;
            tmp_number = @divExact(numbers.items[i], numbers.items[i + 1]);
            _ = numbers.orderedRemove(i);
            _ = numbers.orderedRemove(i);
            _ = symbols.orderedRemove(i);
            try numbers.insert(i, tmp_number);
        } else if (symbols.items[i] == '%') {
            if (numbers.items[i + 1] == 0) return errors.MathError;
            tmp_number = @mod(numbers.items[i], numbers.items[i + 1]);
            _ = numbers.orderedRemove(i);
            _ = numbers.orderedRemove(i);
            _ = symbols.orderedRemove(i);
            try numbers.insert(i, tmp_number);
        } else {
            i += 1;
        }
    }
    i = 0;
    while (symbols.items.len > i) {
        if (symbols.items[i] == '+') {
            tmp_number = numbers.items[i] +% numbers.items[i + 1];
            _ = numbers.orderedRemove(i);
            _ = numbers.orderedRemove(i);
            _ = symbols.orderedRemove(i);
            try numbers.insert(i, tmp_number);
        } else if (symbols.items[i] == '-') {
            tmp_number = numbers.items[i] -% numbers.items[i + 1];
            _ = numbers.orderedRemove(i);
            _ = numbers.orderedRemove(i);
            _ = symbols.orderedRemove(i);
            try numbers.insert(i, tmp_number);
        } else {
            i += 1;
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
