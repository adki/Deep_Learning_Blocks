@ECHO OFF
REM CLS

SET TOP=test

IF EXIST %TOP%.ncb DEL /q %TOP.ncb
IF EXIST %TOP%.ilk DEL /q %TOP.ilk
IF EXIST %TOP%.plg DEL /q %TOP.plg
IF EXIST %TOP%.opt DEL /q %TOP.opt
IF EXIST %TOP%.exe DEL /q %TOP%.exe
IF EXIST %TOP%.exe.stackdump DEL /q %TOP%.exe.stackdump
IF EXIST Debug        RMDIR /s/q Debug
IF EXIST *.o          DEL /q *.o
IF EXIST obj          RMDIR /s/q obj
