const std = @import("std");
const Allocator = std.mem.Allocator;
const log = @import("log");
const tp = @import("thespian");
const location_history = @import("location_history");
const command = @import("command");
const cmd = command.executeName;

const tui = @import("../tui.zig");
const Editor = @import("../editor.zig").Editor;
const CurSel = @import("../editor.zig").CurSel;
const Buffer = @import("Buffer");
const Cursor = Buffer.Cursor;
const Selection = Buffer.Selection;

var commands: Commands = undefined;

pub fn init() !void {
    var v: void = {};
    try commands.init(&v);
}

pub fn deinit() void {
    commands.deinit();
}

const Commands = command.Collection(cmds_);
const cmds_ = struct {
    pub const Target = void;
    const Ctx = command.Context;
    const Meta = command.Metadata;
    const Result = command.Result;

    pub fn w(_: *void, ctx: Ctx) Result {
        try cmd("save_file", ctx);
    }
    pub const w_meta: Meta = .{ .description = "w (save)" };

    pub fn @"w!"(_: *void, ctx: Ctx) Result {
        try cmd("force_save_file", ctx);
    }
    pub const @"w!_meta": Meta = .{ .description = "w! (write/save file, overwriting external changes)" };

    pub fn q(_: *void, ctx: Ctx) Result {
        try cmd("quit", ctx);
    }
    pub const q_meta: Meta = .{ .description = "q (quit)" };

    pub fn qa(_: *void, ctx: Ctx) Result {
        try cmd("quit", ctx);
    }
    pub const qa_meta: Meta = .{ .description = "qa (close all)" };

    pub fn @"q!"(_: *void, ctx: Ctx) Result {
        try cmd("quit_without_saving", ctx);
    }
    pub const @"q!_meta": Meta = .{ .description = "q! (quit without saving)" };

    pub fn @"qa!"(_: *void, ctx: Ctx) Result {
        try cmd("quit_without_saving", ctx);
    }
    pub const @"qa!_meta": Meta = .{ .description = "qa! (quit without saving)" };

    pub fn wq(_: *void, _: Ctx) Result {
        try cmd("save_file", .fmt(.{ "then", .{ "quit", .{} } }));
    }
    pub const wq_meta: Meta = .{ .description = "wq (write/save file and quit)" };

    pub fn @"x!"(_: *void, _: Ctx) Result {
        try cmd("force_save_file", .fmt(.{ "then", .{ "quit_without_saving", .{} } }));
    }
    pub const @"x!_meta": Meta = .{ .description = "x! (write/save file and exit, ignoring other unsaved changes)" };

    pub fn x(_: *void, _: Ctx) Result {
        try cmd("save_file", .fmt(.{ "then", .{ "quit", .{} } }));
    }
    pub const x_meta: Meta = .{ .description = "x (write/save file and quit)" };

    pub fn wa(_: *void, _: Ctx) Result {
        if (tui.get_buffer_manager()) |bm|
            bm.save_all(.{}) catch |e| return tp.exit_error(e, @errorReturnTrace());
    }
    pub const wa_meta: Meta = .{ .description = "wa (save all)" };

    pub fn xa(_: *void, _: Ctx) Result {
        if (tui.get_buffer_manager()) |bm|
            bm.save_all(.{ .then = .{ .bytes = tp.message.fmt(.{ "cmd", "quit", .{} }).buf } }) catch |e|
                return tp.exit_error(e, @errorReturnTrace());
    }
    pub const xa_meta: Meta = .{ .description = "xa (write all and quit)" };

    pub fn @"xa!"(_: *void, ctx: Ctx) Result {
        if (tui.get_buffer_manager()) |bm|
            bm.save_all(.{ .then = .{ .bytes = tp.message.fmt(.{ "cmd", "quit_without_saving", .{} }).buf }, .then_on_error = true }) catch
                try cmd("quit_without_saving", .empty_from(ctx));
    }
    pub const @"xa!_meta": Meta = .{ .description = "xa! (write all and exit, ignoring other unsaved changes)" };

    pub fn wqa(_: *void, ctx: Ctx) Result {
        const bm = tui.get_buffer_manager() orelse return cmd("quit", .empty_from(ctx));
        bm.save_all(.{ .then = .{ .bytes = tp.message.fmt(.{ "cmd", "quit", .{} }).buf } }) catch |e|
            return tp.exit_error(e, @errorReturnTrace());
    }
    pub const wqa_meta: Meta = .{ .description = "wqa (write all and quit)" };

    pub fn @"wqa!"(_: *void, ctx: Ctx) Result {
        if (tui.get_buffer_manager()) |bm|
            bm.save_all(.{ .then = .{ .bytes = tp.message.fmt(.{ "cmd", "quit_without_saving", .{} }).buf }, .then_on_error = true }) catch
                try cmd("quit_without_saving", .empty_from(ctx));
    }
    pub const @"wqa!_meta": Meta = .{ .description = "wqa! (write all and exit, ignoring unsaved changes)" };

    pub fn rl(_: *void, ctx: Ctx) Result {
        try cmd("reload_file", .empty_from(ctx));
    }
    pub const rl_meta: Meta = .{ .description = "rl (reload current file)" };

    pub fn rla(_: *void, _: Ctx) Result {
        if (tui.get_buffer_manager()) |bm|
            bm.reload_all() catch |e| return tp.exit_error(e, @errorReturnTrace());
    }
    pub const rla_meta: Meta = .{ .description = "rla (reload all files)" };

    pub fn o(_: *void, ctx: Ctx) Result {
        try cmd("open_file", .empty_from(ctx));
    }
    pub const o_meta: Meta = .{ .description = "o (open file)" };

    pub fn @"wq!"(_: *void, ctx: Ctx) Result {
        cmd("force_save_file", .empty_from(ctx)) catch {};
        try cmd("quit_without_saving", .empty_from(ctx));
    }
    pub const @"wq!_meta": Meta = .{ .description = "wq! (write/save file and quit without saving)" };

    pub fn n(_: *void, ctx: Ctx) Result {
        try cmd("create_new_file", .empty_from(ctx));
    }
    pub const n_meta: Meta = .{ .description = "n (Create new buffer/tab)" };

    pub fn bn(_: *void, ctx: Ctx) Result {
        try cmd("next_tab", .empty_from(ctx));
    }
    pub const bn_meta: Meta = .{ .description = "bn (Next buffer/tab)" };

    pub fn bp(_: *void, ctx: Ctx) Result {
        try cmd("previous_tab", .empty_from(ctx));
    }
    pub const bp_meta: Meta = .{ .description = "bp (Previous buffer/tab)" };

    pub fn bc(_: *void, ctx: Ctx) Result {
        try cmd("delete_buffer", .empty_from(ctx));
    }
    pub const bc_meta: Meta = .{ .description = "bc (Close buffer/tab)" };

    pub fn @"bc!"(_: *void, ctx: Ctx) Result {
        try cmd("close_file_without_saving", .empty_from(ctx));
    }
    pub const @"bc!_meta": Meta = .{ .description = "bc! (Close buffer/tab, ignoring changes)" };

    pub fn @"bco!"(_: *void, _: Ctx) Result {
        const mv = tui.mainview() orelse return;
        if (tui.get_buffer_manager()) |bm| {
            if (mv.get_active_buffer()) |buffer| try bm.delete_others(buffer);
        }
    }
    pub const @"bco!_meta": Meta = .{ .description = "bco! (Close other buffers/tabs, discarding changes)" };

    pub fn bco(_: *void, ctx: Ctx) Result {
        const logger = log.logger("helix-mode");
        defer logger.deinit();
        const mv = tui.mainview() orelse return;
        const bm = tui.get_buffer_manager() orelse return;
        if (mv.get_active_buffer()) |buffer| {
            const remaining = try bm.close_others(buffer);
            if (remaining > 0) {
                logger.print("{} unsaved buffer(s) remaining", .{remaining});
                try cmd("next_tab", .empty_from(ctx));
            }
        }
    }
    pub const bco_meta: Meta = .{ .description = "bco (Close other buffers/tabs)" };

    pub fn save_selection(_: *void, _: Ctx) Result {
        const logger = log.logger("helix-mode");
        defer logger.deinit();
        logger.print("saved location", .{});
        const mv = tui.mainview() orelse return;
        const file_path = mv.get_active_file_path() orelse return;
        const primary = (mv.get_active_editor() orelse return).get_primary();
        const sel: ?location_history.Selection = if (primary.selection) |sel| .{
            .begin = .{ .row = sel.begin.row, .col = sel.begin.col },
            .end = .{ .row = sel.end.row, .col = sel.end.col },
        } else null;
        mv.location_history_.update(file_path, .{
            .row = primary.cursor.row + 1,
            .col = primary.cursor.col + 1,
        }, sel);
    }
    pub const save_selection_meta: Meta = .{ .description = "Save current selection to location history" };

    pub fn split_selection_on_newline(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const root = try ed.buf_root();
        const cursels = try ed.cursels.toOwnedSlice(ed.allocator);
        defer ed.allocator.free(cursels);
        for (cursels) |*cursel_| if (cursel_.*) |*cursel| {
            try add_cursors_to_cursel_line_ends_helix(ed, root, cursel);
        };
        ed.clamp(ctx.now);
    }
    pub const split_selection_on_newline_meta: Meta = .{ .description = "Add cursor to each line in selection helix" };

    pub fn match_brackets(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const root = ed.buf_root() catch return;
        try ed.with_cursels_const_once_arg(root, &match_bracket, ctx);
        ed.clamp(ctx.now);
    }
    pub const match_brackets_meta: Meta = .{ .description = "Go to matching bracket" };

    pub fn extend_line_below(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const root = try ed.buf_root();

        var repeat: usize = 1;
        _ = ctx.args.match(.{tp.extract(&repeat)}) catch false;
        while (repeat > 0) : (repeat -= 1) {
            for (ed.cursels.items) |*cursel_| if (cursel_.*) |*cursel| {
                const sel = cursel.enable_selection_normal();
                sel.normalize();

                try Editor.move_cursor_begin(root, &sel.begin, ed.metrics);
                try Editor.move_cursor_end(root, &sel.end, ed.metrics);
                try Editor.move_cursor_right(root, &sel.end, ed.metrics);
                cursel.cursor = sel.end;
            };
        }

        ed.clamp(ctx.now);
    }
    pub const extend_line_below_meta: Meta = .{ .arguments = &.{.integer}, .description = "Select current line, if already selected, extend to next line" };

    pub fn move_next_word_start(_: *void, ctx: Ctx) Result {
        try move_to_word(ctx, Editor.move_cursor_word_right_vim);
    }
    pub const move_next_word_start_meta: Meta = .{ .description = "Move next word start", .arguments = &.{.integer} };

    pub fn extend_next_word_start(_: *void, ctx: Ctx) Result {
        try extend_to_word(ctx, Editor.move_cursor_word_right_vim);
    }
    pub const extend_next_word_start_meta: Meta = .{ .description = "Extend next word start", .arguments = &.{.integer} };

    pub fn move_next_long_word_start(_: *void, ctx: Ctx) Result {
        try move_to_word(ctx, move_cursor_long_word_right);
    }
    pub const move_next_long_word_start_meta: Meta = .{ .description = "Move next long word start", .arguments = &.{.integer} };

    pub fn extend_next_long_word_start(_: *void, ctx: Ctx) Result {
        try extend_to_word(ctx, move_cursor_long_word_right);
    }
    pub const extend_next_long_word_start_meta: Meta = .{ .description = "Extend next long word start", .arguments = &.{.integer} };

    pub fn move_prev_word_start(_: *void, ctx: Ctx) Result {
        try move_to_word(ctx, move_cursor_word_left_helix);
    }
    pub const move_prev_word_start_meta: Meta = .{ .description = "Move previous word start", .arguments = &.{.integer} };

    pub fn extend_prev_word_start(_: *void, ctx: Ctx) Result {
        try extend_to_word(ctx, move_cursor_word_left_helix);
    }
    pub const extend_prev_word_start_meta: Meta = .{ .description = "Extend previous word start", .arguments = &.{.integer} };

    pub fn move_prev_long_word_start(_: *void, ctx: Ctx) Result {
        try move_to_word(ctx, move_cursor_long_word_left);
    }
    pub const move_prev_long_word_start_meta: Meta = .{ .description = "Move previous long word start", .arguments = &.{.integer} };

    pub fn extend_prev_long_word_start(_: *void, ctx: Ctx) Result {
        try extend_to_word(ctx, move_cursor_long_word_left);
    }
    pub const extend_prev_long_word_start_meta: Meta = .{ .description = "Extend previous word start", .arguments = &.{.integer} };

    pub fn move_next_word_end(_: *void, ctx: Ctx) Result {
        try move_to_word(ctx, move_cursor_word_right_end_helix);
    }
    pub const move_next_word_end_meta: Meta = .{ .description = "Move next word end", .arguments = &.{.integer} };

    pub fn extend_next_word_end(_: *void, ctx: Ctx) Result {
        try extend_to_word(ctx, move_cursor_word_right_end_helix);
    }
    pub const extend_next_word_end_meta: Meta = .{ .description = "Extend next word end", .arguments = &.{.integer} };

    pub fn move_next_long_word_end(_: *void, ctx: Ctx) Result {
        try move_to_word(ctx, move_cursor_long_word_right_end);
    }
    pub const move_next_long_word_end_meta: Meta = .{ .description = "Move next long word end", .arguments = &.{.integer} };

    pub fn extend_next_long_word_end(_: *void, ctx: Ctx) Result {
        try extend_to_word(ctx, move_cursor_long_word_right_end);
    }
    pub const extend_next_long_word_end_meta: Meta = .{ .description = "Extend next long word end", .arguments = &.{.integer} };

    pub fn cut_forward_internal_inclusive(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const b = try ed.buf_for_update();
        tui.clipboard_start_group();
        const root = try ed.cut_to(move_noop, b.root);
        try ed.update_buf(root, ctx.now);
        ed.clamp(ctx.now);
    }
    pub const cut_forward_internal_inclusive_meta: Meta = .{ .description = "Cut next character to internal clipboard (inclusive)" };

    pub fn select_right_helix(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const root = try ed.buf_root();

        var repeat: usize = 1;
        _ = ctx.args.match(.{tp.extract(&repeat)}) catch false;
        while (repeat > 0) : (repeat -= 1) {
            for (ed.cursels.items) |*cursel_| if (cursel_.*) |*cursel| {
                const sel = cursel.enable_selection(root, ed.metrics);

                // handling left to right transition
                const sel_begin: i32 = @intCast(sel.begin.col);
                const sel_end: i32 = @intCast(sel.end.col);
                if ((sel_begin - sel_end) == 1 and sel.begin.row == sel.end.row) {
                    try Editor.move_cursor_right(root, &sel.end, ed.metrics);
                    sel.begin.col -= 1;
                }

                try Editor.move_cursor_right(root, &sel.end, ed.metrics);
                cursel.cursor = sel.end;
                cursel.check_selection(root, ed.metrics);
            };
        }
        ed.clamp(ctx.now);
    }
    pub const select_right_helix_meta: Meta = .{ .description = "Select right", .arguments = &.{.integer} };

    pub fn select_left_helix(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const root = try ed.buf_root();

        var repeat: usize = 1;
        _ = ctx.args.match(.{tp.extract(&repeat)}) catch false;
        while (repeat > 0) : (repeat -= 1) {
            for (ed.cursels.items) |*cursel_| if (cursel_.*) |*cursel| {
                if (cursel.selection == null) {
                    cursel.selection = Selection.from_cursor(&cursel.cursor);
                    try cursel.selection.?.begin.move_right(root, ed.metrics);
                }
                if (cursel.selection) |*sel| {
                    try Editor.move_cursor_left(root, &sel.end, ed.metrics);
                    cursel.cursor = sel.end;

                    if (sel.begin.col == sel.end.col and sel.begin.row == sel.end.row) {
                        try sel.begin.move_right(root, ed.metrics);
                        try Editor.move_cursor_left(root, &sel.end, ed.metrics);
                        cursel.cursor = sel.end;
                    }
                }

                cursel.check_selection(root, ed.metrics);
            };
        }
        ed.clamp(ctx.now);
    }
    pub const select_left_helix_meta: Meta = .{ .description = "Select left", .arguments = &.{.integer} };

    pub fn select_to_char_left_helix(_: *void, ctx: Ctx) Result {
        save_last_char_motion(.to_left, ctx);
        try to_char_helix(ctx, &select_cursel_to_char_left_helix);
    }
    pub const select_to_char_left_helix_meta: Meta = .{ .description = "Select to char left" };

    pub fn select_till_char_left_helix(_: *void, ctx: Ctx) Result {
        save_last_char_motion(.till_left, ctx);
        try to_char_helix(ctx, &select_cursel_till_char_left_helix);
    }
    pub const select_till_char_left_helix_meta: Meta = .{ .description = "Select until char left" };

    pub fn extend_to_char_left_helix(_: *void, ctx: Ctx) Result {
        save_last_char_motion(.to_left, ctx);
        try to_char_helix(ctx, &extend_cursel_to_char_left_helix);
    }
    pub const extend_to_char_left_helix_meta: Meta = .{ .description = "Extend Selection to char left" };

    pub fn extend_till_char_left_helix(_: *void, ctx: Ctx) Result {
        save_last_char_motion(.till_left, ctx);
        try to_char_helix(ctx, &extend_cursel_till_char_left_helix);
    }
    pub const extend_till_char_left_helix_meta: Meta = .{ .description = "Extend Selection until char left" };

    pub fn select_till_char_right_helix(_: *void, ctx: Ctx) Result {
        save_last_char_motion(.till_right, ctx);
        try to_char_helix(ctx, &select_cursel_till_char_right_helix);
    }
    pub const select_till_char_right_helix_meta: Meta = .{ .description = "Select until char right" };

    pub fn select_to_char_right_helix(_: *void, ctx: Ctx) Result {
        save_last_char_motion(.to_right, ctx);
        try to_char_helix(ctx, &select_cursel_to_char_right_helix);
    }
    pub const select_to_char_right_helix_meta: Meta = .{ .description = "Select to char right" };

    pub fn extend_till_char_right_helix(_: *void, ctx: Ctx) Result {
        save_last_char_motion(.till_right, ctx);
        try to_char_helix(ctx, &extend_cursel_till_char_right_helix);
    }
    pub const extend_till_char_right_helix_meta: Meta = .{ .description = "Extend Selection until char right" };

    pub fn extend_to_char_right_helix(_: *void, ctx: Ctx) Result {
        save_last_char_motion(.to_right, ctx);
        try to_char_helix(ctx, &extend_cursel_to_char_right_helix);
    }
    pub const extend_to_char_right_helix_meta: Meta = .{ .description = "Extend Selection to char right" };

    pub fn select_textobject_inner(_: *void, ctx: Ctx) Result {
        var action: []const u8 = "";

        if (!try ctx.args.match(.{tp.extract(&action)})) return error.Stop;
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const root = ed.buf_root() catch return;

        if (std.mem.eql(u8, action, "w")) {
            try ed.with_cursels_const(root, select_inner_word, ed.metrics);
        } else if (std.mem.eql(u8, action, "W")) {
            try ed.with_cursels_const(root, select_inner_long_word, ed.metrics);
        } else {
            return;
        }
        ed.clamp(ctx.now);
    }
    pub const select_textobject_inner_meta: Meta = .{ .description = "select inside object helix" };

    pub fn surround_add(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const b = try ed.buf_for_update();
        const root = try ed.with_cursels_mut_once_arg(b.root, surround_cursel_add, ed.allocator, ctx);
        try ed.update_buf(root, ctx.now);
        ed.clamp(ctx.now);
        ed.need_render();
    }
    pub const surround_add_meta: Meta = .{ .description = "surround add" };

    pub fn select_textobject_around(_: *void, ctx: Ctx) Result {
        var action: []const u8 = "";

        if (!try ctx.args.match(.{tp.extract(&action)})) return error.Stop;
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const root = ed.buf_root() catch return;

        if (std.mem.eql(u8, action, "w")) {
            try ed.with_cursels_const(root, select_around_word, ed.metrics);
        } else if (std.mem.eql(u8, action, "W")) {
            try ed.with_cursels_const(root, select_inner_long_word, ed.metrics);
        } else {
            return;
        }
        ed.clamp(ctx.now);
    }
    pub const select_textobject_around_meta: Meta = .{ .description = "select around object helix" };

    pub fn copy_helix(_: *void, _: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const root = ed.buf_root() catch return;

        tui.clipboard_start_group();

        for (ed.cursels.items) |*cursel_| if (cursel_.*) |*cursel| if (cursel.selection) |sel|
            tui.clipboard_add_chunk(try Editor.copy_selection(root, sel, tui.clipboard_allocator(), ed.metrics));

        ed.logger.print("copy: {d} selections", .{ed.cursels.items.len});
    }
    pub const copy_helix_meta: Meta = .{ .description = "Copy selection to clipboard (helix)" };

    pub fn paste_after(_: *void, ctx: Ctx) Result {
        try paste_helix(ctx, insert_after);
    }
    pub const paste_after_meta: Meta = .{ .description = "Paste from clipboard after selection" };

    pub fn replace_selections_with_clipboard(_: *void, ctx: Ctx) Result {
        try paste_helix(ctx, insert_replace_selection);
    }
    pub const replace_selections_with_clipboard_meta: Meta = .{ .description = "Replace selection from clipboard" };

    pub fn paste_clipboard_before(_: *void, ctx: Ctx) Result {
        try paste_helix(ctx, insert_before);
    }
    pub const paste_clipboard_before_meta: Meta = .{ .description = "Paste from clipboard before selection" };

    pub fn replace_with_character_helix(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const b = try ed.buf_for_update();
        const root = try ed.with_cursels_mut_once_arg(b.root, replace_cursel_with_character, ed.allocator, ctx);
        try ed.update_buf(root, ctx.now);
        ed.clamp(ctx.now);
        ed.need_render();
    }
    pub const replace_with_character_helix_meta: Meta = .{ .description = "Replace with character" };

    pub fn keep_primary_selection(_: *void, _: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const primary = ed.get_primary().*;
        ed.cancel_all_selections();
        ed.cancel_all_matches();
        ed.get_primary().* = primary;
    }
    pub const keep_primary_selection_meta: Meta = .{};

    pub fn search_selection(_: *void, _: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const sel = ed.get_primary().selection orelse {
            ed.logger.print("no selection", .{});
            return;
        };
        const query = try ed.get_selection(sel, ed.allocator);
        defer ed.allocator.free(query);
        ed.match_type = .find;
        ed.set_last_find_query(query, .find, .exact);
        ed.logger.print("set find register to '{s}'", .{query});
    }
    pub const search_selection_meta: Meta = .{};

    pub fn add_next_match_helix(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        if (ed.matches.items.len == 0)
            try ed.repeat_last_find(null, ctx);
        try ed.add_cursor_next_match(.empty_from(ctx));
    }
    pub const add_next_match_helix_meta: Meta = .{};

    pub fn switch_to_lowercase(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const b = try ed.buf_for_update();
        const root = try ed.with_cursels_mut_once_arg(b.root, switch_to_lowercase_cursel, ed.allocator, ctx);
        try ed.update_buf(root, ctx.now);
        ed.clamp(ctx.now);
        ed.need_render();
    }
    pub const switch_to_lowercase_meta: Meta = .{ .description = "Switch to lowercase" };

    pub fn move_char_left(_: *void, ctx: Ctx) Result {
        try move_cursors_helix(ctx, move_cursor_char_left_helix);
    }
    pub const move_char_left_meta: Meta = .{ .description = "Move left (helix)", .arguments = &.{.integer} };

    pub fn move_char_right(_: *void, ctx: Ctx) Result {
        try move_cursors_helix(ctx, move_cursor_char_right_helix);
    }
    pub const move_char_right_meta: Meta = .{ .description = "Move right (helix)", .arguments = &.{.integer} };

    pub fn move_line_up(_: *void, ctx: Ctx) Result {
        try move_cursors_helix(ctx, move_cursor_line_up_helix);
    }
    pub const move_line_up_meta: Meta = .{ .description = "Move up (helix)", .arguments = &.{.integer} };

    pub fn move_line_down(_: *void, ctx: Ctx) Result {
        try move_cursors_helix(ctx, move_cursor_line_down_helix);
    }
    pub const move_line_down_meta: Meta = .{ .description = "Move down (helix)", .arguments = &.{.integer} };

    pub fn goto_line_end(_: *void, ctx: Ctx) Result {
        try move_cursors_helix(.empty_from(ctx), move_cursor_line_end_helix);
    }
    pub const goto_line_end_meta: Meta = .{ .description = "Goto line end (helix)" };

    pub fn goto_file_start(_: *void, ctx: Ctx) Result {
        try goto_line_helix_impl(ctx, .first, .move);
    }
    pub const goto_file_start_meta: Meta = .{ .description = "Goto line number <n> else file start (helix)", .arguments = &.{.integer} };

    pub fn extend_to_file_start(_: *void, ctx: Ctx) Result {
        try goto_line_helix_impl(ctx, .first, .extend);
    }
    pub const extend_to_file_start_meta: Meta = .{ .description = "Extend to line number <n> else file start (helix)", .arguments = &.{.integer} };

    pub fn goto_line_helix(_: *void, ctx: Ctx) Result {
        try goto_line_helix_impl(ctx, .last, .move);
    }
    pub const goto_line_helix_meta: Meta = .{ .description = "Goto line number <n> else last line (helix)", .arguments = &.{.integer} };

    pub fn extend_to_line_helix(_: *void, ctx: Ctx) Result {
        try goto_line_helix_impl(ctx, .last, .extend);
    }
    pub const extend_to_line_helix_meta: Meta = .{ .description = "Extend to line number <n> else last line (helix)", .arguments = &.{.integer} };

    pub fn goto_last_line(_: *void, ctx: Ctx) Result {
        try goto_line_helix_impl(.empty_from(ctx), .last, .move);
    }
    pub const goto_last_line_meta: Meta = .{ .description = "Goto last line (helix)" };

    pub fn extend_to_last_line(_: *void, ctx: Ctx) Result {
        try goto_line_helix_impl(.empty_from(ctx), .last, .extend);
    }
    pub const extend_to_last_line_meta: Meta = .{ .description = "Extend to last line (helix)" };

    pub fn goto_window_top(_: *void, ctx: Ctx) Result {
        try goto_window_helix_impl(ctx, .top, .move);
    }
    pub const goto_window_top_meta: Meta = .{ .description = "Goto window top", .arguments = &.{.integer} };

    pub fn goto_window_center(_: *void, ctx: Ctx) Result {
        try goto_window_helix_impl(ctx, .center, .move);
    }
    pub const goto_window_center_meta: Meta = .{ .description = "Goto window center" };

    pub fn goto_window_bottom(_: *void, ctx: Ctx) Result {
        try goto_window_helix_impl(ctx, .bottom, .move);
    }
    pub const goto_window_bottom_meta: Meta = .{ .description = "Goto window bottom", .arguments = &.{.integer} };

    pub fn extend_to_window_top(_: *void, ctx: Ctx) Result {
        try goto_window_helix_impl(ctx, .top, .extend);
    }
    pub const extend_to_window_top_meta: Meta = .{ .description = "Extend to window top", .arguments = &.{.integer} };

    pub fn extend_to_window_center(_: *void, ctx: Ctx) Result {
        try goto_window_helix_impl(ctx, .center, .extend);
    }
    pub const extend_to_window_center_meta: Meta = .{ .description = "Extend to window center" };

    pub fn extend_to_window_bottom(_: *void, ctx: Ctx) Result {
        try goto_window_helix_impl(ctx, .bottom, .extend);
    }
    pub const extend_to_window_bottom_meta: Meta = .{ .description = "Extend to window bottom", .arguments = &.{.integer} };

    pub fn repeat_last_motion(_: *void, ctx: Ctx) Result {
        const last = last_char_motion orelse return;
        var mode: []const u8 = "select";
        _ = ctx.args.match(.{tp.extract(&mode)}) catch false;
        const extend = std.mem.eql(u8, mode, "extend");
        const op: Editor.cursel_operator_mut_once_arg = switch (last.kind) {
            .to_left => if (extend) &extend_cursel_to_char_left_helix else &select_cursel_to_char_left_helix,
            .till_left => if (extend) &extend_cursel_till_char_left_helix else &select_cursel_till_char_left_helix,
            .to_right => if (extend) &extend_cursel_to_char_right_helix else &select_cursel_to_char_right_helix,
            .till_right => if (extend) &extend_cursel_till_char_right_helix else &select_cursel_till_char_right_helix,
        };
        const egc = last.egc_buf[0..last.egc_len];
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const root = ed.buf_root() catch return;
        try ed.with_cursels_const_once_arg(root, op, .fmt(.{egc}));
        ed.clamp(ctx.now);
    }
    pub const repeat_last_motion_meta: Meta = .{ .description = "Repeat last motion (f, t, F, T)" };

    pub fn collapse_selections(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const root = try ed.buf_root();
        for (ed.cursels.items) |*cursel_| if (cursel_.*) |*cursel| {
            cursel.disable_selection(root, ed.metrics);
        };
        ed.clamp(ctx.now);
    }
    pub const collapse_selections_meta: Meta = .{ .description = "Collapse selections to single cursors" };

    pub fn ensure_selections_forward(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        for (ed.cursels.items) |*cursel_| if (cursel_.*) |*cursel| if (cursel.selection) |*sel| {
            if (sel.is_reversed()) {
                sel.reverse();
                cursel.cursor = sel.end;
            }
        };
        ed.clamp(ctx.now);
    }
    pub const ensure_selections_forward_meta: Meta = .{ .description = "Ensure all selections face forward" };

    pub fn extend_to_line_bounds(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const root = try ed.buf_root();
        for (ed.cursels.items) |*cursel_| if (cursel_.*) |*cursel| {
            extend_cursel_to_line_bounds(root, cursel, ed.metrics);
        };
        ed.clamp(ctx.now);
    }
    pub const extend_to_line_bounds_meta: Meta = .{ .description = "Extend selections to line bounds (line-wise selection)" };

    pub fn shrink_to_line_bounds(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const root = try ed.buf_root();
        for (ed.cursels.items) |*cursel_| if (cursel_.*) |*cursel| {
            shrink_cursel_to_line_bounds(root, cursel, ed.metrics);
        };
        ed.clamp(ctx.now);
    }
    pub const shrink_to_line_bounds_meta: Meta = .{ .description = "Shrink selections to line bounds (line-wise selection)" };

    pub fn remove_primary_selection(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        var count: usize = 0;
        for (ed.cursels.items) |cursel_| if (cursel_) |_| {
            count += 1;
        };
        if (count < 2) return;
        var idx = ed.cursels.items.len;
        while (idx > 0) : (idx -= 1) if (ed.cursels.items[idx - 1]) |_| {
            _ = ed.cursels.orderedRemove(idx - 1);
            break;
        };
        ed.clamp(ctx.now);
    }
    pub const remove_primary_selection_meta: Meta = .{ .description = "Remove primary selection" };

    pub fn rotate_selections_forward(_: *void, ctx: Ctx) Result {
        try rotate_selections(ctx, .forward);
    }
    pub const rotate_selections_forward_meta: Meta = .{ .description = "Make the next selection primary" };

    pub fn rotate_selections_backward(_: *void, ctx: Ctx) Result {
        try rotate_selections(ctx, .backward);
    }
    pub const rotate_selections_backward_meta: Meta = .{ .description = "Make the previous selection primary" };

    pub fn add_prev_match_helix(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        if (ed.matches.items.len == 0)
            try ed.repeat_last_find(null, ctx);
        try ed.add_cursor_prev_match(.empty_from(ctx));
    }
    pub const add_prev_match_helix_meta: Meta = .{};

    pub fn goto_first_nonwhitespace(_: *void, ctx: Ctx) Result {
        try move_cursors_helix(.empty_from(ctx), move_cursor_first_nonwhitespace_helix);
    }
    pub const goto_first_nonwhitespace_meta: Meta = .{ .description = "Goto first non-whitespace character of line (helix)" };

    pub fn extend_line_up(_: *void, ctx: Ctx) Result {
        try extend_cursels_helix(ctx, move_cursor_line_up_helix);
    }
    pub const extend_line_up_meta: Meta = .{ .description = "Extend selection up (helix)", .arguments = &.{.integer} };

    pub fn extend_line_down(_: *void, ctx: Ctx) Result {
        try extend_cursels_helix(ctx, move_cursor_line_down_helix);
    }
    pub const extend_line_down_meta: Meta = .{ .description = "Extend selection down (helix)", .arguments = &.{.integer} };

    pub fn extend_to_line_start(_: *void, ctx: Ctx) Result {
        try extend_cursels_helix(.empty_from(ctx), Editor.move_cursor_begin);
    }
    pub const extend_to_line_start_meta: Meta = .{ .description = "Extend selection to line start (helix)" };

    pub fn extend_to_line_end(_: *void, ctx: Ctx) Result {
        try extend_cursels_helix(.empty_from(ctx), move_cursor_line_end_helix);
    }
    pub const extend_to_line_end_meta: Meta = .{ .description = "Extend selection to line end (helix)" };

    pub fn extend_to_first_nonwhitespace(_: *void, ctx: Ctx) Result {
        try extend_cursels_helix(.empty_from(ctx), move_cursor_first_nonwhitespace_helix);
    }
    pub const extend_to_first_nonwhitespace_meta: Meta = .{ .description = "Extend selection to first non-whitespace character of line (helix)" };

    pub fn delete_selection_noyank(_: *void, ctx: Ctx) Result {
        const mv = tui.mainview() orelse return;
        const ed = mv.get_active_editor() orelse return;
        const b = try ed.buf_for_update();
        var root = b.root;
        for (ed.cursels.items) |*cursel_| if (cursel_.*) |*cursel| {
            // a helix cursor without a selection still covers one character
            if (cursel.selection == null)
                Editor.with_selection_const(root, move_noop, cursel, ed.metrics) catch {};
            root = ed.delete_selection(root, cursel, b.allocator) catch continue;
        };
        try ed.update_buf(root, ctx.now);
        ed.clamp(ctx.now);
    }
    pub const delete_selection_noyank_meta: Meta = .{ .description = "Delete selection without yanking" };
};

