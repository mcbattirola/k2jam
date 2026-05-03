package game

import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import k2 "karl2d"
import vmem `core:mem/virtual`

BOOK :: #load("../assets/book.txt")

Game :: struct {
	arena:                vmem.Arena,
	arena_buffer:         []u8,
	allocator:            runtime.Allocator,
	frame_arena:          vmem.Arena,
	frame_allocator:      runtime.Allocator,
	terminate:            bool,
	// audio
	audio_enabled:        bool,
	audio_buffer:         k2.Audio_Buffer,
	audio:                k2.Sound,
	// text
	font_handle:          k2.Font,
	font_bold:            k2.Font,
	// gameplay stuff
	tokens_fed:           f64,
	tokens_per_second:    f64,
	money:                f64,
	money_token_ratio:    f64,
	book_pos:             u64,
	book_chars_typed:     i32,
	book_scroll:          f32,
	market_scroll:        f32,
	market_scroll_max:    f32,
	upgrades_available:   [dynamic; 20]Upgrade,
	auto_type_counter:    f32,
	auto_type_per_second: f32,
}

// global game instance
game: ^Game

GAME_WIDTH :: 800
GAME_HEIGHT :: 600

MONEY_TOKEN_RATIO_INIT :: 1
TOKEN_PER_CHAR :: .77

