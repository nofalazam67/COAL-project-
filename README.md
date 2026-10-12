# Dungeon of Assembly

A console dungeon-survival RPG written in **x86 Assembly (MASM, 32-bit)** with the
**Irvine32** library. This is the end-of-semester project for the COAL
(Computer Organization & Assembly Language) lab.

You explore a small open world hidden by fog of war. Each move is picked from a
menu (or WASD / arrow keys). Exploring earns points, and you face random monsters
in turn-based fights. Collect gold, upgrade your gear in the shop, find the
**Ancient Key** and defeat the **Dragon King**.

```
  DUNGEON OF ASSEMBLY  -  explore - fight - survive

 ╔════════════════════════════════════════╗ ╔════════════════════════════════╗
 ║████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ == NOFAL ==                    ║
 ║█...@...░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ Level 1   XP 48 / 50           ║
 ║█..■....░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ HP [████████████░░░░░░░░]      ║
 ║█.......░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║    64 / 100                    ║
 ║█....░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ ATK 10   DEF 4                 ║
 ║█...$░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ Gold 62      Potions 2         ║
 ║█....░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ Ancient Key: MISSING           ║
 ║░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ Score 175   Kills 3            ║
 ║░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ Zone  Green Meadows            ║
 ║░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ Pos (4,1)  Steps 9             ║
 ║░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║                                ║
 ║░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ LEGEND                         ║
 ║░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ @ You  $ Shop  + Fountain      ║
 ║░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ ■ Chest  K Key   B Boss        ║
 ║░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║ ║ ~ Water  █ Wall  ░ Unknown     ║
 ╚════════════════════════════════════════╝ ╚════════════════════════════════╝
 > Defeated Goblin Raider  +18 XP  +12 gold

 [1/W] North   [2/S] South   [3/A] West   [4/D] East   (arrows work too)
 [5] Drink Potion   [6] Rest / Camp   [7] Save Game   [8] Quit to Title
```

```
╔════════════════════════════════ B A T T L E ════════════════════════════════╗
║      ,   ,                                                                  ║
║     (\o o/)                           Goblin Raider                         ║
║      \ ^ /                            HP [████████████░░░░░░░░]             ║
║      /|=|\                               18 / 30   ATK 8  DEF 2             ║
║       / \                                                                   ║
║                                       NOFAL  (Lv 1)                         ║
║                                       HP [███████████████░░░░░]             ║
║                                          75 / 100   ATK 10  DEF 4           ║
║ ╔═════════════════════════════════════════════════════════════════════════╗ ║
║ ║ You hit the Goblin Raider for 12 damage                                 ║ ║
║ ║ Goblin Raider hits you for 9 damage                                     ║ ║
║ ╚═════════════════════════════════════════════════════════════════════════╝ ║
║   [1] Attack       [2] Heavy Strike (60% hit, x2 damage)                    ║
║   [3] Drink Potion [4] Flee (50% chance)                                    ║
╚═════════════════════════════════════════════════════════════════════════════╝
```

In the real console every element is coloured: green grass, blue water, a
yellow `@`, a red boss gate, and HP bars that turn green, then yellow, then red.

---

## Features

| Feature | Description |
|---|---|
| Open world | 40×15 tile map with 4 zones: Green Meadows, Whispering Woods, Ruined Keep, Dragon Wastes |
| Fog of war | The map is hidden until you walk near it. Each newly discovered tile gives **+1 point** |
| Random encounters | 12% chance per step. Enemies get stronger further east and as you level up |
| Turn-based combat | Attack, Heavy Strike (60% hit, double damage), Potion, Flee. 10% critical hits |
| Boss | The **Dragon King** breathes fire every 3rd turn and can't be fled from |
| Progression | XP, levels (+20 max HP, +3 ATK, +2 DEF per level), gold, score, kill count |
| Inventory | Potions, the Ancient Key (stored as a bit flag), gear upgrades |
| Shop | Potions, sword, armour and vitality charm. Upgrade prices go up each time you buy |
| World objects | Chests (gold, sometimes a potion), healing fountains, the key hut, the boss gate |
| Save / Load | Binary save file `dungeon.sav`, XOR-encrypted and checked with a signature |
| Hall of Fame | Every finished game is **appended** to `halloffame.txt` and shown from the title menu |