fn match_bracket(root: Buffer.Root, cursel: *CurSel, ctx: command.Context, metrics: Buffer.Metrics) error{Stop}!void {
    var symbol: []const u8 = undefined;
    const mode: enum { helix_sel_mode, helix_nor_mode } = if ((ctx.args.match(.{tp.extract(&symbol)}) catch false) and
        std.mem.eql(u8, @tagName(.helix_sel_mode), symbol)) .helix_sel_mode else .helix_nor_mode;

    if (mode == .helix_sel_mode) {
        const begin: Cursor = if (cursel.selection) |sel| sel.begin else cursel.*.cursor;
        if (cursel.*.selection) |*sel| {
            const row, const col = Editor.match_bracket(root, cursel.*.cursor, metrics) catch blk: {
                // Selection in hx mode requires to move to the left to begin manipulation
                try cursel.*.cursor.move_left(root, metrics);
                break :blk try Editor.match_bracket(root, cursel.*.cursor, metrics);
            };
            cursel.*.cursor.row = row;
            cursel.*.cursor.col = col;
            sel.end = cursel.*.cursor;

            //Then to include the whole selection, requires to extend to the right
            if (sel.is_reversed()) {
                try sel.begin.move_right(root, metrics);
            } else {
                try cursel.*.cursor.move_right(root, metrics);
                try sel.end.move_right(root, metrics);
            }
        } else {
            cursel.*.selection = Selection.from_cursor(&begin);
            cursel.*.selection.?.end = cursel.*.cursor;
        }
    } else {
        const row, const col = try Editor.match_bracket(root, cursel.*.cursor, metrics);
        cursel.*.cursor.row = row;
        cursel.*.cursor.col = col;
        cursel.*.selection = null;
    }
}

