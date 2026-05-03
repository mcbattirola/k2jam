package game

import "core:fmt"
import k2 "karl2d"

WINDOW_HEADER_SIZE :: FONT_SIZE_MD + (TILEBAR_PADDING.y * 2)

// keeps the last element so we can call row() withtout params
last_el: k2.Rect
current_window: k2.Rect
current_clip: k2.Rect
current_clip_enabled: bool

window :: proc(title: string, rect: k2.Rect) {
	r := rect
	r.h += WINDOW_HEADER_SIZE

	k2.draw_rect(r, COLOR_SURFACE)
	borders(r)

	// header
	header_rect := k2.Rect{r.x + 4, r.y + 4, r.w - 8, WINDOW_HEADER_SIZE}
	k2.draw_rect(header_rect, COLOR_TITLEBAR_ACTIVE)

	last_el = header_rect
	current_window = r

	text_pos := k2.Vec2{header_rect.x + TILEBAR_PADDING.x, header_rect.y + TILEBAR_PADDING.y}
	k2.draw_text(title, text_pos, FONT_SIZE_MD, COLOR_WHITE, game.font_bold)
}

window_inside :: proc() -> (f32, f32) {
	return current_window.x + WINDOW_X_PADDING, row()
}

// size of the current window's content
window_content_rect :: proc() -> k2.Rect {
	_, y := window_inside()
	return {
		current_window.x + WINDOW_X_PADDING,
		y,
		current_window.w - (WINDOW_X_PADDING * 2),
		current_window.y + current_window.h - y - ROW_SPACE,
	}
}

// returns x and y at the side of the last window
window_side :: proc() -> (f32, f32) {
	return current_window.x + current_window.w + WINDOWS_SPACING, current_window.y
}

window_below :: proc() -> (f32, f32) {
	return window_below_ex(current_window)
}

window_below_ex :: proc(window: k2.Rect) -> (f32, f32) {
	return window.x, window.y + window.h + ROW_SPACE
}

window_full_width :: proc() -> f32 {
	return window_full_width_ex(current_window)
}

window_full_width_ex :: proc(window: k2.Rect) -> f32 {
	return window.w - (WINDOWS_SPACING * 2)
}

window_full_height_ex :: proc(y: f32) -> f32 {
	return GAME_HEIGHT - y - WINDOW_HEADER_SIZE - WINDOWS_SPACING
}


btn :: proc(
	txt: string,
	pos: k2.Vec2,
	font_size: f32 = FONT_SIZE_MD,
	width: f32 = 0,
	disabled: bool = false,
) -> bool {
	txt_size := k2.measure_text(txt, font_size, game.font_handle)

	padding := BUTTON_PADDING
	size := k2.Vec2{txt_size.x + padding.x * 2, txt_size.y + padding.y * 2}

	x := pos.x
	y := pos.y
	w := size.x
	h := size.y

	if width != 0 {
		w = width
	}
	rec := k2.Rect{x, y, w, h}

	thickness: f32 = 2

	// state
	mouse_pos := k2.get_mouse_position()
	hovered := hovered(rec)
	pressed := hovered && k2.mouse_button_is_held(.Left) && !disabled
	clicked := hovered && !disabled && k2.mouse_button_went_down(.Left)

	text_offset := k2.Vec2{0, 0}

	border_type := BorderType.regular
	if pressed {
		border_type = .deep
		text_offset = k2.Vec2{1, 1}
	}

	// background
	k2.draw_rect(rec, COLOR_BTN_BG)

	// borders
	borders(rec, thickness, border_type)

	// text
	text_pos := k2.Vec2{x + padding.x + text_offset.x, y + padding.y + text_offset.y}
	if disabled {
		k2.draw_text(
			txt,
			text_pos + k2.Vec2{1, 1},
			font_size,
			COLOR_DISABLED_SHADOW,
			game.font_handle,
		)
		k2.draw_text(txt, text_pos, font_size, COLOR_DISABLED_TEXT, game.font_handle)
	} else {
		k2.draw_text(txt, text_pos, font_size, COLOR_BLACK, game.font_handle)
	}

	last_el = rec

	return clicked
}

btn_window_ok :: proc() -> bool {
	pos: k2.Vec2 = {current_window.x + current_window.w, current_window.y + current_window.h}
	pos.x -= 92
	pos.y -= 32 + WINDOWS_Y_PADDING
	return btn("OK", pos)
}

