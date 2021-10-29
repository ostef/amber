// Vec2

vec2f :: make_vec2f;
make_vec2f :: inline (x : f32 = 0, y : f32 = 0) -> Vec2f #must
{
	return make_vec2 (x, y);
}

make_vec2f :: inline (vec : $V/Vec2) -> Vec2f #must
{
	return make_vec2f (xx vec.x, xx vec.y);
}

vec2i :: make_vec2i;
make_vec2i :: inline (x : s32 = 0, y : s32 = 0) -> Vec2i #must
{
	return make_vec2 (x, y);
}

make_vec2i :: inline (vec : $V/Vec2) -> Vec2i #must
{
	return make_vec2i (xx vec.x, xx vec.y);
}

vec2 :: make_vec2;
make_vec2 :: inline (x : $T, y : T) -> Vec2 (T) #must
{
	result : Vec2 (T) = ---;
	result.x = x;
	result.y = y;
	
	return result;
}

clamp :: inline (vec : Vec2f, min : Vec2f, max : Vec2f) -> Vec2f #must
{
	result : Vec2f = ---;
	result.x = clamp (vec.x, min.x, max.x);
	result.y = clamp (vec.y, min.y, max.y);
	
	return result;
}

round :: inline (vec : Vec2f) -> Vec2f #must
{
	result : Vec2f = ---;
	result.x = round (vec.x);
	result.y = round (vec.y);
	
	return result;
}

/*
floor :: inline (vec : $V/Vec2) -> V #must
{
	result : V = ---;
	result.x = floor (vec.x);
	result.y = floor (vec.y);
	
	return result;
}

ceil :: inline (vec : $V/Vec2) -> V #must
{
	result : V = ---;
	result.x = ceil (vec.x);
	result.y = ceil (vec.y);
	
	return result;
}
*/

dot :: inline (left : $V/Vec2, right : V) -> V.T #must
{
	return left.x * right.x + left.y * right.y;
}

sqrd_length :: inline (using vec : $V/Vec2) -> V.T #must
{
	return x * x + y * y;
}

length :: inline (vec : $V/Vec2) -> V.T #must
{
	sq_len := sqrd_length (vec);
	
	return sqrt (sq_len);
}

normalized :: inline (using vec : $V/Vec2, fallback : V = .{ 0, 0 }) -> V #must
{
	len := length (vec);
	if len == 0 then return fallback;
	
	return vec2 (x / len, y / len);
}

angle :: inline (a : $V/Vec2, b : V) -> V.T #must
{
	return atan2 (a.x * b.y - a.y * b.x, a.x * b.x + a.y * b.y);
}

operator + :: inline (left : $V/Vec2, right : V) -> V #must
{
	result : V = ---;
	result.x = left.x + right.x;
	result.y = left.y + right.y;
	
	return result;
}

operator - :: inline (left : $V/Vec2, right : V) -> V #must
{
	result : V = ---;
	result.x = left.x - right.x;
	result.y = left.y - right.y;
	
	return result;
}

operator - :: inline (vec : $V/Vec2) -> V #must
{
	result : V = ---;
	result.x = -vec.x;
	result.y = -vec.y;
	
	return result;
}

operator * :: inline (vec : $V/Vec2, scalar : V.T) -> V #must #symmetric
{
	result : V = ---;
	result.x = vec.x * scalar;
	result.y = vec.y * scalar;
	
	return result;
}

operator / :: inline (vec : $V/Vec2, scalar : V.T) -> V #must
{
	result : V = ---;
	result.x = vec.x / scalar;
	result.y = vec.y / scalar;
	
	return result;
}

operator == :: inline (left : $V/Vec2, right : V) -> bool #must
{
	return left.x == right.x && left.y == right.y;
}

// Rect

rectf :: make_rectf;
ltrbf :: make_rectf;
make_rectf :: inline (x1 : f32, y1 : f32, x2 : f32, y2 : f32) -> Rectf #must
{
	return make_rect (x1, y1, x2, y2);
}

make_rectf :: inline (other : $R/Rect) -> Rectf #must
{
	return make_rectf (xx other.x1, xx other.y1, xx other.x2, xx other.y2);
}

xywhf :: make_rectf_size;
make_rectf_size :: inline (x : f32, y : f32, w : f32, h : f32) -> Rectf #must
{
	return make_rect_size (x, y, w, h);
}

recti :: make_recti;
ltrbi :: make_recti;
make_recti :: inline (x1 : s32, y1 : s32, x2 : s32, y2 : s32) -> Recti #must
{
	return make_rect (x1, y1, x2, y2);
}