fn move_to_word(ctx: command.Context, move: Editor.cursor_operator_const) command.Result {
    const mv = tui.mainview() orelse return;
    const ed = mv.get_active_editor() orelse return;
    const root = try ed.buf_root();

    // NOR mode moves n words selecting the last one
    var repeat: usize = 0;
    _ = ctx.args.match(.{tp.extract(&repeat)}) catch false;
    if (repeat > 1) ed.with_cursors_const_repeat(root, move, .fmt(.{repeat - 1})) catch {};

    for (ed.cursels.items) |*cursel_| if (cursel_.*) |*cursel| {
        cursel.selection = null;
    };
    ed.with_selections_const_repeat(root, move, .fmt(.{1})) catch {};
    ed.clamp(ctx.now);
}

fn extend_to_word(ctx: command.Context, move: Editor.cursor_operator_const) command.Result {
    const mv = tui.mainview() orelse return;
    const ed = mv.get_active_editor() orelse return;
    const root = try ed.buf_root();

    ed.with_selections_const_repeat(root, move, ctx) catch {};
    ed.clamp(ctx.now);
}

fn to_char_helix(ctx: command.Context, move: Editor.cursel_operator_mut_once_arg) command.Result {
    const mv = tui.mainview() orelse return;
    const ed = mv.get_active_editor() orelse return;
    const root = ed.buf_root() catch return;
    try ed.with_cursels_const_once_arg(root, move, ctx);
    ed.clamp(ctx.now);
}

