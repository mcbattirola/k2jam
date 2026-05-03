@echo off
setlocal

odin run src\karl2d\build_web -- src -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

if exist out\web rmdir /s /q out\web
if not exist out mkdir out
move src\bin\web out\web
IF %ERRORLEVEL% NEQ 0 exit /b 1

rmdir src\bin 2>NUL