make_recti :: inline (other : $R/Rect) -> Recti #must
{
	return make_recti (xx other.x1, xx other.y1, xx other.x2, xx other.y2);
}

xywhi :: make_recti_size;
make_recti_size :: inline (x : s32, y : s32, w : s32, h : s32) -> Recti #must
{
	return make_rect_size (x, y, w, h);
}

ltrb :: make_rect;
make_rect :: inline (x1 : $T, y1 : T, x2 : T, y2 : T) -> Rect (T) #must
{
	result : Rect (T) = ---;
	result.x1 = x1;
	result.y1 = y1;
	result.x2 = x2;
	result.y2 = y2;
	
	return result;
}

xywh :: make_rect_size;
make_rect_size :: inline (x : $T, y : T, w : T, h : T) -> Rect (T) #must
{
	result : Rect (T) = ---;
	result.x1 = x;
	result.y1 = y;
	result.x2 = x + w;
	result.y2 = y + h;
	
	return result;
}

rect_top_left :: inline (using rect : $R/Rect) -> R.V #must
{
	return vec2 (rect.left, rect.top);
}

rect_top_right :: inline (using rect : $R/Rect) -> R.V #must
{
	return vec2 (rect.right, rect.top);
}

rect_bottom_left :: inline (using rect : $R/Rect) -> R.V #must
{
	return vec2 (rect.left, rect.bottom);
}

rect_bottom_right :: inline (using rect : $R/Rect) -> R.V #must
{
	return vec2 (rect.right, rect.bottom);
}

rect_x :: inline (using rect : $R/Rect) -> R.T #must
{
	return x1;
}

rect_y :: inline (using rect : $R/Rect) -> R.T #must
{
	return y1;
}

rect_width :: inline (using rect : $R/Rect) -> R.T #must
{
	return x2 - x1;
}

rect_height :: inline (using rect : $R/Rect) -> R.T #must
{
	return y2 - y1;
}

rect_position :: inline (using rect : $R/Rect) -> R.V #must
{
	return vec2 (x1, y1);
}

rect_size :: inline (using rect : $R/Rect) -> R.V #must
{
	return vec2 (x2 - x1, y2 - y1);
}

expand_all_sides :: inline (using rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.x1 -= amount;
	result.y1 -= amount;
	result.x2 += amount;
	result.y2 += amount;
	
	return result;
}

expand_left :: inline (using rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.left -= amount;
	
	return result;
}

expand_top :: inline (using rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.top -= amount;
	
	return result;
}

expand_right :: inline (using rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.right += amount;
	
	return result;
}

expand_bottom :: inline (using rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.bottom += amount;
	
	return result;
}

truncate_all_sides :: inline (rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.x1 += amount;
	result.y1 += amount;
	result.x2 -= amount;
	result.y2 -= amount;
	
	return result;
}

truncate_left :: inline (rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.left += amount;
	
	return result;
}

truncate_top :: inline (rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.top += amount;
	
	return result;
}

truncate_right :: inline (rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.right -= amount;
	
	return result;
}

truncate_bottom :: inline (rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.bottom -= amount;
	
	return result;
}

set_position :: inline (rect : $R/Rect, new_x : R.T, new_y : R.T) -> R #must
{
	width  := rect_width (rect);
	height := rect_height (rect);
	result : R = ---;
	result.x1 = new_x;
	result.y1 = new_y;
	result.x2 = new_x + width;
	result.y2 = new_y + height;
	
	return result;
}

set_position :: inline (rect : $R/Rect, new_position : R.V) -> R #must
{
	return set_position (rect, new_position.x, new_position.y);
}

move :: inline (rect : $R/Rect, x_amount : R.T, y_amount : R.T) -> R #must
{
	result := rect;
	result.x1 += x_amount;
	result.y1 += y_amount;
	result.x2 += x_amount;
	result.y2 += y_amount;
	
	return result;
}

move :: inline (rect : $R/Rect, amount : R.V) -> R #must
{
	return move (rect, amount.x, amount.y);
}

set_width :: inline (rect : $R/Rect, new_w : R.T) -> R #must
{
	result := rect;
	result.x2 = result.x1 + new_w;
	
	return result;
}

set_height :: inline (rect : $R/Rect, new_h : R.T) -> R #must
{
	result := rect;
	result.y2 = result.y1 + new_h;
	
	return result;
}

set_size :: inline (rect : $R/Rect, new_w : R.T, new_h : R.T) -> R #must
{
	result := rect;
	result.x2 = result.x1 + new_w;
	result.y2 = result.y1 + new_h;
	
	return result;
}

