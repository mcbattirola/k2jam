package game

import k2 "karl2d"

FONT_SIZE_SM :: 12
FONT_SIZE_MD :: 16
FONT_SIZE_LG :: 24
TILEBAR_PADDING: k2.Vec2 : {8, 4}
BUTTON_PADDING: k2.Vec2 : {32, 8}

COLOR_BG := parse_hex_color("222222")
COLOR_SURFACE := parse_hex_color("c0c0c0")
COLOR_WHITE := parse_hex_color("ffffff")
COLOR_BLACK := parse_hex_color("000000")

COLOR_TITLEBAR_ACTIVE := parse_hex_color("000080")
COLOR_TITLEBAR_INACTIVE := parse_hex_color("808080")

COLOR_BTN_BORDER_TOP := COLOR_WHITE // highlight
COLOR_BTN_BORDER_BOTTOM := parse_hex_color("808080") // shadow
COLOR_BTN_BG := COLOR_SURFACE

// spacings
ROW_SPACE :: 8
WINDOW_X_PADDING :: ROW_SPACE
WINDOWS_Y_PADDING :: ROW_SPACE
WINDOWS_SPACING :: ROW_SPACE


parse_hex_color :: proc "contextless" (s: string) -> k2.Color {
	r := (hex_to_u8(s[0]) << 4) | hex_to_u8(s[1])
	g := (hex_to_u8(s[2]) << 4) | hex_to_u8(s[3])
	b := (hex_to_u8(s[4]) << 4) | hex_to_u8(s[5])

	return k2.Color{r, g, b, 255}
}

hex_to_u8 :: proc "contextless" (c: u8) -> u8 {
	if c >= '0' && c <= '9' do return c - '0'
	if c >= 'a' && c <= 'f' do return c - 'a' + 10
	if c >= 'A' && c <= 'F' do return c - 'A' + 10
	return 0
}
