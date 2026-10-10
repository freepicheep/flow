const std = @import("std");
const Buffer = @import("Buffer");
const Cursor = @import("Buffer").Cursor;
const Result = @import("command").Result;
const fmt_command = @import("command").fmt;

const helix = @import("tui").exports.mode.helix;
const Editor = @import("tui").exports.editor.Editor;

const a = std.testing.allocator;

fn apply_movements(movements: []const u8, root: Buffer.Root, cursor: *Cursor, the_metrics: Buffer.Metrics, row: usize, col: usize) Result {
    for (movements) |move| {
        switch (move) {
            'W' => {
                try helix.test_internal.move_cursor_long_word_right(root, cursor, the_metrics);
            },
            'B' => {
                try helix.test_internal.move_cursor_long_word_left(root, cursor, the_metrics);
            },
            'E' => {
                try helix.test_internal.move_cursor_long_word_right_end(root, cursor, the_metrics);
            },
            'w' => {
                try Editor.move_cursor_word_right_vim(root, cursor, the_metrics);
            },
            'b' => {
                try helix.test_internal.move_cursor_word_left_helix(root, cursor, the_metrics);
            },
            'e' => {
                try helix.test_internal.move_cursor_word_right_end_helix(root, cursor, the_metrics);
            },
            else => {
                return error.Stop;
            },
        }
    }
    try std.testing.expectEqual(col, cursor.col);
    try std.testing.expectEqual(row, cursor.row);
}

const MoveExpected = struct {
    moves: []const u8,
    row: usize,
    col: usize,
};

