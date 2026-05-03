package game

import k2 "karl2d"

init :: proc() {
	k2.init(GAME_WIDTH, GAME_HEIGHT, "It Demands Data")
	game_init(nil)
}

step :: proc() -> bool {
	game_update()
	return game_should_run()
}
