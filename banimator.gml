#define BA_AnimationLoad
var fn;
fn = argument0;

if (!file_exists(fn)) {
    return 0;
}

var file;
file = file_bin_open(fn, 0);

// signature check
var signature;
signature = (file_bin_read_byte(file)<<16)|(file_bin_read_byte(file)<<8)|file_bin_read_byte(file);
if (signature != 4342094) { 
    file_bin_close(file);
    return 0;
}

// parsing header
var ban_frames;
ban_frames = (file_bin_read_byte(file)<<8)|file_bin_read_byte(file);

// create map
var map;
map = ds_map_create();
ds_map_add(map, "frames", ban_frames);
ds_map_add(map, "tick", 1);
ds_map_add(map, "current_frame", 0);
ds_map_add(map, "lap", 0);

// parsing rest
var i;
for (i = 0; i < ban_frames; i += 1) {
    var bones;
    bones = file_bin_read_byte(file);
    ds_map_add(map, "frame"+string(i)+"bones", bones);
    var j;
    for (j = 0; j < bones; j += 1) {
        var bone_id, SIGN, bone_angle, bone_speed;
        bone_id = file_bin_read_byte(file);
        SIGN = file_bin_read_byte(file);
        bone_angle = (file_bin_read_byte(file)<<8)|file_bin_read_byte(file);
        if (SIGN) { bone_angle = -bone_angle; }
        bone_speed = file_bin_read_byte(file);
        ds_map_add(map, "frame"+string(i)+"bone"+string(j)+"id", bone_id);
        ds_map_add(map, "frame"+string(i)+"bone"+string(j)+"angle", bone_angle);
        ds_map_add(map, "frame"+string(i)+"bone"+string(j)+"speed", bone_speed);
    }
    var highest_speed;
    highest_speed = 0;
    for (j = 0; j < bones; j += 1) {
        if (highest_speed < ds_map_find_value(map, "frame"+string(i)+"bone"+string(j)+"speed")) {
            highest_speed = ds_map_find_value(map, "frame"+string(i)+"bone"+string(j)+"speed");
        }
    }
    ds_map_add(map, "frame"+string(i)+"highest_speed", highest_speed);
}

file_bin_close(file);

return map;

#define BA_AnimationPlay
var skeleton, anim, loop;
skeleton = argument0;
anim = argument1;
loop = argument2;

var tick, frame, frames, highest_speed;
tick = BA_AnimationGetTick(anim);
frame = BA_AnimationGetFrame(anim);
frames = BA_AnimationGetFrames(anim);

if (frame == frames) {
    if (loop == 1) {
        frame = 0;
        BA_AnimationSetFrame(anim, frame);
    } else {
        frame = 0;
        BA_SkeletonFlush(skeleton);
        BA_AnimationSetFrame(anim, frame);
        return 0;
    }
}

highest_speed = BA_AnimationGetFrameHighestSpeed(anim, frame);

var i, bones, angles;
bones = BA_AnimationGetFrameBones(anim, frame);

for (i = 0; i < bones; i += 1) {
    var bone_id, bone_angle, bone_speed, cur_angle;
    bone_id = BA_AnimationGetFrameId(anim, frame, i);
    bone_angle = BA_AnimationGetFrameAngle(anim, frame, i);
    bone_speed = BA_AnimationGetFrameSpeed(anim, frame, i);
    cur_angle = BA_BoneGetMeta(skeleton, bone_id);
    angles[i] = bone_angle;
    
    var to_angle, step;
    to_angle = bone_angle - cur_angle;
    
    if (tick < bone_speed) {
        step = to_angle / bone_speed;
    } else {
        step = 0;
    }
    
    to_angle = BA_BoneGetAngle(skeleton, bone_id) + step;
    
    BA_BoneRotate(skeleton, bone_id, to_angle);
}

tick += 1;
BA_AnimationSetTick(anim, tick);

