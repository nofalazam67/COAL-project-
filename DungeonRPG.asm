; ============================================================
;  COAL Lab Project  -  DUNGEON OF ASSEMBLY  (Text RPG Game)
;
;  Name    : ______________________
;  Roll No : ______________   Section : ____
;
;  Assembler : MASM (32-bit)  +  Irvine32 library
; ============================================================
;  Game idea
;  - The whole map is shown on the screen, the player is '@'
;  - Move with W A S D (or 1 2 3 4)
;  - While walking, enemies can attack you (random battles)
;  - Open chests (C) for gold, buy items in the shop ($)
;  - Heal at the fountain (+), find the key (K)
;  - Use the key to open the boss room (B) and kill the Dragon
;  - Game can be saved / loaded and the high score is kept
;    in a text file
; ============================================================

INCLUDE Irvine32.inc

; ---------------------- constants ---------------------------
ROWS        = 15
COLS        = 40
MAP_SIZE    = ROWS * COLS
NAME_SIZE   = 20
ITEM_LEN    = 28              ; every shop item name uses 28 bytes
BAR_SIZE    = 20              ; length of the HP bar
CHANCE      = 15              ; % chance of a battle on each step
POTION_HEAL = 30
YES         EQU 1
NO          EQU 0

; ---------------------- prototypes --------------------------
ShowBar    PROTO, value:DWORD, maxValue:DWORD
SaveToFile PROTO, fileName:PTR BYTE, dataAddr:PTR BYTE, dataSize:DWORD

.data
; ---------------------- the map (2D array) ------------------
; #  wall        ~  water        .  ground
; $  shop        +  fountain     C  chest
; K  key         B  boss room
mapOriginal BYTE "########################################"
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

; colors of the map tiles (anything else is light cyan)
tileChars  BYTE "#~.BK"
tileColors DWORD gray, lightBlue, green, lightRed, lightMagenta

; ------------- everything below is written to the save file -------------
saveStart  LABEL BYTE
playerName BYTE NAME_SIZE DUP(0)
pRow       DWORD ?            ; player position (row)
pCol       DWORD ?            ; player position (column)
hp         DWORD ?
maxHp      DWORD ?
attack     DWORD ?
defense    DWORD ?
level      DWORD ?
xp         DWORD ?
gold       DWORD ?
potions    DWORD ?
hasKey     DWORD ?
score      DWORD ?
kills      DWORD ?
steps      DWORD ?
totalDmgLo DWORD ?            ; 64-bit total damage (low part)
totalDmgHi DWORD ?            ; 64-bit total damage (high part)
prices     DWORD 3 DUP(?)     ; potion, sword, armor
gameMap    BYTE MAP_SIZE DUP(?)
saveEnd    LABEL BYTE
SAVE_SIZE  = saveEnd - saveStart

; starting values (same order as pRow ... prices)
startStats DWORD 1, 1, 100, 100, 10, 3, 1, 0, 20, 3, NO, 0, 0, 0, 0, 0, 15, 40, 35
defaultName BYTE "HERO",0

; ---------------------- enemies (parallel arrays) ------------
name1      BYTE "Slime",0
name2      BYTE "Goblin",0
name3      BYTE "Skeleton",0
name4      BYTE "Orc",0
enemyNames DWORD name1, name2, name3, name4    ; array of addresses
enemyHPs   DWORD 15, 25, 35, 45
enemyAtks  DWORD 4, 6, 9, 12
enemyXPs   DWORD 10, 18, 28, 40
enemyGolds DWORD 5, 10, 15, 22
bossName   BYTE "DRAGON",0

; current enemy in the battle
enemyName  DWORD ?            ; address of the name
eHP        DWORD ?
eAtk       DWORD ?
eXP        DWORD ?
eGold      DWORD ?
isBoss     BYTE NO

; ---------------------- movement keys -----------------------
moveKeys   BYTE "wsad1234"
rowChange  SDWORD -1, 1,  0, 0, -1, 1,  0, 0
colChange  SDWORD  0, 0, -1, 1,  0, 0, -1, 1

; ---------------------- other variables ---------------------
playerIdx  DWORD ?
newRow     DWORD ?
newCol     DWORD ?
gameWon    BYTE NO
highScore  DWORD 0
msgPtr     DWORD ?

