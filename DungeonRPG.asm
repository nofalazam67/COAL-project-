;======================================================================
;   D U N G E O N   O F   A S S E M B L Y
;   A console dungeon-survival RPG written in x86 Assembly
;----------------------------------------------------------------------
;   Course    : Computer Organization & Assembly Language (COAL) Lab
;   Assembler : MASM (32-bit, flat model)
;   Library   : Irvine32
;
;   Features  : open-world ASCII map with fog of war, random enemy
;               encounters, turn-based combat, levelling, inventory,
;               shop, healing fountains, chests, a key quest, a final
;               boss, encrypted save/load files and a Hall of Fame
;               text file.
;
;   See README.md for build steps and a COAL-concept index.
;======================================================================

INCLUDE Irvine32.inc

;======================================================================
;                              CONSTANTS
;======================================================================
MAP_W         = 40                  ; map width  (TileIndex relies on 40 = 32 + 8)
MAP_H         = 15                  ; map height
MAP_SIZE      = MAP_W * MAP_H       ; 600 tiles
MAP_X         = 2                   ; screen column of map's top-left tile
MAP_Y         = 3                   ; screen row    of map's top-left tile
HUD_X         = 46                  ; screen column of HUD text
MSG_ROW       = 19                  ; message line
BAR_LEN       = 20                  ; cells in an HP bar
NAME_MAX      = 16                  ; player name buffer size
VIEW_RX       = 3                   ; horizontal sight radius (fog of war)
VIEW_RY       = 2                   ; vertical   sight radius
ENCOUNTER_PCT = 12                  ; % chance of a fight per step
POTION_HEAL   = 40
FAME_LINES    = 15                  ; hall-of-fame rows shown
START_X       = 1
START_Y       = 1

FLAG_KEY      = 00000001b           ; bit 0 : player owns the Ancient Key
FLAG_BOSS     = 00000010b           ; bit 1 : Dragon King defeated

FOG_CHAR      = 176                 ; light shade  (CP437)
WALL_CHAR     = 219                 ; full block
CHEST_CHAR    = 254                 ; small square
FULL_CELL     = 219
EMPTY_CELL    = 176

SAVE_MAGIC    = 'COAL'              ; file signature
XOR_KEY       = 5Ah                 ; save-file cipher key

;======================================================================
;                              STRUCTURES
;======================================================================
PlayerT STRUCT
    pname     BYTE  NAME_MAX DUP(0)
    hp        DWORD 100
    maxHp     DWORD 100
    atk       DWORD 10
    def       DWORD 4
    lvl       DWORD 1
    xp        DWORD 0
    gold      DWORD 30
    score     DWORD 0
    posX      DWORD START_X
    posY      DWORD START_Y
    potions   DWORD 2
    flags     DWORD 0               ; bit field: FLAG_KEY / FLAG_BOSS
    steps     DWORD 0
    kills     DWORD 0
    upg       DWORD 4 DUP(0)        ; times each shop item was bought
PlayerT ENDS

EnemyT STRUCT
    eName     DWORD ?               ; pointer to name string
    eHp       DWORD ?
    eMaxHp    DWORD ?
    eAtk      DWORD ?
    eDef      DWORD ?
    eXp       DWORD ?
    eGold     DWORD ?
    eColor    DWORD ?
    eArt      DWORD ?               ; pointer to ASCII art
EnemyT ENDS

SAVE_SIZE = 4 + SIZEOF PlayerT + MAP_SIZE + MAP_SIZE

;======================================================================
;                              MACROS
;======================================================================
; move cursor to (col,row)
mGoto MACRO col:REQ, row:REQ
    push edx
    mov  dl, col
    mov  dh, row
    call Gotoxy
    pop  edx
ENDM

; set text colour from constants
mColor MACRO fore:REQ, back:=<black>
    push eax
    mov  eax, fore + (back * 16)
    call SetTextColor
    pop  eax
ENDM

; print a literal string (no commas / special chars inside)
mPrint MACRO text:REQ
    LOCAL txt
    .data
    txt BYTE text, 0
    .code
    push edx
    mov  edx, OFFSET txt
    call WriteString
    pop  edx
ENDM

mPrintAt MACRO col:REQ, row:REQ, text:REQ
    mGoto  col, row
    mPrint text
ENDM

; print a string variable by label
mShow MACRO strLabel:REQ
    push edx
    mov  edx, OFFSET strLabel
    call WriteString
    pop  edx
ENDM

; print number held in a 32-bit memory/register operand
mNum MACRO value:REQ
    push eax
    mov  eax, value
    call WriteDec
    pop  eax
ENDM

;======================================================================
;                              PROTOTYPES
;======================================================================
TryMove     PROTO stepX:SDWORD, stepY:SDWORD
TileIndex   PROTO tx:DWORD, ty:DWORD
DrawBar     PROTO cur:DWORD, maxv:DWORD, barColor:DWORD
DrawBox     PROTO left:DWORD, top:DWORD, wid:DWORD, hgt:DWORD, boxColor:DWORD
DrawArt     PROTO artPtr:DWORD, col:DWORD, row:DWORD
CalcDamage  PROTO attack:DWORD, defense:DWORD
Battle      PROTO isBoss:DWORD
RecordScore PROTO resultText:DWORD

;======================================================================
;                              DATA
;======================================================================
.data

;---------------------------- world map -------------------------------
; #  wall      ~ water     . ground    $ shop      + fountain
; C  chest     K key       B boss lair
mapTemplate LABEL BYTE
    BYTE "########################################"
    BYTE "#.......~~......#..C........#.........C#"
    BYTE "#..C....~~...+..#...........#..........#"
    BYTE "#.......~~......#...######..#...$......#"
    BYTE "#...........~~..#...#K...#..#..........#"
    BYTE "#...$.......~~......#....#.......#######"
    BYTE "#...........~~..#...##.###..#....#.....#"
    BYTE "#######.....~~..#...........#....#.....#"
    BYTE "#.....#.........#####.#######....#..B..#"
    BYTE "#..C..#....~~.......#.......C....#.....#"
    BYTE "#.....#....~~..+....#...+........#.....#"
    BYTE "#..........~~.......#.......~~~..##.####"
    BYTE "#......C...~~...C...#.......~~~........#"
    BYTE "#..........~~.......#..........+.......#"
    BYTE "########################################"

worldMap    BYTE MAP_SIZE DUP(?)            ; live copy (chests disappear)
visited     BYTE MAP_SIZE DUP(0)            ; fog-of-war mask

colorLUT    BYTE 128 DUP(?)                 ; tile char -> colour  (XLAT)
glyphLUT    BYTE 128 DUP(?)                 ; tile char -> glyph   (XLAT)

;---------------------------- player ----------------------------------
playerDefault PlayerT <>
player        PlayerT <>

;---------------------------- enemies ---------------------------------
sSlime      BYTE "Cave Slime",0
sGoblin     BYTE "Goblin Raider",0
sSkeleton   BYTE "Skeleton Knight",0
sOrc        BYTE "Orc Brute",0
sWraith     BYTE "Shadow Wraith",0
sDragon     BYTE "DRAGON KING",0

artSlime    BYTE "             ",0
            BYTE "    .----.   ",0
            BYTE "   ( o  o )  ",0
            BYTE "  (   __   ) ",0
            BYTE "   `------'  ",0,0
artGoblin   BYTE "    ,   ,    ",0
            BYTE "   (\o o/)   ",0
            BYTE "    \ ^ /    ",0
            BYTE "    /|=|\    ",0
            BYTE "     / \     ",0,0
artSkel     BYTE "     .-.     ",0
            BYTE "    (o.o)    ",0
            BYTE "     |=|     ",0
            BYTE "    __|__    ",0
            BYTE "   //.=|=.\\ ",0,0
artOrc      BYTE "   \_____/   ",0
            BYTE "   [ O O ]   ",0
            BYTE "    \_W_/    ",0
            BYTE "   /|###|\   ",0
            BYTE "    |   |    ",0,0
artWraith   BYTE '    .-""-.   ',0
            BYTE "   / x  x \  ",0
            BYTE "   \  ~~  /  ",0
            BYTE "    )    (   ",0
            BYTE "   /_/\/\_\  ",0,0
artDragon   BYTE "                \||/",0
            BYTE "                |  @___oo",0
            BYTE "      /\  /\   / (__,,,,|",0
            BYTE "     ) /^\) ^\/ _)",0
            BYTE "     )   /^\/   _)",0
            BYTE "     )   _ /  / _)",0
            BYTE " /\  )/\/ ||  | )_)",0
            BYTE "<  >      |(,,) )__)",0
            BYTE " ||      /    \)___)\",0
            BYTE " | \____(      )___) )___",0
            BYTE "  \______(_______;;; __;;;",0,0

;               name      hp  max atk def  xp gold colour        art
enemyTable  EnemyT <OFFSET sSlime,   22, 22,  6, 1, 12,  8, lightGreen,   OFFSET artSlime>
            EnemyT <OFFSET sGoblin,  30, 30,  8, 2, 18, 12, green,        OFFSET artGoblin>
            EnemyT <OFFSET sSkeleton,40, 40, 11, 4, 28, 16, white,        OFFSET artSkel>
            EnemyT <OFFSET sOrc,     55, 55, 14, 5, 40, 22, brown,        OFFSET artOrc>
            EnemyT <OFFSET sWraith,  65, 65, 17, 6, 55, 30, lightMagenta, OFFSET artWraith>
