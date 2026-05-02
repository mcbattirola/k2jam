package game

import "base:runtime"
import "core:fmt"
import "core:math/linalg"
import "core:os"
import k2 "karl2d"
import vmem `core:mem/virtual`

Game :: struct {
	arena:           vmem.Arena,
	arena_buffer:    []u8,
	allocator:       runtime.Allocator,
	frame_arena:     vmem.Arena,
	frame_allocator: runtime.Allocator,
	terminate:       bool,
	// audio
	audio_enabled:   bool,
	audio_buffer:    k2.Audio_Buffer,
	audio:           k2.Sound,
	// text
	font_handle:     k2.Font,
	font_bold:       k2.Font,
	// gameplay stuff
	tokens_fed:      f32,
}

// global game instance
game: ^Game

GAME_WIDTH :: 800
GAME_HEIGHT :: 600

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
		fmt.printfln("error creating game : %s", err)
		os.exit(1)
	}
	game = g

	game.arena = arena
	game.arena_buffer = arena_buffer
	game.allocator = arena_allocator


	// frame arena, cleaned up every frame
	if err := vmem.arena_init_growing(&game.frame_arena); err != nil {
		fmt.printfln("error starting frame arena: %d", err)
		os.exit(1)
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
	return k2.key_went_down(.T)
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

	move_direction: [2]f32

	if k2.key_is_held(.Up) || k2.gamepad_button_is_held(0, .Left_Face_Up) {
		move_direction.y = -1
	}

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
	window("Book", {x, y, BOOK_WINDOW_WIDTH, BOOK_WINDOW_HEIGHT})
	x, y = window_side()

	book_window := current_window

	window(
		"Market",
		{x, y, GAME_WIDTH - BOOK_WINDOW_WIDTH - (WINDOWS_SPACING * 3), BOOK_WINDOW_HEIGHT},
	)
	market_btn_width: f32 = 256
	x, y = window_inside()

	if btn("$10 - Auto Complete", {x, y}, width = market_btn_width) {fmt.println("clicked")}
	y = row()
	if btn(
		"$100 - Buy Internet Crawler",
		{x, y},
		width = market_btn_width,
	) {fmt.println("clicked")}

	x, y = window_below_ex(book_window)

	window("Control Panel", {x, y, window_full_width_ex(main_window), window_full_height_ex(y)})
	x, y = window_inside()
	if btn("$100 - Buy Internet Crawler", {x, y}) {fmt.println("clicked")}

	k2.present()
}

normalize :: proc(v: k2.Vec2) -> k2.Vec2 {
	if v.x * v.x + v.y * v.y <= 1e-12 {
		return v
	}
	return linalg.normalize(v)
}