; ---------------------- files -------------------------------
saveFile   BYTE "dungeon.sav",0
scoreFile  BYTE "highscore.txt",0
saveSig    BYTE "DUNG"        ; first 4 bytes of a save file
fileHeader BYTE 4 DUP(?)
fileHandle DWORD ?
numBuffer  BYTE 12 DUP(0)
numLength  DWORD ?

; ---------------------- strings -----------------------------
msgLine    BYTE "==========================================",0
msgTitle   BYTE "        D U N G E O N   O F   A S S E M B L Y",0
msgHeader  BYTE "==========================================",13,10
           BYTE "        D U N G E O N   O F   A S S E M B L Y",13,10
           BYTE "==========================================",13,10,0
msgMenu    BYTE 13,10,"   1. New Game",13,10,"   2. Load Game",13,10
           BYTE "   3. How to Play",13,10,"   4. Exit",13,10,13,10,0
msgHigh    BYTE "   High Score: ",0
msgChoice  BYTE 13,10,13,10,"   Enter your choice: ",0
msgAskName BYTE "Enter your name: ",0
msgHelp    BYTE "HOW TO PLAY",13,10,13,10
           BYTE "- Move with W A S D or 1 2 3 4. Every step gives 1 point.",13,10
           BYTE "- Enemies may attack while you walk. Stronger ones live in the east.",13,10
           BYTE "- C = chest (gold)   $ = shop   + = fountain (full heal)",13,10
           BYTE "- K = key. You need the key to enter the boss room B.",13,10
           BYTE "- Kill the DRAGON to win the game.",13,10
           BYTE "- # walls and ~ water cannot be crossed.",13,10,0

msgName    BYTE " Name: ",0
msgLevel   BYTE "   Level: ",0
msgXP      BYTE "   XP: ",0
msgGold    BYTE "   Gold: ",0
msgHP      BYTE " HP: ",0
msgSlash   BYTE "/",0
msgAtk     BYTE " ATK: ",0
msgDef     BYTE "   DEF: ",0
msgPotions BYTE "   Potions: ",0
msgKey     BYTE "   Key: ",0
msgYes     BYTE "YES",0
msgNo      BYTE "NO",0
msgScore   BYTE " Score: ",0
msgKeys    BYTE " [W/1] Up  [S/2] Down  [A/3] Left  [D/4] Right",13,10
           BYTE " [5] Drink Potion  [6] Save Game  [7] Quit",13,10,0
msgInvalid BYTE " Invalid key!",0
msgAnyKey  BYTE " Press any key to continue...",0

msgWall    BYTE " You hit a wall.",0
msgWater   BYTE " The water is too deep.",0
msgChest   BYTE " You opened a chest! Gold found: ",0
msgFountain BYTE " You drink from the fountain. HP is full!",0
msgGotKey  BYTE " You found the KEY! Now go to the boss room (B).",0
msgLocked  BYTE " The boss room is locked. Find the key (K) first!",0

msgShop    BYTE "================ SHOP ================",13,10,0
itemNames  BYTE " 1. Potion (+30 HP)        ",0
           BYTE " 2. Sharpen Sword (+3 ATK) ",0
           BYTE " 3. Iron Armor (+2 DEF)    ",0
msgLeave   BYTE " 4. Leave the shop",0
msgBought  BYTE " Item bought!",0
msgNoMoney BYTE " Not enough gold!",0

msgAppear  BYTE " A wild enemy appears: ",0
msgBossApp BYTE " FINAL BATTLE! The boss wakes up: ",0
msgEnemyHP BYTE "  HP: ",0
msgYourHP  BYTE " Your HP: ",0
msgBattle  BYTE " 1. Attack   2. Drink Potion   3. Run Away",0
msgYouHit  BYTE " You hit the enemy! Damage: ",0
msgHitsYou BYTE " The enemy hits you! Damage: ",0
msgCrit    BYTE " CRITICAL HIT!",0
msgRan     BYTE " You ran away!",0
msgNoRun   BYTE " You could not escape!",0
msgWin     BYTE " You defeated the enemy! XP and gold gained.",0
msgDead    BYTE " You have been defeated...",0
msgLevelUp BYTE " LEVEL UP! You are now level ",0
msgNoPot   BYTE " You have no potions!",0
msgDrank   BYTE " You drank a potion. HP is now ",0