ENEMY_COUNT = ($ - enemyTable) / SIZEOF EnemyT

bossTemplate EnemyT <OFFSET sDragon, 250, 250, 22, 8, 400, 300, lightRed, OFFSET artDragon>
curEnemy     EnemyT <>
battleTurn   DWORD 0
critFlag     BYTE  0
levelUpFlag  BYTE  0

;---------------------------- input dispatch --------------------------
keyTable    BYTE "1w2s3a4d5678"
KEY_COUNT   = ($ - keyTable)
actionTable DWORD MoveNorth, MoveNorth, MoveSouth, MoveSouth
            DWORD MoveWest,  MoveWest,  MoveEast,  MoveEast
            DWORD DrinkPotion, RestCamp, SaveGame, QuitToTitle

;---------------------------- shop ------------------------------------
prices      DWORD 15, 40, 35, 50        ; base prices (upgrades scale up)
SHOP_ITEMS  = ($ - prices) / TYPE prices
itemLabels  DWORD tShop1, tShop2, tShop3, tShop4
shopEffects DWORD BuyPotion, BuySword, BuyArmor, BuyVitality

;---------------------------- zones -----------------------------------
zone0       BYTE "Green Meadows   ",0
zone1       BYTE "Whispering Woods",0
zone2       BYTE "Ruined Keep     ",0
zone3       BYTE "Dragon Wastes   ",0
zoneNames   DWORD zone0, zone1, zone2, zone3

;---------------------------- files -----------------------------------
saveFile    BYTE "dungeon.sav",0
scoreFile   BYTE "halloffame.txt",0
fileHandle  HANDLE ?
bytesRead   DWORD ?
saveBuf     BYTE SAVE_SIZE DUP(?)
fameBuf     BYTE 4096 DUP(?)
lineBuf     BYTE 128 DUP(?)

;---------------------------- messages --------------------------------
msgBuf      BYTE 96 DUP(0)
logP        BYTE 96 DUP(0)              ; battle log: player line
logE        BYTE 96 DUP(0)              ; battle log: enemy line
outPtr      DWORD ?                     ; write cursor for Buf* helpers
msgPtr      DWORD OFFSET tWelcome
msgColor    DWORD lightGray
needFrame   BYTE 1
gameRunning BYTE 0

blankLine   BYTE 77 DUP(' '),0
crlfStr     BYTE 13,10,0
defaultName BYTE "Hero",0

tWelcome    BYTE "Welcome, traveller! Find the Ancient Key and slay the Dragon King.",0
tWall       BYTE "A solid wall blocks your way.",0
tWater      BYTE "The water is too deep to cross.",0
tSealed     BYTE "The lair gate is sealed by old magic. Find the Ancient Key!",0
tQuiet      BYTE "You travel onward. All is quiet...",0
tFountain   BYTE "The fountain's water restores you to full health!",0
tKey        BYTE "You found the ANCIENT KEY! The Dragon's lair can now be opened.",0
tChest1     BYTE "You open a chest and find ",0
tChest2     BYTE " gold",0
tChestPot   BYTE " and a potion!",0
tNoPotion   BYTE "You have no potions left!",0
tDrank      BYTE "You drink a potion. HP restored to ",0
tFullHp     BYTE "You are already at full health.",0
tRest       BYTE "You set up camp and rest. HP is now ",0
tAmbush     BYTE "You are ambushed while resting!",0
tSaved      BYTE "Game saved to dungeon.sav",0
tSaveFail   BYTE "ERROR: could not create the save file.",0
tUnknown    BYTE "Unknown command. Use 1-8, W/A/S/D or the arrow keys.",0
tQuitAsk    BYTE "Quit to title? Unsaved progress will be lost. (Y/N)",0
tFled       BYTE "You escaped safely.",0
tDefeated1  BYTE "Defeated ",0
tDefeated2  BYTE "  +",0
tDefeated3  BYTE " XP  +",0
tLevelUp    BYTE "  ** LEVEL UP! **",0
tSlash      BYTE " / ",0
tYes        BYTE "FOUND  ",0
tNo         BYTE "MISSING",0

tYouHit     BYTE "You hit the ",0
tFor        BYTE " for ",0
tDamage     BYTE " damage",0
tCrit       BYTE " - CRITICAL!",0
tMiss       BYTE "Your heavy strike misses!",0
tHitsYou    BYTE " hits you for ",0
tBreath     BYTE " breathes FIRE for ",0
tNoEscape   BYTE "There is no escape from the Dragon King!",0
tFleeFail   BYTE "You fail to escape!",0
tEnemyDies  BYTE "Victory! The enemy is slain.",0
tYouDie     BYTE "You have fallen in battle...",0
tEncounter  BYTE "A wild ",0
tAppears    BYTE " appears!",0

tWin        BYTE "VICTORY ",0
tLose       BYTE "DEFEATED",0
tLoadOk     BYTE "Save file loaded. Welcome back!",0
tNoSave     BYTE "No save file found (dungeon.sav).",0
tBadSave    BYTE "Save file is corrupted or from another version.",0
tNoFame     BYTE "No heroes recorded yet. Be the first!",0
tFameHead   BYTE "NAME            | SCORE | LVL | KILLS | RESULT",13,10
            BYTE "----------------+-------+-----+-------+---------",13,10,0
tSep        BYTE " | ",0
tOpt1       BYTE "[1] Attack       [2] Heavy Strike (60% hit, x2 damage)",0
tOpt2       BYTE "[3] Drink Potion [4] Flee (50% chance)",0
tHelpCamp   BYTE "CAMP  Rest to heal 25% HP - but watch out for ambushes.",0

;---------------------------- title art -------------------------------
titleArt    BYTE " ____  _   _ _   _  ____ _____ ___  _   _ ",0
            BYTE "|  _ \| | | | \ | |/ ___| ____/ _ \| \ | |",0
            BYTE "| | | | | | |  \| | |  _|  _|| | | |  \| |",0
            BYTE "| |_| | |_| | |\  | |_| | |__| |_| | |\  |",0
            BYTE "|____/ \___/|_| \_|\____|_____\___/|_| \_|",0,0
titleColors BYTE lightRed, yellow, lightGreen, lightCyan, lightMagenta

skullArt    BYTE "      _____      ",0
            BYTE "     /     \     ",0
            BYTE "    | () () |    ",0
            BYTE "     \  ^  /     ",0
            BYTE "      |||||      ",0
            BYTE "      |||||      ",0,0
crownArt    BYTE "    _  /\  _     ",0
            BYTE "   / \/  \/ \    ",0
            BYTE "  |  o  o  o |   ",0
            BYTE "  |__________|   ",0,0
shopArt     BYTE "   _________________   ",0
            BYTE "  /  WANDERING MERCH \ ",0
            BYTE " |  [=]  [+]  [/]  $  |",0
            BYTE " |_____________________|",0,0

;======================================================================
;                              CODE
;======================================================================
.code

;----------------------------------------------------------------------
main PROC
; Program entry: title menu loop.
;----------------------------------------------------------------------
    call Randomize
    call InitTables

TitleLoop:
    call TitleScreen                ; AL = chosen key
    cmp  al, '1'
    je   DoNew
    cmp  al, '2'
    je   DoLoad
    cmp  al, '3'
    je   DoFame
    cmp  al, '4'
    je   DoHelp
    cmp  al, '5'
    je   DoQuit
    jmp  TitleLoop

DoNew:
    call NewGame
    call PlayGame
    jmp  TitleLoop
DoLoad:
    call LoadGame                   ; EAX = 1 on success
    test eax, eax
    jz   TitleLoop
    call PlayGame
    jmp  TitleLoop
DoFame:
    call ShowHallOfFame
    jmp  TitleLoop
DoHelp:
    call ShowHelp
    jmp  TitleLoop
DoQuit:
    mColor lightGray
    call Clrscr
    exit
main ENDP

;======================================================================
;                       INITIALISATION / GAME FLOW
;======================================================================

;----------------------------------------------------------------------
InitTables PROC USES eax ecx edi
; Builds the two 128-byte lookup tables used with XLAT when drawing.
;----------------------------------------------------------------------
    cld
    mov  edi, OFFSET colorLUT       ; default colour for every char
    mov  ecx, 128
    mov  al, lightGray
    rep  stosb

    mov  edi, OFFSET glyphLUT       ; identity mapping: glyph = char
    mov  ecx, 128
    xor  al, al
IdLoop:
    stosb
    inc  al
    loop IdLoop

    mov  colorLUT['#'], gray
    mov  glyphLUT['#'], WALL_CHAR
    mov  colorLUT['.'], green
    mov  colorLUT['~'], lightBlue + (blue * 16)
    mov  colorLUT['$'], yellow
    mov  colorLUT['+'], lightCyan
    mov  colorLUT['C'], brown
    mov  glyphLUT['C'], CHEST_CHAR
    mov  colorLUT['K'], lightMagenta
    mov  colorLUT['B'], white + (red * 16)
    ret
InitTables ENDP

