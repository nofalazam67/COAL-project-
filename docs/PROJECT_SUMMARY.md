---
title: "Dungeon of Assembly: Project Summary"
subtitle: "COAL (EE2003) Lab Project"
---

# 1. Project overview

**Dungeon of Assembly** is a text-based dungeon RPG written in **x86 (32-bit)
Assembly language** with **MASM** and the **Irvine32 library**.

The whole map is printed on the console. The player (`@`) chooses an action from a menu
each turn: move up, down, left or right, drink a potion, save or quit. Every step earns
a point. While walking, random enemies attack and are fought in turn-based battles.
The player collects gold from chests, buys items in the shop, finds the key and finally
defeats the Dragon in the boss room.

- **Language / tools:** x86 Assembly (MASM), Irvine32, Visual Studio
- **Size:** about 970 lines of code (not counting comments), 29 procedures
- **Platform:** Windows console

# 2. Objectives

- Use the topics of the COAL course in one complete program.
- Practise low-level programming: registers, memory, the stack and procedures.
- Use file handling to save the game and keep a high score.
- Keep the design simple: one map, one boss, clear text menus.

# 3. Game features

## 3.1 The map
A 15 × 40 map is stored as a **two-dimensional array** of characters and printed
completely every turn.

| Symbol | Meaning |
|---|---|
| `@` | Player |
| `#` | Wall (cannot pass) |
| `~` | Water (cannot pass) |
| `.` | Ground (enemies can appear here) |
| `C` | Chest: 10 to 30 gold, +20 points |
| `$` | Shop |
| `+` | Fountain: full HP |
| `K` | Key: needed for the boss room, +50 points |
| `B` | Boss room (the Dragon) |

## 3.2 Battles
- There is a 15% chance of an enemy on every step on ground.
- There are 4 enemies (Slime, Goblin, Skeleton, Orc). Stronger ones appear further east
  and they get more HP as the player levels up.
- Battle menu: **1. Attack**, **2. Drink Potion**, **3. Run Away** (50% chance).
- Damage = attack + random(0 .. attack/2) − defense/2, with a 10% chance of a
  critical hit (double damage).
- The **Dragon** (180 HP) is the final boss. You cannot run away from it.

## 3.3 Player progress
- **XP and levels:** the next level needs level × 50 XP. Each level gives +20 max HP,
  +3 attack, +2 defense and a full heal.
- **Gold:** from enemies and chests.
- **Score:** +1 per step, +20 per chest, +50 for the key, +XP per enemy,
  +500 for the Dragon.

## 3.4 Shop
| Item | Effect | Starting price |
|---|---|---|
| Potion | +30 HP when used | 15 gold |
| Sharpen Sword | +3 attack | 40 gold (+20 after each buy) |
| Iron Armor | +2 defense | 35 gold (+20 after each buy) |

## 3.5 Files
- **Save / load game:** `dungeon.sav` holds a 4-byte header `DUNG`, then the player
  name, all stats and the map. When loading, the header is checked first.
- **High score:** `highscore.txt` stores the best score as text. It is shown on the main
  menu and updated when a game ends with a new record.

# 4. Menus

**Main menu:** 1. New Game, 2. Load Game, 3. How to Play, 4. Exit

**Game screen:**

| Key | Action |
|---|---|
| W or 1 | Move up |
| S or 2 | Move down |
| A or 3 | Move left |
| D or 4 | Move right |
| 5 | Drink potion |
| 6 | Save game |
| 7 | Quit to main menu |

**Battle:** 1. Attack, 2. Drink Potion, 3. Run Away

**Shop:** 1. Potion, 2. Sword, 3. Armor, 4. Leave

# 5. Course topics used

