const std = @import("std");

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Model = struct {
    count: u32 = 0,
    button: vxfw.Button,

    pub fn widget(self: *Model) vxfw.Widget {
        return .{
            .userdata = self,
            .eventHandler = eventHandler,
            .drawFn = draw,
        };
    }

    fn eventHandler(
        ptr: *anyopaque,
        ctx: *vxfw.EventContext,
        event: vxfw.Event,
    ) anyerror!void {
        const self: *Model = @ptrCast(@alignCast(ptr));
        switch (event) {
            .init => return ctx.requestFocus(self.button.widget()),
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true })) {
                    ctx.quit = true;
                    return;
                }
            },
            .focus_in => return ctx.requestFocus(self.button.widget()),
            else => {},
        }
    }

    fn draw(
        ptr: *anyopaque,
        ctx: vxfw.DrawContext,
    ) std.mem.Allocator.Error!vxfw.Surface {
        const self: *Model = @ptrCast(@alignCast(ptr));
        const max_size = ctx.max.size();

        const count_text = try std.fmt.allocPrint(
            ctx.arena,
            "{d}",
            .{self.count},
        );
        const text: vxfw.Text = .{ .text = count_text };

        const text_child: vxfw.SubSurface = .{
            .origin = .{ .row = 0, .col = 0 },
            .surface = try text.draw(ctx),
        };

        const button_child: vxfw.SubSurface = .{
            .origin = .{ .row = 2, .col = 0 },
            .surface = try self.button.draw(
                ctx.withConstraints(ctx.min, .{ .width = 16, .height = 3 }),
            ),
        };

        const children = try ctx.arena.alloc(vxfw.SubSurface, 2);
        children[0] = text_child;
        children[1] = button_child;

        return .{
            .size = max_size,
            .widget = self.widget(),
            .buffer = &.{},
            .children = children,
        };
    }

    fn onClick(maybe_ptr: ?*anyopaque, ctx: *vxfw.EventContext) anyerror!void {
        const ptr = maybe_ptr orelse return;
        const self: *Model = @ptrCast(@alignCast(ptr));
        self.count +|= 1;
        return ctx.consumeAndRedraw();
    }
};

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    var app = try vxfw.App.init(allocator);
    defer app.deinit();

    const model = try allocator.create(Model);
    defer allocator.destroy(model);

    model.* = .{
        .count = 0,
        .button = .{
            .label = "Click me!",
            .onClick = Model.onClick,
            .userdata = model,
        },
    };

    try app.run(model.widget(), .{});
}