;----------------------------------------------------------------------
NewGame PROC USES eax ecx edx esi edi
; Resets player, map and fog, then asks for the hero's name.
;----------------------------------------------------------------------
    cld
    mov  esi, OFFSET playerDefault  ; player = playerDefault
    mov  edi, OFFSET player
    mov  ecx, SIZEOF PlayerT
    rep  movsb

    mov  esi, OFFSET mapTemplate    ; worldMap = mapTemplate (DWORD copy)
    mov  edi, OFFSET worldMap
    mov  ecx, MAP_SIZE / 4
    rep  movsd

    mov  edi, OFFSET visited        ; clear the fog-of-war mask
    mov  ecx, MAP_SIZE
    xor  al, al
    rep  stosb

    mColor lightGray
    call Clrscr
    INVOKE DrawBox, 18, 8, 44, 7, yellow
    mColor lightCyan
    mPrintAt 22, 10, "What is your name, adventurer?"
    mColor white
    mPrintAt 22, 12, "> "
    mov  edx, OFFSET player.pname
    mov  ecx, NAME_MAX - 1
    call ReadString
    test eax, eax
    jnz  HasName
    INVOKE Str_copy, ADDR defaultName, ADDR player.pname
HasName:
    mov  esi, OFFSET player.pname
    call ToUpperStr

    call RevealArea
    mov  edx, OFFSET tWelcome
    mov  eax, yellow
    call SetMessage
    ret
NewGame ENDP

;----------------------------------------------------------------------
PlayGame PROC
; Main game loop: draw -> read key -> dispatch -> check end conditions.
;----------------------------------------------------------------------
    mov  gameRunning, 1
    mov  needFrame, 1
GameLoop:
    cmp  needFrame, 0
    je   NoFrame
    call DrawFrame
    mov  needFrame, 0
NoFrame:
    call DrawMap
    call DrawHud
    call DrawMessage

    call GetAction                  ; AL = normalised key
    call DispatchAction

    cmp  player.hp, 0
    je   PlayerDied
    test player.flags, FLAG_BOSS
    jnz  PlayerWon
    cmp  gameRunning, 0
    jne  GameLoop
    ret
PlayerDied:
    call GameOverScreen
    ret
PlayerWon:
    call VictoryScreen
    ret
PlayGame ENDP

;----------------------------------------------------------------------
GetAction PROC
; Reads one key. Returns lower-case char in AL; arrow keys -> w/a/s/d.
;----------------------------------------------------------------------
    call ReadChar
    cmp  al, 0
    je   Extended
    cmp  al, 0E0h
    je   Extended
    or   al, 00100000b              ; set bit 5 => lower case
    ret
Extended:                           ; AH holds the scan code
    mov  al, 'w'
    cmp  ah, 48h                    ; up
    je   Done
    mov  al, 's'
    cmp  ah, 50h                    ; down
    je   Done
    mov  al, 'a'
    cmp  ah, 4Bh                    ; left
    je   Done
    mov  al, 'd'
    cmp  ah, 4Dh                    ; right
    je   Done
    mov  al, 0
Done:
    ret
GetAction ENDP

;----------------------------------------------------------------------
DispatchAction PROC USES ecx edi
; Finds AL in keyTable with REPNE SCASB and calls the matching
; procedure through the actionTable jump table.
;----------------------------------------------------------------------
    cld
    mov  edi, OFFSET keyTable
    mov  ecx, KEY_COUNT
    repne scasb
    jne  Unknown
    mov  eax, KEY_COUNT - 1
    sub  eax, ecx                   ; index of matched key
    call actionTable[eax*4]         ; indirect call
    ret
Unknown:
    mov  edx, OFFSET tUnknown
    mov  eax, lightGray
    call SetMessage
    ret
DispatchAction ENDP

;======================================================================
;                              ACTIONS
;======================================================================
MoveNorth PROC
    INVOKE TryMove, 0, -1
    ret
MoveNorth ENDP

MoveSouth PROC
    INVOKE TryMove, 0, 1
    ret
MoveSouth ENDP

MoveWest PROC
    INVOKE TryMove, -1, 0
    ret
MoveWest ENDP

MoveEast PROC
    INVOKE TryMove, 1, 0
    ret
MoveEast ENDP

;----------------------------------------------------------------------
TryMove PROC USES eax ebx edx esi, stepX:SDWORD, stepY:SDWORD
; Attempts to move the player and triggers whatever is on the tile.
;----------------------------------------------------------------------
    LOCAL nx:DWORD, ny:DWORD

    mov  eax, player.posX
    add  eax, stepX
    mov  nx, eax
    mov  eax, player.posY
    add  eax, stepY
    mov  ny, eax

    cmp  nx, MAP_W                  ; unsigned compare also rejects -1
    jae  HitWall
    cmp  ny, MAP_H
    jae  HitWall

    INVOKE TileIndex, nx, ny
    mov  esi, eax
    mov  al, worldMap[esi]

    cmp  al, '#'
    je   HitWall
    cmp  al, '~'
    je   HitWater
    cmp  al, 'B'
    jne  Walk

    ; ---- boss gate ----
    test player.flags, FLAG_KEY
    jnz  BossFight
    mov  edx, OFFSET tSealed
    mov  eax, lightRed
    call SetMessage
    ret
BossFight:
    INVOKE Battle, 1
    ret

Walk:
    mov  eax, nx
    mov  player.posX, eax
    mov  eax, ny
    mov  player.posY, eax
    inc  player.steps
    call RevealArea

    mov  edx, OFFSET tQuiet         ; default message
    mov  eax, lightGray
    call SetMessage

    mov  al, worldMap[esi]
    cmp  al, '$'
    je   AtShop
    cmp  al, '+'
    je   AtFountain
    cmp  al, 'C'
    je   AtChest
    cmp  al, 'K'
    je   AtKey

    ; ---- open ground: random encounter? ----
    mov  eax, 100
    call RandomRange
    cmp  eax, ENCOUNTER_PCT
    jae  Done
    INVOKE Battle, 0
    jmp  Done

AtShop:
    call Shop
    jmp  Done

AtFountain:
    mov  eax, player.maxHp
    mov  player.hp, eax
    mov  edx, OFFSET tFountain
    mov  eax, lightCyan
    call SetMessage
    jmp  Done

AtChest:
    mov  worldMap[esi], '.'         ; chest is consumed
    add  player.score, 25
    mov  eax, 31
    call RandomRange
    add  eax, 15                    ; 15..45 gold
    add  player.gold, eax
    mov  ebx, eax

    mov  edx, OFFSET msgBuf
    call BufBegin
    mov  edx, OFFSET tChest1
    call BufAddStr
    mov  eax, ebx
    call BufAddNum
    mov  edx, OFFSET tChest2
    call BufAddStr

    mov  eax, 3                     ; 1 in 3 chance of a bonus potion
    call RandomRange
    test eax, eax
    jnz  NoBonus
    inc  player.potions
    mov  edx, OFFSET tChestPot
    call BufAddStr
    jmp  ChestMsg
NoBonus:
    mov  al, '!'
    call BufAddChar
ChestMsg:
    mov  edx, OFFSET msgBuf
    mov  eax, yellow
    call SetMessage
    jmp  Done

AtKey:
    mov  worldMap[esi], '.'
    or   player.flags, FLAG_KEY     ; set bit 0
    add  player.score, 100
    mov  edx, OFFSET tKey
    mov  eax, lightMagenta
    call SetMessage
    jmp  Done

HitWall:
    mov  edx, OFFSET tWall
    mov  eax, gray
    call SetMessage
    ret
HitWater:
    mov  edx, OFFSET tWater
    mov  eax, lightBlue
    call SetMessage
    ret
Done:
    ret
TryMove ENDP

;----------------------------------------------------------------------
TileIndex PROC USES ebx, tx:DWORD, ty:DWORD
; Returns EAX = ty * MAP_W + tx, computed with shifts: y*40 = y*32 + y*8
;----------------------------------------------------------------------
    mov  eax, ty
    mov  ebx, eax
    shl  eax, 5                     ; y * 32
    shl  ebx, 3                     ; y * 8
    add  eax, ebx
    add  eax, tx
    ret
TileIndex ENDP

;----------------------------------------------------------------------
RevealArea PROC USES eax ebx ecx
; Clears fog in a (2*VIEW_RX+1) x (2*VIEW_RY+1) window around the
; player. Every newly discovered tile is worth 1 point.
;----------------------------------------------------------------------
    mov  ecx, player.posY
    sub  ecx, VIEW_RY               ; ecx = row (signed)
RowLoop:
    mov  eax, player.posY
    add  eax, VIEW_RY
    cmp  ecx, eax
    jg   Done
    cmp  ecx, 0
    jl   NextRow
    cmp  ecx, MAP_H
    jge  NextRow

    mov  ebx, player.posX
    sub  ebx, VIEW_RX               ; ebx = column (signed)
ColLoop:
    mov  eax, player.posX
    add  eax, VIEW_RX
    cmp  ebx, eax
    jg   NextRow
    cmp  ebx, 0
    jl   NextCol
    cmp  ebx, MAP_W
    jge  NextCol

    INVOKE TileIndex, ebx, ecx
    cmp  visited[eax], 0
    jne  NextCol
    mov  visited[eax], 1
    inc  player.score               ; exploration points
NextCol:
    inc  ebx
    jmp  ColLoop
NextRow:
    inc  ecx
    jmp  RowLoop