fn select_inner_word(root: Buffer.Root, cursel: *CurSel, metrics: Buffer.Metrics) !void {
    if (!cursel.cursor.test_at(root, Editor.is_word_char, metrics)) return;
    var prev = cursel.cursor;
    var next = cursel.cursor;
    Editor.move_cursor_left_until(root, &prev, Editor.is_word_boundary_left, metrics);
    Editor.move_cursor_right_until(root, &next, Editor.is_word_boundary_right, metrics);
    try next.move_right(root, metrics);
    const sel = cursel.enable_selection(root, metrics);
    sel.begin = prev;
    sel.end = next;
    cursel.*.cursor = next;
}

fn select_inner_long_word(root: Buffer.Root, cursel: *CurSel, metrics: Buffer.Metrics) !void {
    if (cursel.cursor.test_at(root, Editor.is_whitespace, metrics)) return;
    var prev = cursel.cursor;
    var next = cursel.cursor;
    Editor.move_cursor_left_until(root, &prev, is_long_word_boundary_left, metrics);
    Editor.move_cursor_right_until(root, &next, is_long_word_boundary_right, metrics);
    try next.move_right(root, metrics);
    const sel = cursel.enable_selection(root, metrics);
    sel.begin = prev;
    sel.end = next;
    cursel.*.cursor = next;
}

fn is_tab_or_space(c: []const u8) bool {
    return (c[0] == ' ') or (c[0] == '\t');
}

fn is_tab_or_espace_at_cursor(root: Buffer.Root, cursor: *const Cursor, metrics: Buffer.Metrics) bool {
    return cursor.test_at(root, is_tab_or_space, metrics);
}
fn is_not_tab_or_espace_at_cursor(root: Buffer.Root, cursor: *const Cursor, metrics: Buffer.Metrics) bool {
    return !cursor.test_at(root, is_tab_or_space, metrics);
}

fn select_around_word(root: Buffer.Root, cursel: *CurSel, metrics: Buffer.Metrics) !void {
    if (!cursel.cursor.test_at(root, Editor.is_word_char, metrics)) return;
    var expander = cursel.*;
    try select_inner_word(root, &expander, metrics);
    const sel_e = expander.enable_selection(root, metrics);
    var prev = sel_e.begin;
    var next = sel_e.end;
    if (next.test_at(root, is_tab_or_space, metrics)) {
        Editor.move_cursor_right_until(root, &next, is_not_tab_or_espace_at_cursor, metrics);
    } else {
        next = sel_e.end;
        prev.move_left(root, metrics) catch {};
        if (prev.test_at(root, is_tab_or_space, metrics)) {
            Editor.move_cursor_left_until(root, &prev, is_not_tab_or_espace_at_cursor, metrics);
            prev.move_right(root, metrics) catch {};
        } else {
            prev = sel_e.begin;
        }
    }
    const sel = cursel.enable_selection(root, metrics);
    sel.begin = prev;
    sel.end = next;
    cursel.*.cursor = next;
}