## Controls

| Key | Action |
|---|---|
| `1` / `W` / ↑ | Move north |
| `2` / `S` / ↓ | Move south |
| `3` / `A` / ← | Move west |
| `4` / `D` / → | Move east |
| `5` | Drink a potion (+40 HP) |
| `6` | Rest / camp (+25% HP, 35% chance of an ambush) |
| `7` | Save game |
| `8` | Quit to title |

**How to win:** the Ancient Key `K` is in a hut in the Ruined Keep. Pick it up,
then walk into the lair gate `B` in the Dragon Wastes and defeat the Dragon King.
Collect chests, use the shop and level up to about 6 first.

---

## Building and running

**Requirements:** Windows, Visual Studio (C++ workload, which includes MASM), and
the [Irvine32 library](https://asmirvine.com) installed in `C:\Irvine`.

### Option A: Visual Studio (the usual lab setup)
1. Open your Irvine32 project template (`Project32_VS20xx`).
2. Remove the sample `.asm` file and add `DungeonRPG.asm` to the project.
3. Build and run with **Ctrl+F5**.

### Option B: command line
Open the **x86 Native Tools / Developer Command Prompt for VS** and run:
```
build.bat
DungeonRPG.exe
```
If Irvine is installed somewhere else, edit the `IRVINE` path at the top of
`build.bat`.

> Use a console window at least **80×25**. The map uses CP437 box and block
> characters (`█ ░ ═ ║`), which the default Windows console displays.

Files the game creates in its working directory:
- `dungeon.sav`: the encrypted binary save game
- `halloffame.txt`: the plain-text score history (you can open it in Notepad)

---

## COAL concepts index

Where each lab topic appears in `DungeonRPG.asm` (procedure names in brackets):

| Concept | Where it is used |
|---|---|
| **Data definition** (`BYTE`, `DWORD`, `DUP`, strings, `LABEL`) | `.data` section: map, lookup tables, buffers |
| **Constants** (`=`, `EQU`, `$` for array length) | `MAP_W`, `FLAG_KEY`, `KEY_COUNT = ($ - keyTable)`, `ENEMY_COUNT` |
| **Structures** (`STRUCT`, `SIZEOF`, `TYPE`) | `PlayerT`, `EnemyT`, `enemyTable` (array of structs), `SIZEOF PlayerT` |
| **Macros** (params, `REQ`, defaults, `LOCAL`) | `mGoto`, `mColor`, `mPrint`, `mPrintAt`, `mShow`, `mNum` |
| **Procedures** (`PROC`, `USES`, `LOCAL`, `PROTO`, `INVOKE`, stack params) | `TryMove`, `DrawBar`, `DrawBox`, `CalcDamage`, `Battle` |
| **Recursion** | `BufAddNum`: prints a number by calling itself on `n / 10` |
| **Addressing modes** (direct, indirect, indexed, scaled, base+index) | `worldMap[esi]`, `prices[ebx*4]`, `[edi + 2]`, `enemyTable[eax]` |
| **Arithmetic** (`ADD`, `SUB`, `INC`, `DEC`, `MUL`, `IMUL`, `DIV`) | damage, XP curve (`lvl*50`), HP bar (`hp*20/max`), zone (`x/10`), shop prices |
| **Shifts** (`SHL`, `SHR`) | `TileIndex`: `y*40 = (y<<5)+(y<<3)`; halving defence; doubling crits |
| **Bitwise logic** (`AND`, `OR`, `XOR`, `TEST`) | key/boss bit flags, upper/lower case (`AND 0DFh`, `OR 20h`), XOR cipher |
| **Conditional jumps** (signed and unsigned) | bounds checks (`JAE` catches -1 as unsigned), `JG`/`JL` in `RevealArea` |
| **Loops** (`LOOP`, `JECXZ`, nested loops) | `DrawMap` (rows × columns), `RevealArea`, `DrawBox`, `XorBuffer` |
| **Stack** (`PUSH`/`POP`, `PUSHFD`/`POPFD`, frames) | macros keep registers safe; `LoadGame` keeps the carry flag across a call |
| **String instructions** (`MOVSB/MOVSD`, `STOSB/STOSD`, `LODSB`, `SCASB`, `REP`, `REPNE`, `CLD`/`STD`) | `NewGame`, `SaveGame`, `BufAddStr`, `DispatchAction`, `DrawArt`, backward scan in `ShowHallOfFame` |
| **`XLAT` lookup tables** | `DrawMap`: tile → colour and tile → glyph |
| **Jump tables / indirect `CALL`** | `actionTable` (keyboard commands), `shopEffects` (shop items) |
| **File handling (Irvine)** | `CreateOutputFile`, `OpenInputFile`, `WriteToFile`, `ReadFromFile`, `CloseFile` |
| **File handling (Win32 API)** | `CreateFile` with `OPEN_ALWAYS`, plus `SetFilePointer` with `FILE_END` to **append** (`RecordScore`) |
| **Binary vs text files** | `dungeon.sav` holds raw struct bytes; `halloffame.txt` holds formatted text lines |
| **Console I/O and graphics** | `Gotoxy`, `SetTextColor`, `Clrscr`, `ReadChar` (arrow scan codes), `ReadString`, `WriteDec`, `Delay` animations |
| **Random numbers** | `Randomize`, `RandomRange`: encounters, damage, loot, enemy choice |

## Program structure

```
main ─► TitleScreen ─┬─ NewGame ─► PlayGame (main loop)
                     ├─ LoadGame ─► PlayGame
                     ├─ ShowHallOfFame
                     └─ ShowHelp

PlayGame loop:  DrawFrame* ► DrawMap ► DrawHud ► DrawMessage
                ► GetAction ► DispatchAction (jump table)
                    ├─ MoveN/S/E/W ► TryMove ─┬─ RevealArea (fog + points)
                    │                         ├─ Shop / fountain / chest / key
                    │                         ├─ Battle(0) random encounter
                    │                         └─ Battle(1) Dragon King (needs key)
                    ├─ DrinkPotion   ├─ RestCamp   ├─ SaveGame   └─ QuitToTitle
                ► HP = 0 ?  GameOverScreen ► RecordScore
                ► boss dead? VictoryScreen ► RecordScore
```

| Group | Procedures |
|---|---|
| Game flow | `main`, `InitTables`, `NewGame`, `PlayGame`, `GetAction`, `DispatchAction` |
| World | `MoveNorth/South/East/West`, `TryMove`, `TileIndex`, `RevealArea`, `DrinkPotion`, `RestCamp`, `QuitToTitle` |
| Combat | `SpawnEnemy`, `CalcDamage`, `Battle`, `CheckLevelUp`, `BattleFlash`, `HitFlash`, `DrawBattle` |
| Shop | `Shop`, `ItemPrice`, `BuyPotion`, `BuySword`, `BuyArmor`, `BuyVitality`, `BoughtMsg` |
| UI | `DrawFrame`, `DrawMap`, `DrawHud`, `HpColor`, `DrawBar`, `DrawBox`, `DrawArt`, `SetMessage`, `DrawMessage` |
| Strings | `BufBegin`, `BufAddChar`, `BufAddStr`, `BufAddNum` (recursive), `BufPadTo`, `ToUpperStr`, `XorBuffer` |
| Files | `SaveGame`, `LoadGame`, `RecordScore`, `ShowHallOfFame` |
| Screens | `TitleScreen`, `ShowHelp`, `ShowFinalStats`, `GameOverScreen`, `VictoryScreen` |

## Game formulas

```
damage      = ATK + random(0 .. ATK/2) - DEF/2      (minimum 1, 10% chance x2)
heavy hit   = damage x 2, lands 60% of the time
boss fire   = damage x 3/2 on every 3rd enemy turn
XP to level = level x 50
enemy type  = zone (x / 10) + random(0..1)   ->  Slime, Goblin, Skeleton, Orc, Wraith
enemy scale = +5 HP and +1 ATK per player level above 1
score       = +1 per discovered tile, +25 per chest, +100 key,
              +2*XP + gold per kill, +100 per level-up, +1000 Dragon King
shop price  = base price x (times bought + 1)          (potions stay 15 g)
```

### Save file layout (`dungeon.sav`, 1,292 bytes, XOR 5Ah)
```
offset 0      4 bytes   signature 'COAL'
offset 4     88 bytes   PlayerT structure
offset 92   600 bytes   world map (opened chests / taken key)
offset 692  600 bytes   fog-of-war mask
```