Done:
    ret
RevealArea ENDP

;----------------------------------------------------------------------
DrinkPotion PROC USES edx
; Heals POTION_HEAL HP (capped at maxHp). Returns EAX = 1 if drunk.
;----------------------------------------------------------------------
    cmp  player.potions, 0
    jne  HavePotion
    mov  edx, OFFSET tNoPotion
    mov  eax, lightRed
    call SetMessage
    mov  eax, 0
    ret
HavePotion:
    mov  eax, player.hp
    cmp  eax, player.maxHp
    jb   CanHeal
    mov  edx, OFFSET tFullHp
    mov  eax, lightGray
    call SetMessage
    mov  eax, 0
    ret
CanHeal:
    dec  player.potions
    add  eax, POTION_HEAL
    cmp  eax, player.maxHp
    jbe  Store
    mov  eax, player.maxHp
Store:
    mov  player.hp, eax

    mov  edx, OFFSET msgBuf
    call BufBegin
    mov  edx, OFFSET tDrank
    call BufAddStr
    mov  eax, player.hp
    call BufAddNum
    mov  edx, OFFSET msgBuf
    mov  eax, lightGreen
    call SetMessage
    mov  eax, 1
    ret
DrinkPotion ENDP

;----------------------------------------------------------------------
RestCamp PROC USES eax ebx edx
; Heals 25% of max HP, but there is a 35% chance of an ambush.
;----------------------------------------------------------------------
    mov  eax, player.maxHp
    shr  eax, 2                     ; maxHp / 4
    add  eax, player.hp
    cmp  eax, player.maxHp
    jbe  Store
    mov  eax, player.maxHp
Store:
    mov  player.hp, eax

    mov  eax, 100
    call RandomRange
    cmp  eax, 35
    jae  Peaceful
    mov  edx, OFFSET tAmbush
    mov  eax, lightRed
    call SetMessage
    INVOKE Battle, 0
    ret
Peaceful:
    mov  edx, OFFSET msgBuf
    call BufBegin
    mov  edx, OFFSET tRest
    call BufAddStr
    mov  eax, player.hp
    call BufAddNum
    mov  edx, OFFSET msgBuf
    mov  eax, lightGreen
    call SetMessage
    ret
RestCamp ENDP

;----------------------------------------------------------------------
QuitToTitle PROC USES eax edx
;----------------------------------------------------------------------
    mov  edx, OFFSET tQuitAsk
    mov  eax, yellow
    call SetMessage
    call DrawMessage
    call ReadChar
    or   al, 20h
    cmp  al, 'y'
    jne  Stay
    mov  gameRunning, 0
    ret
Stay:
    mov  edx, OFFSET tQuiet
    mov  eax, lightGray
    call SetMessage
    ret
QuitToTitle ENDP

;======================================================================
;                              COMBAT
;======================================================================

;----------------------------------------------------------------------
SpawnEnemy PROC USES eax ebx ecx edx esi edi
; Picks an enemy based on the zone (posX / 10) and copies it into
; curEnemy, then scales it with the player's level.
;----------------------------------------------------------------------
    mov  eax, player.posX
    xor  edx, edx
    mov  ebx, 10
    div  ebx                        ; eax = zone 0..3
    mov  ebx, eax
    mov  eax, 2
    call RandomRange                ; 0 or 1
    add  eax, ebx                   ; enemy index 0..4
    cmp  eax, ENEMY_COUNT - 1
    jbe  IndexOk
    mov  eax, ENEMY_COUNT - 1
IndexOk:
    imul eax, SIZEOF EnemyT         ; byte offset into table
    lea  esi, enemyTable[eax]
    mov  edi, OFFSET curEnemy
    mov  ecx, SIZEOF EnemyT
    cld
    rep  movsb

    mov  eax, player.lvl            ; +5 HP and +1 ATK per player level
    dec  eax
    mov  ebx, eax
    imul eax, 5
    add  curEnemy.eHp, eax
    add  curEnemy.eMaxHp, eax
    add  curEnemy.eAtk, ebx
    ret
SpawnEnemy ENDP

;----------------------------------------------------------------------
CalcDamage PROC USES ebx, attack:DWORD, defense:DWORD
; EAX = attack + rand(0..attack/2) - defense/2   (minimum 1)
; 10% chance of a critical hit (damage * 2). Sets critFlag.
;----------------------------------------------------------------------
    mov  eax, attack
    shr  eax, 1
    inc  eax
    call RandomRange
    add  eax, attack
    mov  ebx, defense
    shr  ebx, 1
    sub  eax, ebx
    jg   Positive
    mov  eax, 1
Positive:
    mov  critFlag, 0
    push eax
    mov  eax, 10
    call RandomRange
    test eax, eax
    pop  eax
    jnz  NoCrit
    shl  eax, 1
    mov  critFlag, 1
NoCrit:
    ret
CalcDamage ENDP

;----------------------------------------------------------------------
Battle PROC USES ebx ecx edx esi edi, isBoss:DWORD
; Turn-based fight. Returns EAX: 1 = won, 0 = fled, 2 = player died.
;----------------------------------------------------------------------
    mov  needFrame, 1
    mov  battleTurn, 0
    mov  logP, 0
    mov  logE, 0

    cmp  isBoss, 0
    jne  SetupBoss
    call SpawnEnemy
    jmp  Intro
SetupBoss:
    mov  esi, OFFSET bossTemplate
    mov  edi, OFFSET curEnemy
    mov  ecx, SIZEOF EnemyT
    cld
    rep  movsb

Intro:
    mov  edx, OFFSET logE           ; "A wild X appears!"
    call BufBegin
    mov  edx, OFFSET tEncounter
    call BufAddStr
    mov  edx, curEnemy.eName
    call BufAddStr
    mov  edx, OFFSET tAppears
    call BufAddStr
    call BattleFlash

BattleLoop:
    call DrawBattle
    call ReadChar
    cmp  al, '1'
    je   DoAttack
    cmp  al, '2'
    je   DoHeavy
    cmp  al, '3'
    je   DoPotion
    cmp  al, '4'
    je   DoFlee
    jmp  BattleLoop

;---- player turn ----
DoAttack:
    INVOKE CalcDamage, player.atk, curEnemy.eDef
    jmp  ApplyHit
DoHeavy:
    mov  eax, 100
    call RandomRange
    cmp  eax, 60                    ; 60% chance to land
    jb   HeavyHits
    mov  edx, OFFSET logP
    call BufBegin
    mov  edx, OFFSET tMiss
    call BufAddStr
    jmp  EnemyTurn
HeavyHits:
    INVOKE CalcDamage, player.atk, curEnemy.eDef
    shl  eax, 1                     ; double damage
ApplyHit:
    mov  ebx, eax
    cmp  ebx, curEnemy.eHp
    jb   Partial
    mov  curEnemy.eHp, 0
    jmp  LogHit
Partial:
    sub  curEnemy.eHp, ebx
LogHit:
    mov  edx, OFFSET logP
    call BufBegin
    mov  edx, OFFSET tYouHit
    call BufAddStr
    mov  edx, curEnemy.eName
    call BufAddStr
    mov  edx, OFFSET tFor
    call BufAddStr
    mov  eax, ebx
    call BufAddNum
    mov  edx, OFFSET tDamage
    call BufAddStr
    cmp  critFlag, 0
    je   EnemyTurn
    mov  edx, OFFSET tCrit
    call BufAddStr
    jmp  EnemyTurn

DoPotion:
    call DrinkPotion                ; also writes msgBuf
    test eax, eax
    jz   PotionFail
    mov  edx, OFFSET logP
    call BufBegin
    mov  edx, OFFSET msgBuf
    call BufAddStr
    jmp  EnemyTurn
PotionFail:
    mov  edx, OFFSET logP
    call BufBegin
    mov  edx, msgPtr
    call BufAddStr
    jmp  BattleLoop                 ; no turn lost

DoFlee:
    cmp  isBoss, 0
    je   TryFlee
    mov  edx, OFFSET logP
    call BufBegin
    mov  edx, OFFSET tNoEscape
    call BufAddStr
    jmp  EnemyTurn
TryFlee:
    mov  eax, 2
    call RandomRange
    test eax, eax
    jz   Fled
    mov  edx, OFFSET logP
    call BufBegin
    mov  edx, OFFSET tFleeFail
    call BufAddStr
    jmp  EnemyTurn
Fled:
    mov  edx, OFFSET tFled
    mov  eax, lightGray
    call SetMessage
    mov  eax, 0
    ret

;---- enemy turn ----
EnemyTurn:
    cmp  curEnemy.eHp, 0
    je   EnemyDead
    inc  battleTurn
    INVOKE CalcDamage, curEnemy.eAtk, player.def
    mov  ebx, eax

    mov  edx, OFFSET logE
    call BufBegin
    mov  edx, curEnemy.eName
    call BufAddStr

    ; boss breathes fire every 3rd turn: (turn MOD 3) == 0
    cmp  isBoss, 0
    je   NormalHit
    mov  eax, battleTurn
    xor  edx, edx
    mov  ecx, 3
    div  ecx
    test edx, edx
    jnz  NormalHit
    mov  eax, ebx                   ; damage * 3 / 2
    imul eax, 3
    shr  eax, 1
    mov  ebx, eax
    mov  edx, OFFSET tBreath
    jmp  WriteHit
