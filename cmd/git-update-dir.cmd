@echo off
setlocal

goto :start
:help
echo Usage:
echo    %~n0 [--gc] directory
echo    %~n0 --fsck directory
echo    %~n0 [-help ^| --help]
goto :EOF

:start
if "%~1" == "-help"  goto :help
if "%~1" == "--help" goto :help
if "%~1" == "--fsck" goto :_git_fsck
if "%~1" == "--gc"   goto :_git_update_gc

:_git_update_only
if "%~1" == "" goto :help
set UPDATE_WITH_GC=0
set SVN_CMD=:git_svn_fetch
set GIT_CMD=:git_remote_update
call :git_process_dir %1
goto :EOF

:_git_update_gc
if "%~2" == "" goto :help
set UPDATE_WITH_GC=1
set SVN_CMD=:git_svn_fetch
set GIT_CMD=:git_remote_update
call :git_process_dir %2
goto :EOF

:_git_fsck
if "%~2" == "" goto :help
set SVN_CMD=:git_fsck
set GIT_CMD=:git_fsck
call :git_process_dir %2
goto :EOF

rem ***** function :git_process_dir(dir)
:git_process_dir
if exist "%~1\.git\svn" (
	call %SVN_CMD% "%~1"
	goto :EOF
)
if exist "%~1\objects\info" (
	if exist "%~1\refs\heads" (
		if exist "%~1\svn" (
		 	call %SVN_CMD% "%~1"
		) else (
			call %GIT_CMD% "%~1"
		)
		goto :EOF
	)
)
if exist "%~1\.git" (
	call %GIT_CMD% "%~1"
)
if exist "%~1\*.*" (
	call :git_enum_sub_dirs "%~1\*.*"
) else (
	call :git_enum_sub_dirs "%~1"
)
goto :EOF

rem ***** function :git_enum_sub_dirs(dir)
:git_enum_sub_dirs
for /d %%i in (%1) do (
	if not "%~1" == "." (rem) if not "%~1" == ".." (rem) if not "%~1" == ".git" (rem) (
		call :git_process_dir "%%~i"
	)
)
goto :EOF

rem ***** function :git_svn_fetch(dir)
:git_svn_fetch
echo.
echo --------------------------------------------------
echo %~1
echo --^> Rebasing...
if exist "%~1\.git\svn" (
	call :git_do_cmd %1 svn rebase
) else (
	call :git_do_cmd %1 svn fetch
)
if %UPDATE_WITH_GC% equ 1 (
	echo --^> Packing  ...
	call :git_do_cmd %1 gc
)
call :git_do_cmd %1 update-server-info
goto :EOF

rem ***** function :git_remote_update(dir)
:git_remote_update
echo.
echo --------------------------------------------------
echo %~1
echo --^> Fetching ...
call :git_do_cmd %1 remote update
if %UPDATE_WITH_GC% equ 1 (
	echo --^> Packing  ...
	call :git_do_cmd %1 gc
)
call :git_do_cmd %1 update-server-info
goto :EOF

rem ***** function :git_fsck(dir)
:git_fsck
echo.
echo --------------------------------------------------
echo %~1
echo --^> Fscking  ...
call :git_do_cmd %1 fsck
goto :EOF

rem ***** function :git_do_cmd(dir, ...)
:git_do_cmd
pushd %1
git %2 %3 %4 %5 %6 %7 %8 %9
popd
goto :EOF
