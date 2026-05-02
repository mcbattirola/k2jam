# K2 Jam - It Demands Data

An incremental game where you type to feed an AI tokens.

As you get money, you can buy stuff like auto-complete, internet crawlers,
and eventually startups to feed doomscrolllers data into the machine.


## Gameplay

Exactly like Cookie Clicker, except instead of clicking a cookie, you see
the words of a book. You type to feed the machine, but eventually you
automate everything.


## TODO

- [x] UI system (windows 98 look)
- [x] Build the UI
- [x] Token system
- [x] Shop
- [ ] Book writing system
- [ ] Enable new upgrades as we go


_____


Hot reload template readme below:

## How it works

- `hotreload/main.odin` is the host executable. It owns the window and Karl2D state.
- `game/` is compiled as a DLL. This is your actual game code.
- When you rebuild the DLL, the host swaps it in without restarting the process.

If the size of your game state changes, the game will restart (but the window stays open).  
If it doesn’t, state is preserved across reloads.

Each DLL has its own PDB, debugging should work (but it wasn't tested).

## Running

```bash
./build-hot-reload.bat
```

The first time you run, this will generate both `./game_hotreload.exe` and the DLL files.

`./game_hotreload.exe` will start the game, and when you run `build-hot-reload.bat` again, it will generate a new DLL and the game will automatically swap.

Usual loop should be:

1. Edit Code
2. Run `build-hot-reload.bat`
3. Watch the game change

## Credits

This is heavily inspired by [Odin + Raylib + Hot Reload template](https://github.com/karl-zylinski/odin-raylib-hot-reload-game-template).