msgSaved   BYTE " Game saved.",0
msgSaveErr BYTE " Error: could not save the game.",0
msgNoSave  BYTE " No save file found.",0
msgBadSave BYTE " Save file is damaged.",0

msgOver    BYTE "              G A M E   O V E R",0
msgVictory BYTE "       Y O U   W O N !   The Dragon is dead!",0
msgKills   BYTE " Enemies killed: ",0
msgSteps   BYTE "   Steps: ",0
msgTotDmg  BYTE " Total damage dealt: ",0
msgNewHigh BYTE " *** NEW HIGH SCORE! ***",0

.code
; ============================================================
main PROC
    call Randomize
    call LoadHighScore

menuLoop:
    call ShowTitle               ; returns key in AL
    cmp al, '1'
    je optNew
    cmp al, '2'
    je optLoad
    cmp al, '3'
    je optHelp
    cmp al, '4'
    je optExit
    jmp menuLoop

optNew:
    call NewGame
    call PlayGame
    jmp menuLoop

optLoad:
    call LoadGame                ; EAX = 1 if loaded
    cmp eax, 1
    jne menuLoop
    call PlayGame
    jmp menuLoop

optHelp:
    call Clrscr
    mov edx, OFFSET msgHelp
    call WriteString
    call WaitKey
    jmp menuLoop

optExit:
    exit
main ENDP

; ============================================================
; ShowTitle - draws the main menu, returns the key in AL
; ============================================================
ShowTitle PROC
    call Clrscr
    mov eax, yellow
    call SetTextColor
    mov edx, OFFSET msgHeader
    call WriteString
    mov eax, white
    call SetTextColor
    mov edx, OFFSET msgMenu
    call WriteString
    mov edx, OFFSET msgHigh
    mov eax, highScore
    call PrintNum
    mov edx, OFFSET msgChoice
    call WriteString
    call ReadChar
    ret
ShowTitle ENDP

; ============================================================
; NewGame - resets all values and asks the player's name
; ============================================================
NewGame PROC
    cld
    ; copy starting stats into the player variables
    mov esi, OFFSET startStats
    mov edi, OFFSET pRow
    mov ecx, LENGTHOF startStats
    rep movsd

    ; copy the original map into the game map
    mov esi, OFFSET mapOriginal
    mov edi, OFFSET gameMap
    mov ecx, MAP_SIZE
    rep movsb

    call Clrscr
    mov edx, OFFSET msgAskName
    call WriteString
    mov edx, OFFSET playerName
    mov ecx, NAME_SIZE - 1
    call ReadString
    cmp eax, 0                   ; nothing typed?
    jne nameOk
    mov esi, OFFSET defaultName
    mov edi, OFFSET playerName
    mov ecx, LENGTHOF defaultName
    rep movsb
nameOk:
    call UpperName
    ret
NewGame ENDP

; ============================================================
; UpperName - changes the player name to capital letters
; ============================================================
UpperName PROC
    mov esi, OFFSET playerName
    mov edi, OFFSET playerName
    mov ecx, NAME_SIZE
    cld
upLoop:
    lodsb                        ; AL = next char
    cmp al, 'a'
    jb notSmall
    cmp al, 'z'
    ja notSmall
    and al, 11011111b            ; clear bit 5 -> capital letter
notSmall:
    stosb
    cmp al, 0                    ; stop at the end of the string
    loopnz upLoop
    ret
UpperName ENDP

; ============================================================
; PlayGame - main game loop
; ============================================================
PlayGame PROC
    mov gameWon, NO
gameLoop:
    call DrawScreen
    call ReadChar
    or al, 00100000b             ; set bit 5 -> small letter
    cmp al, '5'
    je usePotion
    cmp al, '6'
    je doSave
    cmp al, '7'
    jne notQuit
    ret                          ; back to the main menu
notQuit:

    ; is it a movement key? search it in moveKeys
    mov edi, OFFSET moveKeys
    mov ecx, LENGTHOF moveKeys
    cld
    repne scasb
    jne badKey
    mov esi, LENGTHOF moveKeys - 1
    sub esi, ecx                 ; ESI = index of the key
    mov ebx, rowChange[esi * TYPE rowChange]
    mov ecx, colChange[esi * TYPE colChange]
    call MovePlayer
    jmp checkEnd

