# Instruction & Library Reference: Dungeon of Assembly

Everything used in `DungeonRPG.asm`, with a one-line definition of each.
The counts show how many times each instruction appears in the code.
The "Course topic" column links each item to the EE2003 course outline.

---

## 1. CPU instructions

### Data transfer
| Instruction | Used | What it does | Course topic |
|---|---|---|---|
| `MOV` | 250 | Copies a value from a source to a destination | Data Transfer (Wk 4) |
| `MOVZX` | 2 | Copies a small value into a bigger register and fills the rest with zeros | Data Transfer (Wk 4) |
| `PUSH` | 12 | Puts a value on top of the stack | PUSH and POP (Wk 7) |
| `POP` | 8 | Takes the top value off the stack | PUSH and POP (Wk 7) |

### Arithmetic
| Instruction | Used | What it does | Course topic |
|---|---|---|---|
| `ADD` | 25 | Adds two values | Arithmetic (Wk 4) |
| `SUB` | 10 | Subtracts the source from the destination | Arithmetic (Wk 4) |
| `INC` | 11 | Adds 1 | Arithmetic (Wk 4) |
| `DEC` | 1 | Subtracts 1 | Arithmetic (Wk 4) |
| `MUL` | 6 | Unsigned multiply: `EDX:EAX = EAX * operand` | Multiplication & Division (Wk 10) |
| `DIV` | 3 | Unsigned divide: `EAX` = quotient, `EDX` = remainder | Multiplication & Division (Wk 10) |
| `ADC` | 1 | Adds with the carry flag (used for the 64-bit damage total) | Extended Addition (Wk 10) |

### Boolean, comparison and shifts
| Instruction | Used | What it does | Course topic |
|---|---|---|---|
| `AND` | 1 | Bitwise AND: clears bit 5 to make a letter capital | Boolean instructions (Wk 8) |
| `OR` | 1 | Bitwise OR: sets bit 5 to make a key a small letter | Boolean instructions (Wk 8) |
| `TEST` | 1 | ANDs two values only to set the flags (checks if the key flag is set) | Boolean instructions (Wk 8) |
| `CMP` | 55 | Compares two values by subtracting them (only the flags change) | Comparison instructions (Wk 8) |
| `SHL` | 1 | Shift left, which multiplies by 2 (critical hit = double damage) | Shift & Rotate (Wk 10) |
| `SHR` | 2 | Shift right, which divides by 2 (attack/2, defense/2) | Shift & Rotate (Wk 10) |

### Jumps and loops
| Instruction | Used | What it does | Course topic |
|---|---|---|---|
| `JMP` | 19 | Always jumps to a label | Control transfer (Wk 5) |
| `LOOP` | 5 | Decrements `ECX` and jumps while `ECX` is not 0 | Arrays and Loops (Wk 5) |
| `LOOPNZ` | 1 | Like `LOOP`, but also stops when the zero flag is set | Conditional loops (Wk 9) |
| `JE` / `JZ` | 27 / 1 | Jump if equal / zero | Conditional jumps (Wk 8) |
| `JNE` | 14 | Jump if not equal | Conditional jumps (Wk 8) |
| `JA` / `JAE` | 3 / 3 | Jump if above / above or equal (unsigned) | Conditional jumps (Wk 8) |
| `JB` / `JBE` | 6 / 2 | Jump if below / below or equal (unsigned) | Conditional jumps (Wk 8) |
| `JGE` | 1 | Jump if greater or equal (signed) | Conditional jumps (Wk 8) |
| `JNC` | 1 | Jump if the carry flag is clear (file read was OK) | Conditional jumps (Wk 8) |

### Procedures
| Instruction | Used | What it does | Course topic |
|---|---|---|---|
| `CALL` | 154 | Pushes the return address and jumps to a procedure | Procedures (Wk 7) |
| `RET` | 36 | Returns to the caller (`RET 8` also removes 2 parameters) | Procedures / Stack frames (Wk 7, 12) |

### String primitives
| Instruction | Used | What it does | Course topic |
|---|---|---|---|
| `CLD` | 4 | Clears the direction flag, so string instructions move forward | String primitives (Wk 13) |
| `MOVSB` / `MOVSD` | 2 / 1 | Copies a byte / double-word from `[ESI]` to `[EDI]` | String primitives (Wk 13) |
| `STOSB` | 1 | Stores `AL` at `[EDI]` | String primitives (Wk 13) |
| `LODSB` | 1 | Loads the byte at `[ESI]` into `AL` | String primitives (Wk 13) |
| `SCASB` | 1 | Compares `AL` with the byte at `[EDI]` (searches for the pressed key) | String primitives (Wk 13) |
| `CMPSB` | 1 | Compares the bytes at `[ESI]` and `[EDI]` (checks the save file header) | String primitives (Wk 13) |
| `REP` / `REPE` / `REPNE` | 3 / 1 / 1 | Repeat the string instruction: `ECX` times / while equal / while not equal | String primitives (Wk 13) |

---

