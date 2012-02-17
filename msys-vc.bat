@echo off

if not exist ..\msvcgit\setup_32bit_env.cmd (
	echo "..\msvcgit\setup_32bit_env.cmd" is not found.
	goto :EOF
)

rem set VCVARSCMD="%VS100COMNTOOLS%\..\..\VC\vcvarsall.bat"
rem if exist %VCVARSCMD% goto :vcinit

set VCVARSCMD="%VS90COMNTOOLS%\..\..\VC\vcvarsall.bat"
if exist %VCVARSCMD% goto :vcinit

set VCVARSCMD="%VS80COMNTOOLS%\..\..\VC\vcvarsall.bat"
if exist %VCVARSCMD% goto :vcinit

echo <VSInstallDir>\VC\vcvarsall.bat is not found.
goto :EOF

:vcinit
call %VCVARSCMD% x86
call ..\msvcgit\setup_32bit_env.cmd
set MSVC=1
rem set DEBUG=1

call .\msys.bat
