@echo off
setlocal
setlocal ENABLEDELAYEDEXPANSION

for /F "delims=" %%I in ("%~dp0..") do set git_install_root=%%~fI
set PATH=%git_install_root%\bin;%git_install_root%\mingw\bin;%git_install_root%\cmd;%PATH%

set opt_rebase=0
set opt_fixurl=0
set opt_recursive=0
set opt_gc=0
set opt_fsck=0

rem ****************************************************************************
rem * Parse command arguments
rem ****************************************************************************

:parse_args
if "%~1" == ""       goto :help
if "%~1" == "help"   goto :help
if "%~1" == "-help"  goto :help
if "%~1" == "--help" goto :help
if "%~1" == "msysgit-init" (
	set gitx_cmd=gitx_msysgit_init
	shift /1
	goto :parse_opts
)
if "%~1" == "msysgit-uninit" (
	set gitx_cmd=gitx_msysgit_uninit
	shift /1
	goto :parse_opts
)
if "%~1" == "svn-fetch" (
	set gitx_cmd=gitx_svn_fetch
	shift /1
	goto :parse_opts
)
if "%~1" == "submodule-fixup" (
	set gitx_cmd=gitx_submodule_fixup
	shift /1
	goto :parse_opts
)
if "%~1" == "subdir" (
	set gitx_cmd=gitx_subdir
	shift /1
	goto :parse_opts
)
echo Error: invalid command.
goto :EOF

:parse_opts
if "%~1" == "-help"  goto :help
if "%~1" == "--help" goto :help
if "%~1" == "--rebase" (
	set opt_rebase=1
	shift /1
	goto :parse_opts
)
if "%~1" == "--fixurl" (
	set opt_fixurl=1
	shift /1
	goto :parse_opts
)
if "%~1" == "--recursive" (
	set opt_recursive=1
	shift /1
	goto :parse_opts
)
if "%~1" == "--gc" (
	set opt_gc=1
	shift /1
	goto :parse_opts
)
goto :%gitx_cmd%

rem ****************************************************************************
rem * Show Help Message
rem ****************************************************************************
:help
echo Usage:
echo.    %~n0 msysgit-init
echo.    %~n0 msysgit-uninit
echo.    %~n0 svn-fetch [--rebase] [^<directory^>]
echo.    %~n0 submodule-fixup [--fixurl] [--recursive] [^<directory^>]
echo.    %~n0 subdir [--gc] ^<directory^> update
echo.    %~n0 subdir ^<directory^> "command-string"
echo.    %~n0 [help ^| -help ^| --help]
echo.
goto :EOF

rem ****************************************************************************
rem * Initialize msysgit environment
rem ****************************************************************************
:gitx_msysgit_init
fsutil >nul 2>nul
if %errorlevel% neq 0 (
	echo User privilege is insufficient.
	echo Please run this script As Administrator.
	echo.
	pause
	goto :EOF
)
pushd %git_install_root%\cmd >nul
call :gmi_upgrade
call :gmi_config
call :gmi_add_custom_cacerts
call :gmi_set_all_loaders
popd
goto :EOF

:gmi_upgrade
if exist CustomCA.crt       ren CustomCA.crt custom-ca-bundle.crt >nul 2>nul
if exist git-config-win.cmd rm -f git-config-win.cmd git-svn-fetch.cmd git-update-dir.cmd
goto :EOF

:gmi_config
if not exist default mkdir default >nul
if exist git.cmd  move /y git.cmd  default\git.cmd  >nul
if exist gitk.cmd move /y gitk.cmd default\gitk.cmd >nul
call :gmi_copy_def custom-ca-bundle.crt custom-ca-bundle.def
call :gmi_copy_def git-ldr.ini          git-ldr.def
call :gmi_copy_def git-config-init.cmd  git-config-init.def
goto :EOF

:gmi_copy_def
if not exist %1 copy %2 %1 >nul 2>nul
if exist %2 move /y %2 default\%2 >nul
goto :EOF

