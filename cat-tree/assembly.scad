// 猫爬架整体装配预览（只用来看效果，不用打印）
use <cat_tree_parts.scad>
part = "none";

post = 70; plate_t = 8; board = 18; sock = 68;

wood   = "#c9955a";
ply    = "#e2c08d";
rope   = "#d9c49a";
rope2  = "#bfa775";
carpet = "#8a9bb0";
print  = "#1f8a7a";
cush   = "#e8e4dc";

module rope_wrap(z0, z1) {
    for (z = [z0 : 8 : z1 - 6]) {
        color(rope)  translate([0, 0, z + 3]) linear_extrude(4.5) offset(6) square(post, center = true);
        color(rope2) translate([0, 0, z])     linear_extrude(3.5) offset(5) square(post, center = true);
    }
}

// 一根柱子：底法兰 + 方木 + 顶法兰；返回顶面高度 = 26 + L + 8
module column(L, wraps) {
    color(print) translate([0, 0, board]) post_mount();
    color(wood)  translate([-post / 2, -post / 2, board + plate_t]) cube([post, post, L]);
    color(print) translate([0, 0, board + plate_t + L + plate_t]) mirror([0, 0, 1]) post_mount();
    for (w = wraps) {
        rope_wrap(w[0], w[1]);
        color(print) translate([0, 0, w[0] - 16]) rope_collar();
        color(print) translate([0, 0, w[1]]) rope_collar();
    }
}

module platform(cx, cy, sx, sy, ztop) {
    color(ply)    translate([cx - sx / 2, cy - sy / 2, ztop - board]) cube([sx, sy, board]);
    color(carpet) translate([cx - sx / 2 + 4, cy - sy / 2 + 4, ztop]) cube([sx - 8, sy - 8, 4]);
}

/* 底座 */
color(ply) translate([-300, -300, 0]) cube([600, 600, board]);
color(carpet) translate([-296, -296, board]) cube([592, 592, 3]);

/* 主柱 1150mm：顶层 1202 */
translate([-150, 150, 0]) column(1150, [[102, 610], [760, 1100]]);
/* 副柱 700mm：中层 752 */
translate([85, 120, 0])   column(700,  [[102, 650]]);
/* 小跳台柱 350mm：402 */
translate([150, -170, 0]) column(350,  [[102, 300]]);

platform(-100, 100, 400, 400, 1202);
platform(85, 120, 400, 350, 752);
platform(150, -170, 300, 250, 402);

/* 中层侧挂支架（主柱这一段不缠绳） */
color(print) translate([-115, 120, 734]) mirror([0, 0, 1]) side_bracket();

/* 顶层围栏：后面和左右两侧，正面开口 */
zt = 1202;
// 围栏的外裙边包住板边，所以整体向外偏 6mm（围栏厚度）
color(print) {
    translate([-306, 306, zt]) mirror([0, 1, 0]) rim_corner();
    translate([106, 306, zt])  rotate(180) rim_corner();
    translate([-200, 306, zt]) mirror([0, 1, 0]) rim_straight(200);
    translate([-306, 0, zt])   mirror([1, 0, 0]) rotate(90) rim_straight(200);
    translate([106, 0, zt])    rotate(90) rim_straight(200);
}
/* 猫窝软垫 */
color(cush) translate([-100, 110, zt + 4]) scale([1, 1, 0.28]) sphere(r = 165, $fn = 64);

/* 逗猫球挂钩 + 小球 */
color(print) translate([-60, -96, 1184 - 6]) rotate(90) toy_hook();
color("#c94f3d") translate([-66, -50, 1060]) sphere(r = 18, $fn = 32);
color("#555") translate([-66, -50, 1078]) cylinder(d = 1.5, h = 85);
