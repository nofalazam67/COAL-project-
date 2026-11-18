# Dungeon of Assembly

COAL lab project: a text-based dungeon RPG in **x86 Assembly (MASM, 32-bit)**
using the **Irvine32** library.

The whole map is printed on the screen and the player (`@`) moves with W/A/S/D.
Each step gives 1 point. Monsters (`M`) stand at fixed places on the map: walking
into one starts a turn-based fight. Monsters on the left side are weak and get
stronger towards the right. Chests give gold, the shop sells potions and
upgrades, and the key `K` opens the boss room `B`. Kill the Dragon to win.

## Controls
| Key | Action |
|---|---|
| W | Move up |
| S | Move down |
| A | Move left |
| D | Move right |
| P | Drink potion (+30 HP) |
| Q | Quit to main menu |

In battle: `1` Attack, `2` Drink Potion, `3` Run Away (always works, except against the Dragon).

## Map symbols
`@` player, `#` wall, `~` water, `.` ground, `M` monster, `C` chest, `$` shop,
`+` fountain (full heal), `K` key, `B` boss room.

## Monster areas (area = column / 10)
| Columns | Monster | HP | Attack |
|---|---|---|---|
| 0–9 | Slime | 15 | 4 |
| 10–19 | Goblin | 25 | 6 |
| 20–29 | Skeleton | 35 | 9 |
| 30–39 | Orc | 45 | 12 |

Monsters get +5 HP per player level. The Dragon has 180 HP and 20 attack.

## How to build
1. Open your Irvine32 Visual Studio project (`Project32_VS20xx`).
2. Add `DungeonRPG.asm` to the project (remove the sample `.asm`).
3. Build and run with **Ctrl+F5**.

Or, from the *x86 Native Tools Command Prompt*, run `build.bat`
(edit the `IRVINE` path inside if Irvine is not in `C:\Irvine`).

## Documents
- `docs/PROJECT_SUMMARY.md` / `.docx`: project description
- `docs/INSTRUCTION_REFERENCE.md`: every instruction and function used, with definitions