rem #--------- Add Custom CA certificates into "curl-ca-bundle.crt".
:gmi_add_custom_cacerts
call :gmi_update_ca_bundle ..\bin\curl-ca-bundle.crt
call :gmi_update_ca_bundle ..\mingw\bin\curl-ca-bundle.crt
goto :EOF
:gmi_update_ca_bundle
set curl-ca-bundle=%1
if not exist %curl-ca-bundle% goto :EOF
sed -e "/^===== Begin Custom CA =====$/,/^===== End Custom CA =====$/d" %curl-ca-bundle:\=/% > %curl-ca-bundle%.tmp
if not exist %curl-ca-bundle%.tmp goto :EOF
call :chmod_644 %curl-ca-bundle%
del %curl-ca-bundle%
copy %curl-ca-bundle%.tmp %curl-ca-bundle% >nul
del %curl-ca-bundle%.tmp
type custom-ca-bundle.crt >> %curl-ca-bundle%
goto :EOF

rem #--------- Set Git command agent.
:gmi_set_all_loaders
call :gmi_set_git_loader gitk.exe
call :gmi_set_git_loader git-receive-pack.exe
call :gmi_set_git_loader git-upload-archive.exe
call :gmi_set_git_loader git-upload-pack.exe
goto :EOF

:gmi_set_git_loader
if exist %1 del %1
call :get_osver
if %get_osver_result% geq 6.0 (
	mklink %1 git.exe >nul
) else (
	copy /y git.exe %1 >nul
)
goto :EOF

rem ****************************************************************************
rem * Uninitialize msysgit environment
rem ****************************************************************************
:gitx_msysgit_uninit
fsutil >nul 2>nul
if %errorlevel% neq 0 (
	echo User privilege is insufficient.
	echo Please run this script As Administrator.
	echo.
	pause
	goto :EOF
)
pushd %git_install_root%\cmd >nul
rm -f git?*.exe
if exist default\git.cmd  move /y default\git.cmd  git.cmd  >nul
if exist default\gitk.cmd move /y default\gitk.cmd gitk.cmd >nul
call :gmu_remove_def custom-ca-bundle.crt custom-ca-bundle.def
call :gmu_remove_def git-ldr.ini          git-ldr.def
call :gmu_remove_def git-config-init.cmd  git-config-init.def
rd default >nul 2>nul
popd
goto :EOF

:gmu_remove_def
if exist default\%2 move /y default\%2 %2 >nul
cmp %1 %2 >nul 2>nul
if %errorlevel% equ 0 del %1
goto :EOF

rem ****************************************************************************
rem * Git SVN fetch
rem ****************************************************************************
:gitx_svn_fetch
set GSVNF_LOGFILE="_.gitsvn$.log"
if "%~1" == "" (set gsvnf_repo_dir=.) else (set gsvnf_repo_dir=%1)
if %opt_rebase% equ 1 (
	call :gsvnf_rebase %gsvnf_repo_dir%
) else (
	call :gsvnf_fetch %gsvnf_repo_dir%
)
goto :EOF

rem # function :gsvnf_fetch("directory")
:gsvnf_fetch
pushd %1 > nul
:gsvnf_loop
git svn fetch > %GSVNF_LOGFILE%
if %errorlevel% neq 0 goto :gsvnf_error
type %GSVNF_LOGFILE%
for %%i in (%GSVNF_LOGFILE%) do if %%~zi equ 0 goto :gsvnf_success
goto :gsvnf_loop
:gsvnf_success
set errorlevel=0
goto :gsvnf_exit
:gsvnf_error
set errorlevel=-1
:gsvnf_exit
if exist %GSVNF_LOGFILE% del %GSVNF_LOGFILE%
popd
goto :EOF

rem # function :gsvnf_rebase("directory")
:gsvnf_rebase
if not exist "%~1\.git\svn" (
	set errorlevel=-1
	goto :EOF
)
pushd %1 > nul
git svn rebase
popd
goto :EOF

rem ****************************************************************************
rem * Fixup sumodule path
rem ****************************************************************************
:gitx_submodule_fixup
set GSF_TMPFILE=config$$$
if "%~1" == "" (set rootdir=.) else (set rootdir=%~1)
set rootdir=%rootdir:\=/%

if not exist "%rootdir%/.git/config" goto :EOF
call :gsf_update_repository "%rootdir%" "%rootdir%/.git"
goto :EOF