if (tick >= highest_speed) {
    for (i = 0; i < bones; i += 1) {
        var bone_id;
        bone_id = BA_AnimationGetFrameId(anim, frame, i);
        BA_BoneSetMeta(skeleton, bone_id, angles[i]);
    }
    frame += 1;
    BA_AnimationSetTick(anim, 1);
    BA_AnimationSetFrame(anim, frame);
}

#define BA_AnimationGetTick
var anim;
anim = argument0;

return ds_map_find_value(anim, "tick");

#define BA_AnimationGetFrame
var anim;
anim = argument0;

return ds_map_find_value(anim, "current_frame");

#define BA_AnimationGetFrameId
var anim, frame_id, bone;
anim = argument0;
frame_id = argument1;
bone = argument2;

return ds_map_find_value(anim, "frame"+string(frame_id)+"bone"+string(bone)+"id");

#define BA_AnimationGetFrameAngle
var anim, frame_id, bone;
anim = argument0;
frame_id = argument1;
bone = argument2;

return ds_map_find_value(anim, "frame"+string(frame_id)+"bone"+string(bone)+"angle");

#define BA_AnimationGetFrameSpeed
var anim, frame_id, bone;
anim = argument0;
frame_id = argument1;
bone = argument2;

return ds_map_find_value(anim, "frame"+string(frame_id)+"bone"+string(bone)+"speed");

#define BA_AnimationGetFrameBones
var anim, frame_id;
anim = argument0;
frame_id = argument1;

return ds_map_find_value(anim, "frame"+string(frame_id)+"bones");

#define BA_AnimationGetFrames
var anim;
anim = argument0;

return ds_map_find_value(anim, "frames");

#define BA_AnimationGetFrameHighestSpeed
var anim, frame_id;
anim = argument0;
frame_id = argument1;

return ds_map_find_value(anim, "frame"+string(frame_id)+"highest_speed");

#define BA_AnimationGetLap
var anim;
anim = argument0;

return ds_map_find_value(anim, "lap");

#define BA_AnimationSetTick
var anim, tick;
anim = argument0;
tick = argument1;

return ds_map_replace(anim, "tick", tick);

#define BA_AnimationSetFrame
var anim, frame;
anim = argument0;
frame = argument1;

return ds_map_replace(anim, "current_frame", frame);

#define BA_AnimationSetLap
var anim, val;
anim = argument0;
val = argument1;

return ds_map_replace(anim, "lap", val);

#define BA_AnimationFlush
var anim;
anim = argument0;

ds_map_replace(anim, "tick", 1);
ds_map_replace(anim, "current_frame", 0);

#define BA_AnimationDelete
var map;
map = argument0;

ds_map_destroy(map);

#define BA_BoneGetAngle
var map, bone_id;
map = argument0;
bone_id = argument1;

return ds_map_find_value(map, "bone"+string(bone_id)+"angle");

#define BA_BoneGetMeta
var map, bone_id;
map = argument0;
bone_id = argument1;

return ds_map_find_value(map, "bone"+string(bone_id)+"meta");

#define BA_BoneGetSemantic
var map, semantic;
map = argument0;
semantic = argument1;

return ds_map_find_value(map, string(semantic));

#define BA_BoneRotate
var map, bone_id, angle;
map = argument0;
bone_id = argument1;
angle = argument2;

// extract data
var bone_parent, bone_offsetx, bone_offsety;
bone_parent = ds_map_find_value(map, "bone"+string(bone_id)+"parent");
bone_parentx = ds_map_find_value(map, "bone"+string(bone_parent)+"x");
bone_parenty = ds_map_find_value(map, "bone"+string(bone_parent)+"y");
bone_offsetx = ds_map_find_value(map, "bone"+string(bone_id)+"offsetx");
bone_offsety = ds_map_find_value(map, "bone"+string(bone_id)+"offsety");
var bone_parent_angle;
bone_parent_angle = ds_map_find_value(map, "bone"+string(bone_parent)+"angle");

// find point
var newx, newy;
newx = bone_offsetx;
newy = bone_offsety;

