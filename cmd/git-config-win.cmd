@echo off
setlocal
goto :git_config_win

:git-config
rem *********************** Set global user name and email.
rem git config --global user.name "Your Name"
rem git config --global user.email your-name@email.com
rem *********************** Windows CRLF
rem git config --global core.autocrlf true
rem git config --global core.safecrlf false
rem *********************** Show Chinese log. Choose encoding method for other languages.
rem git config --global i18n.logoutputencoding gbk
goto :EOF

:add_custom_cacerts
rem *********************** Add Custom CA certificates into "curl-ca-bundle.crt".
call :update_ca_bundle ..\bin\curl-ca-bundle.crt
call :update_ca_bundle ..\mingw\bin\curl-ca-bundle.crt
goto :EOF
:update_ca_bundle
set curl-ca-bundle=%1
if not exist %curl-ca-bundle% goto :EOF
call :chmod_644 %curl-ca-bundle%
sed -i -e '/^===== Begin Custom CA =====$/,/^===== End Custom CA =====$/d' %curl-ca-bundle:\=/%
cat CustomCA.crt >> %curl-ca-bundle%
call :chmod_644 %curl-ca-bundle%
goto :EOF

:set_all_loaders
rem *********************** Set Git command agent.
call :set_git_loader gitk.exe
call :set_git_loader git-receive-pack.exe
call :set_git_loader git-upload-archive.exe
call :set_git_loader git-upload-pack.exe
goto :EOF


:set_git_loader
copy /y git.exe %1 >nul
goto :EOF

:chmod_644
icacls %1 /reset >nul 2>nul
if %errorlevel% neq 0 cacls %1 /C /E /G SYSTEM:F administrators:F everyone:R >nul
attrib -R %1
goto :EOF

:git_config_win
for /F "delims=" %%I in ("%~dp0..") do set git_install_root=%%~fI
set PATH=%git_install_root%\bin;%git_install_root%\mingw\bin;%git_install_root%\cmd;%PATH%
pushd %git_install_root%\cmd >nul
call :git-config
call :add_custom_cacerts
call :set_all_loaders
popd >nul
goto :EOF