NormalHit:
    mov  edx, OFFSET tHitsYou
WriteHit:
    call BufAddStr
    mov  eax, ebx
    call BufAddNum
    mov  edx, OFFSET tDamage
    call BufAddStr

    cmp  ebx, player.hp
    jb   Survive
    mov  player.hp, 0
    jmp  PlayerDead
Survive:
    sub  player.hp, ebx
    call HitFlash
    jmp  BattleLoop

;---- outcomes ----
EnemyDead:
    inc  player.kills
    mov  eax, curEnemy.eXp
    add  player.xp, eax
    mov  eax, curEnemy.eGold
    add  player.gold, eax
    mov  eax, curEnemy.eXp          ; score += xp*2 + gold
    shl  eax, 1
    add  eax, curEnemy.eGold
    add  player.score, eax
    cmp  isBoss, 0
    je   NotBoss
    or   player.flags, FLAG_BOSS
    add  player.score, 1000
NotBoss:
    mov  edx, OFFSET logE
    call BufBegin
    mov  edx, OFFSET tEnemyDies
    call BufAddStr
    call DrawBattle
    mColor yellow
    mPrintAt 4, 22, "Press any key to continue..."
    call ReadChar

    mov  levelUpFlag, 0
    call CheckLevelUp

    mov  edx, OFFSET msgBuf         ; "Defeated X  +xp XP  +g gold"
    call BufBegin
    mov  edx, OFFSET tDefeated1
    call BufAddStr
    mov  edx, curEnemy.eName
    call BufAddStr
    mov  edx, OFFSET tDefeated2
    call BufAddStr
    mov  eax, curEnemy.eXp
    call BufAddNum
    mov  edx, OFFSET tDefeated3
    call BufAddStr
    mov  eax, curEnemy.eGold
    call BufAddNum
    mov  edx, OFFSET tChest2
    call BufAddStr
    cmp  levelUpFlag, 0
    je   NoLvlMsg
    mov  edx, OFFSET tLevelUp
    call BufAddStr
NoLvlMsg:
    mov  edx, OFFSET msgBuf
    mov  eax, lightGreen
    call SetMessage
    mov  eax, 1
    ret

PlayerDead:
    mov  edx, OFFSET logP
    call BufBegin
    mov  edx, OFFSET tYouDie
    call BufAddStr
    call DrawBattle
    mColor lightRed
    mPrintAt 4, 22, "Press any key..."
    call ReadChar
    mov  eax, 2
    ret
Battle ENDP

;----------------------------------------------------------------------
CheckLevelUp PROC USES eax
; While xp >= lvl * 50 : level up (+20 maxHp, +3 atk, +2 def, full heal)
;----------------------------------------------------------------------
Again:
    mov  eax, player.lvl
    imul eax, 50
    cmp  player.xp, eax
    jb   Done
    sub  player.xp, eax
    inc  player.lvl
    add  player.maxHp, 20
    add  player.atk, 3
    add  player.def, 2
    mov  eax, player.maxHp
    mov  player.hp, eax
    add  player.score, 100
    mov  levelUpFlag, 1
    jmp  Again
Done:
    ret
CheckLevelUp ENDP

;----------------------------------------------------------------------
BattleFlash PROC USES eax ecx
; Short "encounter" animation using background colours and Delay.
;----------------------------------------------------------------------
    mov  ecx, 3
Flash:
    mColor white, red
    call Clrscr
    mov  eax, 70
    call Delay
    mColor white, black
    call Clrscr
    mov  eax, 70
    call Delay
    loop Flash
    ret
BattleFlash ENDP

;----------------------------------------------------------------------
HitFlash PROC USES eax
; Flashes the player's HP label when damaged.
;----------------------------------------------------------------------
    mColor white, red
    mPrintAt 40, 7, " HIT "
    mov  eax, 150
    call Delay
    ret
HitFlash ENDP

;----------------------------------------------------------------------
DrawBattle PROC USES eax edx
;----------------------------------------------------------------------
    mColor lightGray
    call Clrscr
    INVOKE DrawBox, 0, 0, 79, 24, lightRed
    mColor yellow
    mPrintAt 33, 0, " B A T T L E "

    mov  eax, curEnemy.eColor       ; enemy art
    call SetTextColor
    INVOKE DrawArt, curEnemy.eArt, 3, 2

    ; ---- enemy panel ----
    mov  eax, curEnemy.eColor
    call SetTextColor
    mGoto 40, 3
    mov  edx, curEnemy.eName
    call WriteString
    mColor lightGray
    mGoto 40, 4
    mPrint "HP "
    INVOKE DrawBar, curEnemy.eHp, curEnemy.eMaxHp, lightRed
    mGoto 40, 5
    mPrint "   "
    mNum curEnemy.eHp
    mShow tSlash
    mNum curEnemy.eMaxHp
    mPrint "   ATK "
    mNum curEnemy.eAtk
    mPrint "  DEF "
    mNum curEnemy.eDef

    ; ---- player panel ----
    mColor lightCyan
    mGoto 40, 8
    mShow player.pname
    mPrint "  (Lv "
    mNum player.lvl
    mPrint ")"
    mColor lightGray
    mGoto 40, 9
    mPrint "HP "
    call HpColor
    INVOKE DrawBar, player.hp, player.maxHp, eax
    mGoto 40, 10
    mPrint "   "
    mNum player.hp
    mShow tSlash
    mNum player.maxHp
    mPrint "   ATK "
    mNum player.atk
    mPrint "  DEF "
    mNum player.def
    mGoto 40, 11
    mPrint "   Potions: "
    mNum player.potions

    ; ---- log ----
    INVOKE DrawBox, 2, 14, 75, 4, gray
    mColor lightGreen
    mGoto 4, 15
    mShow logP
    mColor lightRed
    mGoto 4, 16
    mShow logE

    ; ---- options ----
    mColor white
    mGoto 4, 19
    mShow tOpt1
    mGoto 4, 20
    mShow tOpt2
    ret
DrawBattle ENDP

;======================================================================
;                              SHOP
;======================================================================

;----------------------------------------------------------------------
Shop PROC USES eax ebx edx
; Buy items. Prices come from an array, effects from a jump table.
;----------------------------------------------------------------------
    mov  needFrame, 1
    mov  edx, OFFSET tShopHello
    mov  eax, yellow
    call SetMessage
ShopLoop:
    mColor lightGray
    call Clrscr
    INVOKE DrawBox, 10, 1, 60, 21, yellow
    mColor yellow
    INVOKE DrawArt, OFFSET shopArt, 27, 2

    mColor white
    mPrintAt 14, 8, "Your gold: "
    mNum player.gold
    mPrint "    Potions: "
    mNum player.potions

    mColor lightCyan
    xor  ebx, ebx                   ; list items with their current price
ItemLoop:
    mov  dl, 14
    mov  dh, bl
    add  dh, 10
    call Gotoxy
    mov  al, '['
    call WriteChar
    mov  al, bl
    add  al, '1'
    call WriteChar
    mPrint "] "
    mov  edx, itemLabels[ebx*4]
    call WriteString
    call ItemPrice
    call WriteDec
    mPrint " g   "
    inc  ebx
    cmp  ebx, SHOP_ITEMS
    jb   ItemLoop
    mColor gray
    mPrintAt 14, 15, "[0] Leave the shop"
    mGoto 14, 18
    mov  eax, msgColor
    call SetTextColor
    mov  edx, msgPtr
    call WriteString

    call ReadChar
    cmp  al, '0'
    je   ExitShop
    cmp  al, '1'
    jb   ShopLoop
    cmp  al, '4'
    ja   ShopLoop

    sub  al, '1'                    ; index 0..3
    movzx ebx, al
    call ItemPrice
    cmp  player.gold, eax
    jb   TooPoor
    sub  player.gold, eax
    call shopEffects[ebx*4]
    test ebx, ebx                   ; potions keep a fixed price
    jz   Bought
    inc  player.upg[ebx*4]
Bought:
    mov  edx, OFFSET msgBuf
    mov  eax, lightGreen
    call SetMessage
    jmp  ShopLoop
TooPoor:
    mov  edx, OFFSET msgBuf
    call BufBegin
    mov  edx, OFFSET tPoor
    call BufAddStr
    mov  edx, OFFSET msgBuf
    mov  eax, lightRed
    call SetMessage
    jmp  ShopLoop
ExitShop:
    mov  edx, OFFSET tLeaveShop
    mov  eax, yellow
    call SetMessage
    ret
Shop ENDP

.data
tPoor       BYTE "You cannot afford that.",0
tShopHello  BYTE "Welcome, traveller! Take a look at my wares.",0
tLeaveShop  BYTE "The merchant waves goodbye. Safe travels!",0
tBought     BYTE "Purchased: ",0
tShop1      BYTE "Healing Potion   (+40 HP)          ",0
tShop2      BYTE "Sharpen Sword    (+3 ATK)          ",0
tShop3      BYTE "Iron Armour      (+2 DEF)          ",0
tShop4      BYTE "Vitality Charm   (+20 MAX HP)      ",0
tItPotion   BYTE "Healing Potion",0
tItSword    BYTE "Sharpened Sword (+3 ATK)",0
tItArmour   BYTE "Iron Armour (+2 DEF)",0
tItCharm    BYTE "Vitality Charm (+20 MAX HP)",0
.code

