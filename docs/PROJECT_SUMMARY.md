---
title: "Dungeon of Assembly: Project Summary"
subtitle: "COAL (Computer Organization & Assembly Language) Lab Project"
---

# 1. Project overview

**Dungeon of Assembly** is a console-based dungeon survival RPG written entirely in
**x86 (32-bit) Assembly language** using **MASM** and the **Irvine32 library**.

The player explores a small open world drawn in ASCII and colour. At every step the
player chooses what to do from a menu (move north, south, west or east, drink a potion,
rest, save). Walking reveals the map and earns points. Random monsters ambush the player
and are fought in turn-based combat. The player collects gold, buys upgrades, finds a
hidden key and finally defeats the Dragon King to win.

**Language / tools:** x86 Assembly (MASM), Irvine32, Visual Studio (or `ml.exe` + `link.exe`)
**Size:** about 2,350 lines of assembly in one source file (`DungeonRPG.asm`)
**Platform:** Windows console (80 x 25 or larger)

# 2. Aim and objectives

- Show practical use of the main COAL topics in one working program.
- Build an interactive game using only low-level instructions: no high-level language.
- Use real **file handling** (binary save game and text score file).
- Keep the design simple and minimalistic: one map, one boss, clear menus.

# 3. What the game does

## 3.1 Story and goal
The Dragon King threatens the realm. The hero must find the **Ancient Key** hidden in the
Ruined Keep, open the lair gate in the far east and defeat the dragon.

## 3.2 The open world
- A 40 x 15 tile map split into 4 zones: **Green Meadows**, **Whispering Woods**,
  **Ruined Keep** and **Dragon Wastes**.
- **Fog of war:** the map starts hidden and is revealed as the player walks. Each newly
  discovered tile gives **+1 point**.
- Map objects:

| Symbol | Meaning |
|---|---|
| `@` | The player |
| `#` (block) | Wall: cannot be crossed |
| `~` | Deep water: cannot be crossed |
| `$` | Shop: buy potions and upgrades |
| `+` | Fountain: fully restores HP (unlimited use) |
| chest (small square) | Chest: gold, sometimes a potion (+25 points) |
| `K` | The Ancient Key (+100 points) |
| `B` | The Dragon King's lair (needs the key) |

## 3.3 Random encounters and combat
- There is a 12% chance of a monster ambush on each step on open ground.
- Enemies get stronger further east and as the player levels up: Cave Slime, Goblin
  Raider, Skeleton Knight, Orc Brute, Shadow Wraith.
- Combat is turn-based. Each turn the player picks an action, then the enemy attacks.
- 10% of hits are **critical hits** (double damage).
- The **Dragon King** (final boss) has 250 HP, cannot be escaped from and breathes fire
  (1.5x damage) every third turn.

## 3.4 Progression
- **XP and levels:** each level gives +20 max HP, +3 attack, +2 defence and a full heal.
  XP needed for the next level = level x 50.
- **Gold:** earned from enemies and chests, spent in the shop.
- **Score:** exploration, chests, key, kills, level-ups and the boss all add points.

## 3.5 Shop
| Item | Effect | Base price |
|---|---|---|
| Healing Potion | +40 HP when used | 15 g (fixed) |
| Sharpen Sword | +3 Attack | 40 g |
| Iron Armour | +2 Defence | 35 g |
| Vitality Charm | +20 Max HP | 50 g |

Upgrade prices go up each time an item is bought (price x number bought + 1).

## 3.6 Save, load and hall of fame
- **Save game:** writes the whole game state to `dungeon.sav` (binary, XOR-encrypted, with a
  signature so corrupted or wrong files are rejected).
- **Load game:** reads and checks the file, then restores the exact game.
- **Hall of Fame:** when a game ends (win or lose) a line with name, score, level, kills and
  result is added to the text file `halloffame.txt`. It can be viewed from the title menu.

# 4. Menus and options

## 4.1 Title menu
| Key | Option |
|---|---|
| 1 | New Adventure (asks for a hero name) |
| 2 | Load Saved Game |
| 3 | Hall of Fame |
| 4 | How to Play |
| 5 | Exit |

## 4.2 Exploration menu
| Key | Action |
|---|---|
| 1 / W / Up arrow | Move north |
| 2 / S / Down arrow | Move south |
| 3 / A / Left arrow | Move west |
| 4 / D / Right arrow | Move east |
| 5 | Drink a potion (+40 HP) |
| 6 | Rest / camp (+25% HP, 35% chance of an ambush) |
| 7 | Save game |
| 8 | Quit to the title screen |

## 4.3 Battle menu
| Key | Action |
|---|---|
| 1 | Attack |
| 2 | Heavy Strike (60% chance to hit, double damage) |
| 3 | Drink potion (does not use up the turn if you have none) |
| 4 | Flee (50% chance; not possible against the boss) |

## 4.4 Shop menu
Keys 1 to 4 buy the items shown above, and 0 leaves the shop.

## 4.5 Game screens
Title screen, How to Play, exploration screen (map + status panel), battle screen,
shop screen, Victory screen, Game Over screen and Hall of Fame. Screenshots are in
`docs/screenshots/`.