badKey:
    mov edx, OFFSET msgInvalid
    call WriteString
    jmp pressKey
usePotion:
    call DrinkPotion
    jmp pressKey
doSave:
    call SaveGame
pressKey:
    call WaitKey

checkEnd:
    cmp hp, 0
    je playerLost
    cmp gameWon, YES
    jne gameLoop

    mov edx, OFFSET msgVictory   ; the Dragon is dead
    mov eax, yellow
    call EndScreen
    ret
playerLost:
    mov edx, OFFSET msgOver
    mov eax, lightRed
    call EndScreen
    ret
PlayGame ENDP

; ============================================================
; DrawScreen - prints the whole map, the stats and the menu
; ============================================================
DrawScreen PROC
    call Clrscr
    mov eax, yellow
    call SetTextColor
    mov edx, OFFSET msgTitle
    call PrintLn

    ; player index = pRow * COLS + pCol
    mov eax, pRow
    mov ebx, COLS
    mul ebx
    add eax, pCol
    mov playerIdx, eax

    ; ---- map: nested loops over rows and columns ----
    mov esi, 0                   ; index in gameMap
    mov ecx, ROWS
rowLoop:
    push ecx                     ; save outer loop counter
    mov ecx, COLS
colLoop:
    cmp esi, playerIdx
    jne notPlayer
    mov eax, yellow              ; draw the player
    call SetTextColor
    mov al, '@'
    call WriteChar
    jmp nextCol
notPlayer:
    mov al, gameMap[esi]
    call SetTileColor
    call WriteChar
nextCol:
    inc esi
    loop colLoop
    call Crlf
    pop ecx
    loop rowLoop

    call ShowStats
    mov edx, OFFSET msgKeys
    call WriteString
    ret
DrawScreen ENDP

; ============================================================
; ShowStats - prints all player information
; ============================================================
ShowStats PROC
    mov eax, white
    call SetTextColor
    mov edx, OFFSET msgName
    call WriteString
    mov edx, OFFSET playerName
    call WriteString
    mov edx, OFFSET msgLevel
    mov eax, level
    call PrintNum
    mov edx, OFFSET msgXP
    mov eax, xp
    call PrintNum
    mov edx, OFFSET msgGold
    mov eax, gold
    call PrintNumLn

    mov edx, OFFSET msgHP
    mov eax, hp
    call PrintNum
    mov edx, OFFSET msgSlash
    mov eax, maxHp
    call PrintNum
    mov al, ' '
    call WriteChar
    INVOKE ShowBar, hp, maxHp
    call Crlf

    mov edx, OFFSET msgAtk
    mov eax, attack
    call PrintNum
    mov edx, OFFSET msgDef
    mov eax, defense
    call PrintNum
    mov edx, OFFSET msgPotions
    mov eax, potions
    call PrintNum
    mov edx, OFFSET msgKey
    call WriteString
    mov edx, OFFSET msgNo
    test hasKey, 1
    jz showKey
    mov edx, OFFSET msgYes
showKey:
    call PrintLn

    mov edx, OFFSET msgScore
    mov eax, score
    call PrintNumLn
    ret
ShowStats ENDP

; ============================================================
; SetTileColor - sets the text color for the tile in AL
;                (AL is not changed)
; ============================================================
SetTileColor PROC USES eax ecx esi
    mov esi, 0
    mov ecx, LENGTHOF tileChars
findTile:
    cmp al, tileChars[esi]
    je foundTile
    inc esi
    loop findTile
    mov eax, lightCyan           ; not in the table ($ C +)
    jmp setIt
foundTile:
    mov eax, tileColors[esi * TYPE tileColors]
setIt:
    call SetTextColor
    ret
SetTileColor ENDP

