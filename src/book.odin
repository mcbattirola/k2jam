package game

import k2 "karl2d"

BOOK_FONT_SIZE :: FONT_SIZE_MD
BOOK_LINE_HEIGHT :: BOOK_FONT_SIZE
BOOK_LOOKAHEAD_LINES :: 4

book_first_letter_index :: proc() -> u64 {
	book := BOOK
	for i in 0 ..< len(book) {
		c := book[i]
		if (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') {
			return u64(i)
		}
	}

	return 0
}

book_update :: proc() {
	book := BOOK

	pos, ok := book_next_typable_index(game.book_pos)
	game.book_pos = pos
	if !ok {
		return
	}

	highlighted_char := book[game.book_pos]
	highlighted_key := book_char_to_key(highlighted_char)
	if highlighted_key != .None && k2.key_went_down(highlighted_key) {
		game.book_pos += 1
		game.book_pos, _ = book_next_typable_index(game.book_pos)
		game.book_chars_typed += 1

		// word ended
		if highlighted_char == ' ' {
			grant := f64(game.book_chars_typed) * 0.75
			game.tokens_fed += grant
			game.book_chars_typed = 0
		}
	}
}

book_char_to_key :: proc(c: u8) -> k2.Keyboard_Key {
	if c >= 'a' && c <= 'z' {
		return k2.Keyboard_Key(c - ('a' - 'A'))
	}

	return k2.Keyboard_Key(c)
}

book_next_typable_index :: proc(pos: u64) -> (u64, bool) {
	book := BOOK
	i := int(pos)

	for i < len(book) {
		switch book[i] {
		case '\r', '\n', '"', '?':
			i += 1
			continue
		}

		return u64(i), true
	}

	return u64(len(book)), false
}

book_draw :: proc() {
	book := BOOK
	area := window_content_rect()
	book_scroll_to_cursor(area)
	k2.set_scissor_rect(area)

	pos := k2.Vec2{area.x, area.y - game.book_scroll}
	line_start_x := pos.x
	max_x := area.x + area.w

	highlight_idx := int(game.book_pos)

	for i in 0 ..< len(book) {
		c := book[i]

		if c == '\r' {
			continue
		}

		if c == '\n' {
			pos.x = line_start_x
			pos.y += BOOK_LINE_HEIGHT
			if pos.y > area.y + area.h {
				break
			}
			continue
		}

		ch_buf := [?]u8{c}
		ch := string(ch_buf[:])
		size := k2.measure_text(ch, BOOK_FONT_SIZE, game.font_handle)

		if pos.x + size.x > max_x && pos.x > line_start_x {
			pos.x = line_start_x
			pos.y += BOOK_LINE_HEIGHT
		}

		// Window ended, we can stop.
		if pos.y > area.y + area.h {
			break
		}
		if pos.y + BOOK_LINE_HEIGHT < area.y {
			pos.x += size.x
			continue
		}

		if i == highlight_idx {
			highlight := k2.Rect{pos.x, pos.y, size.x, BOOK_FONT_SIZE}
			if size.x < 4 {
				highlight.w = 4
			}
			k2.draw_rect(highlight, COLOR_BLUE)
			k2.draw_text(ch, pos, BOOK_FONT_SIZE, COLOR_WHITE, game.font_handle)
		} else {
			k2.draw_text(ch, pos, BOOK_FONT_SIZE, COLOR_BLACK, game.font_handle)
		}

		pos.x += size.x
	}

	k2.set_scissor_rect(nil)
}

book_scroll_to_cursor :: proc(area: k2.Rect) {
	cursor_y := book_char_y(game.book_pos, area.w)
	cursor_top := area.y + cursor_y - game.book_scroll
	cursor_bottom := cursor_top + BOOK_LINE_HEIGHT * (1 + BOOK_LOOKAHEAD_LINES)
	area_bottom := area.y + area.h

	if cursor_bottom > area_bottom {
		game.book_scroll = cursor_y + BOOK_LINE_HEIGHT * (1 + BOOK_LOOKAHEAD_LINES) - area.h
	} else if cursor_top < area.y {
		game.book_scroll = cursor_y
	}

	if game.book_scroll < 0 {
		game.book_scroll = 0
	}

	max_scroll := book_content_height(area.w) - area.h
	if max_scroll < 0 {
		max_scroll = 0
	}
	if game.book_scroll > max_scroll {
		game.book_scroll = max_scroll
	}
}

book_char_y :: proc(target: u64, width: f32) -> f32 {
	book := BOOK
	target_idx := int(target)
	x: f32 = 0
	y: f32 = 0

	for i in 0 ..< len(book) {
		if i == target_idx {
			return y
		}

		c := book[i]
		if c == '\r' {
			continue
		}

		if c == '\n' {
			x = 0
			y += BOOK_LINE_HEIGHT
			continue
		}

		ch_buf := [?]u8{c}
		ch := string(ch_buf[:])
		size := k2.measure_text(ch, BOOK_FONT_SIZE, game.font_handle)

		if x + size.x > width && x > 0 {
			x = 0
			y += BOOK_LINE_HEIGHT
		}

		x += size.x
	}

	return y
}

book_content_height :: proc(width: f32) -> f32 {
	book := BOOK
	x: f32 = 0
	y: f32 = 0

	for i in 0 ..< len(book) {
		c := book[i]
		if c == '\r' {
			continue
		}

		if c == '\n' {
			x = 0
			y += BOOK_LINE_HEIGHT
			continue
		}

		ch_buf := [?]u8{c}
		ch := string(ch_buf[:])
		size := k2.measure_text(ch, BOOK_FONT_SIZE, game.font_handle)

		if x + size.x > width && x > 0 {
			x = 0
			y += BOOK_LINE_HEIGHT
		}

		x += size.x
	}

	return y + BOOK_LINE_HEIGHT
}
