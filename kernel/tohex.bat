@echo off & setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set LOOKUP=0123456789abcdef &set HEXSTR=&set PREFIX=
if "%1"=="" echo 0&goto :EOF
set /a A=%* || exit /b 1
if !A! LSS 0 set /a A=0xfffffff + !A! + 1 & set PREFIX=f
:loop
set /a B=!A! %% 16 & set /a A=!A! / 16
set HEXSTR=!LOOKUP:~%B%,1!%HEXSTR%
if %A% GTR 0 goto :loop
echo %PREFIX%%HEXSTR%
goto :EOF
