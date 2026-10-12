# Instruction & Library Reference: Dungeon of Assembly

Everything used in `DungeonRPG.asm` (x86 32-bit, MASM syntax, Irvine32 library),
with a one-line definition of each. The counts are how many times each
instruction appears in the source.

---

## 1. CPU instructions

### Data movement
| Instruction | Used | What it does |
|---|---|---|
| `MOV` | 406 | Copies a value from a source to a destination (register, memory or constant) |
| `MOVZX` | 3 | Copies a smaller value into a bigger register and fills the upper bits with zeros |
| `LEA` | 3 | Loads the *address* a memory operand would refer to, without reading memory |
| `PUSH` | 9 | Puts a value on top of the stack |
| `POP` | 9 | Takes the top value off the stack into a register |
| `PUSHFD` | 1 | Pushes the 32-bit FLAGS register onto the stack |
| `POPFD` | 1 | Pops the stack back into the FLAGS register |
| `XLAT` | 2 | Table lookup: replaces `AL` with the byte at `[EBX + AL]` |

### Arithmetic
| Instruction | Used | What it does |
|---|---|---|
| `ADD` | 35 | Adds the source to the destination |
| `SUB` | 15 | Subtracts the source from the destination |
| `INC` | 25 | Adds 1 |
| `DEC` | 5 | Subtracts 1 |
| `MUL` | 2 | Unsigned multiply: `EDX:EAX = EAX * operand` |
| `IMUL` | 5 | Signed multiply (the form with a constant gives a 32-bit result) |
| `DIV` | 5 | Unsigned divide: `EAX = EDX:EAX / operand`, `EDX` = remainder |

### Logic and bit manipulation
| Instruction | Used | What it does |
|---|---|---|
| `AND` | 1 | Bitwise AND (used to clear bit 5 and make a letter upper case) |
| `OR` | 4 | Bitwise OR (used to set flag bits and make a letter lower case) |
| `XOR` | 11 | Bitwise exclusive OR (zeroes registers and encrypts the save file) |
| `TEST` | 14 | ANDs two values and only sets flags, so it checks a bit or tests for zero |
| `SHL` | 7 | Shifts bits left, which multiplies by 2, 4, 8, 32 and so on |
| `SHR` | 4 | Shifts bits right, which divides by powers of two |

### Comparison and jumps
| Instruction | Used | What it does |
|---|---|---|
| `CMP` | 79 | Subtracts to set the flags, without keeping the result |
| `JMP` | 42 | Always jumps to a label |
| `JE` / `JZ` | 36 / 8 | Jump if equal / zero (ZF = 1) |
| `JNE` / `JNZ` | 14 / 7 | Jump if not equal / not zero |
| `JA` / `JAE` | 4 / 5 | Jump if above / above or equal (unsigned) |
| `JB` / `JBE` | 12 / 4 | Jump if below / below or equal (unsigned) |
| `JG` / `JGE` | 3 / 2 | Jump if greater / greater or equal (signed) |
| `JL` | 2 | Jump if less (signed) |
| `JC` / `JNC` | 1 / 1 | Jump if the carry flag is set / clear (file-read error check) |
| `JECXZ` | 4 | Jump if `ECX` = 0 (guards loops and divides) |
| `LOOP` | 8 | Decrements `ECX` and jumps while it is not zero |

### Procedures
| Instruction | Used | What it does |
|---|---|---|
| `CALL` | 246 | Pushes the return address and jumps to a procedure (direct, and indirect through a table) |
| `RET` | 70 | Returns to the caller |

### String / block instructions
| Instruction | Used | What it does |
|---|---|---|
| `CLD` | 12 | Clears the direction flag, so string instructions move forward |
| `STD` | 1 | Sets the direction flag, so string instructions move backward |
| `MOVSB` / `MOVSD` | 9 / 1 | Copies a byte / double-word from `[ESI]` to `[EDI]` |
| `STOSB` / `STOSD` | 4 / 1 | Stores `AL` / `EAX` at `[EDI]` |
| `LODSB` | 1 | Loads the byte at `[ESI]` into `AL` |
| `SCASB` | 4 | Compares `AL` with the byte at `[EDI]` |
| `REP` | 12 | Repeats the next string instruction `ECX` times |
| `REPNE` | 4 | Repeats the next string instruction while the values are not equal and `ECX` is not 0 |

---

## 2. Assembler directives, operators and keywords

| Item | What it does |
|---|---|
| `INCLUDE` | Pulls another file into the program (`Irvine32.inc`) |
| `.data` / `.code` | Starts the data section / the code section |
| `END main` | Marks the end of the program and its entry point |
| `BYTE`, `DWORD`, `SDWORD` | Reserve 1-byte, 4-byte unsigned and 4-byte signed variables |
| `DUP` | Repeats a value N times (`BYTE 600 DUP(0)`) |
| `LABEL` | Gives a name to an address without reserving space |
| `=` (equate) | Defines a numeric constant (`MAP_W = 40`) |
| `$` | The current address, used for sizes (`($ - table)`) |
| `STRUCT` / `ENDS` | Defines a structure (a group of named fields) |
| `SIZEOF` / `TYPE` | Total size in bytes / size of one element |
| `OFFSET` / `ADDR` | The address of a variable (in plain code / inside `INVOKE`) |
| `PTR` (`BYTE PTR`, `DWORD PTR`) | Forces the size of a memory operand |
| `PROC` / `ENDP` | Starts / ends a procedure |
| `USES` | Automatically saves and restores the listed registers around a procedure |
| `LOCAL` | Declares local variables on the stack |
| `PROTO` | Declares a procedure's prototype (name and parameters) |
| `INVOKE` | Calls a procedure and pushes its arguments for you |
| `MACRO` / `ENDM` | Defines a text macro |
| `REQ` / `:=` in macros | Marks a macro parameter as required / gives it a default value |
| `HANDLE` | Type for a file handle |
| `exit` | Irvine macro that ends the program (`INVOKE ExitProcess,0`) |
| Indexed operand `table[reg*4]` | Array access with a scale factor of 1, 2, 4 or 8 |
| Structure field `player.hp` | Accesses one field of a structure variable |

