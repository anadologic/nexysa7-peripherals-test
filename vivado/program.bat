@echo off
setlocal

set VIVADO=F:\Xilinx\Vivado\2023.1\bin\vivado.bat
set SCRIPT_DIR=%~dp0

"%VIVADO%" -mode batch -source "%SCRIPT_DIR%program.tcl"