| Course topic (week) | Where it is used |
|---|---|
| Defining data, symbolic constants (3) | Map, arrays, strings; `ROWS = 15`, `YES EQU 1` |
| Data transfer, addressing, arithmetic (4) | `MOV`, `MOVZX`, `ADD`, `SUB`, `INC`, `DEC` everywhere |
| Operators and directives (5) | `OFFSET`, `PTR`, `TYPE`, `LENGTHOF`, `LABEL` |
| Control transfer, arrays and loops (5) | `JMP`, `LOOP`; parallel enemy arrays, prices array |
| Procedures, runtime stack, PUSH/POP (7) | 29 procedures; registers saved with `PUSH`/`POP` and `USES` |
| Boolean and comparison, conditional jumps (8) | `AND`/`OR` for letter case, `TEST`, `CMP`, `JE`/`JNE`/`JA`/`JB`... |
| Conditional loops, high-level constructs (9) | `LOOPNZ` in `UpperName`; `.IF/.ELSE` in `DrinkPotion` |
| Shift, multiplication and division (10) | `SHL`/`SHR` in damage; `MUL`/`DIV` for HP bar, XP, map index, zones |
| Extended addition (10) | 64-bit damage total with `ADD` + `ADC` |
| Stack frames (12) | `CalcDamage` reads parameters at `[ebp+8]`, `[ebp+12]`, ends with `RET 8` |
| Recursion (12) | `IntToStr` calls itself to convert the score to text |
| INVOKE, ADDR, PROC, PROTO, LOCAL (12) | `ShowBar` and `SaveToFile` |
| String primitives (13) | `MOVSB`, `MOVSD`, `STOSB`, `LODSB`, `SCASB`, `CMPSB` with `REP`/`REPE`/`REPNE` |
| Two-dimensional arrays (13) | The map: `gameMap[row*COLS + col]` with base-index addressing |
| File handling (Irvine32) | Save/load game and high score file |

# 6. Libraries and functions used

**Irvine32 procedures:** `Clrscr`, `SetTextColor`, `WriteString`, `WriteChar`,
`WriteDec`, `Crlf`, `ReadChar`, `ReadString`, `Randomize`, `RandomRange`,
`CreateOutputFile`, `OpenInputFile`, `WriteToFile`, `ReadFromFile`, `CloseFile`.

**Instructions:** `MOV`, `MOVZX`, `PUSH`, `POP`, `ADD`, `SUB`, `INC`, `DEC`, `MUL`,
`DIV`, `ADC`, `AND`, `OR`, `TEST`, `CMP`, `SHL`, `SHR`, `JMP`, `JE`, `JZ`, `JNE`,
`JA`, `JAE`, `JB`, `JBE`, `JGE`, `JNC`, `LOOP`, `LOOPNZ`, `CALL`, `RET`, `CLD`,
`MOVSB`, `MOVSD`, `STOSB`, `LODSB`, `SCASB`, `CMPSB`, `REP`, `REPE`, `REPNE`.

**Directives:** `INCLUDE`, `.data`, `.code`, `BYTE`, `DWORD`, `SDWORD`, `DUP`, `=`,
`EQU`, `LABEL`, `OFFSET`, `PTR`, `TYPE`, `LENGTHOF`, `PROC`, `ENDP`, `USES`,
`LOCAL`, `PROTO`, `INVOKE`, `ADDR`, `.IF`, `.ELSE`, `.ENDIF`.

Definitions of all of these are in `INSTRUCTION_REFERENCE.md`.

# 7. Program structure

```
main (menu)
 |-- 1. New Game  --> NewGame --> PlayGame
 |-- 2. Load Game --> LoadGame --> PlayGame
 |-- 3. How to Play
 '-- 4. Exit

PlayGame loop:
   DrawScreen (map + ShowStats) --> ReadChar
     |-- W/A/S/D or 1-4 --> MovePlayer
     |        |-- wall / water: message
     |        |-- C chest, K key, + fountain, $ Shop
     |        |-- B: BossBattle (needs the key)
     |        '-- ground: 15% RandomBattle --> Battle --> CalcDamage, CheckLevelUp
     |-- 5 DrinkPotion   |-- 6 SaveGame   '-- 7 back to the menu
   HP = 0       --> EndScreen (Game Over) --> high score check
   Dragon dead  --> EndScreen (You Won)   --> high score check
```

# 8. Testing

- The program assembles with 0 errors and 0 warnings.
- 40 test runs with random key presses showed no crashes.
- Full games were played from start to the Dragon (win and lose).
- Saving and loading restores the same position, stats and map. A damaged or missing
  save file shows an error message.

# 9. Possible improvements

- More enemy types and a bigger map
- Sound with the Windows `Beep` function
- More than one save slot
