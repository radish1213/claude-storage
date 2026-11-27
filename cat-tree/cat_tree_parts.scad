// 落地式猫爬架 - 打印连接件（可调参数）
// 单位：mm。用 70×70 方木立柱、18mm 多层板平台。
//
// 导出单个零件示例：
//   openscad -D 'part="post_mount"' -o post_mount.stl cat_tree_parts.scad
// part 可选：post_mount / side_bracket / rope_collar / rim_straight / rim_corner / toy_hook / all

part = "all";

/* ---------- 主要参数（按实际木料量一下再改） ---------- */
post      = 70;    // 方木边长（买回来量一下，常见 68~70）
clr       = 0.5;   // 套筒单边间隙，太紧就加大到 0.7
board     = 18;    // 平台板厚
rope      = 8;     // 剑麻绳直径
wall      = 6;     // 套筒壁厚
plate_t   = 8;     // 法兰底板厚度
screw_d   = 4.5;   // 木螺丝孔径（配 4mm 木螺丝）
head_d    = 9;     // 沉头直径

$fn = 48;

/* ---------- 通用小工具 ---------- */
module rounded_square(s, r) {
    offset(r) offset(-r) square(s, center = true);
}

// 沉头螺丝孔：沿 +Z 方向，沉头在 z=0 处朝 +Z 开口
module cs_hole(len = 40) {
    translate([0, 0, -len]) cylinder(d = screw_d, h = len + 1);
    translate([0, 0, -head_d / 2 + 0.01]) cylinder(d1 = 0, d2 = head_d, h = head_d / 2);
    cylinder(d = head_d, h = 20);
}

/* ======================================================
   1. 立柱法兰 post_mount（底座和柱顶共用，同一个零件）
   - 底座：板面朝下放在底座板上，立柱插进套筒
   - 柱顶：倒过来套在柱子顶端，平台放在板面上
   螺丝都从套筒这一侧拧，沉头孔已经朝这边
   ====================================================== */
mount_plate = 150;
sock_h      = 60;

module post_mount() {
    inner = post + 2 * clr;
    outer = inner + 2 * wall;
    difference() {
        union() {
            // 底板
            linear_extrude(plate_t) rounded_square(mount_plate, 12);
            // 套筒
            linear_extrude(plate_t + sock_h) rounded_square(outer, 4);
            // 对角加强筋
            for (a = [45, 135, 225, 315]) rotate(a)
                translate([0, 0, plate_t]) rotate([90, 0, 0])
                    linear_extrude(6, center = true)
                    polygon([[outer / 2 * sqrt(2) - 4, 0], [mount_plate / 2 * sqrt(2) - 14, 0],
                             [outer / 2 * sqrt(2) - 4, sock_h * 0.6]]);
        }
        // 方孔
        translate([0, 0, plate_t]) linear_extrude(sock_h + 1) rounded_square(inner, 1.5);
        // 入口倒角
        translate([0, 0, plate_t + sock_h - 2])
            linear_extrude(2.01, scale = (inner + 4) / inner) square(inner, center = true);
        // 底板螺丝孔（4 个，在四边中间）
        for (p = [[60, 0], [-60, 0], [0, 60], [0, -60]])
            translate([p[0], p[1], plate_t]) cs_hole(plate_t + 2);
        // 套筒侧面螺丝孔（两对面各 2 个），拧进立柱
        for (s = [0, 180]) rotate(s)
            for (z = [plate_t + 18, plate_t + 45])
                translate([outer / 2, 0, z]) rotate([0, 90, 0]) cs_hole(wall + 2);
    }
}

/* ======================================================
   2. 侧挂三角支架 side_bracket
   竖边贴主柱（这段立柱不缠剑麻绳），横边托住中层平台底面
   打印方向：L 形平躺，层纹顺着 L 走，最结实
   ====================================================== */
br_w = 60;   // 宽
br_l = 110;  // 两条边长
br_t = 8;    // 板厚

module side_bracket() {
    difference() {
        union() {
            cube([br_l, br_w, br_t]);                 // 横边（贴平台底）
            cube([br_t, br_w, br_l]);                 // 竖边（贴立柱）
            // 两侧三角筋
            for (y = [0, br_w - 6])
                translate([0, y + 6, 0]) rotate([90, 0, 0]) linear_extrude(6)
                    polygon([[br_t, br_t], [br_l - 5, br_t], [br_t, br_l - 5]]);
        }
        // 横边螺丝孔（向上拧进平台）
        for (x = [45, 90]) translate([x, br_w / 2, br_t]) cs_hole(br_t + 2);
        // 竖边螺丝孔（拧进立柱）
        for (z = [45, 90]) translate([br_t, br_w / 2, z]) rotate([0, -90, 0]) cs_hole(br_t + 2);
    }
}