set_size :: inline (rect : $R/Rect, new_size : R.V) -> R #must
{
	return set_size (rect, new_size.w, new_size.h);
}

grow :: inline (rect : $R/Rect, x_amount : R.T, y_amount : R.T) -> R #must
{
	result := rect;
	result.x2 += x_amount;
	result.y2 += y_amount;
	
	return result;
}

grow :: inline (rect : $R/Rect, amount : R.V) -> R #must
{
	return grow (rect, amount.w, amount.h);
}

clip :: inline (rect : $R/Rect, clip_by : R) -> R #must
{
	result : R = ---;
	result.x1 = max (rect.x1, clip_by.x1);
	result.y1 = max (rect.y1, clip_by.y1);
	result.x2 = min (rect.x2, clip_by.x2);
	result.y2 = min (rect.y2, clip_by.y2);
	
	return result;
}

contains :: inline (rect : $R/Rect, point : R.V) -> bool #must
{
	return point.x >= rect.x1 && point.x <= rect.x2 && point.y >= rect.y1 && point.y <= rect.y2;
}

operator == :: inline (left : $R/Rect, right : R) -> bool #must
{
	return left.x1 == right.x1 && left.y1 == right.y1 && left.x2 == right.x2 && left.y2 == right.y2;
}

// RGBA

rgba :: make_rgba;
make_rgba :: inline (r : u8 = 0, g : u8 = 0, b : u8 = 0, a : u8 = 255) -> RGBA #must
{
	result : RGBA = ---;
	result.r = r;
	result.g = g;
	result.b = b;
	result.a = a;
	
	return result;
}

make_rgba :: inline (using color : RGBAf) -> RGBA #must
{
	result : RGBA = ---;
	result.r = cast (u8) (r * 255);
	result.g = cast (u8) (g * 255);
	result.b = cast (u8) (b * 255);
	result.a = cast (u8) (a * 255);
	
	return result;
}

make_rgba :: inline (color : RGBA, a : u8) -> RGBA #must
{
	result : RGBA = ---;
	result.r = color.r;
	result.g = color.g;
	result.b = color.b;
	result.a = a;
	
	return result;
}

operator == :: inline (left : RGBA, right : RGBA) -> bool #must
{
	return left.r == right.r && left.g == right.g && left.b == right.b && left.a == right.a;
}

// RGBAf

rgbaf :: make_rgbaf;
make_rgbaf :: inline (r : f32 = 0, g : f32 = 0, b : f32 = 0, a : f32 = 0) ->  RGBAf #must
{
	result : RGBAf = ---;
	result.r = saturate (r);
	result.g = saturate (g);
	result.b = saturate (b);
	result.a = saturate (a);
	
	return result;
}

make_rgbaf :: inline (using color : RGBA) -> RGBAf #must
{
	result : RGBAf = ---;
	result.r = r / 255.0;
	result.g = g / 255.0;
	result.b = b / 255.0;
	result.a = a / 255.0;
	
	return result;
}

invert :: inline (using color : RGBA) -> RGBA #must
{
	result : RGBA = ---;
	result.r = 255 - r;
	result.g = 255 - g;
	result.b = 255 - b;
	result.a = a;
	
	return result;
}

dim :: inline (using color : RGBA, factor : f32) -> RGBA #must
{
	result : RGBA = ---;
	result.r = xx clamp (r / factor, 0, 255);
	result.g = xx clamp (g / factor, 0, 255);
	result.b = xx clamp (b / factor, 0, 255);
	result.a = a;
	
	return result;
}

operator == :: inline (left : RGBAf, right : RGBAf) -> bool #must
{
	return left.r == right.r && left.g == right.g && left.b == right.b && left.a == right.a;
}

// Range

rangei :: make_rangei;
make_rangei :: inline (min : s64, max : s64) -> Rangei #must
{
	return make_range (min, max);
}

rangef :: make_rangef;
make_rangef :: inline (min : f32, max : f32) -> Rangef #must
{
	return make_range (min, max);
}

make_range :: inline (min : $T, max : T) -> Range (T) #must
{
	result : Range (T) = ---;
	result.min = min;
	result.max = max;
	
	return result;
}

length :: inline (range : $R/Range) -> R.T #must
{
	return abs (range.max - range.min);
}

signed_length :: inline (range : $R/Range) -> R.T #must
{
	return range.max - range.min;
}

contains :: inline (range : $R/Range, value : R.T) -> bool #must
{
	return value >= range.min && value <= range.max;
}

operator == :: inline (left : $R/Range, right : R) -> bool #must
{
	return left.min == right.min && left.max == right.max;
}