# 5. COAL concepts demonstrated

| COAL topic | How it is used in the game |
|---|---|
| Data definition and arrays | Map, enemy table, lookup tables, text buffers |
| Constants and equates | Map size, flags, colours, prices |
| Structures | `PlayerT` (player stats) and `EnemyT` (enemy stats) |
| Macros | Six macros for cursor movement, colour and printing |
| Procedures and the stack | About 60 procedures with parameters, local variables and saved registers |
| Recursion | Number-to-text conversion calls itself on `n / 10` |
| Addressing modes | Direct, indirect, indexed and scaled (`table[reg*4]`) |
| Arithmetic | `ADD`, `SUB`, `MUL`, `IMUL`, `DIV` for damage, XP, HP bars, prices |
| Shifts | Map index `y*40 = (y<<5)+(y<<3)`, halving and doubling values |
| Bitwise logic | Bit flags for key and boss, case conversion, XOR encryption |
| Branching and loops | Conditional jumps (signed and unsigned), `LOOP`, `JECXZ`, nested loops |
| String instructions | `MOVSB`, `STOSB`, `LODSB`, `SCASB`, `REP`, `REPNE`, `CLD`, `STD` |
| Table lookup | `XLAT` converts a map character to a colour and symbol |
| Jump tables | Keyboard commands and shop items are called through address tables |
| File handling | Binary save file and appended text score file |
| Console I/O | Cursor control, colours, key input, animation delays |
| Random numbers | Encounters, damage, loot and enemy choice |

# 6. Libraries and functions used

## 6.1 Irvine32 library procedures
`Clrscr`, `Gotoxy`, `SetTextColor`, `WriteChar`, `WriteString`, `WriteDec`, `Crlf`,
`ReadChar`, `ReadString`, `Randomize`, `RandomRange`, `Delay`, `Str_copy`,
`CreateOutputFile`, `OpenInputFile`, `WriteToFile`, `ReadFromFile`, `CloseFile`.

## 6.2 Windows API (through SmallWin.inc)
`CreateFile`, `SetFilePointer`, `ExitProcess`.

## 6.3 Main CPU instructions
`MOV`, `MOVZX`, `LEA`, `PUSH`, `POP`, `PUSHFD`, `POPFD`, `XLAT`, `ADD`, `SUB`, `INC`, `DEC`,
`MUL`, `IMUL`, `DIV`, `AND`, `OR`, `XOR`, `TEST`, `SHL`, `SHR`, `CMP`, `JMP`, `JE`, `JNE`, `JZ`,
`JNZ`, `JA`, `JAE`, `JB`, `JBE`, `JG`, `JGE`, `JL`, `JC`, `JNC`, `JECXZ`, `LOOP`, `CALL`, `RET`,
`CLD`, `STD`, `MOVSB`, `MOVSD`, `STOSB`, `STOSD`, `LODSB`, `SCASB`, `REP`, `REPNE`.

## 6.4 MASM directives
`INCLUDE`, `.data`, `.code`, `END`, `BYTE`, `DWORD`, `SDWORD`, `DUP`, `LABEL`, `=` (equate),
`STRUCT`/`ENDS`, `SIZEOF`, `TYPE`, `OFFSET`, `ADDR`, `PTR`, `PROC`/`ENDP`, `USES`, `LOCAL`,
`PROTO`, `INVOKE`, `MACRO`/`ENDM`.

A one-line definition of each item is in `docs/INSTRUCTION_REFERENCE.md`.

# 7. Program structure

```
main  -->  Title menu
             |-- New Game  --> PlayGame loop
             |-- Load Game --> PlayGame loop
             |-- Hall of Fame
             |-- How to Play
             '-- Exit

PlayGame loop:
   draw screen --> read key --> jump table --> run action
        |
        |-- Move  --> reveal map, then shop / fountain / chest / key / boss gate / random fight
        |-- Potion, Rest, Save, Quit
        |
   HP = 0       --> Game Over screen --> write to Hall of Fame
   Boss defeated --> Victory screen  --> write to Hall of Fame
```

# 8. Files

| File | Purpose |
|---|---|
| `DungeonRPG.asm` | Complete source code |
| `build.bat` | Builds the project from a Visual Studio command prompt |
| `README.md` | Build steps, controls, formulas, save-file layout |
| `docs/INSTRUCTION_REFERENCE.md` | Every instruction and function used, with definitions |
| `docs/screenshots/` | Screenshots of each game screen |
| `dungeon.sav` | Created by the game: encrypted binary save |
| `halloffame.txt` | Created by the game: text list of results |

# 9. Testing done

- The source assembles with **0 errors and 0 warnings**.
- 40 automated games with 3,000 random key presses each ran with **no crashes**.
- An automated player completed the full game (key, shop, boss, victory) in 8 of 10 test runs.
- Saving and loading restores the exact game; corrupted or missing save files show an error.

*Note: testing was done with a MASM-compatible assembler on Linux. Please run it once in
Visual Studio on Windows before submission.*

# 10. Possible future improvements

- Larger map with more zones and several bosses.
- Inventory with weapons and armour that can be equipped.
- Sound effects using the Windows `Beep` function.
- Multiple save slots.