var cosangle, sinangle;
cosangle = cos(degtorad(-angle));
sinangle = sin(degtorad(-angle));

// rotate point
var xnew, ynew;
xnew = (newx * cosangle) - (newy * sinangle);
ynew = (newx * sinangle) + (newy * cosangle);

// translate point
newx = xnew + bone_parentx;
newy = ynew + bone_parenty;

// update data
ds_map_replace(map, "bone"+string(bone_id)+"x", newx);
ds_map_replace(map, "bone"+string(bone_id)+"y", newy);
ds_map_replace(map, "bone"+string(bone_id)+"angle", angle);

#define BA_BoneMove
var map, bone_id, xx, yy;
map = argument0;
bone_id = argument1;
xx = argument2;
yy = argument3;

// extract data
var bone_childs, bone_parent, bone_offsetx, bone_offsety;
bone_childs = ds_map_find_value(map, "bone"+string(bone_id)+"childs");
bone_parent = ds_map_find_value(map, "bone"+string(bone_id)+"parent");
bone_offsetx = ds_map_find_value(map, "bone"+string(bone_id)+"offsetx");
bone_offsety = ds_map_find_value(map, "bone"+string(bone_id)+"offsety");
bone_parentx = ds_map_find_value(map, "bone"+string(bone_parent)+"x");
bone_parenty = ds_map_find_value(map, "bone"+string(bone_parent)+"y");

if (bone_id != bone_parent) {
    xx = bone_parentx + bone_offsetx;
    yy = bone_parenty + bone_offsety;
}

// update data
ds_map_replace(map, "bone"+string(bone_id)+"x", xx);
ds_map_replace(map, "bone"+string(bone_id)+"y", yy);

// move all childs
var i;
for (i = 0; i < bone_childs; i += 1) {
    var bone_child_id;
    bone_child_id = ds_map_find_value(map, "bone"+string(bone_id)+"child"+string(i));
    BA_BoneMove(map, bone_child_id, xx, yy);
}

#define BA_BoneSetSprite
var map, bone_id, sprite;
map = argument0;
bone_id = argument1;
sprite = argument2;

ds_map_replace(map, "bone"+string(bone_id)+"sprite", sprite);

#define BA_BoneSetMeta
var map, bone_id, meta;
map = argument0;
bone_id = argument1;
meta = argument2;

ds_map_replace(map, "bone"+string(bone_id)+"meta", meta);

#define BA_BoneSetSemantic
var map, bone_id, semantic;
map = argument0;
bone_id = argument1;
semantic = argument2;

ds_map_replace(map, string(semantic), bone_id);

#define BA_BoneAddDepth
var map, bone_id;
map = argument0;
bone_id = argument1;

var i, bones;
bones = ds_map_find_value(map, "bones");

for (i = 0; i < bones - 1; i += 1) {
    var depth_bone;
    depth_bone = ds_map_find_value(map, "depth"+string(i));
    if (depth_bone == bone_id) {
        var temp;
        temp = ds_map_find_value(map, "depth"+string(i + 1));
        ds_map_replace(map, "depth"+string(i + 1), bone_id);
        ds_map_replace(map, "depth"+string(i), temp);
        break;
    }
}

#define BA_BoneSubDepth
var map, bone_id;
map = argument0;
bone_id = argument1;

var i, bones;
bones = ds_map_find_value(map, "bones");

for (i = 1; i < bones; i += 1) {
    var depth_bone;
    depth_bone = ds_map_find_value(map, "depth"+string(i));
    if (depth_bone == bone_id) {
        var temp;
        temp = ds_map_find_value(map, "depth"+string(i - 1));
        ds_map_replace(map, "depth"+string(i - 1), bone_id);
        ds_map_replace(map, "depth"+string(i), temp);
        break;
    }
}

#define BA_SkeletonLoad
var fn;
fn = argument0;

if (!file_exists(fn)) {
    return 0;
}

var file;
file = file_bin_open(fn, 0);

