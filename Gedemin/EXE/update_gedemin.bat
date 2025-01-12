@echo off
setlocal

echo *************************************************
echo **                                             **
echo **  Usage:                                     **
echo **  update_gedemin {/ftp /no_ftp} {/d /p /l}   **
echo **    [ver_file.rc] [new_exe_size]             **
echo **                                             **
echo *************************************************

if "%2"=="" goto exit

if NOT exist d:\nul subst d: k:\

set RegQry=HKLM\Hardware\Description\System\CentralProcessor\0
reg.exe Query %RegQry% > checkOS.txt
find /i "x86" < CheckOS.txt > StringCheck.txt
 
if %ERRORLEVEL% == 0 (
  goto os32
) else (
  goto os64
)

:os32
set delphi_path=C:\Program Files\Borland\Delphi5\Bin
goto path_is_set

:os64
set delphi_path=C:\Program Files (x86)\Borland\Delphi5\Bin

:path_is_set

del StringCheck.txt
del CheckOS.txt

set starteam_connect=Andreik:1@india:49201

if "%2"=="/d" goto make_debug 

set gedemin_cfg=gedemin.product.cfg
set gedemin_upd_cfg=gedemin_upd.product.cfg
set gdcc_cfg=gdcc.product.cfg
set gudf_cfg=gudf.product.cfg
set compiler_switch=-b
set arc_name=gedemin.rar
set gudf_arc_name=gudf.rar
set etalon_arc_name=etalon.rar
set full_etalon_name=k:\golden\gedemin\exe\etalon.fdb
set target_dir=beta

if "%2"=="/l" set gedemin_cfg=gedemin.lock.cfg
if "%2"=="/l" set arc_name=gedemin_lock.rar
if "%2"=="/l" set target_dir=lock

goto start_process

:make_debug
set gedemin_cfg=gedemin.debug.cfg
set gedemin_upd_cfg=gedemin_upd.debug.cfg
set gdcc_cfg=gdcc.product.cfg
set gudf_cfg=gudf.debug.cfg
set compiler_switch=-b -vt
set arc_name=gedemin_debug.rar
set gudf_arc_name=gudf_debug.rar
set etalon_arc_name=etalon.rar
set full_etalon_name=k:\golden\gedemin\exe\etalon.fdb
set target_dir=debug

:start_process

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Check out latest sources                   **
echo **                                             **
echo *************************************************

if not exist "c:\program files\StarBase\StarTeam 5.3\stcmd.exe" goto pull_from_git

"c:\program files\StarBase\StarTeam 5.3\stcmd" co -p "%starteam_connect%/Gedemin" -is -x -stop -f NCO -nologo -q
"c:\program files\StarBase\StarTeam 5.3\stcmd" co -p "%starteam_connect%/Comp5"   -is -x -stop -f NCO -nologo -q

goto sources_checked_out

:pull_from_git

cd ..\..
git checkout beta
git pull
cd gedemin\exe

:sources_checked_out

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Remove old DCUs                            **
echo **                                             **
echo *************************************************

cd ..\dcu
del *.dcu
cd ..\exe

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Increment version number                   **
echo **                                             **
echo *************************************************

if "%3"=="" incverrc.exe ..\gedemin\gedemin_ver.rc

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Prepare .cfg files                         **
echo **                                             **
echo *************************************************

cd ..\gedemin
copy gedemin.cfg gedemin.current.cfg /y
copy %gedemin_cfg% gedemin.cfg /y

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Compile resources                          **
echo **                                             **
echo *************************************************

del gedemin.res
"%delphi_path%\brcc32.exe" -fogedemin.res -i..\images gedemin.rc
if not exist gedemin.res eventcreate /t error /id 1 /l application /so gedemin /d "gedemin.res compilation error"

del gedemin_ver.res
if "%3"=="" (
  "%delphi_path%\brcc32.exe" -fogedemin_ver.res -i..\images gedemin_ver.rc
) else (
  "%delphi_path%\brcc32.exe" -fogedemin_ver.res -i..\images %3
)
if not exist gedemin_ver.res eventcreate /t error /id 1 /l application /so gedemin /d "gedemin_ver.res compilation error"

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Compile gedemin.exe                        **
echo **                                             **
echo *************************************************

del ..\exe\gedemin.exe

if exist ..\exe\gedemin.exe eventcreate /t error /id 1 /l application /so gedemin /d "Can not delete gedemin.exe"
if exist ..\exe\gedemin.exe goto exit

"%delphi_path%\dcc32.exe" %compiler_switch% gedemin.dpr

if not exist ..\exe\gedemin.exe eventcreate /t error /id 1 /l application /so gedemin /d "gedemin.exe compilation error"
if not exist ..\exe\gedemin.exe pause

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Restore .cfg files                         **
echo **                                             **
echo *************************************************

copy gedemin.current.cfg gedemin.cfg /y
del gedemin.current.cfg > nul

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Strip relocation information               **
echo **                                             **
echo *************************************************

cd ..\exe
stripreloc /b gedemin.exe