---

## 3. Macros written in this project

| Macro | What it does |
|---|---|
| `mGoto col,row` | Moves the console cursor to a position |
| `mColor fore,back` | Sets the text and background colour |
| `mPrint "text"` | Prints a literal string |
| `mPrintAt col,row,"text"` | Moves the cursor, then prints a literal string |
| `mShow label` | Prints a stored string variable |
| `mNum value` | Prints a number held in a register or variable |

---

## 4. Irvine32 library procedures

| Procedure | What it does |
|---|---|
| `Clrscr` | Clears the console screen |
| `Gotoxy` | Moves the cursor to column `DL`, row `DH` |
| `SetTextColor` | Sets the text colour (low 4 bits) and background (high 4 bits) from `EAX` |
| `WriteChar` | Prints the character in `AL` |
| `WriteString` | Prints the 0-terminated string whose address is in `EDX` |
| `WriteDec` | Prints the unsigned number in `EAX` |
| `Crlf` | Moves to the start of the next line |
| `ReadChar` | Waits for one key and returns it in `AL`. For arrow keys, `AL` = 0 and `AH` = the scan code |
| `ReadString` | Reads a line of text into the buffer at `EDX` (max length in `ECX`) |
| `Randomize` | Seeds the random number generator from the clock |
| `RandomRange` | Returns a random number from 0 to `EAX - 1` in `EAX` |
| `Delay` | Pauses for `EAX` milliseconds (used for the battle flash) |
| `Str_copy` | Copies a 0-terminated string (used for the default name "Hero") |
| `CreateOutputFile` | Creates or overwrites a file for writing and returns a handle |
| `OpenInputFile` | Opens an existing file for reading and returns a handle |
| `WriteToFile` | Writes `ECX` bytes from the buffer at `EDX` to the file in `EAX` |
| `ReadFromFile` | Reads up to `ECX` bytes into the buffer at `EDX`; carry flag = error |
| `CloseFile` | Closes the file handle in `EAX` |

### Irvine colour constants
`black`, `blue`, `green`, `cyan`, `red`, `brown`, `gray`, `lightGray`, `lightBlue`,
`lightGreen`, `lightCyan`, `lightRed`, `lightMagenta`, `yellow`, `white`: console colour values (0 to 15).

### Windows API (through `SmallWin.inc`)
| Item | What it does |
|---|---|
| `CreateFile` | Opens or creates a file with full control (here `OPEN_ALWAYS` + `GENERIC_WRITE`) |
| `SetFilePointer` | Moves the file position (here to `FILE_END`, so new scores are appended) |
| `ExitProcess` | Ends the program (called through the `exit` macro) |
| `GENERIC_WRITE`, `DO_NOT_SHARE`, `NULL`, `OPEN_ALWAYS`, `FILE_ATTRIBUTE_NORMAL`, `FILE_END`, `INVALID_HANDLE_VALUE` | Constants for the calls above |

---

## 5. Procedures written in this project

| Procedure | What it does |
|---|---|
| `main` | Title-menu loop |
| `InitTables` | Fills the colour and glyph lookup tables used by `XLAT` |
| `NewGame` | Resets everything and asks for the hero's name |
| `PlayGame` | The main game loop |
| `GetAction` | Reads a key and turns arrow keys into W/A/S/D |
| `DispatchAction` | Finds the key with `REPNE SCASB`, then calls its handler through a jump table |
| `MoveNorth/South/West/East` | The four movement commands |
| `TryMove` | Moves the player and handles the tile they step on |
| `TileIndex` | Converts (x, y) to a map index with shifts |
| `RevealArea` | Clears the fog around the player and adds exploration points |
| `DrinkPotion` / `RestCamp` / `QuitToTitle` | Heal with a potion / rest at camp / return to the title |
| `SpawnEnemy` | Picks and scales an enemy for the current zone and player level |
| `CalcDamage` | Computes damage with randomness and critical hits |
| `Battle` | The whole turn-based fight |
| `CheckLevelUp` | Applies level-ups when enough XP is earned |
| `BattleFlash` / `HitFlash` | Short screen-flash animations |
| `DrawBattle` | Draws the battle screen |
| `Shop`, `ItemPrice`, `BuyPotion/Sword/Armor/Vitality`, `BoughtMsg` | Shop screen, scaling prices, item effects |
| `DrawFrame`, `DrawMap`, `DrawHud`, `HpColor`, `DrawBar`, `DrawBox`, `DrawArt` | All drawing code |
| `SetMessage`, `DrawMessage` | Stores and shows the one-line message |
| `BufBegin`, `BufAddChar`, `BufAddStr`, `BufAddNum`, `BufPadTo` | Builds text strings (`BufAddNum` is recursive) |
| `ToUpperStr`, `XorBuffer` | Upper-cases text / XOR encrypts or decrypts a buffer |
| `SaveGame`, `LoadGame` | Binary encrypted save and load |
| `RecordScore`, `ShowHallOfFame` | Append a result to the text file / read and show it |
| `TitleScreen`, `ShowHelp`, `ShowFinalStats`, `GameOverScreen`, `VictoryScreen` | The menu and ending screens |