; ============================================================
; ShowBar - draws an HP bar like [##########----------]
;   filled = value * BAR_SIZE / maxValue
; ============================================================
ShowBar PROC USES eax ebx ecx edx, value:DWORD, maxValue:DWORD
    LOCAL filled:DWORD

    mov eax, value
    mov ebx, BAR_SIZE
    mul ebx                      ; EDX:EAX = value * BAR_SIZE
    div maxValue                 ; EAX = filled part
    mov filled, eax

    mov al, '['
    call WriteChar
    mov ecx, filled
    cmp ecx, 0
    je emptyPart
fillLoop:
    mov al, '#'
    call WriteChar
    loop fillLoop
emptyPart:
    mov ecx, BAR_SIZE
    sub ecx, filled
    cmp ecx, 0
    je barDone
emptyLoop:
    mov al, '-'
    call WriteChar
    loop emptyLoop
barDone:
    mov al, ']'
    call WriteChar
    ret
ShowBar ENDP

; ============================================================
; MovePlayer - EBX = row change, ECX = column change
; ============================================================
MovePlayer PROC
    mov eax, pRow
    add eax, ebx
    mov newRow, eax
    mov eax, pCol
    add eax, ecx
    mov newCol, eax

    ; 2D array: row offset = newRow * COLS, column = newCol
    mov eax, newRow
    mov ebx, COLS
    mul ebx
    mov edi, eax                 ; EDI = row offset
    mov esi, newCol              ; ESI = column
    mov al, gameMap[edi+esi]     ; base-index addressing

    mov edx, OFFSET msgWall
    cmp al, '#'
    je showMsg
    mov edx, OFFSET msgWater
    cmp al, '~'
    je showMsg
    cmp al, 'B'
    je bossRoom

    ; the move is allowed
    mov ebx, newRow
    mov pRow, ebx
    mov ebx, newCol
    mov pCol, ebx
    inc steps
    inc score                    ; 1 point for every step

    cmp al, 'C'
    je openChest
    cmp al, 'K'
    je foundKey
    mov edx, OFFSET msgFountain
    cmp al, '+'
    je fountain
    cmp al, '$'
    jne normalGround
    call Shop
    ret

normalGround:                    ; maybe a random battle
    mov eax, 100
    call RandomRange             ; EAX = 0..99
    cmp eax, CHANCE
    jae moveDone
    call RandomBattle
moveDone:
    ret

bossRoom:
    mov edx, OFFSET msgLocked
    cmp hasKey, YES
    jne showMsg
    call BossBattle
    ret

fountain:
    mov ebx, maxHp
    mov hp, ebx
    jmp showMsg

foundKey:
    mov gameMap[edi+esi], '.'
    mov hasKey, YES
    add score, 50
    mov edx, OFFSET msgGotKey
    jmp showMsg

openChest:
    mov gameMap[edi+esi], '.'        ; chest is now empty
    mov eax, 21
    call RandomRange
    add eax, 10                  ; 10..30 gold
    add gold, eax
    add score, 20
    mov edx, OFFSET msgChest
    call PrintNum
    call WaitKey
    ret

showMsg:
    call WriteString
    call WaitKey
    ret
MovePlayer ENDP

; ============================================================
; RandomBattle - picks an enemy and starts the battle
;   enemies get stronger on the right side of the map
; ============================================================
RandomBattle PROC
    ; zone = column / 10   (0..3)
    mov eax, pCol
    mov edx, 0
    mov ebx, 10
    div ebx
    mov esi, eax

    ; index = zone + random(0..1), max 3
    mov eax, 2
    call RandomRange
    add esi, eax
    cmp esi, 3
    jbe indexOk
    mov esi, 3
indexOk:
    mov eax, enemyNames[esi * TYPE enemyNames]
    mov enemyName, eax

    ; copy the stats from the parallel arrays
    mov eax, enemyHPs[esi * TYPE enemyHPs]
    mov eHP, eax
    mov eax, enemyAtks[esi * TYPE enemyAtks]
    mov eAtk, eax
    mov eax, enemyXPs[esi * TYPE enemyXPs]
    mov eXP, eax
    mov eax, enemyGolds[esi * TYPE enemyGolds]
    mov eGold, eax

    ; enemy gets +5 HP for every player level
    mov eax, level
    mov ebx, 5
    mul ebx
    add eHP, eax

    mov isBoss, NO
    mov edx, OFFSET msgAppear
    call Battle
    ret
RandomBattle ENDP

; ============================================================
; BossBattle - sets up the Dragon and starts the battle
; ============================================================
BossBattle PROC
    mov enemyName, OFFSET bossName
    mov eHP, 180
    mov eAtk, 16
    mov eXP, 200
    mov eGold, 100
    mov isBoss, YES
    mov edx, OFFSET msgBossApp
    call Battle
    ret
BossBattle ENDP

; ============================================================
; Battle - turn based fight with the current enemy
;   EDX = intro message
; ============================================================
Battle PROC
    call Clrscr
    mov eax, lightRed
    call SetTextColor
    call WriteString             ; intro message
    mov edx, enemyName
    call PrintLn
battleLoop:
    mov edx, OFFSET msgLine
    call PrintLn
    mov edx, enemyName           ; enemy name and HP
    call WriteString
    mov edx, OFFSET msgEnemyHP
    mov eax, eHP
    call PrintNumLn
    mov edx, OFFSET msgYourHP    ; player HP
    mov eax, hp
    call PrintNumLn
    mov edx, OFFSET msgBattle
    call PrintLn

    call ReadChar
    cmp al, '1'
    je doAttack
    cmp al, '2'
    je doPotion
    cmp al, '3'
    jne battleLoop

    ; ---- run away (50%, not possible against the boss) ----
    cmp isBoss, YES
    je cannotRun
    mov eax, 2
    call RandomRange             ; 0 or 1
    cmp eax, 0
    jne cannotRun
    mov edx, OFFSET msgRan
    jmp endBattle
cannotRun:
    mov edx, OFFSET msgNoRun
    call PrintLn
    jmp enemyTurn

doPotion:
    call DrinkPotion
    jmp enemyTurn

doAttack:
    ; damage = CalcDamage(attack, 0)  (parameters on the stack)
    push 0                       ; enemies have no defense
    push attack
    call CalcDamage              ; EAX = damage
    add totalDmgLo, eax          ; 64-bit addition
    adc totalDmgHi, 0
    mov edx, OFFSET msgYouHit
    call PrintNumLn
    cmp eax, eHP
    jae enemyDead
    sub eHP, eax

enemyTurn:
    push defense
    push eAtk
    call CalcDamage              ; EAX = damage to the player
    mov edx, OFFSET msgHitsYou
    call PrintNumLn
    cmp eax, hp
    jae playerDead
    sub hp, eax
    jmp battleLoop

enemyDead:
    mov edx, OFFSET msgWin
    call PrintLn
    mov eax, eXP
    add xp, eax
    add score, eax
    mov eax, eGold
    add gold, eax
    inc kills
    cmp isBoss, YES
    jne notBoss
    mov gameWon, YES
    add score, 500
notBoss:
    call CheckLevelUp
    call WaitKey
    ret

playerDead:
    mov hp, 0
    mov edx, OFFSET msgDead
endBattle:
    call PrintLn
    call WaitKey
    ret
Battle ENDP

; ============================================================
; CalcDamage - uses a stack frame
;   [ebp+8]  = attack power
;   [ebp+12] = defense
;   damage = attack + random(0..attack/2) - defense/2
;   (minimum 1, 10% chance of double damage)
;   returns EAX = damage
; ============================================================
CalcDamage PROC
    push ebp
    mov ebp, esp
    push ebx

    mov eax, [ebp+8]
    shr eax, 1                   ; attack / 2
    inc eax
    call RandomRange             ; EAX = 0 .. attack/2
    add eax, [ebp+8]

    mov ebx, [ebp+12]
    shr ebx, 1                   ; defense / 2
    sub eax, ebx
    cmp eax, 1
    jge damageOk
    mov eax, 1                   ; at least 1 damage
damageOk:
    mov ebx, eax                 ; EBX = damage
    mov eax, 10
    call RandomRange
    cmp eax, 0                   ; 1 in 10 chance
    jne noCrit
    shl ebx, 1                   ; double damage
    mov edx, OFFSET msgCrit
    call PrintLn
noCrit:
    mov eax, ebx

    pop ebx
    pop ebp
    ret 8                        ; remove the 2 parameters
CalcDamage ENDP

; ============================================================
; CheckLevelUp - needs level*50 xp for the next level
; ============================================================
CheckLevelUp PROC
    mov eax, level
    mov ebx, 50
    mul ebx                      ; EAX = xp needed
    cmp xp, eax
    jb noLevelUp

    sub xp, eax
    inc level
    add maxHp, 20
    add attack, 3
    add defense, 2
    mov eax, maxHp
    mov hp, eax                  ; full HP on level up

    mov edx, OFFSET msgLevelUp
    mov eax, level
    call PrintNumLn
noLevelUp:
    ret
CheckLevelUp ENDP

; ============================================================
; DrinkPotion - heals POTION_HEAL HP (not more than maxHp)
; ============================================================
DrinkPotion PROC
    .IF potions == 0
        mov edx, OFFSET msgNoPot
        call PrintLn
    .ELSE
        dec potions
        mov eax, hp
        add eax, POTION_HEAL
        .IF eax > maxHp
            mov eax, maxHp
        .ENDIF
        mov hp, eax
        mov edx, OFFSET msgDrank
        call PrintNum
        call Crlf
    .ENDIF
    ret
DrinkPotion ENDP

; ============================================================
; Shop - buy potions and upgrades
;   prices[] is an array: 0 = potion, 1 = sword, 2 = armor
; ============================================================
Shop PROC
shopLoop:
    call Clrscr
    mov edx, OFFSET msgShop
    call WriteString
    mov edx, OFFSET msgGold
    mov eax, gold
    call PrintNumLn
    call Crlf

    ; print the 3 items with their prices
    mov esi, 0
    mov edx, OFFSET itemNames
itemLoop:
    mov eax, prices[esi * TYPE prices]
    call PrintNumLn
    add edx, ITEM_LEN            ; next item name
    inc esi
    cmp esi, 3
    jb itemLoop
    mov edx, OFFSET msgLeave
    call PrintLn

    call ReadChar
    cmp al, '4'
    je leaveShop
    cmp al, '1'
    jb shopLoop
    cmp al, '3'
    ja shopLoop

    sub al, '1'                  ; item number 0..2
    movzx ebx, al
    mov eax, prices[ebx * TYPE prices]
    mov edx, OFFSET msgNoMoney
    cmp gold, eax
    jb shopMsg
    sub gold, eax

    cmp ebx, 0
    je buyPotion
    cmp ebx, 1
    je buySword
    add defense, 2               ; item 2 = armor
    jmp priceUp
buySword:
    add attack, 3
priceUp:
    add prices[ebx * TYPE prices], 20   ; upgrades get more expensive
    jmp bought
buyPotion:
    inc potions
bought:
    mov edx, OFFSET msgBought
shopMsg:
    call WriteString
    call WaitKey
    jmp shopLoop

leaveShop:
    ret
Shop ENDP

; ============================================================
; SaveGame - writes "DUNG" + all player data + map to a file
; ============================================================
SaveGame PROC
    mov edx, OFFSET saveFile
    call CreateOutputFile
    mov fileHandle, eax
    mov edx, OFFSET msgSaveErr
    cmp eax, INVALID_HANDLE_VALUE
    je saveDone

    mov edx, OFFSET saveSig      ; header
    mov ecx, LENGTHOF saveSig
    call WriteToFile
    mov eax, fileHandle          ; data block
    mov edx, OFFSET saveStart
    mov ecx, SAVE_SIZE
    call WriteToFile
    mov eax, fileHandle
    call CloseFile
    mov edx, OFFSET msgSaved
saveDone:
    call WriteString
    ret
SaveGame ENDP

; ============================================================
; LoadGame - reads the save file back
;   returns EAX = 1 if loaded, 0 if not
; ============================================================
LoadGame PROC
    mov edx, OFFSET saveFile
    call OpenInputFile
    mov fileHandle, eax
    mov edx, OFFSET msgNoSave
    cmp eax, INVALID_HANDLE_VALUE
    je loadFail

    mov edx, OFFSET fileHeader   ; read the 4 byte header
    mov ecx, LENGTHOF fileHeader
    call ReadFromFile

    ; compare header with "DUNG"
    mov esi, OFFSET fileHeader
    mov edi, OFFSET saveSig
    mov ecx, LENGTHOF saveSig
    cld
    repe cmpsb
    jne badFile

    mov eax, fileHandle
    mov edx, OFFSET saveStart
    mov ecx, SAVE_SIZE
    call ReadFromFile
    cmp eax, SAVE_SIZE
    jne badFile

    mov eax, fileHandle
    call CloseFile
    mov eax, 1
    ret

badFile:
    mov eax, fileHandle
    call CloseFile
    mov edx, OFFSET msgBadSave
loadFail:
    call WriteString
    call WaitKey
    mov eax, 0
    ret
LoadGame ENDP

; ============================================================
; SaveToFile - writes a buffer to a new file
; ============================================================
SaveToFile PROC, fileName:PTR BYTE, dataAddr:PTR BYTE, dataSize:DWORD
    mov edx, fileName
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je writeFail
    mov fileHandle, eax
    mov edx, dataAddr
    mov ecx, dataSize
    call WriteToFile
    mov eax, fileHandle
    call CloseFile
writeFail:
    ret
SaveToFile ENDP

; ============================================================
; LoadHighScore - reads highscore.txt (a number as text)
; ============================================================
LoadHighScore PROC
    mov highScore, 0
    mov edx, OFFSET scoreFile
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je noScoreFile
    mov fileHandle, eax

    mov edx, OFFSET numBuffer
    mov ecx, LENGTHOF numBuffer - 1
    call ReadFromFile
    jnc readOk                   ; carry flag = read error
    mov eax, 0
readOk:
    mov numBuffer[eax], 0        ; end the string
    mov eax, fileHandle
    call CloseFile

    mov esi, OFFSET numBuffer
    call StrToInt
    mov highScore, eax
noScoreFile:
    ret
LoadHighScore ENDP

; ============================================================
; SaveHighScore - writes highScore as text into highscore.txt
; ============================================================
SaveHighScore PROC
    mov eax, highScore
    mov edi, OFFSET numBuffer
    call IntToStr                ; EDI now points after the last digit
    mov ecx, edi
    sub ecx, OFFSET numBuffer
    mov numLength, ecx
    INVOKE SaveToFile, ADDR scoreFile, ADDR numBuffer, numLength
    ret
SaveHighScore ENDP

; ============================================================
; IntToStr - RECURSIVE: converts EAX to decimal digits at [EDI]
;   example 345 -> IntToStr(34) then write '5'
; ============================================================
IntToStr PROC
    push eax
    push ebx
    push edx

    mov edx, 0
    mov ebx, 10
    div ebx                      ; EAX = number / 10, EDX = last digit
    cmp eax, 0
    je writeDigit
    call IntToStr                ; first write the other digits
writeDigit:
    add dl, '0'
    mov [edi], dl
    inc edi

    pop edx
    pop ebx
    pop eax
    ret
IntToStr ENDP

; ============================================================
; StrToInt - converts digits at [ESI] to a number in EAX
; ============================================================
StrToInt PROC USES ebx ecx edx esi
    mov eax, 0
convLoop:
    movzx ebx, BYTE PTR [esi]
    cmp bl, '0'
    jb convDone
    cmp bl, '9'
    ja convDone
    sub bl, '0'
    mov ecx, 10
    mul ecx                      ; EAX = EAX * 10
    add eax, ebx
    inc esi
    jmp convLoop
convDone:
    ret
StrToInt ENDP

; ============================================================
; EndScreen - game over or victory screen
;   EDX = message, EAX = color
; ============================================================
EndScreen PROC
    mov msgPtr, edx
    call Clrscr
    call SetTextColor
    mov edx, OFFSET msgLine
    call PrintLn
    mov edx, msgPtr
    call PrintLn
    mov edx, OFFSET msgLine
    call PrintLn

    call ShowStats
    mov edx, OFFSET msgKills
    mov eax, kills
    call PrintNum
    mov edx, OFFSET msgSteps
    mov eax, steps
    call PrintNumLn
    mov edx, OFFSET msgTotDmg
    mov eax, totalDmgLo          ; low 32 bits are enough to show
    call PrintNumLn

    ; new high score?
    mov eax, score
    cmp eax, highScore
    jbe notHigh
    mov highScore, eax
    call SaveHighScore
    mov edx, OFFSET msgNewHigh
    call PrintLn
notHigh:
    call WaitKey
    ret
EndScreen ENDP

; ============================================================
; small helper procedures
; ============================================================
PrintLn PROC                     ; prints string at EDX + new line
    call WriteString
    call Crlf
    ret
PrintLn ENDP

PrintNum PROC                    ; prints string at EDX + number in EAX
    call WriteString
    call WriteDec
    ret
PrintNum ENDP

PrintNumLn PROC                  ; same as PrintNum + new line
    call PrintNum
    call Crlf
    ret
PrintNumLn ENDP

WaitKey PROC                     ; waits for any key
    push eax
    push edx
    call Crlf
    mov edx, OFFSET msgAnyKey
    call WriteString
    call ReadChar
    pop edx
    pop eax
    ret
WaitKey ENDP

END main