rem # function gsf_update_repository("working_dir", "repository_dir")
:gsf_update_repository
if not exist "%~1/.gitmodules" goto :EOF
set module_state=-1
for /f "usebackq eol=# tokens=1,2 delims==<TAB> " %%i in ("%~1/.gitmodules") do (
	call :gsf_trim %%i
	set var_name=!gsf_trim_result!
	call :gsf_trim %%j
	set var_value=!gsf_trim_result!

	if "!var_name!" == "submodule" (
		set module_name=!var_value!
		set /a module_state=2
	)
	if "!var_name!" == "path" (
		set module_path=!var_value:\=/!
		set /a module_state=!module_state!-1
	)
	if "!var_name!" == "url" (
		set module_url=!var_value!
		set /a module_state=!module_state!-1
	)
	
	if !module_state! equ 0 (
		call :gsf_update_submodule %1 %2
		set module_state=-1
	)
)
goto :EOF

rem # function gsf_update_submodule("working_dir", "repository_dir")
:gsf_update_submodule
echo Updating [%module_name%] ......
echo.    [%~1/%module_path%/]
echo.    path = "%module_path%"
echo.    url  = %module_url%

if not exist "%~2/modules/%module_path%/config" goto :EOF

rem #--------- Get submodule reporitory directory.
pushd "%~2/modules/%module_path%" >nul
for /f %%i in ('cd') do set gitdir=%%i
set gitdir=%gitdir:\=/%
popd

rem #--------- Update .git file in submodule working directory.
if not exist "%~1/%module_path%/" (
	mkdir "%~1/%module_path%" >nul 2>nul
	if %errorlevel% neq 0 (
		echo Error: can not make direcotry "%module_path%/".
		goto :EOF
	)
)
echo gitdir: %gitdir%> "%~1/%module_path%/.git"

rem #--------- Get submodule working directory.
pushd "%~1/%module_path%" >nul
for /f %%i in ('cd') do set worktree=%%i
set worktree=%worktree:\=/%
popd

rem #--------- Update config of submodule repository.
pushd "%~2/modules/%module_path%" >nul
sed -e 's/^\([[:space:]]*worktree[[:space:]]*=[[:space:]]*\).*$/\1%worktree:/=\/%/' config > %GSF_TMPFILE%
if not exist %GSF_TMPFILE% (
	echo Error: can not write "%~2/modules/%module_path%".
	popd
	goto :EOF
)
copy %GSF_TMPFILE% config >nul
del %GSF_TMPFILE% >nul
git config --local core.worktree %worktree%
set origin_url=
set upstream_url=
for /f %%i in ('git config --local remote.origin.url')   do set origin_url=%%i
for /f %%i in ('git config --local remote.upstream.url') do set upstream_url=%%i
if not "%origin_url%" == "" (
	if %opt_fixurl% equ 1 (
		git config --local remote.origin.url %module_url%
		set origin_url=%module_url%
	)
	echo.    remote.origin.url =
	echo.        !origin_url!
)
if not "%upstream_url%" == "" (
	echo.    remote.upstream.url =
	echo.        %upstream_url%
)
popd

rem #--------- Update submodule url.
pushd "%~2" >nul
git config --local submodule.%module_name%.url %module_url%
popd
echo.

rem #--------- Traverse submodules recursively.
if %opt_recursive% equ 1 (
	pushd "%module_path%/" >nul
	call :gsf_update_repository "%~1/%module_path%" "%~2/modules/%module_path%"
	popd
)
goto :EOF

rem # function gsf_trim("string")
:gsf_trim
set gsf_trim_result=%~1
set gsf_trim_result=%gsf_trim_result:"=%
set gsf_trim_result=%gsf_trim_result:[=%
set gsf_trim_result=%gsf_trim_result:]=%
call :trim "%gsf_trim_result%"
set gsf_trim_result=%trim_result%
goto :EOF

rem ****************************************************************************
rem * Do a git command for a specified directory and all of its sub-directories.
rem ****************************************************************************
:gitx_subdir
if "%~1" == "" goto :EOF
set rootdir=%1
shift /1

if "%~1" == "" goto :EOF
if "%~1" == "update" (
	if %opt_gc% equ 1 (goto :gsd_update_gc) else (goto :gsd_update_only)
) else (
	set CMDLINE=%1 %2 %3 %4 %5 %6 %7 %8 %9
	goto :gsd_cmd
)