fn select_around_long_word(root: Buffer.Root, cursel: *CurSel, metrics: Buffer.Metrics) !void {
    if (!cursel.cursor.test_at(root, Editor.is_word_char, metrics)) return;
    var expander = cursel.*;
    try select_inner_long_word(root, &expander, metrics);
    const sel_e = try expander.enable_selection(root, metrics);
    var prev = sel_e.begin;
    var next = sel_e.end;
    if (next.test_at(root, is_tab_or_space, metrics)) {
        Editor.move_cursor_right_until(root, &next, is_not_tab_or_espace_at_cursor, metrics);
    } else {
        next = sel_e.end;
        prev.move_left(root, metrics) catch {};
        if (prev.test_at(root, is_tab_or_space, metrics)) {
            Editor.move_cursor_left_until(root, &prev, is_not_tab_or_espace_at_cursor, metrics);
            prev.move_right(root, metrics) catch {};
        } else {
            prev = sel_e.begin;
        }
    }
    const sel = try cursel.enable_selection(root, metrics);
    sel.begin = prev;
    sel.end = next;
    cursel.*.cursor = next;
}

fn select_cursel_to_char_left_helix(root: Buffer.Root, cursel: *CurSel, ctx: command.Context, metrics: Buffer.Metrics) error{Stop}!void {
    char_motion_cursel(root, cursel, ctx, metrics, .to_left, .move);
}

fn extend_cursel_to_char_left_helix(root: Buffer.Root, cursel: *CurSel, ctx: command.Context, metrics: Buffer.Metrics) error{Stop}!void {
    char_motion_cursel(root, cursel, ctx, metrics, .to_left, .extend);
}

fn select_cursel_till_char_left_helix(root: Buffer.Root, cursel: *CurSel, ctx: command.Context, metrics: Buffer.Metrics) error{Stop}!void {
    char_motion_cursel(root, cursel, ctx, metrics, .till_left, .move);
}

fn extend_cursel_till_char_left_helix(root: Buffer.Root, cursel: *CurSel, ctx: command.Context, metrics: Buffer.Metrics) error{Stop}!void {
    char_motion_cursel(root, cursel, ctx, metrics, .till_left, .extend);
}

fn select_cursel_till_char_right_helix(root: Buffer.Root, cursel: *CurSel, ctx: command.Context, metrics: Buffer.Metrics) error{Stop}!void {
    char_motion_cursel(root, cursel, ctx, metrics, .till_right, .move);
}

fn extend_cursel_till_char_right_helix(root: Buffer.Root, cursel: *CurSel, ctx: command.Context, metrics: Buffer.Metrics) error{Stop}!void {
    char_motion_cursel(root, cursel, ctx, metrics, .till_right, .extend);
}

fn select_cursel_to_char_right_helix(root: Buffer.Root, cursel: *CurSel, ctx: command.Context, metrics: Buffer.Metrics) error{Stop}!void {
    char_motion_cursel(root, cursel, ctx, metrics, .to_right, .move);
}

fn extend_cursel_to_char_right_helix(root: Buffer.Root, cursel: *CurSel, ctx: command.Context, metrics: Buffer.Metrics) error{Stop}!void {
    char_motion_cursel(root, cursel, ctx, metrics, .to_right, .extend);
}

/// The character the (block) cursor is displayed on in helix's inclusive
/// selection model. For a forward selection that is the last selected
/// character, otherwise it is the cursor position itself.
fn cursel_head(root: Buffer.Root, cursel: *const CurSel, metrics: Buffer.Metrics) Cursor {
    if (cursel.selection) |sel| if (!sel.is_reversed() and !sel.empty()) {
        var head = sel.end;
        head.move_left(root, metrics) catch {};
        // keep the sticky column of the cursor for vertical movement
        head.target = if (cursel.cursor.eql(sel.end))
            cursel.cursor.target -| 1
        else if (cursel.cursor.eql(head))
            cursel.cursor.target
        else
            head.col;
        return head;
    };
    return cursel.cursor;
}

fn char_motion_cursel(root: Buffer.Root, cursel: *CurSel, ctx: command.Context, metrics: Buffer.Metrics, kind: CharMotion, behavior: GotoBehavior) void {
    const head = cursel_head(root, cursel, metrics);
    const target = find_char_target_helix(root, head, kind, ctx, metrics) catch return;
    switch (behavior) {
        .move => {
            // helix f/t/F/T select from the current head to the target
            var sel: Selection = .{ .begin = head, .end = head };
            sel.end.move_right(root, metrics) catch {};
            extend_selection_to(root, &sel, target, metrics);
            cursel.selection = sel;
            cursel.cursor = sel.end;
        },
        .extend => extend_cursel_to(root, cursel, target, metrics),
    }
}

fn egc_at_cursor_eql(root: Buffer.Root, cursor: Cursor, egc: []const u8, metrics: Buffer.Metrics) bool {
    const curr_egc, _, _ = root.egc_at(cursor.row, cursor.col, metrics) catch return false;
    return std.mem.eql(u8, curr_egc, egc);
}

/// Find the new head position for a helix f/t/F/T motion starting at `head`.
/// Like helix, the search never matches the character under the head, and a
/// till motion skips a target character that is directly adjacent so that
/// repeating it makes progress.
fn find_char_target_helix(root: Buffer.Root, head: Cursor, kind: CharMotion, ctx: command.Context, metrics: Buffer.Metrics) error{Stop}!Cursor {
    var egc: []const u8 = undefined;
    if (!(ctx.args.match(.{tp.extract(&egc)}) catch return error.Stop))
        return error.Stop;
    var cursor = head;
    switch (kind) {
        .to_right => {
            try cursor.move_right(root, metrics);
            try move_cursor_to_char_right_beyond_eol(root, &cursor, metrics, ctx);
        },
        .till_right => {
            try cursor.move_right(root, metrics);
            if (egc_at_cursor_eql(root, cursor, egc, metrics))
                try cursor.move_right(root, metrics);
            try move_cursor_to_char_right_beyond_eol(root, &cursor, metrics, ctx);
            try cursor.move_left(root, metrics);
        },
        .to_left => {
            try move_cursor_to_char_left_beyond_eol(root, &cursor, metrics, ctx);
        },
        .till_left => {
            var prev = cursor;
            if (prev.move_left(root, metrics)) {
                if (egc_at_cursor_eql(root, prev, egc, metrics))
                    cursor = prev;
            } else |_| return error.Stop;
            try move_cursor_to_char_left_beyond_eol(root, &cursor, metrics, ctx);
            try cursor.move_right(root, metrics);
        },
    }
    cursor.target = cursor.col;
    return cursor;
}

fn move_cursor_find_egc_beyond_eol(root: Buffer.Root, cursor: *Cursor, ctx: command.Context, metrics: Buffer.Metrics, move: find_char_function) error{Stop}!void {
    move(root, cursor, metrics, ctx);
}

fn move_cursor_word_left_helix(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics) error{Stop}!void {
    try Editor.move_cursor_left(root, cursor, metrics);

    // Consume " "
    while (Editor.is_whitespace_at_cursor(root, cursor, metrics)) {
        try Editor.move_cursor_left(root, cursor, metrics);
    }

    var next = cursor.*;
    next.move_left(root, metrics) catch return;
    var next_next = next;
    next_next.move_left(root, metrics) catch return;

    const cur = next.test_at(root, Editor.is_non_word_char, metrics);
    const nxt = next_next.test_at(root, Editor.is_non_word_char, metrics);
    if (cur != nxt) {
        try Editor.move_cursor_left(root, cursor, metrics);
        return;
    } else {
        try move_cursor_word_left_helix(root, cursor, metrics);
    }
}

fn replace_cursel_with_character(ed: *Editor, root: Buffer.Root, cursel: *CurSel, allocator: Allocator, ctx: command.Context) error{Stop}!Buffer.Root {
    var egc: []const u8 = undefined;
    if (!(ctx.args.match(.{tp.extract(&egc)}) catch return error.Stop))
        return error.Stop;

    const saved = cursel.*;
    defer cursel.* = saved;

    const selection = cursel.enable_selection(root, ed.metrics);
    selection.normalize();

    var sel_length: usize = 1;
    _ = root.get_range(selection.*, null, null, &sel_length, ed.metrics) catch return error.Stop;

    var sfa_buf: [4096]u8 = undefined;
    var sfa: std.heap.BufferFirstAllocator = .init(&sfa_buf, ed.allocator);
    const sfa_allocator = sfa.allocator();

    const total_length = sel_length * egc.len;
    const replacement = sfa_allocator.alloc(u8, total_length) catch return error.Stop;
    defer sfa_allocator.free(replacement);

    for (0..sel_length) |i|
        @memcpy(replacement[i * egc.len .. (i + 1) * egc.len], egc);
    return insert_replace_selection(ed, root, cursel, replacement, allocator) catch return error.Stop;
}

fn find_open_close_pair(bracket: []const u8) struct { left: []const u8, right: []const u8 } {
    for (Buffer.unicode.open_close_pairs) |pair| {
        if (std.mem.eql(u8, bracket, pair[0]) or std.mem.eql(u8, bracket, pair[1])) {
            return .{ .left = pair[0], .right = pair[1] };
        }
    }
    return .{ .left = bracket, .right = bracket };
}

fn surround_cursel_add(ed: *Editor, root: Buffer.Root, cursel: *CurSel, allocator: Allocator, ctx: command.Context) error{Stop}!Buffer.Root {
    var encloser: []const u8 = undefined;
    if (!(ctx.args.match(.{tp.extract(&encloser)}) catch return error.Stop))
        return error.Stop;

    const enclose_pair = find_open_close_pair(encloser);
    cursel.check_selection(root, ed.metrics);

    const sel = cursel.enable_selection(root, ed.metrics);
    const root_, const enclosed, const nudges = try surround_add(root, sel.*, enclose_pair.left, enclose_pair.right, allocator, ed.metrics);
    cursel.selection = enclosed;
    for (nudges) |nudge| ed.nudge_insert(nudge, cursel, encloser.len);

    if (enclosed.end.right_of(enclosed.begin)) {
        try cursel.*.cursor.move_right(root_, ed.metrics);
    }
    return root_;
}

