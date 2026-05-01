# RACHE Prototype

Single-room detective loop prototype for Godot 4.6.

## Controls

- `WASD` / arrow keys: move
- `E`: inspect / advance dialogue
- `1`, `2`, `3`, `4`: choose investigation options when shown
- `Enter` / `Space` / `E`: start from title
- `R` / `Enter`: return to title from ending
- `Esc`: quit from ending

## Prototype Flow

1. Start from the title screen.
2. Inspect the room and optionally bind memory at the pocket watch.
3. Inspect each object and use choices to push clues from `UNKNOWN` to `HAZY` or `CLEAR`.
4. Read the `Thought` HUD if you are unsure where the detective's attention is drifting.
5. Stand near the door to hear voices outside; this does not require inspecting the door.
6. Use lethal choices carefully: tasting the residue, forcing the door, and opening the watch in NG+ can all kill.
7. Death returns the detective to the starting position of the loop.
8. Revisit clues after death; loop phase changes the wording, choices, and available insight.
9. Use the pocket watch to open the verdict once all clue states are known.
10. In Game 1, R is the clean answer. In NG+, investigate further to uncover the wider involvement.

## State Layers

- `clue_state`: objective facts for each interactable.
- `score`: where the detective's suspicion is drifting.
- `route`: soft narrative guards, spent death causes, and strict NG+ true-ending gates.
- `route_flags` / `true_path`: legacy mirrors kept for compatibility while the FSM settles.
- `user://savegame.json`: checkpoint data saved after start, resolved death, and ending.

## Minimum Test Path

1. Bind memory at the pocket watch.
2. Inspect table, body, door, RACHE, photo, and watch.
3. Use options that satisfy dependency order so clues become `CLEAR` where possible.
4. Trigger a death through residue or door to enter a later loop.
5. Revisit unresolved `HAZY` clues.
6. Return to the watch once every clue is known.
7. Choose R to close Game 1, then loop again for NG+.
8. In NG+, clear the room again, then follow the true-ending sequence:
   - after table and body are clear, taste the residue again;
   - after door and RACHE are clear, force the door again;
   - after both deaths are understood, hold the watch open.
9. Re-clear any hazy clue states, return to the watch, then choose `Myself`.

## Phase 1 Checks

1. Force the door once and return after death.
2. Try forcing the door again before finding a new lead.
3. Expected: no extra death loop; the game says that death will not teach anything new.
4. Watch the top-right `Thought` text after each clue.
5. Expected: after dialogue closes, the prompt gives a narrative nudge, not an explicit objective marker.