;----------------------------------------------------------------------
ItemPrice PROC USES edx
; EBX = item index. Returns EAX = prices[i] * (times bought + 1)
;----------------------------------------------------------------------
    mov  eax, player.upg[ebx*4]
    inc  eax
    mul  prices[ebx*4]              ; EDX:EAX = EAX * price
    ret
ItemPrice ENDP

; Each effect applies the item and writes "Purchased: X" into msgBuf.
BuyPotion PROC USES edx
    inc  player.potions
    mov  edx, OFFSET tItPotion
    call BoughtMsg
    ret
BuyPotion ENDP

BuySword PROC USES edx
    add  player.atk, 3
    mov  edx, OFFSET tItSword
    call BoughtMsg
    ret
BuySword ENDP

BuyArmor PROC USES edx
    add  player.def, 2
    mov  edx, OFFSET tItArmour
    call BoughtMsg
    ret
BuyArmor ENDP

BuyVitality PROC USES edx
    add  player.maxHp, 20
    add  player.hp, 20
    mov  edx, OFFSET tItCharm
    call BoughtMsg
    ret
BuyVitality ENDP

BoughtMsg PROC USES edx              ; EDX = item name
    push edx
    mov  edx, OFFSET msgBuf
    call BufBegin
    mov  edx, OFFSET tBought
    call BufAddStr
    pop  edx
    call BufAddStr
    ret
BoughtMsg ENDP

;======================================================================
;                        DRAWING / USER INTERFACE
;======================================================================

;----------------------------------------------------------------------
DrawFrame PROC
; Static parts of the exploration screen (drawn only when needed).
;----------------------------------------------------------------------
    mColor lightGray
    call Clrscr
    mColor black, cyan
    mGoto 0, 0
    mShow blankLine
    mPrintAt 2, 0, "DUNGEON OF ASSEMBLY  -  explore - fight - survive"

    INVOKE DrawBox, MAP_X - 1, MAP_Y - 1, MAP_W + 2, MAP_H + 2, brown
    INVOKE DrawBox, HUD_X - 2, MAP_Y - 1, 34, MAP_H + 2, brown

    mColor white
    mPrintAt HUD_X, 14, "LEGEND"
    mColor yellow
    mPrintAt HUD_X, 15, "@ You  "
    mPrint "$ Shop  "
    mColor lightCyan
    mPrint "+ Fountain"
    mColor brown
    mGoto HUD_X, 16
    mov  al, CHEST_CHAR
    call WriteChar
    mPrint " Chest  "
    mColor lightMagenta
    mPrint "K Key   "
    mColor white, red
    mPrint "B"
    mColor lightRed
    mPrint " Boss"
    mColor lightBlue, blue
    mGoto HUD_X, 17
    mPrint "~"
    mColor gray
    mPrint " Water  "
    mov  al, WALL_CHAR
    call WriteChar
    mPrint " Wall  "
    mov  al, FOG_CHAR
    call WriteChar
    mPrint " Unknown"

    mColor white
    mPrintAt 1, 21, "[1/W] North   [2/S] South   [3/A] West   [4/D] East   (arrows work too)"
    mPrintAt 1, 22, "[5] Drink Potion   [6] Rest / Camp   [7] Save Game   [8] Quit to Title"
    ret
DrawFrame ENDP

;----------------------------------------------------------------------
DrawMap PROC USES eax ebx ecx edx esi
; Draws the visible world. Colours and glyphs are looked up with XLAT.
;----------------------------------------------------------------------
    LOCAL row:DWORD, col:DWORD

    xor  esi, esi                   ; tile index 0..MAP_SIZE-1
    mov  row, 0
RowLoop:
    mov  eax, row
    add  al, MAP_Y
    mov  dh, al
    mov  dl, MAP_X
    call Gotoxy
    mov  col, 0
ColLoop:
    mov  eax, col                   ; is the player here?
    cmp  eax, player.posX
    jne  NotPlayer
    mov  eax, row
    cmp  eax, player.posY
    jne  NotPlayer
    mov  eax, yellow + (black * 16)
    call SetTextColor
    mov  al, '@'
    call WriteChar
    jmp  NextCol

NotPlayer:
    cmp  visited[esi], 0
    jne  Seen
    mov  eax, gray
    call SetTextColor
    mov  al, FOG_CHAR
    call WriteChar
    jmp  NextCol

Seen:
    mov  cl, worldMap[esi]          ; keep tile char in CL
    mov  al, cl
    mov  ebx, OFFSET colorLUT
    xlat                            ; AL = colorLUT[AL]
    movzx eax, al
    call SetTextColor
    mov  al, cl
    mov  ebx, OFFSET glyphLUT
    xlat                            ; AL = glyphLUT[AL]
    call WriteChar

NextCol:
    inc  esi
    inc  col
    cmp  col, MAP_W
    jb   ColLoop
    inc  row
    cmp  row, MAP_H
    jb   RowLoop
    ret
DrawMap ENDP


;----------------------------------------------------------------------
DrawHud PROC USES eax ebx edx
; Player status panel on the right of the map.
;----------------------------------------------------------------------
    mColor yellow
    mPrintAt HUD_X, 3, "== "
    mShow player.pname
    mPrint " ==        "

    mColor lightGray
    mPrintAt HUD_X, 4, "Level "
    mNum player.lvl
    mPrint "   XP "
    mNum player.xp
    mShow tSlash
    mov  eax, player.lvl
    imul eax, 50
    mNum eax
    mPrint "     "

    mPrintAt HUD_X, 5, "HP "
    call HpColor
    INVOKE DrawBar, player.hp, player.maxHp, eax
    mColor lightGray
    mPrintAt HUD_X, 6, "   "
    mNum player.hp
    mShow tSlash
    mNum player.maxHp
    mPrint "     "

    mPrintAt HUD_X, 7, "ATK "
    mNum player.atk
    mPrint "   DEF "
    mNum player.def
    mPrint "    "

    mColor yellow
    mPrintAt HUD_X, 8, "Gold "
    mNum player.gold
    mPrint "    "
    mColor lightGreen
    mPrintAt HUD_X + 13, 8, "Potions "
    mNum player.potions
    mPrint "   "

    mColor lightMagenta
    mPrintAt HUD_X, 9, "Ancient Key: "
    test player.flags, FLAG_KEY
    jz   NoKey
    mShow tYes
    jmp  KeyDone
NoKey:
    mShow tNo
KeyDone:

    mColor lightCyan
    mPrintAt HUD_X, 10, "Score "
    mNum player.score
    mPrint "   Kills "
    mNum player.kills
    mPrint "   "

    mColor lightGray
    mPrintAt HUD_X, 11, "Zone  "
    mov  eax, player.posX           ; zone = posX / 10
    xor  edx, edx
    mov  ebx, 10
    div  ebx
    mov  edx, zoneNames[eax*4]
    call WriteString

    mPrintAt HUD_X, 12, "Pos ("
    mNum player.posX
    mPrint ","
    mNum player.posY
    mPrint ")  Steps "
    mNum player.steps
    mPrint "   "
    ret
DrawHud ENDP

;----------------------------------------------------------------------
HpColor PROC
; Returns EAX = bar colour for the player's HP:
;   > 50% green, > 25% yellow, otherwise red.
;----------------------------------------------------------------------
    push ebx
    mov  eax, player.hp
    shl  eax, 1                     ; hp * 2
    cmp  eax, player.maxHp
    ja   Healthy
    shl  eax, 1                     ; hp * 4
    cmp  eax, player.maxHp
    ja   Hurt
    mov  eax, lightRed
    jmp  Done
Healthy:
    mov  eax, lightGreen
    jmp  Done
Hurt:
    mov  eax, yellow
Done:
    pop  ebx
    ret
HpColor ENDP

