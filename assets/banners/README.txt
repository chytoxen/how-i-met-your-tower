Squad photo banners (the lobby easter egg).

Bundled photos must be named:  banner1.jpg, banner2.jpg, banner3.jpg, ...
(.png / .jpeg / .webp also work). They auto-hang as framed, spotlit banners around
the airport terminal — no code changes needed. If there are more wall slots than
photos, the photos cycle to fill them. There are 11 slots in the current lobby.

Why the strict naming? Exported Godot games can't list a res:// folder at runtime
(only imported resources ship, not the original files), so the game loads these by
EXACT path. Number them 1..N with no gaps.

Players can ALSO drop loose images into a `banners/` folder placed next to the game
.exe at runtime — those are read from the real filesystem and any filename works.