fn surround_add(root: Buffer.Root, sel: Selection, left: []const u8, right: []const u8, allocator: Allocator, metrics: Buffer.Metrics) error{Stop}!struct { Buffer.Root, Selection, [2]Buffer.Nudge } {
    var begin = sel.begin;
    var end = sel.end;
    if (sel.is_reversed()) {
        end = sel.begin;
        begin = sel.end;
    }
    if (begin.row == end.row and end.col == begin.col) {
        end.move_right(root, metrics) catch {};
    }
    const right_row, const right_col, const root_right = root.insert_chars(end.row, end.col, right, allocator, metrics) catch return error.Stop;
    const left_row, const left_col, const root_ = root_right.insert_chars(begin.row, begin.col, left, allocator, metrics) catch return error.Stop;
    const nudges: [2]Buffer.Nudge = .{
        .insert(.{ .begin = end, .end = .{ .row = right_row, .col = right_col } }, root, root_right, metrics),
        .insert(.{ .begin = begin, .end = .{ .row = left_row, .col = left_col } }, root_right, root_, metrics),
    };

    if (begin.row == end.row) {
        try end.move_right(root_, metrics); // for left-bracket column shift on same row
    }
    try end.move_right(root_, metrics); // skip past right bracket
    return .{ root_, .{ .begin = begin, .end = end }, nudges };
}

fn move_noop(_: Buffer.Root, _: *Cursor, _: Buffer.Metrics) error{Stop}!void {}

fn move_cursor_word_right_end_helix(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics) error{Stop}!void {
    try Editor.move_cursor_right(root, cursor, metrics);
    Editor.move_cursor_right_until(root, cursor, Editor.is_word_boundary_right_vim, metrics);
    try cursor.move_right(root, metrics);
}

fn move_cursor_to_char_left_beyond_eol(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics, ctx: command.Context) error{Stop}!void {
    var egc: []const u8 = undefined;
    if (!(ctx.args.match(.{tp.extract(&egc)}) catch return error.Stop))
        return error.Stop;
    var test_cursor = cursor.*;
    try test_cursor.move_left(root, metrics);
    while (true) {
        const curr_egc, _, _ = root.egc_at(test_cursor.row, test_cursor.col, metrics) catch return error.Stop;
        if (std.mem.eql(u8, curr_egc, egc)) {
            cursor.row = test_cursor.row;
            cursor.col = test_cursor.col;
            cursor.target = cursor.col;
            return;
        }
        test_cursor.move_left(root, metrics) catch return error.Stop;
    }
}

fn move_cursor_to_char_right_beyond_eol(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics, ctx: command.Context) error{Stop}!void {
    var egc: []const u8 = undefined;
    if (!(ctx.args.match(.{tp.extract(&egc)}) catch return error.Stop))
        return error.Stop;
    var test_cursor = cursor.*;
    while (true) {
        const curr_egc, _, _ = root.egc_at(test_cursor.row, test_cursor.col, metrics) catch return error.Stop;
        if (std.mem.eql(u8, curr_egc, egc)) {
            cursor.row = test_cursor.row;
            cursor.col = test_cursor.col;
            cursor.target = cursor.col;
            return;
        }
        test_cursor.move_right(root, metrics) catch return error.Stop;
    }
}

fn move_cursor_till_char_left_beyond_eol(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics, ctx: command.Context) error{Stop}!void {
    var egc: []const u8 = undefined;
    if (!(ctx.args.match(.{tp.extract(&egc)}) catch return error.Stop))
        return error.Stop;
    var test_cursor = cursor;
    try test_cursor.move_left(root, metrics);
    var prev = test_cursor.*;
    try prev.move_left(root, metrics);
    while (true) {
        const prev_egc, _, _ = root.egc_at(prev.row, prev.col, metrics) catch return error.Stop;
        if (std.mem.eql(u8, prev_egc, egc)) {
            cursor.row = test_cursor.row;
            cursor.col = test_cursor.col;
            cursor.target = cursor.col;
            return;
        }
        test_cursor.move_left(root, metrics) catch return error.Stop;
        prev.move_left(root, metrics) catch return error.Stop;
    }
}

fn move_cursor_till_char_right_beyond_eol(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics, ctx: command.Context) error{Stop}!void {
    var egc: []const u8 = undefined;
    if (!(ctx.args.match(.{tp.extract(&egc)}) catch return error.Stop))
        return error.Stop;
    var test_cursor = cursor;
    try test_cursor.move_right(root, metrics);
    var next = test_cursor.*;
    try next.move_right(root, metrics);
    while (true) {
        const next_egc, _, _ = root.egc_at(next.row, next.col, metrics) catch return error.Stop;
        if (std.mem.eql(u8, next_egc, egc)) {
            cursor.row = test_cursor.row;
            cursor.col = test_cursor.col;
            cursor.target = cursor.col;
            return;
        }
        test_cursor.move_right(root, metrics) catch return error.Stop;
        next.move_right(root, metrics) catch return error.Stop;
    }
}

fn add_cursors_to_cursel_line_ends_helix(ed: *Editor, root: Buffer.Root, cursel: *CurSel) !void {
    const original_cursel = cursel.*;
    const sel = cursel.enable_selection(root, ed.metrics);
    sel.normalize();
    var row = sel.begin.row;
    const is_multiline = sel.begin.row != sel.end.row;
    var last_cursel: *CurSel = cursel;
    var first = true;

    const selection_goes_to_eol = sel.end.col == 0;
    const end_row = if (selection_goes_to_eol) sel.end.row else (sel.end.row + 1);
    while (row < end_row) : (row += 1) {
        const new_cursel = try ed.cursels.addOne(ed.allocator);
        new_cursel.* = CurSel{
            .selection = null,
            .cursor = .{
                .row = row,
                .col = 0,
            },
        };
        if (new_cursel.*) |*the_cursel| {
            if (!is_eol_right(root, &new_cursel.*.?.cursor, ed.metrics)) {
                if (first) {
                    first = false;
                    new_cursel.*.?.cursor.col = sel.begin.col;
                    if (is_multiline) {
                        new_cursel.*.?.cursor.col = try root.line_width(row, ed.metrics);
                        new_cursel.*.?.selection = Selection.from_cursor(&new_cursel.*.?.cursor);
                        new_cursel.*.?.selection.?.begin.col = sel.begin.col;
                        new_cursel.*.?.selection.?.end.target = new_cursel.*.?.selection.?.end.col;
                    } else if (original_cursel.selection) |the_sel| {
                        new_cursel.*.?.cursor = original_cursel.cursor;
                        new_cursel.*.?.selection = Selection.from_cursor(&new_cursel.*.?.cursor);
                        new_cursel.*.?.selection = the_sel;
                    }
                } else {
                    try ed.select_line_at_cursor(root, &new_cursel.*.?, .exclude_eol);
                    new_cursel.*.?.selection.?.end.target = new_cursel.*.?.selection.?.end.col;
                }
                new_cursel.*.?.cursor.target = new_cursel.*.?.cursor.col;
            }
            last_cursel = the_cursel;
        }
    }
    if (is_multiline and !selection_goes_to_eol) {
        if (last_cursel.selection) |*sel_| {
            last_cursel.cursor.col = sel.end.col;
            sel_.*.end.col = sel.end.col;
            sel_.*.end.target = sel.end.col;
        }
    }
}

fn insert_before(editor: *Editor, root: Buffer.Root, cursel: *CurSel, text: []const u8, allocator: Allocator) !Buffer.Root {
    var root_: Buffer.Root = root;
    const cursor: *Cursor = &cursel.cursor;

    cursel.check_selection(root, editor.metrics);
    if (cursel.selection) |sel_| {
        var sel = sel_;
        sel.normalize();
        cursor.move_to(root, sel.begin.row, sel.begin.col, editor.metrics) catch {};

        if (text[text.len - 1] == '\n') {
            cursor.move_begin();
        }
    } else if (text[text.len - 1] == '\n') {
        cursor.move_begin();
    }

    cursel.disable_selection_normal();
    const begin = cursel.cursor;
    const before = root_;
    cursor.row, cursor.col, root_ = try root_.insert_chars(cursor.row, cursor.col, text, allocator, editor.metrics);
    cursor.target = cursor.col;
    cursel.selection = Selection{ .begin = begin, .end = cursor.* };
    editor.nudge_insert(.insert(.{ .begin = begin, .end = cursor.* }, before, root_, editor.metrics), cursel, text.len);
    return root_;
}

fn insert_replace_selection(editor: *Editor, root: Buffer.Root, cursel: *CurSel, text: []const u8, allocator: Allocator) !Buffer.Root {
    // replaces the selection, if no selection, replaces the current
    // character and sets the selection to the replacement text
    var root_: Buffer.Root = root;
    cursel.check_selection(root, editor.metrics);

    if (cursel.selection == null) {
        // Select current character to replace it
        Editor.with_selection_const(root, move_noop, cursel, editor.metrics) catch {};
    }
    root_ = editor.delete_selection(root, cursel, allocator) catch root;

    const cursor = &cursel.cursor;
    const begin = cursel.cursor;
    const before = root_;
    cursor.row, cursor.col, root_ = try root_.insert_chars(cursor.row, cursor.col, text, allocator, editor.metrics);
    cursor.target = cursor.col;
    cursel.selection = Selection{ .begin = begin, .end = cursor.* };
    editor.nudge_insert(.insert(.{ .begin = begin, .end = cursor.* }, before, root_, editor.metrics), cursel, text.len);
    return root_;
}