@(export)
game_init :: proc(k2state: ^k2.State) {
	if k2state != nil {
		k2.set_internal_state(k2state)
	}


	// main arena, only gets cleaned up in the end of the game
	arena_size := size_of(Game) + size_of(vmem.Arena)
	arena_buffer := make([]u8, arena_size)
	arena := vmem.Arena{}
	_ = vmem.arena_init_buffer(&arena, arena_buffer)
	arena_allocator := vmem.arena_allocator(&arena)

	// create game inside arena
	g, err := new(Game, allocator = arena_allocator)
	if err != nil {
		panic(fmt.tprintf("error creating game : %s", err))
	}
	game = g

	game.arena = arena
	game.arena_buffer = arena_buffer
	game.allocator = arena_allocator


	// frame arena, cleaned up every frame
	if err := vmem.arena_init_growing(&game.frame_arena); err != nil {
		panic(fmt.tprintf("error starting frame arena: %d", err))
	}
	frame_allocator := vmem.arena_allocator(&game.frame_arena)
	game.frame_allocator = frame_allocator

	game.audio_enabled = false
	game.audio_buffer = k2.load_audio_buffer_from_bytes(#load("../assets/jump.wav"))
	game.audio = k2.create_sound_from_audio_buffer(game.audio_buffer)
	k2.set_sound_volume(game.audio, 1)

	// load fonts
	game.font_handle = k2.load_font_from_bytes(#load("../assets/MS-Sans-Serif.ttf"))
	game.font_bold = k2.load_font_from_bytes(#load("../assets/MS-Sans-Serif-Bold.ttf"))

	// initial gameplay state
	game.money = 0
	game.money_token_ratio = MONEY_TOKEN_RATIO_INIT
	game.book_pos = book_first_letter_index()
	append(&game.upgrades_available, ..INIT_ENABLED_UPGRADES[:])
}

@(export)
game_shutdown :: proc() {
	k2.destroy_sound(game.audio)
	k2.destroy_audio_buffer(game.audio_buffer)

	// unload arenas, fonts, etc.
	vmem.arena_free_all(&game.frame_arena)

	// Note: delete has to be the last thing,
	// since it deallocates the whole game object
	delete(game.arena_buffer)
}

@(export)
game_should_run :: proc() -> bool {
	return !game.terminate
}


@(export)
game_memory :: proc() -> (rawptr, rawptr) {
	return game, nil
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game)
}

@(export)
game_hot_reloaded :: proc(game_mem: rawptr, k2state: ^k2.State) {
	game = (^Game)(game_mem)
	k2.set_internal_state(k2state)
}

@(export)
game_force_reload :: proc() -> bool {
	return k2.key_went_down(.G)
}

@(export)
game_force_restart :: proc() -> bool {
	return k2.key_went_down(.F1)
}

@(export)
game_update :: proc() {
	k2.reset_frame_allocator()
	k2.calculate_frame_time()
	k2.update_audio_mixer()
	k2.process_events()

	vmem.arena_free_all(&game.frame_arena)
	context.allocator = game.frame_allocator

	if k2.key_went_down(.Escape) {
		game.terminate = true
		return
	}

	dt := k2.get_frame_time()

	game.auto_type_counter += game.auto_type_per_second * dt
	book_update()
	tokens_update(dt)

	// audio example
	// if game.enemy_pos.x < 0 {
	// 	if game.audio_enabled {
	// 		k2.play_sound(game.audio)
	// 	}
	// 	game.enemy_pos.x = 800
	// }

	// Draw
	k2.clear(COLOR_SURFACE)

	BOOK_WINDOW_WIDTH :: 400
	BOOK_WINDOW_HEIGHT :: 300

	y: f32 = 0
	x: f32 = 0
	window("It Demands Data", {x, y, GAME_WIDTH, GAME_HEIGHT})
	main_window := current_window
	x, y = window_inside()
	window("THE MACHINE STOPS - E M Forster", {x, y, BOOK_WINDOW_WIDTH, BOOK_WINDOW_HEIGHT})
	book_draw()
	x, y = window_side()

	book_window := current_window

	MARKET_WINDOW_HEIGHT: f32 = BOOK_WINDOW_HEIGHT - 32

	window(
		"Market",
		{x, y, GAME_WIDTH - BOOK_WINDOW_WIDTH - (WINDOWS_SPACING * 3), MARKET_WINDOW_HEIGHT},
	)
	market_btn_width: f32 = 256
	x, y = window_inside()

	// market window scroll
	market_scroll_area := scroll_begin(&game.market_scroll, game.market_scroll_max)
	y -= game.market_scroll
	market_content_y := y

	// upgrade buttons
	hovered_upgrade: Upgrade
	any_hovered_upgrade: bool

	for i in 0 ..< len(game.upgrades_available) {
		u := &game.upgrades_available[i]
		btn_label := fmt.tprintf("$%d - %s", u.cost, upgrade_name(u^))
		disabled := game.money < f64(u.cost) || (u.bought > 0 && u.one_time_buy)
		if btn(btn_label, {x, y}, width = market_btn_width, disabled = disabled) {
			upgrade_buy(u)
		}
		if hovered(last_el) {
			any_hovered_upgrade = true
			hovered_upgrade = u^
		}

		if u.bought > 0 && !u.one_time_buy {
			button := last_el
			qty_x := button.x + button.w + ROW_SPACE
			qty_y := button.y + BUTTON_PADDING.y
			label(fmt.tprintf("%d", u.bought), {qty_x, qty_y})
			last_el = button
		}

		y = row()
	}
	game.market_scroll_max = scroll_end(
		&game.market_scroll,
		market_scroll_area,
		y - market_content_y,
	)

	x, y = window_below()
	if any_hovered_upgrade {
		label(fmt.tprintf("INFO: %s", upgrade_desc(hovered_upgrade)), {x, y})
	}

	x, y = window_below_ex(book_window)

	window("Control Panel", {x, y, window_full_width_ex(main_window), window_full_height_ex(y)})
	x, y = window_inside()
	tokens_value_txt := display_txt_f64(game.tokens_fed)
	tokens_txt := fmt.tprintf("Tokens Fed: %s", tokens_value_txt)
	if game.tokens_per_second > 0 {
		tokens_txt = fmt.tprintf("%s (+%.2f/s)", tokens_txt, game.tokens_per_second)

	}
	label(tokens_txt, {x, y}, font_size = FONT_SIZE_LG)
	y = row()
	label(
		fmt.tprintf("Money: %s$", display_txt_f64(game.money)),
		{x, y},
		color = COLOR_GREEN,
		font_size = FONT_SIZE_LG,
	)
	y = row()
	label(
		fmt.tprintf("Earning %.2f $ per token", game.money_token_ratio),
		{x, y},
		color = COLOR_BLUE,
		font_size = FONT_SIZE_LG,
	)
	y = row()
	if game.auto_type_per_second > 0 {
		label(
			fmt.tprintf("Auto typing: %.2f chars/s", game.auto_type_per_second),
			{x, y},
			font_size = FONT_SIZE_LG,
		)
		y = row()
	}

	k2.present()
	free_all(context.temp_allocator)
}

tokens_update :: proc(dt: f32) {
	tokens_earn := game.tokens_per_second * f64(dt)
	game.tokens_fed += tokens_earn
	game.money += tokens_earn * game.money_token_ratio
}

tokens_grant :: proc(amount: f64) {
	game.tokens_fed += amount
	game.money += amount * game.money_token_ratio
}

normalize :: proc(v: k2.Vec2) -> k2.Vec2 {
	if v.x * v.x + v.y * v.y <= 1e-12 {
		return v
	}
	return linalg.normalize(v)
}