/* ======================================================
   3. 剑麻绳收口环 rope_collar
   套在缠好绳的柱子两端，压住绳头
   ====================================================== */
module rope_collar() {
    inner = post + 2 * rope + 1;
    h = 16;
    difference() {
        linear_extrude(h) rounded_square(inner + 8, 10);
        translate([0, 0, -1]) linear_extrude(h + 2) rounded_square(inner, 8);
        translate([inner / 2 + 4, 0, h / 2]) rotate([0, 90, 0]) translate([0, 0, 0]) cs_hole(10);
    }
}

/* ======================================================
   4. 猫窝围栏 rim_straight / rim_corner
   卡在顶层平台边缘，外侧包住板边，内侧压片用螺丝固定
   顶层 400×400：2 个转角 + 3 段直边，正面留口给猫进出
   ====================================================== */
rim_h   = 55;   // 高出平台面的高度
rim_t   = 6;    // 围栏厚度
tab_w   = 40;   // 压片宽度
tab_t   = 4;

// 沿 X 方向的一段围栏截面，外侧面在 y=0，平台面在 z=0
module rim_profile_seg(len) {
    // 墙体：向下包住板边，向上围起来
    translate([0, 0, -board]) cube([len, rim_t, board + rim_h]);
    // 压片
    cube([len, tab_w, tab_t]);
    // 顶部圆边
    translate([0, rim_t / 2, rim_h]) rotate([0, 90, 0]) cylinder(d = rim_t, h = len);
}

module rim_straight(len = 200) {
    difference() {
        rim_profile_seg(len);
        for (x = [len * 0.25, len * 0.75]) translate([x, rim_t + (tab_w - rim_t) / 2, tab_t]) cs_hole(tab_t + 2);
    }
}

module rim_corner(leg = 100) {
    difference() {
        union() {
            rim_profile_seg(leg);
            translate([rim_t, 0, 0]) mirror([1, 0, 0]) rotate(90) rim_profile_seg(leg);
        }
        translate([leg * 0.65, rim_t + (tab_w - rim_t) / 2, tab_t]) cs_hole(tab_t + 2);
        translate([rim_t + (tab_w - rim_t) / 2, leg * 0.65, tab_t]) cs_hole(tab_t + 2);
    }
}

/* ======================================================
   5. 玩具挂钩 toy_hook（拧在平台底面边缘，挂逗猫球）
   ====================================================== */
module toy_hook() {
    th = 12;
    difference() {
        union() {
            cube([50, th, 6]);                                 // 贴平台底的板
            translate([42, 0, -40]) cube([8, th, 46]);          // 向下的臂
            translate([32, 0, -40]) rotate([-90, 0, 0])
                difference() { cylinder(r = 18, h = th); translate([0, 0, -1]) cylinder(r = 10, h = th + 2);
                               translate([-20, -20, -1]) cube([40, 20, th + 2]); }
        }
        for (x = [12, 30]) translate([x, th / 2, 6]) cs_hole(8);
    }
}

/* ---------- 打印朝向（直接导出就是可打印的方向） ---------- */
module print_part(p) {
    if (p == "post_mount")   post_mount();
    if (p == "side_bracket") translate([0, 0, br_w]) rotate([-90, 0, 0]) side_bracket();
    if (p == "rope_collar")  rope_collar();
    if (p == "rim_straight") rotate([90, 0, 0]) rim_straight();     // 外侧面贴平台，免支撑
    if (p == "rim_corner")   translate([0, 0, board]) rim_corner();   // 正立打印，压片下方需加支撑
    if (p == "toy_hook")     rotate([90, 0, 0]) toy_hook();
}

if (part == "all") {
    translate([0, 0, 0])      print_part("post_mount");
    translate([180, 0, 0])    print_part("side_bracket");
    translate([0, 160, 0])    print_part("rope_collar");
    translate([150, 160, 0])  print_part("toy_hook");
    translate([-120, -220, 0]) print_part("rim_straight");
    translate([150, -260, 0]) print_part("rim_corner");
} else if (part != "none") {
    print_part(part);
}