;----------------------------------------------------------------------
DrawBar PROC USES eax ebx ecx edx, cur:DWORD, maxv:DWORD, barColor:DWORD
; Draws [#########.....] at the cursor. filled = cur * BAR_LEN / maxv
;----------------------------------------------------------------------
    xor  ebx, ebx
    mov  ecx, maxv
    jecxz Draw                      ; guard against divide by zero
    mov  eax, cur
    mov  ebx, BAR_LEN
    mul  ebx                        ; EDX:EAX = cur * BAR_LEN
    div  ecx                        ; EAX = filled cells
    mov  ebx, eax
    cmp  ebx, BAR_LEN
    jbe  Draw
    mov  ebx, BAR_LEN
Draw:
    mColor white
    mov  al, '['
    call WriteChar
    mov  eax, barColor
    call SetTextColor
    mov  ecx, ebx
    jecxz Empty
    mov  al, FULL_CELL
Fill:
    call WriteChar
    loop Fill
Empty:
    mColor gray
    mov  ecx, BAR_LEN
    sub  ecx, ebx
    jecxz Close
    mov  al, EMPTY_CELL
Blank:
    call WriteChar
    loop Blank
Close:
    mColor white
    mov  al, ']'
    call WriteChar
    ret
DrawBar ENDP

;----------------------------------------------------------------------
DrawBox PROC USES eax ecx edx, left:DWORD, top:DWORD, wid:DWORD, hgt:DWORD, boxColor:DWORD
; Double-line box using CP437 characters. wid, hgt >= 3.
;----------------------------------------------------------------------
    mov  eax, boxColor
    call SetTextColor

    mov  dl, BYTE PTR left          ; top edge
    mov  dh, BYTE PTR top
    call Gotoxy
    mov  al, 201
    call WriteChar
    mov  ecx, wid
    sub  ecx, 2
    mov  al, 205
TopEdge:
    call WriteChar
    loop TopEdge
    mov  al, 187
    call WriteChar

    mov  ecx, hgt                   ; sides
    sub  ecx, 2
    mov  al, 186
Sides:
    inc  dh
    mov  dl, BYTE PTR left
    call Gotoxy
    call WriteChar
    add  dl, BYTE PTR wid
    dec  dl
    call Gotoxy
    call WriteChar
    loop Sides

    inc  dh                         ; bottom edge
    mov  dl, BYTE PTR left
    call Gotoxy
    mov  al, 200
    call WriteChar
    mov  ecx, wid
    sub  ecx, 2
    mov  al, 205
BottomEdge:
    call WriteChar
    loop BottomEdge
    mov  al, 188
    call WriteChar
    ret
DrawBox ENDP

;----------------------------------------------------------------------
DrawArt PROC USES eax ecx edx edi, artPtr:DWORD, col:DWORD, row:DWORD
; Prints a list of 0-terminated lines (list ends with an empty string).
; Uses REPNE SCASB to jump over each line's terminating zero.
;----------------------------------------------------------------------
    mov  edi, artPtr
    cld
LineLoop:
    cmp  BYTE PTR [edi], 0
    je   Done
    mov  dl, BYTE PTR col
    mov  dh, BYTE PTR row
    call Gotoxy
    mov  edx, edi
    call WriteString
    mov  al, 0
    mov  ecx, 0FFFFh
    repne scasb                     ; EDI -> first byte after the 0
    inc  row
    jmp  LineLoop
Done:
    ret
DrawArt ENDP

;----------------------------------------------------------------------
SetMessage PROC
; EDX = message text, EAX = colour
;----------------------------------------------------------------------
    mov  msgPtr, edx
    mov  msgColor, eax
    ret
SetMessage ENDP

;----------------------------------------------------------------------
DrawMessage PROC USES eax edx
;----------------------------------------------------------------------
    mColor lightGray
    mGoto 1, MSG_ROW
    mShow blankLine
    mGoto 1, MSG_ROW
    mColor white
    mPrint "> "
    mov  eax, msgColor
    call SetTextColor
    mov  edx, msgPtr
    call WriteString
    ret
DrawMessage ENDP

;======================================================================
;                      STRING-BUILDER HELPERS
;======================================================================

;----------------------------------------------------------------------
BufBegin PROC
; EDX = destination buffer. Starts a new, empty string there.
;----------------------------------------------------------------------
    mov  outPtr, edx
    mov  BYTE PTR [edx], 0
    ret
BufBegin ENDP

;----------------------------------------------------------------------
BufAddChar PROC USES edi
; Appends AL.
;----------------------------------------------------------------------
    mov  edi, outPtr
    mov  [edi], al
    inc  edi
    mov  BYTE PTR [edi], 0
    mov  outPtr, edi
    ret
BufAddChar ENDP

;----------------------------------------------------------------------
BufAddStr PROC USES eax esi edi
; Appends the 0-terminated string at EDX (LODSB / STOSB copy).
;----------------------------------------------------------------------
    cld
    mov  esi, edx
    mov  edi, outPtr
CopyLoop:
    lodsb
    test al, al
    jz   Finish
    stosb
    jmp  CopyLoop
Finish:
    mov  BYTE PTR [edi], 0
    mov  outPtr, edi
    ret
BufAddStr ENDP

;----------------------------------------------------------------------
BufAddNum PROC USES eax ebx edx
; Appends unsigned EAX in decimal. RECURSIVE:
;   print(n) = { if n >= 10 then print(n / 10) ; emit n MOD 10 }
;----------------------------------------------------------------------
    mov  ebx, 10
    xor  edx, edx
    div  ebx                        ; EAX = n / 10, EDX = n MOD 10
    test eax, eax
    jz   Emit
    call BufAddNum                  ; recurse on the quotient
Emit:
    mov  al, dl
    add  al, '0'
    call BufAddChar
    ret
BufAddNum ENDP

;----------------------------------------------------------------------
BufPadTo PROC USES eax ecx
; Pads the current buffer with spaces until it is ECX chars long.
; EDX = start of the buffer.
;----------------------------------------------------------------------
PadLoop:
    mov  eax, outPtr
    sub  eax, edx                   ; current length
    cmp  eax, ecx
    jae  Done
    mov  al, ' '
    call BufAddChar
    jmp  PadLoop
Done:
    ret
BufPadTo ENDP

;----------------------------------------------------------------------
ToUpperStr PROC USES eax esi
; ESI = string. Converts a..z to A..Z by clearing bit 5 (AND 0DFh).
;----------------------------------------------------------------------
NextChar:
    mov  al, [esi]
    test al, al
    jz   Done
    cmp  al, 'a'
    jb   Skip
    cmp  al, 'z'
    ja   Skip
    and  al, 11011111b
    mov  [esi], al
Skip:
    inc  esi
    jmp  NextChar
Done:
    ret
ToUpperStr ENDP

;----------------------------------------------------------------------
XorBuffer PROC USES eax ecx esi
; Simple XOR cipher. ESI = buffer, ECX = length. Applying it twice
; returns the original data, so it both encrypts and decrypts.
;----------------------------------------------------------------------
    jecxz Done
CipherLoop:
    xor  BYTE PTR [esi], XOR_KEY
    inc  esi
    loop CipherLoop
Done:
    ret
XorBuffer ENDP

;======================================================================
;                          FILE HANDLING
;======================================================================

;----------------------------------------------------------------------
SaveGame PROC USES eax ecx edx esi edi
; Packs [magic | player | worldMap | visited] into saveBuf, XOR-encrypts
; it and writes it to dungeon.sav in binary.
;----------------------------------------------------------------------
    cld
    mov  edi, OFFSET saveBuf
    mov  eax, SAVE_MAGIC
    stosd
    mov  esi, OFFSET player
    mov  ecx, SIZEOF PlayerT
    rep  movsb
    mov  esi, OFFSET worldMap
    mov  ecx, MAP_SIZE
    rep  movsb
    mov  esi, OFFSET visited
    mov  ecx, MAP_SIZE
    rep  movsb

    mov  esi, OFFSET saveBuf
    mov  ecx, SAVE_SIZE
    call XorBuffer

    mov  edx, OFFSET saveFile
    call CreateOutputFile
    cmp  eax, INVALID_HANDLE_VALUE
    je   Failed
    mov  fileHandle, eax
    mov  edx, OFFSET saveBuf
    mov  ecx, SAVE_SIZE
    call WriteToFile
    mov  ecx, eax                   ; bytes written
    mov  eax, fileHandle
    call CloseFile
    cmp  ecx, SAVE_SIZE
    jne  Failed

    mov  edx, OFFSET tSaved
    mov  eax, lightGreen
    call SetMessage
    ret
Failed:
    mov  edx, OFFSET tSaveFail
    mov  eax, lightRed
    call SetMessage
    ret
SaveGame ENDP

;----------------------------------------------------------------------
LoadGame PROC USES ecx edx esi edi
; Reads dungeon.sav, decrypts and validates it. Returns EAX = 1 on
; success, 0 on failure (an error is shown).
;----------------------------------------------------------------------
    mov  edx, OFFSET saveFile
    call OpenInputFile
    cmp  eax, INVALID_HANDLE_VALUE
    je   NoFile
    mov  fileHandle, eax

    mov  edx, OFFSET saveBuf
    mov  ecx, SAVE_SIZE
    call ReadFromFile
    mov  bytesRead, eax
    pushfd                          ; keep CF (read error) across CloseFile
    mov  eax, fileHandle
    call CloseFile
    popfd
    jc   Corrupt
    cmp  bytesRead, SAVE_SIZE
    jne  Corrupt

    mov  esi, OFFSET saveBuf        ; decrypt
    mov  ecx, SAVE_SIZE
    call XorBuffer
    cmp  DWORD PTR saveBuf, SAVE_MAGIC
    jne  Corrupt

    cld                             ; unpack
    mov  esi, OFFSET saveBuf + 4
    mov  edi, OFFSET player
    mov  ecx, SIZEOF PlayerT
    rep  movsb
    mov  edi, OFFSET worldMap
    mov  ecx, MAP_SIZE
    rep  movsb
    mov  edi, OFFSET visited
    mov  ecx, MAP_SIZE
    rep  movsb

    mov  edx, OFFSET tLoadOk
    mov  eax, lightGreen
    call SetMessage
    mov  eax, 1
    ret

NoFile:
    mov  edx, OFFSET tNoSave
    jmp  ShowError
Corrupt:
    mov  edx, OFFSET tBadSave
ShowError:
    mColor lightRed
    mGoto 20, 21
    call WriteString
    mColor gray
    mPrintAt 20, 22, "Press any key..."
    call ReadChar
    mov  eax, 0
    ret
LoadGame ENDP

;----------------------------------------------------------------------
RecordScore PROC USES eax ecx edx, resultText:DWORD
; Formats one line and APPENDS it to halloffame.txt:
;   NAME            | SCORE | LVL | KILLS | RESULT
; Uses Win32 CreateFile (OPEN_ALWAYS) + SetFilePointer (FILE_END).
;----------------------------------------------------------------------
    mov  edx, OFFSET lineBuf
    call BufBegin
    mov  edx, OFFSET player.pname
    call BufAddStr
    mov  edx, OFFSET lineBuf
    mov  ecx, 15
    call BufPadTo
    mov  edx, OFFSET tSep
    call BufAddStr
    mov  eax, player.score
    call BufAddNum
    mov  edx, OFFSET lineBuf
    mov  ecx, 23
    call BufPadTo
    mov  edx, OFFSET tSep
    call BufAddStr
    mov  eax, player.lvl
    call BufAddNum
    mov  edx, OFFSET lineBuf
    mov  ecx, 29
    call BufPadTo
    mov  edx, OFFSET tSep
    call BufAddStr
    mov  eax, player.kills
    call BufAddNum
    mov  edx, OFFSET lineBuf
    mov  ecx, 37
    call BufPadTo
    mov  edx, OFFSET tSep
    call BufAddStr
    mov  edx, resultText
    call BufAddStr
    mov  edx, OFFSET crlfStr
    call BufAddStr

    INVOKE CreateFile, ADDR scoreFile, GENERIC_WRITE, DO_NOT_SHARE, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    cmp  eax, INVALID_HANDLE_VALUE
    je   Done
    mov  fileHandle, eax
    INVOKE SetFilePointer, fileHandle, 0, 0, FILE_END

    mov  eax, fileHandle
    mov  edx, OFFSET lineBuf
    mov  ecx, outPtr
    sub  ecx, OFFSET lineBuf        ; length = end - start
    call WriteToFile
    mov  eax, fileHandle
    call CloseFile
Done:
    ret
RecordScore ENDP

;----------------------------------------------------------------------
ShowHallOfFame PROC USES eax ebx ecx edx edi
; Reads halloffame.txt (text file) and prints the newest FAME_LINES
; results. The start of that block is found by scanning the buffer
; BACKWARDS for line feeds (STD + REPNE SCASB).
;----------------------------------------------------------------------
    mColor lightGray
    call Clrscr
    mColor yellow
    mPrintAt 28, 1, "H A L L   O F   F A M E"
    mColor gray
    mPrintAt 24, 2, "(most recent results are shown)"
    mColor lightCyan
    mGoto 0, 4
    mShow tFameHead

    mov  edx, OFFSET scoreFile
    call OpenInputFile
    cmp  eax, INVALID_HANDLE_VALUE
    je   Empty
    mov  fileHandle, eax
    mov  edx, OFFSET fameBuf
    mov  ecx, SIZEOF fameBuf - 1
    call ReadFromFile
    jnc  ReadOk
    mov  eax, 0
ReadOk:
    mov  fameBuf[eax], 0            ; null-terminate what was read
    mov  ebx, eax                   ; EBX = bytes read
    mov  eax, fileHandle
    call CloseFile
    cmp  ebx, 2
    jb   Empty

    lea  edi, fameBuf[ebx - 2]      ; skip the final line feed
    mov  ecx, ebx
    dec  ecx
    mov  ebx, FAME_LINES
    mov  al, 10                     ; LF
    std                             ; scan towards lower addresses
FindLine:
    repne scasb
    jne  ShowAll                    ; reached the start of the file
    dec  ebx
    jnz  FindLine
    cld
    lea  edx, [edi + 2]             ; first char after that LF
    jmp  PrintIt
ShowAll:
    cld
    mov  edx, OFFSET fameBuf
PrintIt:
    mColor white
    call WriteString
    jmp  Wait4Key
Empty:
    mColor gray
    mShow tNoFame
Wait4Key:
    call Crlf
    call Crlf
    mColor yellow
    mPrint "Press any key to return..."
    call ReadChar
    ret
ShowHallOfFame ENDP

;======================================================================
;                        TITLE / INFO SCREENS
;======================================================================

;----------------------------------------------------------------------
TitleScreen PROC USES ecx edx esi edi
; Returns AL = key pressed.
;----------------------------------------------------------------------
    mColor lightGray
    call Clrscr
    INVOKE DrawBox, 0, 0, 79, 24, lightBlue

    ; banner: each line in a different colour (indexed array)
    mov  edi, OFFSET titleArt
    xor  esi, esi                   ; line index
    mov  dh, 2
    cld
BannerLoop:
    cmp  BYTE PTR [edi], 0
    je   BannerDone
    movzx eax, titleColors[esi]
    call SetTextColor
    mov  dl, 18
    call Gotoxy
    push edx
    mov  edx, edi
    call WriteString
    pop  edx
    mov  al, 0
    mov  ecx, 0FFFFh
    repne scasb
    inc  esi
    inc  dh
    jmp  BannerLoop
BannerDone:

    mColor white
    mPrintAt 29, 8, "O F   A S S E M B L Y"
    mColor gray
    mPrintAt 18, 10, "A dungeon-survival RPG in x86 assembly language"

    mColor lightCyan
    mPrintAt 30, 13, "[1]  New Adventure"
    mPrintAt 30, 14, "[2]  Load Saved Game"
    mPrintAt 30, 15, "[3]  Hall of Fame"
    mPrintAt 30, 16, "[4]  How to Play"
    mPrintAt 30, 17, "[5]  Exit"
    mColor yellow
    mPrintAt 28, 20, "Choose an option (1-5)"
    call ReadChar
    ret
TitleScreen ENDP

;----------------------------------------------------------------------
ShowHelp PROC
;----------------------------------------------------------------------
    mColor lightGray
    call Clrscr
    INVOKE DrawBox, 0, 0, 79, 24, lightGreen
    mColor yellow
    mPrintAt 32, 1, "H O W   T O   P L A Y"
    mColor white
    mPrintAt 3, 3,  "GOAL  Find the Ancient Key (K) hidden in the Ruined Keep and use it"
    mPrintAt 3, 4,  "      to open the lair (B) of the DRAGON KING in the far east."
    mColor lightGray
    mPrintAt 3, 6,  "MOVE  1/W North   2/S South   3/A West   4/D East   or arrow keys"
    mPrintAt 3, 7,  "      The map starts hidden. Walking reveals it - +1 point per tile."
    mPrintAt 3, 9,  "MAP   $ Shop: buy potions and upgrades with gold"
    mPrintAt 3, 10, "      + Fountain: fully restores HP (unlimited use)"
    mPrintAt 3, 11, "      Chests: gold and sometimes potions (+25 points)"
    mPrintAt 3, 12, "      Walls and deep water cannot be crossed"
    mPrintAt 3, 14, "FIGHT Enemies ambush you on open ground. They grow stronger"
    mPrintAt 3, 15, "      further east and as you level up."
    mPrintAt 3, 16, "      Attack - Heavy Strike (risky) - Potion - Flee"
    mGoto 3, 18
    mShow tHelpCamp
    mPrintAt 3, 19, "SAVE  Progress is saved (encrypted) in dungeon.sav. Final scores"
    mPrintAt 3, 20, "      are written to halloffame.txt."
    mColor yellow
    mPrintAt 3, 22, "Press any key to return..."
    call ReadChar
    ret
ShowHelp ENDP

;----------------------------------------------------------------------
ShowFinalStats PROC
; Shared by the victory and game-over screens.
;----------------------------------------------------------------------
    mColor white
    mPrintAt 28, 13, "Hero   : "
    mShow player.pname
    mPrintAt 28, 14, "Level  : "
    mNum player.lvl
    mPrintAt 28, 15, "Kills  : "
    mNum player.kills
    mPrintAt 28, 16, "Steps  : "
    mNum player.steps
    mColor yellow
    mPrintAt 28, 17, "SCORE  : "
    mNum player.score
    mColor gray
    mPrintAt 20, 20, "Your result was added to halloffame.txt"
    mColor yellow
    mPrintAt 20, 22, "Press any key to return to the title..."
    ret
ShowFinalStats ENDP

;----------------------------------------------------------------------
GameOverScreen PROC
;----------------------------------------------------------------------
    INVOKE RecordScore, OFFSET tLose
    mColor lightGray
    call Clrscr
    INVOKE DrawBox, 0, 0, 79, 24, red
    mColor lightRed
    INVOKE DrawArt, OFFSET skullArt, 31, 2
    mPrintAt 30, 10, "G A M E   O V E R"
    call ShowFinalStats
    call ReadChar
    ret
GameOverScreen ENDP

;----------------------------------------------------------------------
VictoryScreen PROC
;----------------------------------------------------------------------
    INVOKE RecordScore, OFFSET tWin
    mColor lightGray
    call Clrscr
    INVOKE DrawBox, 0, 0, 79, 24, yellow
    mColor yellow
    INVOKE DrawArt, OFFSET crownArt, 31, 3
    mColor lightGreen
    mPrintAt 22, 9,  "THE DRAGON KING HAS FALLEN"
    mColor white
    mPrintAt 22, 10, "The realm is saved. Songs will be sung of you."
    call ShowFinalStats
    call ReadChar
    ret
VictoryScreen ENDP

END main