:gsd_update_only
set UPDATE_WITH_GC=0
set SVN_CMD=:gsd_svn_fetch
set GIT_CMD=:gsd_remote_update
call :gsd_process_dir %rootdir%
goto :EOF

:gsd_update_gc
set UPDATE_WITH_GC=1
set SVN_CMD=:gsd_svn_fetch
set GIT_CMD=:gsd_remote_update
call :gsd_process_dir %rootdir%
goto :EOF

:gsd_cmd
set SVN_CMD=:gsd_dir_cmd
set GIT_CMD=:gsd_dir_cmd
call :gsd_process_dir %rootdir%
goto :EOF

rem # function :gsd_process_dir(dir)
:gsd_process_dir
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
	call :gsd_enum_sub_dirs "%~1\*.*"
) else (
	call :gsd_enum_sub_dirs "%~1"
)
goto :EOF

rem # function :gsd_enum_sub_dirs("directory")
:gsd_enum_sub_dirs
for /d %%i in (%1) do (
	if not "%~1" == "." (rem) if not "%~1" == ".." (rem) if not "%~1" == ".git" (rem) (
		call :gsd_process_dir "%%~i"
	)
)
goto :EOF

rem # function :gsd_svn_fetch("directory")
:gsd_svn_fetch
echo.
echo --------------------------------------------------
echo %~1
echo --^> Fetching...
call :gitx_svn_fetch %1
if exist "%~1\.git\svn" (
echo --^> Rebasing...
	set opt_rebase=1
	call :gitx_svn_fetch %1
	set opt_rebase=0
)
if %UPDATE_WITH_GC% equ 1 (
	echo --^> Packing  ...
	call :gsd_do_cmd %1 gc
)
call :gsd_do_cmd %1 update-server-info
goto :EOF

rem ***** function :gsd_remote_update("directory")
:gsd_remote_update
echo.
echo --------------------------------------------------
echo %~1
echo --^> Fetching ...
call :gsd_do_cmd %1 remote update
if %UPDATE_WITH_GC% equ 1 (
	echo --^> Packing  ...
	call :gsd_do_cmd %1 gc
)
call :gsd_do_cmd %1 update-server-info
goto :EOF

rem # function :gsd_dir_cmd("directory")
:gsd_dir_cmd
echo.
echo --------------------------------------------------
echo %~1
call :gsd_do_cmd %1 %CMDLINE%
goto :EOF

rem # function :gsd_do_cmd("directory", ...)
:gsd_do_cmd
pushd %1
git %2 %3 %4 %5 %6 %7 %8 %9
popd
goto :EOF

rem ****************************************************************************
rem * Utilities
rem ****************************************************************************

rem # function :trim("string")
:trim
set trim_result=%~1
call :trim_left "%trim_result%"
call :trim_right "%trim_left_result%"
set trim_rsult=%trim_right_result%
goto :EOF

rem # function :trim_left("string")
:trim_left
set trim_left_result=%~1
for /f "tokens=*" %%i in ("%trim_left_result%") do set trim_left_result=%%i
goto :EOF

rem # function :trim_right("string")
:trim_right
set trim_right_result=%~1
:_trim_right_loop
set trim_right_char=%trim_right_result:~-1%
if "%trim_right_char%" == "" goto :EOF
if not "%trim_right_char%" == " " (if not "%trim_right_char%" == "	" goto :EOF)
set trim_right_result=%trim_right_result:~0,-1%
goto :_trim_right_loop

rem # function :chmod_644("file")
:chmod_644
icacls %1 /reset >nul 2>nul
if %errorlevel% neq 0 cacls %1 /C /E /G SYSTEM:F administrators:F everyone:R >nul
attrib -R %1
goto :EOF

rem # function :get_osver()
:get_osver
rem #--------- Default OS is Windows 2000
set get_osver_result=5.0
for /f "usebackq" %%i in (`ver ^| sed -e "/^$/d;s/^.*[^0-9\.]\([0-9]\+\.[0-9\.]\+\)[^0-9\.].*$/\1/"`) do set get_osver_result=%%i
goto :EOF