fn insert_after(editor: *Editor, root: Buffer.Root, cursel: *CurSel, text: []const u8, allocator: Allocator) !Buffer.Root {
    var root_: Buffer.Root = root;
    const cursor = &cursel.cursor;
    cursel.check_selection(root, editor.metrics);
    if (text[text.len - 1] == '\n') {
        move_cursor_carriage_return(root, cursel.*, cursor, editor.metrics) catch {};
    } else {
        if (cursel.selection) |sel_| {
            var sel = sel_;
            sel.normalize();
            cursor.move_to(root, sel.end.row, sel.end.col, editor.metrics) catch {};
        } else {
            cursor.move_right(root_, editor.metrics) catch {};
        }
    }

    cursel.disable_selection_normal();
    const begin = cursel.cursor;
    const before = root_;
    cursor.row, cursor.col, root_ = try root_.insert_chars(cursor.row, cursor.col, text, allocator, editor.metrics);
    cursor.target = cursor.col;
    cursel.selection = Selection{ .begin = begin, .end = cursor.* };
    editor.nudge_insert(.insert(.{ .begin = begin, .end = cursor.* }, before, root_, editor.metrics), cursel, text.len);
    return root_;
}

fn is_eol_right(root: Buffer.Root, cursor: *const Cursor, metrics: Buffer.Metrics) bool {
    const line_width = root.line_width(cursor.row, metrics) catch return true;
    if (cursor.col >= line_width)
        return true;
    return false;
}

fn is_not_whitespace_or_eol(c: []const u8) bool {
    return !Editor.is_whitespace_or_eol(c);
}

fn is_whitespace_or_eol_at_cursor(root: Buffer.Root, cursor: *const Cursor, metrics: Buffer.Metrics) bool {
    return cursor.test_at(root, Editor.is_whitespace_or_eol, metrics);
}

fn is_non_whitespace_or_eol_at_cursor(root: Buffer.Root, cursor: *const Cursor, metrics: Buffer.Metrics) bool {
    return cursor.test_at(root, is_not_whitespace_or_eol, metrics);
}

fn is_long_word_boundary_left(root: Buffer.Root, cursor: *const Cursor, metrics: Buffer.Metrics) bool {
    if (cursor.test_at(root, Editor.is_whitespace, metrics)) return false;
    var next = cursor.*;
    next.move_left(root, metrics) catch return true;

    const next_is_whitespace = Editor.is_whitespace_at_cursor(root, &next, metrics);
    if (next_is_whitespace) return true;

    const curr_is_non_word = is_non_whitespace_or_eol_at_cursor(root, cursor, metrics);
    const next_is_non_word = is_non_whitespace_or_eol_at_cursor(root, &next, metrics);
    return curr_is_non_word != next_is_non_word;
}

fn move_cursor_long_word_left(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics) error{Stop}!void {
    try Editor.move_cursor_left(root, cursor, metrics);

    // Consume " "
    while (Editor.is_whitespace_at_cursor(root, cursor, metrics)) {
        try Editor.move_cursor_left(root, cursor, metrics);
    }

    var next = cursor.*;
    next.move_left(root, metrics) catch return;
    var next_next = next;
    next_next.move_left(root, metrics) catch return;

    const cur = next.test_at(root, is_not_whitespace_or_eol, metrics);
    const nxt = next_next.test_at(root, is_not_whitespace_or_eol, metrics);
    if (cur != nxt) {
        try Editor.move_cursor_left(root, cursor, metrics);
        return;
    } else {
        try move_cursor_long_word_left(root, cursor, metrics);
    }
}

fn is_word_boundary_right(root: Buffer.Root, cursor: *const Cursor, metrics: Buffer.Metrics) bool {
    if (Editor.is_whitespace_at_cursor(root, cursor, metrics)) return false;
    var next = cursor.*;
    next.move_right(root, metrics) catch return true;

    const next_is_whitespace = Editor.is_whitespace_at_cursor(root, &next, metrics);
    if (next_is_whitespace) return true;

    const curr_is_non_word = is_non_whitespace_or_eol_at_cursor(root, cursor, metrics);
    const next_is_non_word = is_non_whitespace_or_eol_at_cursor(root, &next, metrics);
    return curr_is_non_word != next_is_non_word;
}

fn move_cursor_long_word_right(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics) error{Stop}!void {
    try cursor.move_right(root, metrics);
    Editor.move_cursor_right_until(root, cursor, is_long_word_boundary_left, metrics);
}

fn is_long_word_boundary_right(root: Buffer.Root, cursor: *const Cursor, metrics: Buffer.Metrics) bool {
    if (Editor.is_whitespace_at_cursor(root, cursor, metrics)) return false;
    var next = cursor.*;
    next.move_right(root, metrics) catch return true;

    const next_is_whitespace = Editor.is_whitespace_at_cursor(root, &next, metrics);
    if (next_is_whitespace) return true;

    const curr_is_non_word = is_non_whitespace_or_eol_at_cursor(root, cursor, metrics);
    const next_is_non_word = is_non_whitespace_or_eol_at_cursor(root, &next, metrics);
    return curr_is_non_word != next_is_non_word;
}

fn move_cursor_long_word_right_end(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics) error{Stop}!void {
    // try Editor.move_cursor_right(root, cursor, metrics);
    Editor.move_cursor_right_until(root, cursor, is_long_word_boundary_right, metrics);
    try cursor.move_right(root, metrics);
}

const pasting_function = @TypeOf(insert_before);
const find_char_function = @TypeOf(move_cursor_to_char_left_beyond_eol);

fn paste_helix(ctx: command.Context, do_paste: pasting_function) command.Result {
    const mv = tui.mainview() orelse return;
    const ed = mv.get_active_editor() orelse return;
    var text_: []const u8 = undefined;

    const clipboard: []const tui.ClipboardEntry = if (ctx.args.buf.len > 0 and try ctx.args.match(.{tp.extract(&text_)}))
        &[_]tui.ClipboardEntry{.{ .text = text_ }}
    else
        tui.clipboard_get_group(0);

    if (clipboard.len == 0) {
        ed.logger.print("paste: nothing to paste", .{});
        return;
    }

    const b = try ed.buf_for_update();
    var root = b.root;

    // Chunks from clipboard are paired to selections
    // If more selections than chunks in the clipboard, the exceding selections
    // use the last chunk in the clipboard

    var bytes: usize = 0;
    for (ed.cursels.items, 0..) |*cursel_, idx| if (cursel_.*) |*cursel| {
        if (idx < clipboard.len) {
            root = try do_paste(ed, root, cursel, clipboard[idx].text, b.allocator);
            bytes += clipboard[idx].text.len;
        } else {
            bytes += clipboard[clipboard.len - 1].text.len;
            root = try do_paste(ed, root, cursel, clipboard[clipboard.len - 1].text, b.allocator);
        }
    };
    ed.logger.print("paste: {d} bytes", .{bytes});

    try ed.update_buf(root, ctx.now);
    ed.clamp(ctx.now);
    ed.need_render();
}

fn move_cursor_carriage_return(root: Buffer.Root, cursel: CurSel, cursor: *Cursor, metrics: Buffer.Metrics) error{Stop}!void {
    if (is_cursel_from_extend_line_below(cursel)) {
        //The cursor is already beginning next line
        return;
    }
    if (!Editor.is_eol_right(root, cursor, metrics)) {
        try Editor.move_cursor_end(root, cursor, metrics);
    }
    try Editor.move_cursor_right(root, cursor, metrics);
}

fn is_cursel_from_extend_line_below(cursel: CurSel) bool {
    if (cursel.selection) |sel_| {
        var sel = sel_;
        sel.normalize();
        return sel.end.row != sel.begin.row and sel.end.col == 0;
    }
    return false;
}

fn switch_to_lowercase_cursel(
    ed: *Editor,
    root: Buffer.Root,
    cursel: *CurSel,
    allocator: Allocator,
    _: command.Context,
) error{Stop}!Buffer.Root {
    const saved = cursel.*;
    defer cursel.* = saved;

    const selection = cursel.enable_selection(root, ed.metrics);

    const ucased = blk: {
        const selected_text = Editor.copy_selection(root, selection.*, allocator, ed.metrics) catch return error.Stop;
        defer allocator.free(selected_text);

        break :blk Buffer.unicode.to_lower(allocator, selected_text) catch return error.Stop;
    };
    defer allocator.free(ucased);

    return insert_replace_selection(ed, root, cursel, ucased, allocator) catch return error.Stop;
}

const CharMotion = enum { to_left, till_left, to_right, till_right };
const LastCharMotion = struct {
    kind: CharMotion,
    egc_buf: [32]u8 = undefined,
    egc_len: usize = 0,
};
var last_char_motion: ?LastCharMotion = null;

fn save_last_char_motion(kind: CharMotion, ctx: command.Context) void {
    var egc: []const u8 = undefined;
    if (!(ctx.args.match(.{tp.extract(&egc)}) catch false)) return;
    if (egc.len > 32) return;
    var last: LastCharMotion = .{ .kind = kind, .egc_len = egc.len };
    @memcpy(last.egc_buf[0..egc.len], egc);
    last_char_motion = last;
}

fn move_cursors_helix(ctx: command.Context, move: Editor.cursor_operator_const) command.Result {
    const mv = tui.mainview() orelse return;
    const ed = mv.get_active_editor() orelse return;
    const root = try ed.buf_root();
    ed.with_cursors_const_repeat(root, move, ctx) catch {};
    ed.clamp(ctx.now);
}

// helix h/l do not wrap across lines
fn move_cursor_char_left_helix(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics) error{Stop}!void {
    if (cursor.col == 0) return;
    cursor.move_left(root, metrics) catch {};
}

fn move_cursor_char_right_helix(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics) error{Stop}!void {
    const line_width = root.line_width(cursor.row, metrics) catch return;
    if (cursor.col >= line_width) return;
    cursor.move_right(root, metrics) catch {};
}

fn move_cursor_line_up_helix(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics) error{Stop}!void {
    cursor.move_up(root, metrics) catch {};
}

fn move_cursor_line_down_helix(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics) error{Stop}!void {
    cursor.move_down(root, metrics) catch {};
}

// helix gl places the cursor on the last character, not on the line ending
fn move_cursor_line_end_helix(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics) error{Stop}!void {
    cursor.move_end(root, metrics);
    if (cursor.col > 0) cursor.move_left(root, metrics) catch {};
}