if "%2"=="/p" goto skip_optimize_debug 
if "%2"=="/l" goto skip_optimize_debug 

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Optimize debug information                 **
echo **                                             **
echo *************************************************

tdspack -e -o -a gedemin.exe

:skip_optimize_debug

echo *************************************************
echo **                                             **
echo **  Prevent C0000006 exception                 **
echo **                                             **
echo *************************************************

editbin /SWAPRUN:NET gdcc.exe
editbin /SWAPRUN:NET gedemin.exe
editbin /SWAPRUN:NET gedemin_upd.exe

if "%4"=="" goto skip_set_exe_size

setexesize gedemin.exe %4

if not exist gedemin.exe goto exit

:skip_set_exe_size

echo *************************************************
echo **                                             **
echo **  gedemin_upd:                               **
echo **  Prepare .cfg files                         **
echo **                                             **
echo *************************************************

cd ..\gedemin
copy gedemin_upd.cfg gedemin_upd.current.cfg /y
copy %gedemin_upd_cfg% gedemin_upd.cfg /y

echo *************************************************
echo **                                             **
echo **  gedemin_upd:                               **
echo **  Compile gedemin_upd.exe                    **
echo **                                             **
echo *************************************************

del ..\exe\gedemin_upd.exe

if exist ..\exe\gedemin_upd.exe eventcreate /t error /id 1 /l application /so gedemin /d "Can not delete gedemin_upd.exe"
if exist ..\exe\gedemin_upd.exe goto exit

"%delphi_path%\brcc32.exe" -fogedemin_upd_ver.res -i..\images gedemin_upd_ver.rc
"%delphi_path%\dcc32.exe" %compiler_switch% gedemin_upd.dpr

if not exist ..\exe\gedemin_upd.exe eventcreate /t error /id 1 /l application /so gedemin /d "gedemin_upd.exe compilation error"

echo *************************************************
echo **                                             **
echo **  gedemin_upd:                               **
echo **  Restore .cfg files                         **
echo **                                             **
echo *************************************************

copy gedemin_upd.current.cfg gedemin_upd.cfg /y
del gedemin_upd.current.cfg > nul

rem pause

echo *************************************************
echo **                                             **
echo **  gdcc:                                      **
echo **  Prepare .cfg files                         **
echo **                                             **
echo *************************************************

cd ..\gedemin
copy gdcc.cfg gdcc.current.cfg /y
copy %gdcc_cfg% gdcc.cfg /y

echo *************************************************
echo **                                             **
echo **  gdcc:                                      **
echo **  Compile gdcc.exe                           **
echo **                                             **
echo *************************************************

"%delphi_path%\brcc32.exe" -fogdcc_ver.res -i..\images gdcc_ver.rc

del ..\exe\gdcc.exe

if exist ..\exe\gdcc.exe goto no_gdcc_compilation

"%delphi_path%\dcc32.exe" %compiler_switch% gdcc.dpr

if not exist ..\exe\gdcc.exe eventcreate /t error /id 1 /l application /so gedemin /d "gdcc.exe compilation error"

:no_gdcc_compilation

echo *************************************************
echo **                                             **
echo **  gdcc:                                      **
echo **  Restore .cfg files                         **
echo **                                             **
echo *************************************************

copy gdcc.current.cfg gdcc.cfg /y
del gdcc.current.cfg > nul

rem pause

echo *************************************************
echo **                                             **
echo **  gudf.dll:                                  **
echo **  Prepare .cfg files                         **
echo **                                             **
echo *************************************************

cd ..\gudf
copy gudf.cfg gudf.current.cfg /y
copy gudf.product.cfg gudf.cfg /y

echo *************************************************
echo **                                             **
echo **  gudf.dll:                                  **
echo **  Compile gudf.dll                           **
echo **                                             **
echo *************************************************

del ..\exe\udf\gudf.dll
"%delphi_path%\dcc32.exe" %compiler_switch% gudf.dpr

if not exist ..\exe\udf\gudf.dll eventcreate /t error /id 1 /l application /so gedemin /d "gudf.dll compilation error"

echo *************************************************
echo **                                             **
echo **  gudf.dll:                                  **
echo **  Restore .cfg files                         **
echo **                                             **
echo *************************************************

copy gudf.current.cfg gudf.cfg /y
del gudf.current.cfg > nul

cd ..\exe

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Check in version number changes            **
echo **                                             **
echo *************************************************

if not exist "c:\program files\StarBase\StarTeam 5.3\stcmd.exe" goto push_to_git

"c:\program files\StarBase\StarTeam 5.3\stcmd" ci -p "%starteam_connect%/Gedemin" -is -x -stop -f NCI -r "Inc build number" -nologo -q

goto changes_committed

:push_to_git

git commit -a -m "Inc version number"
git push 
git checkout master
git merge beta
git push

:changes_committed

if "%1"=="/no_ftp" goto :exit

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Make an archive                            **
echo **                                             **
echo *************************************************

del *.bak /s
del *.tmp /s
del *.new /s
del *.~* /s
del gedemin_upd.ini
del gudf.dll

