@echo off
setlocal
set LOGFILE="_.gitsvn$.log"

goto :start
:help
echo Usage:
echo    %~n0 [--rebase] [repository]
echo    %~n0 [-help ^| --help]
goto :EOF

:start
if "%~1" == "-help"    goto :help
if "%~1" == "--help"   goto :help
if "%~1" == "--rebase" goto :rebase
goto :fetch

:fetch
if "%~1" == "" (call :git_svn_fetch .) else (call :git_svn_fetch %1)
goto :EOF

:rebase
if "%~2" == "" (call :git_svn_rebase .) else (call :git_svn_rebase %2)
goto :EOF

rem ***** function :git_svn_fetch(repository_dir)
:git_svn_fetch
pushd %1 > nul
:gsf_loop
git svn fetch > %LOGFILE%
if not errorlevel 0 goto :gsf_error
type %LOGFILE%
for %%i in (%LOGFILE%) do if %%~zi equ 0 goto :gsf_success
goto :gsf_loop
:gsf_success
set errorlevel=0
goto :gsf_exit
:gsf_error
set errorlevel=-1
:gsf_exit
if exist %LOGFILE% del %LOGFILE%
popd
goto :EOF

rem ***** function :git_svn_rebase(repository_dir)
:git_svn_rebase
if not exist "%~1\.git\svn" (
	set errorlevel=-1
	goto :EOF
)
pushd %1 > nul
git svn rebase
popd
goto :EOF