## 2. Assembler directives and operators
| Item | What it does | Course topic |
|---|---|---|
| `INCLUDE` | Adds the Irvine32 library definitions | Fundamentals (Wk 3) |
| `.data` / `.code` | Start the data section / code section | Fundamentals (Wk 3) |
| `BYTE`, `DWORD`, `SDWORD` | Define 8-bit, 32-bit and signed 32-bit data | Defining Data (Wk 3) |
| `DUP` | Repeats a value (`BYTE 600 DUP(?)`) | Defining Data (Wk 3) |
| `=` and `EQU` | Define symbolic constants (`ROWS = 15`, `YES EQU 1`) | Symbolic Constants (Wk 3) |
| `LABEL` | Names an address without using memory (start/end of the save block) | Operators & Directives (Wk 5) |
| `OFFSET` | Gives the address of a variable | Operators & Directives (Wk 5) |
| `PTR` | Sets the size of a memory operand (`BYTE PTR`) | Operators & Directives (Wk 5) |
| `TYPE` | Size of one array element (used in `array[esi * TYPE array]`) | Operators & Directives (Wk 5) |
| `LENGTHOF` | Number of elements in an array | Operators & Directives (Wk 5) |
| `PROC` / `ENDP` | Start / end a procedure | Procedures (Wk 7) |
| `USES` | Saves and restores registers automatically | Procedures (Wk 7) |
| `.IF` / `.ELSE` / `.ENDIF` | High-level IF statement (used in `DrinkPotion`) | High-level constructs (Wk 9) |
| `PROTO` | Declares a procedure with its parameters | INVOKE, ADDR, PROC, PROTO (Wk 12) |
| `INVOKE` | Calls a procedure and pushes its arguments | INVOKE, ADDR, PROC, PROTO (Wk 12) |
| `ADDR` | Passes the address of a variable in `INVOKE` | INVOKE, ADDR, PROC, PROTO (Wk 12) |
| `LOCAL` | Creates a local variable on the stack (`filled` in `ShowBar`) | Stack frames (Wk 12) |
| `[ebp+8]`, `[ebp+12]` | Reading parameters from the stack frame (`CalcDamage`) | Stack frames (Wk 12) |
| `exit` | Irvine's way to end the program | Fundamentals |

### Addressing modes used
| Mode | Example in the code |
|---|---|
| Immediate | `mov eHP, 180` |
| Register | `mov ebx, eax` |
| Direct | `mov eax, hp` |
| Indirect | `mov [edi], dl` |
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
| `ReadString` | Reads a line of text into the buffer at `EDX` (max `ECX` chars) |
| `Randomize` | Starts the random number generator |
| `RandomRange` | Returns a random number from 0 to `EAX - 1` |
| `CreateOutputFile` | Creates a file for writing; returns the handle in `EAX` |
| `OpenInputFile` | Opens a file for reading; returns the handle in `EAX` |
| `WriteToFile` | Writes `ECX` bytes from `EDX` to the file in `EAX` |
| `ReadFromFile` | Reads up to `ECX` bytes into `EDX`; returns the count in `EAX` (carry flag = error) |
| `CloseFile` | Closes the file in `EAX` |

Constants from Irvine: `INVALID_HANDLE_VALUE` and the colours `white`, `yellow`,
`gray`, `green`, `lightBlue`, `lightRed`, `lightMagenta`, `lightCyan`, `lightGreen`.

---

## 4. Procedures in the project (29)
| Procedure | What it does |
|---|---|
| `main` | Main menu loop |
| `ShowTitle` | Draws the main menu and reads the choice |
| `NewGame` | Resets stats and map (`REP MOVSD`, `REP MOVSB`) and asks for the name |
| `UpperName` | Makes the name capital (`LODSB`, `AND`, `STOSB`, `LOOPNZ`) |
| `PlayGame` | Game loop: draw, read key, act, check win/lose |
| `DrawScreen` | Prints the whole map with nested loops |
| `ShowStats` | Prints name, level, XP, gold, HP bar, attack, defense, potions, key, score |
| `SetTileColor` | Looks up the colour for a map tile in an array |
| `ShowBar` | Draws the HP bar (`INVOKE`, `LOCAL`, `MUL`, `DIV`) |
| `MovePlayer` | Moves the player and handles walls, water, chests, key, fountain, shop, boss |
| `RandomBattle` | Picks an enemy from the parallel arrays based on the map zone |
| `BossBattle` | Sets up the Dragon |
| `Battle` | Turn-based fight: attack, potion, run |
| `CalcDamage` | Damage formula using a stack frame (`[ebp+8]`, `[ebp+12]`, `RET 8`) |
| `CheckLevelUp` | Levels up when XP ≥ level × 50 |
| `DrinkPotion` | Heals the player (`.IF` / `.ELSE`) |
| `Shop` | Buys items; prices are stored in an array |
| `SaveGame` / `LoadGame` | Write / read the save file; the header is checked with `REPE CMPSB` |
| `SaveToFile` | General file writer called with `INVOKE` and `ADDR` |
| `LoadHighScore` / `SaveHighScore` | Read / write `highscore.txt` |
| `IntToStr` | **Recursive**: converts a number to text |
| `StrToInt` | Converts text to a number (multiply by 10 and add) |
| `EndScreen` | Game over / victory screen and high-score check |
| `PrintLn`, `PrintNum`, `PrintNumLn`, `WaitKey` | Small printing helpers |