// signature check
var signature;
signature = (file_bin_read_byte(file)<<16)|(file_bin_read_byte(file)<<8)|file_bin_read_byte(file);
if (signature != 4346699) { 
    file_bin_close(file);
    return 0;
}

// parsing header
var bsk_bones;
bsk_bones = file_bin_read_byte(file);

// create map
var map;
map = ds_map_create();
ds_map_add(map, "bones", bsk_bones);

// parsing rest
var i;
for (i = 0; i < bsk_bones; i += 1) {
    var bone_id, bone_x, bone_y, bone_parent, bone_childs, bone_offsetx, bone_offsety;
    bone_id = file_bin_read_byte(file);
    bone_x = (file_bin_read_byte(file)<<8)|file_bin_read_byte(file);
    bone_y = (file_bin_read_byte(file)<<8)|file_bin_read_byte(file);
    bone_parent = file_bin_read_byte(file);
    bone_childs = file_bin_read_byte(file);
    ds_map_add(map, "bone"+string(bone_id)+"x", bone_x);
    ds_map_add(map, "bone"+string(bone_id)+"y", bone_y);
    ds_map_add(map, "bone"+string(bone_id)+"parent", bone_parent);
    ds_map_add(map, "bone"+string(bone_id)+"childs", bone_childs);
    ds_map_add(map, "bone"+string(bone_id)+"sprite", -1);
    ds_map_add(map, "bone"+string(bone_id)+"angle", 0);
    ds_map_add(map, "bone"+string(bone_id)+"meta", 0);
    var j;
    for (j = 0; j < bone_childs; j += 1) {
        var child_id;
        child_id = file_bin_read_byte(file);
        ds_map_add(map, "bone"+string(bone_id)+"child"+string(j), child_id);
    }
    ds_map_add(map, "depth"+string(i), bone_id);
}

for (i = 0; i < bsk_bones; i += 1) {
    var bone_id, bone_x, bone_y, bone_parent, bone_offsetx, bone_offsety;
    bone_id = i;
    bone_x = ds_map_find_value(map, "bone"+string(i)+"x");
    bone_y = ds_map_find_value(map, "bone"+string(i)+"y");
    bone_parent = ds_map_find_value(map, "bone"+string(i)+"parent");
    if (bone_id != bone_parent) {
        bone_offsetx = bone_x - ds_map_find_value(map, "bone"+string(bone_parent)+"x");
        bone_offsety = bone_y - ds_map_find_value(map, "bone"+string(bone_parent)+"y");
    } else {
        bone_offsetx = 0;
        bone_offsety = 0;
    }
    ds_map_add(map, "bone"+string(bone_id)+"offsetx", bone_offsetx);
    ds_map_add(map, "bone"+string(bone_id)+"offsety", bone_offsety);
}

file_bin_close(file);

return map;

#define BA_SkeletonDraw
var map;
map = argument0;

var bones;
bones = ds_map_find_value(map, "bones");

var j;
for (j = 0; j < bones; j += 1) {
    var i;
    i = ds_map_find_value(map, "depth"+string(j));
    var sprite;
    sprite = ds_map_find_value(map, "bone"+string(i)+"sprite");
    if (sprite != -1) {
        var xx, yy, angle;
        xx = ds_map_find_value(map, "bone"+string(i)+"x");
        yy = ds_map_find_value(map, "bone"+string(i)+"y");
        angle = ds_map_find_value(map, "bone"+string(i)+"angle");
        draw_sprite_ext(sprite, 0, xx, yy, 1, 1, angle, c_white, 1);
    }
}

return 1;

#define BA_SkeletonFlush
var map;
map = argument0;

var bones;
bones = ds_map_find_value(map, "bones");

var i;
for (i = 0; i < bones; i += 1) {
    ds_map_replace(map, "bone"+string(i)+"meta", 0);
    ds_map_replace(map, "bone"+string(i)+"angle", 0);
}

return 1;

#define BA_SkeletonDelete
var map;
map = argument0;

ds_map_destroy(map);

