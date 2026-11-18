# Instruction & Library Reference: Dungeon of Assembly

Everything used in `DungeonRPG.asm`, with a one-line definition of each.
The counts show how many times each instruction appears in the code.

---

## 1. CPU instructions

### Data transfer
| Instruction | Used | What it does |
|---|---|---|
| `MOV` | 177 | Copies a value from a source to a destination |
| `MOVZX` | 1 | Copies a small value into a bigger register and fills the rest with zeros |
| `PUSH` | 9 | Puts a value on top of the stack |
| `POP` | 5 | Takes the top value off the stack |

### Arithmetic
| Instruction | Used | What it does |
|---|---|---|
| `ADD` | 20 | Adds two values |
| `SUB` | 8 | Subtracts the source from the destination |
| `INC` | 8 | Adds 1 |
| `DEC` | 1 | Subtracts 1 |
| `MUL` | 5 | Unsigned multiply: `EDX:EAX = EAX * operand` |
| `DIV` | 2 | Unsigned divide: `EAX` = quotient, `EDX` = remainder |
| `ADC` | 1 | Adds with the carry flag (64-bit total damage) |

### Boolean, comparison and shift
| Instruction | Used | What it does |
|---|---|---|
| `OR` | 1 | Bitwise OR: sets bit 5 to turn a key into a small letter |
| `TEST` | 1 | ANDs two values only to set the flags (checks if the key is held) |
| `CMP` | 37 | Compares two values (only the flags change) |
| `SHR` | 1 | Shift right = divide by 2 (defense / 2 in the damage formula) |

### Jumps and loops
| Instruction | Used | What it does |
|---|---|---|
| `JMP` | 16 | Always jumps to a label |
| `LOOP` | 5 | Decrements `ECX` and jumps while `ECX` is not 0 |
| `JE` / `JZ` | 21 / 1 | Jump if equal / zero |
| `JNE` | 9 | Jump if not equal |
| `JA` / `JAE` | 1 / 2 | Jump if above / above or equal (unsigned) |
| `JB` | 4 | Jump if below (unsigned) |
| `JGE` | 1 | Jump if greater or equal (signed) |

### Procedures
| Instruction | Used | What it does |
|---|---|---|
| `CALL` | 110 | Pushes the return address and jumps to a procedure |
| `RET` | 26 | Returns to the caller (`RET 8` also removes 2 parameters) |

### String primitives
| Instruction | Used | What it does |
|---|---|---|
| `CLD` | 2 | Clears the direction flag, so string instructions move forward |
| `MOVSB` / `MOVSD` | 1 / 1 | Copies a byte / double-word from `[ESI]` to `[EDI]` |
| `SCASB` | 1 | Compares `AL` with the byte at `[EDI]` (finds the pressed key) |
| `REP` / `REPNE` | 2 / 1 | Repeat the string instruction `ECX` times / while not equal |

---

## 2. Assembler directives and operators
| Item | What it does |
|---|---|
| `INCLUDE` | Adds the Irvine32 library definitions |
| `.data` / `.code` | Start the data section / code section |
| `BYTE`, `DWORD`, `SDWORD` | Define 8-bit, 32-bit and signed 32-bit data |
| `DUP` | Repeats a value (`BYTE MAP_SIZE DUP(?)`) |
| `=` and `EQU` | Define symbolic constants (`ROWS = 15`, `YES EQU 1`) |
| `OFFSET` | Gives the address of a variable |
| `PTR` | Sets the size of a memory operand |
| `TYPE` | Size of one array element (used in `array[esi * TYPE array]`) |
| `LENGTHOF` | Number of elements in an array |
| `PROC` / `ENDP` | Start / end a procedure |
| `USES` | Saves and restores registers automatically |
| `.IF` / `.ELSE` / `.ENDIF` | High-level IF statement (used in `DrinkPotion`) |
| `PROTO` / `INVOKE` | Declare a procedure with parameters / call it with arguments (`ShowBar`) |
| `LOCAL` | Creates a local variable on the stack (`filled` in `ShowBar`) |
| `[ebp+8]`, `[ebp+12]` | Reading parameters from the stack frame (`CalcDamage`) |
| `exit` | Irvine's way to end the program |

### Addressing modes used
| Mode | Example in the code |
|---|---|
| Immediate | `mov eHP, 180` |
| Register | `mov esi, eax` |
| Direct | `mov eax, hp` |
| Indexed | `mov al, tileChars[esi]` |
| Scaled indexed | `mov eax, enemyHPs[esi * TYPE enemyHPs]` |
| Base-index (2D array) | `mov al, gameMap[edi+esi]`: row offset + column |
| Stack frame (base + offset) | `mov eax, [ebp+8]` |

---

## 3. Irvine32 library procedures
| Procedure | What it does |
|---|---|
| `Clrscr` | Clears the screen |
| `SetTextColor` | Sets the text colour from `EAX` |
| `WriteString` | Prints the string whose address is in `EDX` |
| `WriteChar` | Prints the character in `AL` |
| `WriteDec` | Prints the number in `EAX` |
| `Crlf` | Moves to a new line |
| `ReadChar` | Waits for one key and returns it in `AL` |

Colour constants from Irvine: `white`, `yellow`, `gray`, `green`, `red`,
`lightBlue`, `lightRed`, `lightMagenta`, `lightCyan`.

---

## 4. Procedures in the project (20)
| Procedure | What it does |
|---|---|
| `main` | Main menu: 1 New Game, 2 How to Play, 3 Exit |
| `NewGame` | Copies the starting stats and the original map (`REP MOVSD`, `REP MOVSB`) |
| `PlayGame` | Game loop: draw, read key, act, check win/lose |
| `DrawScreen` | Prints the whole map with nested loops |
| `ShowStats` | Prints level, XP, gold, HP bar, attack, defense, potions, key, score |
| `SetTileColor` | Looks up the colour for a map tile in an array |
| `ShowBar` | Draws the HP bar (`INVOKE`, `LOCAL`, `MUL`, `DIV`) |
| `MovePlayer` | Moves the player; handles walls, water, monsters, chests, key, fountain, shop, boss |
| `MonsterBattle` | Picks the monster from the map area (column / 10) using parallel arrays |
| `BossBattle` | Sets up the Dragon |
| `Battle` | Turn-based fight: attack, potion, run |
| `CalcDamage` | Damage = attack − defense/2, using a stack frame (`[ebp+8]`, `[ebp+12]`, `RET 8`) |
| `CheckLevelUp` | Levels up when XP ≥ level × 50 |
| `DrinkPotion` | Heals the player (`.IF` / `.ELSE`) |
| `Shop` | Buys items; prices are stored in an array |
| `EndScreen` | Game over / victory screen with final stats |
| `PrintLn`, `PrintNum`, `PrintNumLn`, `WaitKey` | Small printing helpers |
