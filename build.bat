@echo off
REM ------------------------------------------------------------------
REM  Build Dungeon of Assembly from the command line.
REM  Run from "x86 Native Tools Command Prompt for VS" (ml.exe + link.exe).
REM ------------------------------------------------------------------
set IRVINE=C:\Irvine

ml /nologo /c /coff /Zi /I"%IRVINE%" DungeonRPG.asm
if errorlevel 1 goto failed

link /nologo /SUBSYSTEM:CONSOLE /DEBUG /LIBPATH:"%IRVINE%" DungeonRPG.obj Irvine32.lib Kernel32.lib User32.lib /OUT:DungeonRPG.exe
if errorlevel 1 goto failed

echo.
echo Build succeeded: DungeonRPG.exe
goto end

:failed
echo.
echo Build FAILED.
:end