hovered :: proc(rec: k2.Rect) -> bool {
	mouse_pos := k2.get_mouse_position()
	return k2.point_in_rect(mouse_pos, rec) && clip_has_point(mouse_pos)
}


label :: proc(
	txt: string,
	pos: k2.Vec2,
	font_size: f32 = FONT_SIZE_MD,
	bold: bool = false,
	color: k2.Color = COLOR_BLACK,
) {
	font := game.font_handle
	if bold {font = game.font_bold}

	size := k2.measure_text(txt, font_size, font)
	last_el = {pos.x, pos.y, size.x, size.y}
	k2.draw_text(txt, pos, font_size, color, font)
}

divider_h :: proc(x: f32, y: f32, w: f32) {
	k2.draw_line(k2.Vec2{x, y}, k2.Vec2{x + w, y}, 1, COLOR_DIVIDER_DARK)
	k2.draw_line(k2.Vec2{x, y + 1}, k2.Vec2{x + w, y + 1}, 1, COLOR_DIVIDER_LIGHT)
	last_el = {x, y, 2, 2}
}

row :: proc() -> f32 {
	return last_el.y + last_el.h + ROW_SPACE
}

scroll_begin :: proc(scroll: ^f32, max_scroll: f32) -> k2.Rect {
	area := window_content_rect()

	mouse_pos := k2.get_mouse_position()
	wheel := k2.get_mouse_wheel_delta()
	if wheel != 0 && k2.point_in_rect(mouse_pos, area) {
		scroll^ -= wheel * 32
	}
	if scroll^ < 0 {
		scroll^ = 0
	}
	if scroll^ > max_scroll {
		scroll^ = max_scroll
	}

	last_el.y -= scroll^
	k2.set_scissor_rect(area)
	current_clip = area
	current_clip_enabled = true

	return area
}

scroll_end :: proc(scroll: ^f32, area: k2.Rect, content_height: f32) -> f32 {
	max_scroll := content_height - area.h
	if max_scroll < 0 {
		max_scroll = 0
	}
	if scroll^ > max_scroll {
		scroll^ = max_scroll
	}

	k2.set_scissor_rect(nil)
	current_clip_enabled = false

	if max_scroll > 0 {
		draw_scrollbar(area, scroll^, max_scroll)
	}

	return max_scroll
}

clip_has_point :: proc(pos: k2.Vec2) -> bool {
	if !current_clip_enabled {
		return true
	}
	return k2.point_in_rect(pos, current_clip)
}

draw_scrollbar :: proc(area: k2.Rect, scroll: f32, max_scroll: f32) {
	track := k2.Rect{area.x + area.w - 12, area.y, 12, area.h}
	k2.draw_rect(track, COLOR_SURFACE)
	borders(track)

	handle_h := area.h * area.h / (area.h + max_scroll)
	if handle_h < 20 {
		handle_h = 20
	}
	if handle_h > area.h {
		handle_h = area.h
	}

	handle_y := area.y
	available_h := area.h - handle_h
	if available_h > 0 {
		handle_y += (scroll / max_scroll) * available_h
	}

	handle := k2.Rect{track.x + 2, handle_y + 2, track.w - 4, handle_h - 4}
	k2.draw_rect(handle, COLOR_BTN_BG)
	borders(handle)
}


BorderType :: enum {
	regular,
	deep,
}

borders :: proc(rec: k2.Rect, thickness: f32 = 2, type: BorderType = .regular) {
	x := rec.x
	y := rec.y
	w := rec.w
	h := rec.h

	top_left_color := COLOR_BTN_BORDER_TOP
	right_bottom_color := COLOR_BTN_BORDER_BOTTOM
	if type == .deep {
		top_left_color = COLOR_BTN_BORDER_BOTTOM
		right_bottom_color = COLOR_BTN_BORDER_TOP
	}

	k2.draw_line(k2.Vec2{x, y}, k2.Vec2{x + w, y}, thickness, top_left_color) // top
	k2.draw_line(k2.Vec2{x, y}, k2.Vec2{x, y + h}, thickness, top_left_color) // left
	k2.draw_line(k2.Vec2{x, y + h}, k2.Vec2{x + w, y + h}, thickness, right_bottom_color) // bottom
	k2.draw_line(k2.Vec2{x + w, y}, k2.Vec2{x + w, y + h}, thickness, right_bottom_color) // right
}
