@echo off
REM   2011-08-28, Ver 0.1.01
REM   Companion batch file for map2kap.rb (Version 0.2.20 and higher)
REM   to allow drag&drop of files

echo "%CD%"
map2kap.rb %*
echo.
pause