/// Last line of the buffer, ignoring the empty line after a trailing newline
fn last_line_helix(root: Buffer.Root, metrics: Buffer.Metrics) usize {
    const lines = root.lines();
    if (lines < 2) return 0;
    const last = lines - 1;
    const width = root.line_width(last, metrics) catch return last;
    return if (width == 0) last - 1 else last;
}

const GotoBehavior = enum { move, extend };

/// Extend a cursel in helix (inclusive) style so the selection spans from its
/// anchor character to the head character at `target`.
fn extend_cursel_to(root: Buffer.Root, cursel: *CurSel, target: Cursor, metrics: Buffer.Metrics) void {
    const sel = cursel.enable_selection(root, metrics);
    extend_selection_to(root, sel, target, metrics);
    cursel.cursor = sel.end;
}

fn extend_selection_to(root: Buffer.Root, sel: *Selection, target: Cursor, metrics: Buffer.Metrics) void {
    // inclusive selections: a forward selection's anchor character is at
    // begin, a reversed selection's anchor character is just before begin
    var anchor = sel.begin;
    if (sel.is_reversed()) anchor.move_left(root, metrics) catch {};
    const head = target;
    if (head.right_of(anchor) or head.eql(anchor)) {
        sel.begin = anchor;
        sel.end = head;
        if (sel.end.move_right(root, metrics)) {
            sel.end.target = head.target + 1;
        } else |_| {}
    } else {
        sel.begin = anchor;
        sel.begin.move_right(root, metrics) catch {};
        sel.end = head;
    }
}

fn goto_cursor_helix(ed: *Editor, root: Buffer.Root, target: Cursor, behavior: GotoBehavior) void {
    switch (behavior) {
        .move => {
            ed.cancel_all_selections();
            const primary = ed.get_primary();
            primary.selection = null;
            primary.cursor = target;
            primary.cursor.target = target.col;
        },
        .extend => for (ed.cursels.items) |*cursel_| if (cursel_.*) |*cursel| {
            extend_cursel_to(root, cursel, target, ed.metrics);
        },
    }
}

fn goto_line_helix_impl(ctx: command.Context, default: enum { first, last }, behavior: GotoBehavior) command.Result {
    const mv = tui.mainview() orelse return;
    const ed = mv.get_active_editor() orelse return;
    const root = try ed.buf_root();
    var line: usize = 0;
    const has_line = ctx.args.match(.{tp.extract(&line)}) catch false;
    const last = last_line_helix(root, ed.metrics);
    const row: usize = if (has_line and line > 0)
        @min(line - 1, last)
    else switch (default) {
        .first => 0,
        .last => last,
    };
    try ed.send_editor_jump_source();
    goto_cursor_helix(ed, root, .{ .row = row, .col = 0, .target = 0 }, behavior);
    ed.clamp(ctx.now);
    try ed.send_editor_jump_destination();
}

fn goto_window_helix_impl(ctx: command.Context, alignment: enum { top, center, bottom }, behavior: GotoBehavior) command.Result {
    const mv = tui.mainview() orelse return;
    const ed = mv.get_active_editor() orelse return;
    const root = try ed.buf_root();
    var count: usize = 1;
    _ = ctx.args.match(.{tp.extract(&count)}) catch false;
    const offset = if (count > 0) count - 1 else 0;

    const view_top = ed.view.row;
    const buffer_last = last_line_helix(root, ed.metrics);
    const last_visible = @min(view_top + (ed.view.rows -| 1), buffer_last);
    const visible = last_visible - @min(last_visible, view_top);
    // like helix's scrolloff, but only where the view can actually scroll
    const scrolloff = @min(Buffer.View.scroll_cursor_min_border_distance, (ed.view.rows -| 1) / 2);
    const top_margin = if (view_top > 0) scrolloff else 0;
    const bottom_margin = if (last_visible < buffer_last) scrolloff else 0;
    const min_row = @min(view_top + top_margin, last_visible);
    const max_row = @max(last_visible -| bottom_margin, min_row);
    const row = switch (alignment) {
        .top => view_top + top_margin + offset,
        .center => view_top + visible / 2,
        .bottom => last_visible -| (bottom_margin + offset),
    };
    goto_cursor_helix(ed, root, .{ .row = @min(@max(row, min_row), max_row), .col = 0, .target = 0 }, behavior);
    ed.clamp(ctx.now);
}

fn extend_cursel_to_line_bounds(root: Buffer.Root, cursel: *CurSel, metrics: Buffer.Metrics) void {
    const sel = cursel.enable_selection(root, metrics);
    extend_selection_to_line_bounds(root, sel, metrics);
    cursel.cursor = sel.end;
}

fn extend_selection_to_line_bounds(root: Buffer.Root, sel: *Selection, metrics: Buffer.Metrics) void {
    const reversed = sel.is_reversed();
    sel.normalize();
    sel.begin.move_begin();
    if (!(sel.end.col == 0 and sel.end.row > sel.begin.row)) {
        sel.end.move_end(root, metrics);
        sel.end.move_right(root, metrics) catch {};
    }
    if (reversed) sel.reverse();
}

fn shrink_cursel_to_line_bounds(_: Buffer.Root, cursel: *CurSel, _: Buffer.Metrics) void {
    const sel = if (cursel.selection) |*sel| sel else return;
    if (shrink_selection_to_line_bounds(sel)) cursel.cursor = sel.end;
}

/// Returns true if the selection was changed
fn shrink_selection_to_line_bounds(sel: *Selection) bool {
    var s = sel.*;
    const reversed = s.is_reversed();
    s.normalize();
    if (s.begin.row == s.end.row) return false;
    var begin = s.begin;
    var end = s.end;
    if (begin.col != 0) {
        begin.row += 1;
        begin.col = 0;
    }
    end.col = 0;
    if (!end.right_of(begin)) return false;
    begin.target = begin.col;
    end.target = end.col;
    s.begin = begin;
    s.end = end;
    if (reversed) s.reverse();
    sel.* = s;
    return true;
}

fn move_cursor_first_nonwhitespace_helix(root: Buffer.Root, cursor: *Cursor, metrics: Buffer.Metrics) error{Stop}!void {
    cursor.move_begin();
    const line_width = root.line_width(cursor.row, metrics) catch return;
    while (cursor.col < line_width and cursor.test_at(root, is_tab_or_space, metrics))
        cursor.move_right(root, metrics) catch return;
}

fn extend_cursels_helix(ctx: command.Context, move: Editor.cursor_operator_const) command.Result {
    const mv = tui.mainview() orelse return;
    const ed = mv.get_active_editor() orelse return;
    const root = try ed.buf_root();
    var repeat: usize = 1;
    _ = ctx.args.match(.{tp.extract(&repeat)}) catch false;
    while (repeat > 0) : (repeat -= 1) {
        for (ed.cursels.items) |*cursel_| if (cursel_.*) |*cursel| {
            var head = cursel_head(root, cursel, ed.metrics);
            move(root, &head, ed.metrics) catch {};
            extend_cursel_to(root, cursel, head, ed.metrics);
        };
    }
    ed.clamp(ctx.now);
}

fn cursel_less_than(_: void, a_: ?CurSel, b_: ?CurSel) bool {
    const a = a_ orelse return false;
    const b = b_ orelse return true;
    return b.cursor.right_of(a.cursor);
}

fn rotate_selections(ctx: command.Context, direction: enum { forward, backward }) command.Result {
    const mv = tui.mainview() orelse return;
    const ed = mv.get_active_editor() orelse return;
    const primary = ed.get_primary().*;
    // sort by position (null entries last) and drop the nulls
    std.mem.sort(?CurSel, ed.cursels.items, {}, cursel_less_than);
    var len: usize = 0;
    for (ed.cursels.items) |cursel_| if (cursel_) |_| {
        len += 1;
    };
    ed.cursels.shrinkRetainingCapacity(len);
    if (len < 2) return;
    const items = ed.cursels.items;
    var primary_idx: usize = len - 1;
    for (items, 0..) |cursel_, i| if (cursel_) |cursel| if (cursel.cursor.eql(primary.cursor)) {
        primary_idx = i;
        break;
    };
    const new_primary = switch (direction) {
        .forward => (primary_idx + 1) % len,
        .backward => (primary_idx + len - 1) % len,
    };
    // the primary cursor is the last one in the list
    std.mem.rotate(?CurSel, items, (new_primary + 1) % len);
    ed.clamp(ctx.now);
}

const private = @This();
// exports for unittests
pub const test_internal = struct {
    pub const move_cursor_long_word_right = private.move_cursor_long_word_right;
    pub const move_cursor_long_word_left = private.move_cursor_long_word_left;
    pub const move_cursor_long_word_right_end = private.move_cursor_long_word_right_end;
    pub const move_cursor_word_left_helix = private.move_cursor_word_left_helix;
    pub const move_cursor_word_right_end_helix = private.move_cursor_word_right_end_helix;
    pub const move_cursor_to_char_left_beyond_eol = private.move_cursor_to_char_left_beyond_eol;
    pub const move_cursor_to_char_right_beyond_eol = private.move_cursor_to_char_right_beyond_eol;
    pub const move_cursor_till_char_left_beyond_eol = private.move_cursor_till_char_left_beyond_eol;
    pub const move_cursor_till_char_right_beyond_eol = private.move_cursor_till_char_right_beyond_eol;
    pub const insert_before = private.insert_before;
    pub const insert_replace_selection = private.insert_replace_selection;
    pub const insert_after = private.insert_after;
    pub const surround_add = private.surround_add;
    pub const find_char_target_helix = private.find_char_target_helix;
    pub const move_cursor_char_left_helix = private.move_cursor_char_left_helix;
    pub const move_cursor_char_right_helix = private.move_cursor_char_right_helix;
    pub const move_cursor_line_end_helix = private.move_cursor_line_end_helix;
    pub const last_line_helix = private.last_line_helix;
    pub const extend_selection_to = private.extend_selection_to;
    pub const extend_selection_to_line_bounds = private.extend_selection_to_line_bounds;
    pub const shrink_selection_to_line_bounds = private.shrink_selection_to_line_bounds;
};
