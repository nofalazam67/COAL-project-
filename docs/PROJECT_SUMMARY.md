---
title: "Dungeon of Assembly: Project Summary"
subtitle: "COAL Lab Project"
---

# 1. Project overview

**Dungeon of Assembly** is a text-based dungeon RPG written in **x86 (32-bit)
Assembly language** with **MASM** and the **Irvine32 library**.

The whole map is printed on the console. The player (`@`) moves with W/A/S/D, and every
step earns a point. Monsters stand at fixed places on the map; walking into one starts a
turn-based fight. Monsters on the left side of the map are weak and get stronger towards
the right. The player collects gold from chests, buys items in the shop, finds the key
and finally defeats the Dragon in the boss room.

- **Language / tools:** x86 Assembly (MASM), Irvine32, Visual Studio
- **Size:** about 715 lines of code (not counting comments), 20 procedures
- **Platform:** Windows console

# 2. Objectives

- Use the main topics of the COAL course in one complete program.
- Practise low-level programming: registers, memory, arrays, the stack and procedures.
- Keep the design simple: one map, fixed monsters, one boss, clear text menus.

# 3. Game features

## 3.1 The map
A 15 × 40 map is stored as a **two-dimensional array** of characters and printed
completely every turn.

| Symbol | Meaning |
|---|---|
| `@` | Player |
| `#` | Wall (cannot pass) |
| `~` | Water (cannot pass) |
| `.` | Ground |
| `M` | Monster: walk into it to fight |
| `C` | Chest: 20 gold, +20 points |
| `$` | Shop |
| `+` | Fountain: full HP |
| `K` | Key: needed for the boss room, +50 points |
| `B` | Boss room (the Dragon) |

## 3.2 Monsters and battles
- 13 monsters are placed on the map. The monster type depends on the **map area**:
  area = column / 10.

| Area (columns) | Monster | HP | Attack |
|---|---|---|---|
| 0–9 | Slime | 15 | 4 |
| 10–19 | Goblin | 25 | 6 |
| 20–29 | Skeleton | 35 | 9 |
| 30–39 | Orc | 45 | 12 |

- Monsters get +5 HP for every player level.
- Battle menu: **1. Attack**, **2. Drink Potion**, **3. Run Away**.
- Damage = attack − defense/2 (at least 1). There is no randomness.
- Running away always works against monsters (the monster stays on the map), but never
  against the Dragon.
- The **Dragon** (180 HP, 20 attack) is the final boss.

## 3.3 Player progress
- **XP and levels:** the next level needs level × 50 XP. Each level gives +20 max HP,
  +3 attack, +2 defense and a full heal.
- **Gold:** from monsters and chests.
- **Score:** +1 per step, +20 per chest, +50 for the key, +XP per monster,
  +500 for the Dragon.

## 3.4 Shop
| Item | Effect | Starting price |
|---|---|---|
| Potion | +30 HP when used | 15 gold |
| Sharpen Sword | +3 attack | 40 gold (+20 after each buy) |
| Iron Armor | +2 defense | 35 gold (+20 after each buy) |

# 4. Menus

**Main menu:** 1. New Game, 2. How to Play, 3. Exit

**Game screen:**

| Key | Action |
|---|---|
| W | Move up |
| S | Move down |
| A | Move left |
| D | Move right |
| P | Drink potion |
| Q | Quit to main menu |

**Battle:** 1. Attack, 2. Drink Potion, 3. Run Away

**Shop:** 1. Potion, 2. Sword, 3. Armor, 4. Leave

# 5. Course topics used

| Course topic | Where it is used |
|---|---|
| Defining data, symbolic constants | Map, arrays, strings; `ROWS = 15`, `YES EQU 1` |
| Data transfer, addressing, arithmetic | `MOV`, `MOVZX`, `ADD`, `SUB`, `INC`, `DEC` everywhere |
| Operators and directives | `OFFSET`, `PTR`, `TYPE`, `LENGTHOF` |
| Control transfer, arrays and loops | `JMP`, `LOOP`; parallel monster arrays, prices array; `CMP`/`JE` chain for W/A/S/D |
| Procedures, runtime stack, PUSH/POP | 20 procedures; registers saved with `PUSH`/`POP` and `USES` |
| Boolean and comparison, conditional jumps | `OR` for letter case, `TEST`, `CMP`, `JE`/`JNE`/`JA`/`JB`... |
| High-level constructs | `.IF/.ELSE` in `DrinkPotion` |
| Shift, multiplication and division | `SHR` in damage; `MUL`/`DIV` for HP bar, XP, map index, monster area |
| Extended addition | 64-bit damage total with `ADD` + `ADC` |
| Stack frames | `CalcDamage` reads parameters at `[ebp+8]`, `[ebp+12]`, ends with `RET 8` |
| INVOKE, PROC, PROTO, LOCAL | `ShowBar` |
| String primitives | `REP MOVSD`, `REP MOVSB` in `NewGame` |
| Two-dimensional arrays | The map: `gameMap[row*COLS + col]` with base-index addressing |

# 6. Libraries and functions used

**Irvine32 procedures:** `Clrscr`, `SetTextColor`, `WriteString`, `WriteChar`,
`WriteDec`, `Crlf`, `ReadChar`.

**Instructions:** `MOV`, `MOVZX`, `PUSH`, `POP`, `ADD`, `SUB`, `INC`, `DEC`, `MUL`,
`DIV`, `ADC`, `OR`, `TEST`, `CMP`, `SHR`, `JMP`, `JE`, `JZ`, `JNE`, `JA`, `JAE`,
`JB`, `JGE`, `LOOP`, `CALL`, `RET`, `CLD`, `MOVSB`, `MOVSD`, `REP`.

**Directives:** `INCLUDE`, `.data`, `.code`, `BYTE`, `DWORD`, `DUP`, `=`,
`EQU`, `OFFSET`, `PTR`, `TYPE`, `LENGTHOF`, `PROC`, `ENDP`, `USES`, `LOCAL`,
`PROTO`, `INVOKE`, `.IF`, `.ELSE`, `.ENDIF`.

Definitions of all of these are in `INSTRUCTION_REFERENCE.md`.

# 7. Program structure

```
main (menu)
 |-- 1. New Game  --> NewGame --> PlayGame
 |-- 2. How to Play
 '-- 3. Exit

PlayGame loop:
   DrawScreen (map + ShowStats) --> ReadChar
     |-- W/A/S/D --> MovePlayer
     |        |-- wall / water: message
     |        |-- M monster: MonsterBattle --> Battle --> CalcDamage, CheckLevelUp
     |        |-- C chest, K key, + fountain, $ Shop
     |        '-- B: BossBattle (needs the key)
     |-- P DrinkPotion
     '-- Q back to the menu
   HP = 0       --> EndScreen (Game Over)
   Dragon dead  --> EndScreen (You Won)
```

# 8. Possible improvements

- More monster types and a bigger map
- Save / load and a high-score file
- Sound with the Windows `Beep` function