fn metrics() Buffer.Metrics {
    return .{
        .ctx = undefined,
        .egc_length = struct {
            fn f(_: Buffer.Metrics, _: []const u8, colcount: *usize, _: usize) usize {
                colcount.* = 1;
                return 1;
            }
        }.f,
        .egc_chunk_width = struct {
            fn f(_: Buffer.Metrics, chunk_: []const u8, _: usize) usize {
                return chunk_.len;
            }
        }.f,
        .egc_last = struct {
            fn f(_: Buffer.Metrics, _: []const u8) []const u8 {
                @panic("not implemented");
            }
        }.f,
        .tab_width = 8,
    };
}
const doc: []const u8 =
    \\gawk '{print length($0) }' testflowhelixwbe.txt  | tr '\n' ' 'i
    \\
    \\Allows you to know what is the length of each line ^^^^
    \\a small $% Test.here,   with.things()to demo
    \\ with surrounding.space    a bb  AA   a small and long
    \\
    \\  
    \\nospace.
    \\   try std.testing.expectEqual(Buffer.Cursor{ .row = 0, .col = 0 }, buffer.root.byte_offset_to_line_and_col(0, test_metrics(), eol_mode));
    \\
    \\
    \\  $$%.  []{{}. dart de
    \\da
;

var eol_mode: Buffer.EolMode = .lf;
var sanitized: bool = false;

test "words_movement" {
    const now = std.Io.Clock.real.now(std.testing.io);
    const buffer = try Buffer.create(a, now);
    defer buffer.deinit();
    buffer.update(try buffer.load_from_string(doc, &eol_mode, &sanitized), now);
    const root: Buffer.Root = buffer.root;
    var the_cursor = Cursor{ .row = 1, .col = 1, .target = 0 };

    the_cursor.col = 1;
    the_cursor.row = 0;

    const movements: [12]MoveExpected = .{
        .{ .moves = "b", .row = 0, .col = 0 },
        .{ .moves = "w", .row = 0, .col = 5 },
        .{ .moves = "b", .row = 0, .col = 1 },
        .{ .moves = "ww", .row = 0, .col = 7 },
        .{ .moves = "bb", .row = 0, .col = 1 },
        .{ .moves = "www", .row = 0, .col = 13 },
        .{ .moves = "bbb", .row = 0, .col = 1 },
        .{ .moves = "wwww", .row = 0, .col = 19 },
        .{ .moves = "bbbb", .row = 0, .col = 1 },
        .{ .moves = "wb", .row = 0, .col = 1 },
        .{ .moves = "e", .row = 0, .col = 4 },
        .{ .moves = "b", .row = 0, .col = 1 },
    };
    for (movements) |move| {
        try apply_movements(move.moves, root, &the_cursor, metrics(), move.row, move.col);
    }
    the_cursor.row = 11;
    the_cursor.col = 1;

    const more_movements: [2]MoveExpected = .{
        .{ .moves = "b", .row = 8, .col = 135 },
        .{ .moves = "w", .row = 11, .col = 2 },
    };
    for (more_movements) |move| {
        try apply_movements(move.moves, root, &the_cursor, metrics(), move.row, move.col);
    }
}

test "edge_word_movements" {
    const now = std.Io.Clock.real.now(std.testing.io);
    const buffer = try Buffer.create(a, now);
    defer buffer.deinit();
    buffer.update(try buffer.load_from_string(doc, &eol_mode, &sanitized), now);
    const root: Buffer.Root = buffer.root;
    var cursor = Cursor{ .row = 1, .col = 1, .target = 0 };
    cursor.col = 0;
    cursor.row = 0;
    const expected_error = error.Stop;
    var result = helix.test_internal.move_cursor_word_left_helix(root, &cursor, metrics());
    try std.testing.expectError(expected_error, result);
    try std.testing.expectEqual(0, cursor.row);
    try std.testing.expectEqual(0, cursor.col);

    result = helix.test_internal.move_cursor_long_word_left(root, &cursor, metrics());
    try std.testing.expectError(expected_error, result);
    try std.testing.expectEqual(0, cursor.row);
    try std.testing.expectEqual(0, cursor.col);
}

test "long_words_movement" {
    const now = std.Io.Clock.real.now(std.testing.io);
    const buffer = try Buffer.create(a, now);
    defer buffer.deinit();
    buffer.update(try buffer.load_from_string(doc, &eol_mode, &sanitized), now);
    const root: Buffer.Root = buffer.root;
    var the_cursor = Cursor{ .row = 1, .col = 1, .target = 0 };

    the_cursor.col = 1;
    the_cursor.row = 0;

    const movements: [12]MoveExpected = .{
        .{ .moves = "B", .row = 0, .col = 0 },
        .{ .moves = "W", .row = 0, .col = 5 },
        .{ .moves = "B", .row = 0, .col = 1 },
        .{ .moves = "WW", .row = 0, .col = 13 },
        .{ .moves = "BB", .row = 0, .col = 1 },
        .{ .moves = "WWW", .row = 0, .col = 24 },
        .{ .moves = "BBB", .row = 0, .col = 1 },
        .{ .moves = "WWWW", .row = 0, .col = 27 },
        .{ .moves = "BBBB", .row = 0, .col = 1 },
        .{ .moves = "WB", .row = 0, .col = 1 },
        .{ .moves = "E", .row = 0, .col = 4 },
        .{ .moves = "B", .row = 0, .col = 1 },
    };

    for (movements) |move| {
        try apply_movements(move.moves, root, &the_cursor, metrics(), move.row, move.col);
    }
}

test "to_char_right_beyond_eol" {
    const now = std.Io.Clock.real.now(std.testing.io);
    const buffer = try Buffer.create(a, now);
    defer buffer.deinit();
    buffer.update(try buffer.load_from_string(doc, &eol_mode, &sanitized), now);
    const root: Buffer.Root = buffer.root;
    var the_cursor = Cursor{ .row = 1, .col = 1, .target = 0 };

    the_cursor.col = 0;
    the_cursor.row = 0;
    const expected_error = error.Stop;

    // Not found to begin of file
    var result = helix.test_internal.move_cursor_to_char_left_beyond_eol(root, &the_cursor, metrics(), fmt_command(.{"a"}));
    try std.testing.expectError(expected_error, result);
    try std.testing.expectEqual(0, the_cursor.row);
    try std.testing.expectEqual(0, the_cursor.col);

    // Move found in the next line
    try helix.test_internal.move_cursor_to_char_right_beyond_eol(root, &the_cursor, metrics(), fmt_command(.{"T"}));
    try std.testing.expectEqual(3, the_cursor.row);
    try std.testing.expectEqual(11, the_cursor.col);

    // Move found in the previous line
    try helix.test_internal.move_cursor_to_char_left_beyond_eol(root, &the_cursor, metrics(), fmt_command(.{"t"}));
    try std.testing.expectEqual(2, the_cursor.row);
    try std.testing.expectEqual(35, the_cursor.col);

    // Not found to end of buffer, cursor not moved
    result = helix.test_internal.move_cursor_to_char_right_beyond_eol(root, &the_cursor, metrics(), fmt_command(.{"Z"}));
    try std.testing.expectError(expected_error, result);
    try std.testing.expectEqual(2, the_cursor.row);
    try std.testing.expectEqual(35, the_cursor.col);

    // Not found to begin of buffer
    result = helix.test_internal.move_cursor_to_char_left_beyond_eol(root, &the_cursor, metrics(), fmt_command(.{"Z"}));
    try std.testing.expectError(expected_error, result);
    try std.testing.expectEqual(2, the_cursor.row);
    try std.testing.expectEqual(35, the_cursor.col);

    // till char difference
    // Move found in the next line
    try helix.test_internal.move_cursor_till_char_right_beyond_eol(root, &the_cursor, metrics(), fmt_command(.{"T"}));
    try std.testing.expectEqual(3, the_cursor.row);
    try std.testing.expectEqual(10, the_cursor.col);

    // Move found in the previous line
    try helix.test_internal.move_cursor_till_char_left_beyond_eol(root, &the_cursor, metrics(), fmt_command(.{"t"}));
    try std.testing.expectEqual(2, the_cursor.row);
    try std.testing.expectEqual(36, the_cursor.col);

    // Move found in the same line
    try helix.test_internal.move_cursor_till_char_left_beyond_eol(root, &the_cursor, metrics(), fmt_command(.{"u"}));
    try std.testing.expectEqual(2, the_cursor.row);
    try std.testing.expectEqual(10, the_cursor.col);

    // Move found in the same line
    try helix.test_internal.move_cursor_till_char_right_beyond_eol(root, &the_cursor, metrics(), fmt_command(.{"t"}));
    try std.testing.expectEqual(2, the_cursor.row);
    try std.testing.expectEqual(21, the_cursor.col);
}

// TODO: When at end of file, enter sel mode makes
// difficult to get back and is confusing for users.
// Related to that is the fact that when a selection
// is made, then trying to move to the right, the
// first movement is swallowed

test "insert_line_vim nudges other cursors" {
    const now = std.Io.Clock.real.now(std.testing.io);
    const buffer = try Buffer.create(a, now);
    defer buffer.deinit();
    buffer.update(try buffer.load_from_string("one\ntwo\n", &eol_mode, &sanitized), now);

    var cursor: Cursor = .{ .row = 0, .col = 0 };
    _, const nudge = try Editor.insert_line_vim_at(buffer.root, &cursor, "X\n", buffer.allocator, metrics());

    var other: Cursor = .{ .row = 1, .col = 1 };
    other.nudge_insert(nudge);
    try std.testing.expectEqual(2, other.row);
    try std.testing.expectEqual(1, other.col);
}

test "surround_add nudges other cursors by the inserted brackets only" {
    const now = std.Io.Clock.real.now(std.testing.io);
    const buffer = try Buffer.create(a, now);
    defer buffer.deinit();
    buffer.update(try buffer.load_from_string("foo bar baz\n", &eol_mode, &sanitized), now);

    const sel: Buffer.Selection = .{ .begin = .{ .row = 0, .col = 4 }, .end = .{ .row = 0, .col = 7 } };
    _, const enclosed, const nudges = try helix.test_internal.surround_add(buffer.root, sel, "(", ")", buffer.allocator, metrics());

    var inside: Cursor = .{ .row = 0, .col = 5 };
    for (nudges) |nudge| inside.nudge_insert(nudge);
    try std.testing.expectEqual(6, inside.col);

    var after: Cursor = .{ .row = 0, .col = 9 };
    for (nudges) |nudge| after.nudge_insert(nudge);
    try std.testing.expectEqual(11, after.col);

    try std.testing.expectEqual(4, enclosed.begin.col);
    try std.testing.expectEqual(9, enclosed.end.col);
}

test "helix h and l do not wrap lines" {
    const now = std.Io.Clock.real.now(std.testing.io);
    const buffer = try Buffer.create(a, now);
    defer buffer.deinit();
    buffer.update(try buffer.load_from_string("ab\ncd\n", &eol_mode, &sanitized), now);
    const root = buffer.root;

    var cursor: Cursor = .{ .row = 1, .col = 0 };
    try helix.test_internal.move_cursor_char_left_helix(root, &cursor, metrics());
    try std.testing.expectEqual(1, cursor.row);
    try std.testing.expectEqual(0, cursor.col);

    cursor = .{ .row = 0, .col = 1 };
    try helix.test_internal.move_cursor_char_right_helix(root, &cursor, metrics());
    try std.testing.expectEqual(0, cursor.row);
    try std.testing.expectEqual(2, cursor.col);
    // l may rest on the line ending but does not move to the next line
    try helix.test_internal.move_cursor_char_right_helix(root, &cursor, metrics());
    try std.testing.expectEqual(0, cursor.row);
    try std.testing.expectEqual(2, cursor.col);

    try helix.test_internal.move_cursor_char_left_helix(root, &cursor, metrics());
    try std.testing.expectEqual(0, cursor.row);
    try std.testing.expectEqual(1, cursor.col);
}

test "helix gl goes to last character of line" {
    const now = std.Io.Clock.real.now(std.testing.io);
    const buffer = try Buffer.create(a, now);
    defer buffer.deinit();
    buffer.update(try buffer.load_from_string("hello\n\nx\n", &eol_mode, &sanitized), now);
    const root = buffer.root;

    var cursor: Cursor = .{ .row = 0, .col = 1 };
    try helix.test_internal.move_cursor_line_end_helix(root, &cursor, metrics());
    try std.testing.expectEqual(0, cursor.row);
    try std.testing.expectEqual(4, cursor.col);

    cursor = .{ .row = 1, .col = 0 };
    try helix.test_internal.move_cursor_line_end_helix(root, &cursor, metrics());
    try std.testing.expectEqual(1, cursor.row);
    try std.testing.expectEqual(0, cursor.col);
}

test "helix last line ignores trailing newline" {
    const now = std.Io.Clock.real.now(std.testing.io);
    const buffer = try Buffer.create(a, now);
    defer buffer.deinit();
    buffer.update(try buffer.load_from_string("one\ntwo\nthree\n", &eol_mode, &sanitized), now);
    try std.testing.expectEqual(2, helix.test_internal.last_line_helix(buffer.root, metrics()));

    const buffer2 = try Buffer.create(a, now);
    defer buffer2.deinit();
    buffer2.update(try buffer2.load_from_string("one\ntwo", &eol_mode, &sanitized), now);
    try std.testing.expectEqual(1, helix.test_internal.last_line_helix(buffer2.root, metrics()));
}

test "helix extend selection keeps the anchor character" {
    const now = std.Io.Clock.real.now(std.testing.io);
    const buffer = try Buffer.create(a, now);
    defer buffer.deinit();
    buffer.update(try buffer.load_from_string("one\ntwo\nthree\n", &eol_mode, &sanitized), now);
    const root = buffer.root;

    // forward selection of "w" (row 1, col 1) extended down to row 2 col 0
    var sel: Buffer.Selection = .{ .begin = .{ .row = 1, .col = 1 }, .end = .{ .row = 1, .col = 2 } };
    helix.test_internal.extend_selection_to(root, &sel, .{ .row = 2, .col = 0 }, metrics());
    try std.testing.expectEqual(Cursor{ .row = 1, .col = 1 }, Cursor{ .row = sel.begin.row, .col = sel.begin.col });
    try std.testing.expectEqual(Cursor{ .row = 2, .col = 1 }, Cursor{ .row = sel.end.row, .col = sel.end.col });

    // now extend up to the file start: selection flips but still includes "w"
    helix.test_internal.extend_selection_to(root, &sel, .{ .row = 0, .col = 0 }, metrics());
    try std.testing.expect(sel.is_reversed());
    try std.testing.expectEqual(Cursor{ .row = 1, .col = 2 }, Cursor{ .row = sel.begin.row, .col = sel.begin.col });
    try std.testing.expectEqual(Cursor{ .row = 0, .col = 0 }, Cursor{ .row = sel.end.row, .col = sel.end.col });

    // and back down again: forward selection anchored at "w"
    helix.test_internal.extend_selection_to(root, &sel, .{ .row = 1, .col = 2 }, metrics());
    try std.testing.expect(!sel.is_reversed());
    try std.testing.expectEqual(Cursor{ .row = 1, .col = 1 }, Cursor{ .row = sel.begin.row, .col = sel.begin.col });
    try std.testing.expectEqual(Cursor{ .row = 1, .col = 3 }, Cursor{ .row = sel.end.row, .col = sel.end.col });
}

test "helix extend and shrink to line bounds" {
    const now = std.Io.Clock.real.now(std.testing.io);
    const buffer = try Buffer.create(a, now);
    defer buffer.deinit();
    buffer.update(try buffer.load_from_string("one\ntwo\nthree\n", &eol_mode, &sanitized), now);
    const root = buffer.root;

    var sel: Buffer.Selection = .{ .begin = .{ .row = 0, .col = 1 }, .end = .{ .row = 1, .col = 2 } };
    helix.test_internal.extend_selection_to_line_bounds(root, &sel, metrics());
    try std.testing.expectEqual(Cursor{ .row = 0, .col = 0 }, Cursor{ .row = sel.begin.row, .col = sel.begin.col });
    try std.testing.expectEqual(Cursor{ .row = 2, .col = 0 }, Cursor{ .row = sel.end.row, .col = sel.end.col });

    // already line-wise: unchanged
    helix.test_internal.extend_selection_to_line_bounds(root, &sel, metrics());
    try std.testing.expectEqual(Cursor{ .row = 0, .col = 0 }, Cursor{ .row = sel.begin.row, .col = sel.begin.col });
    try std.testing.expectEqual(Cursor{ .row = 2, .col = 0 }, Cursor{ .row = sel.end.row, .col = sel.end.col });

    // reversed selection stays reversed
    sel = .{ .begin = .{ .row = 1, .col = 2 }, .end = .{ .row = 0, .col = 1 } };
    helix.test_internal.extend_selection_to_line_bounds(root, &sel, metrics());
    try std.testing.expect(sel.is_reversed());
    try std.testing.expectEqual(Cursor{ .row = 2, .col = 0 }, Cursor{ .row = sel.begin.row, .col = sel.begin.col });
    try std.testing.expectEqual(Cursor{ .row = 0, .col = 0 }, Cursor{ .row = sel.end.row, .col = sel.end.col });

    // shrink: partial first and last lines are dropped
    sel = .{ .begin = .{ .row = 0, .col = 1 }, .end = .{ .row = 2, .col = 3 } };
    try std.testing.expect(helix.test_internal.shrink_selection_to_line_bounds(&sel));
    try std.testing.expectEqual(Cursor{ .row = 1, .col = 0 }, Cursor{ .row = sel.begin.row, .col = sel.begin.col });
    try std.testing.expectEqual(Cursor{ .row = 2, .col = 0 }, Cursor{ .row = sel.end.row, .col = sel.end.col });

    // single line selections are left alone
    sel = .{ .begin = .{ .row = 0, .col = 1 }, .end = .{ .row = 0, .col = 3 } };
    try std.testing.expect(!helix.test_internal.shrink_selection_to_line_bounds(&sel));
    try std.testing.expectEqual(1, sel.begin.col);
}

test "helix f t F T skip the character under the head" {
    const now = std.Io.Clock.real.now(std.testing.io);
    const buffer = try Buffer.create(a, now);
    defer buffer.deinit();
    buffer.update(try buffer.load_from_string("abaab\nxa\n", &eol_mode, &sanitized), now);
    const root = buffer.root;
    const find = helix.test_internal.find_char_target_helix;

    // f a on an 'a' goes to the next 'a'
    var c = try find(root, .{ .row = 0, .col = 0 }, .to_right, fmt_command(.{"a"}), metrics());
    try std.testing.expectEqual(Cursor{ .row = 0, .col = 2, .target = 2 }, c);

    // t a stops before the next 'a', skipping an adjacent one
    c = try find(root, .{ .row = 0, .col = 1 }, .till_right, fmt_command(.{"a"}), metrics());
    try std.testing.expectEqual(Cursor{ .row = 0, .col = 2, .target = 2 }, c);
    c = try find(root, c, .till_right, fmt_command(.{"a"}), metrics());
    try std.testing.expectEqual(Cursor{ .row = 1, .col = 0, .target = 0 }, c);

    // F a goes backwards, across lines
    c = try find(root, .{ .row = 1, .col = 1 }, .to_left, fmt_command(.{"a"}), metrics());
    try std.testing.expectEqual(Cursor{ .row = 0, .col = 3, .target = 3 }, c);

    // T a stops after the previous 'a', skipping an adjacent one
    c = try find(root, .{ .row = 0, .col = 4 }, .till_left, fmt_command(.{"a"}), metrics());
    try std.testing.expectEqual(Cursor{ .row = 0, .col = 3, .target = 3 }, c);

    // not found
    try std.testing.expectError(error.Stop, find(root, .{ .row = 0, .col = 0 }, .to_right, fmt_command(.{"z"}), metrics()));
}