rem pause

set arc_command="c:\program files\winrar\winrar.exe" a -ibck %arc_name%

if exist %arc_name% del %arc_name% 
%arc_command% gedemin.exe midas.dll midas.sxs.manifest gedemin.exe.manifest
%arc_command% ib_util.dll icudt30.dll icuin30.dll icuuc30.dll
%arc_command% fbembed.dll firebird.msg
%arc_command% microsoft.vc80.crt.manifest msvcp80.dll msvcr80.dll
%arc_command% gedemin_upd.exe
%arc_command% gdcc.exe
%arc_command% libeay32.dll ssleay32.dll
%arc_command% udf\gudf.dll intl\fbintl.conf intl\fbintl.dll
%arc_command% swipl\lib\memfile.dll swipl\lib\readutil.dll
%arc_command% swipl\gd_pl_state.dat 
%arc_command% swipl\libgmp-10.dll swipl\libswipl.dll swipl\pthreadGC2.dll

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Upload to FTP                              **
echo **                                             **
echo *************************************************

goto SkipFTP

if exist temp_ftp_commands.txt del temp_ftp_commands.txt
call BatchSubstitute.bat gedemin.rar %arc_name% ftp_commands.txt > temp_ftp_commands.txt
ftp -s:temp_ftp_commands.txt

:SkipFTP

curl -F data=@"./%arc_name%" http://gsbelarus.com/gs/content/upload2.php

if not errorlevel 0 goto exit

del %arc_name%
del temp_ftp_commands.txt

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Upload gudf.rar                            **
echo **                                             **
echo *************************************************

set arc_command="c:\program files\winrar\winrar.exe" a -ibck %gudf_arc_name%

if exist %gudf_arc_name% del %gudf_arc_name% 
%arc_command% udf\gudf.dll

goto SkipGUDFFTP

if exist temp_ftp_commands.txt del temp_ftp_commands.txt
call BatchSubstitute.bat gedemin.rar %gudf_arc_name% ftp_commands.txt > temp_ftp_commands.txt
ftp -s:temp_ftp_commands.txt

:SkipGUDFFTP

curl -F data=@"./%gudf_arc_name%" http://gsbelarus.com/gs/content/upload2.php

if not errorlevel 0 goto exit

del %gudf_arc_name%
del temp_ftp_commands.txt

echo *************************************************
echo **                                             **
echo **  update_gedemin:                            **
echo **  Upload etalon.rar                          **
echo **                                             **
echo *************************************************

cd ..\sql
call cr.bat localhost/3053 %full_etalon_name%
cd ..\exe

set arc_command="c:\program files\winrar\winrar.exe" a -ibck %etalon_arc_name%

if exist %etalon_arc_name% del %etalon_arc_name% 
%arc_command% %full_etalon_name%

goto SkipEtalonFTP

if exist temp_ftp_commands.txt del temp_ftp_commands.txt
call BatchSubstitute.bat gedemin.rar %etalon_arc_name% ftp_commands.txt > temp_ftp_commands.txt
ftp -s:temp_ftp_commands.txt

:SkipEtalonFTP

curl -F data=@"./%etalon_arc_name%" http://gsbelarus.com/gs/content/upload2.php

if not errorlevel 0 goto exit

del %etalon_arc_name%
del %full_etalon_name%
del temp_ftp_commands.txt

echo *************************************************
echo **                                             **
echo **  for internal usage only                    **
echo **                                             **
echo **                                             **
echo *************************************************

for %%F in (gedemin.exe midas.dll midas.sxs.manifest gedemin.exe.manifest ib_util.dll) do xcopy %%F \\basel\web\%target_dir% /Y
for %%F in (icudt30.dll icuin30.dll icuuc30.dll fbembed.dll firebird.msg) do xcopy %%F \\basel\web\%target_dir% /Y
for %%F in (microsoft.vc80.crt.manifest msvcp80.dll msvcr80.dll gedemin_upd.exe gdcc.exe) do xcopy %%F \\basel\web\%target_dir% /Y
for %%F in (libeay32.dll ssleay32.dll) do xcopy %%F \\basel\web\%target_dir% /Y
xcopy udf\gudf.dll     \\basel\web\%target_dir%\udf\ /Y
xcopy intl\fbintl.conf \\basel\web\%target_dir%\intl\ /Y
xcopy intl\fbintl.dll  \\basel\web\%target_dir%\intl\ /Y
xcopy swipl\gd_pl_state.dat  \\basel\web\%target_dir%\swipl\ /Y
xcopy swipl\libgmp-10.dll  \\basel\web\%target_dir%\swipl\ /Y
xcopy swipl\libswipl.dll  \\basel\web\%target_dir%\swipl\ /Y
xcopy swipl\pthreadGC2.dll  \\basel\web\%target_dir%\swipl\ /Y
xcopy swipl\lib\memfile.dll  \\basel\web\%target_dir%\swipl\lib\ /Y
xcopy swipl\lib\readutil.dll  \\basel\web\%target_dir%\swipl\lib\ /Y
 
:exit



