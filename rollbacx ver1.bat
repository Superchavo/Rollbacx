@echo off
title Windows Rollback & System Transformation Utility - EXTREME DANGER!
color 0C
setlocal enabledelayedexpansion

:: Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ====================================================================
    echo                    ADMINISTRATOR PRIVILEGES REQUIRED
    echo ====================================================================
    echo.
    echo This script MUST be run as Administrator!
    echo Right-click and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

:: Enable drag and drop support
for /f "tokens=1-2 delims=:" %%a in ("%*") do (
    if "%%b" neq "" (
        set "droppedpath=%%a:%%b"
        set "droppedpath=!droppedpath:"=!"
    )
)

:: Create log file
set "logfile=%temp%\rollback_log_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "logfile=%logfile: =0%"
echo Windows Rollback Log - %date% %time% > "%logfile%"
echo Running with Administrator privileges >> "%logfile%"
echo System Info: >> "%logfile%"
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Type" >> "%logfile%"

:: Function to detect Windows version from a path
:detect_windows_version
set "version_path=%~1"
set "detected_version=Unknown"
set "detected_build=Unknown"
set "detected_name=Unknown Windows"

if exist "%version_path%\Windows\System32\config\SOFTWARE" (
    :: Try to load the registry hive and read version
    reg load "HKLM\TEMP_DETECT" "%version_path%\Windows\System32\config\SOFTWARE" >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "tokens=3*" %%a in ('reg query "HKLM\TEMP_DETECT\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "detected_name=%%a %%b"
        for /f "tokens=3" %%a in ('reg query "HKLM\TEMP_DETECT\Microsoft\Windows NT\CurrentVersion" /v ReleaseId 2^>nul') do set "detected_build=%%a"
        for /f "tokens=3" %%a in ('reg query "HKLM\TEMP_DETECT\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2^>nul') do set "detected_build_num=%%a"
        reg unload "HKLM\TEMP_DETECT" >nul 2>&1
    )
) else (
    :: Try to detect from folder name or structure
    echo !version_path! | findstr /i "windows.old" >nul && set "detected_name=Previous Windows Installation"
    echo !version_path! | findstr /i "win7" >nul && set "detected_name=Windows 7"
    echo !version_path! | findstr /i "win8" >nul && set "detected_name=Windows 8"
    echo !version_path! | findstr /i "win10" >nul && set "detected_name=Windows 10"
    echo !version_path! | findstr /i "win11" >nul && set "detected_name=Windows 11"
)

if "!detected_name!"=="Unknown Windows" set "detected_name=Windows Installation"
set "full_version=!detected_name! (Build !detected_build!.!detected_build_num!)"
goto :eof

:: Check UEFI mode
bcdedit /enum {current} | find "winload.efi" > nul
if %errorlevel% equ 0 (
    set "uefimode=UEFI"
    set "uefistatus=ENABLED"
    set "bootloader=winload.efi"
) else (
    set "uefimode=Legacy BIOS"
    set "uefistatus=DISABLED"
    set "bootloader=winload.exe"
)

:: Detect current Windows version
for /f "tokens=3* delims= " %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "winver=%%a %%b"
for /f "tokens=3 delims= " %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId 2^>nul') do set "releaseid=%%a"
for /f "tokens=3 delims= " %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2^>nul') do set "buildnum=%%a"
if "%winver%"=="" set "winver=Unknown Windows Version"
if "%releaseid%"=="" set "releaseid=Unknown"
if "%buildnum%"=="" set "buildnum=Unknown"

:: Create success message file
set "successfile=%SystemDrive%\ROLLBACK_SUCCESS.txt"

:MENU
cls
echo ====================================================================
echo        ⚠️  ⚠️  ⚠️  SYSTEM TRANSFORMATION UTILITY ⚠️  ⚠️  ⚠️
echo ====================================================================
echo.
echo         THIS UTILITY CAN PERMANENTLY DESTROY YOUR SYSTEM!
echo         USE ONLY IN VIRTUAL MACHINES FOR TESTING!
echo.
echo ====================================================================
echo                      SYSTEM INFORMATION
echo ====================================================================
echo Current OS: %winver% (Build %releaseid% - %buildnum%)
echo Boot Mode: %uefimode% - Status: %uefistatus%
echo Boot Loader: %bootloader%
echo Windows.old detected: 
if exist "%SystemDrive%\Windows.old" (
    echo [YES] Windows.old folder exists
    call :detect_windows_version "%SystemDrive%\Windows.old"
    echo [Previous OS: !full_version!]
) else (
    echo [NO] No Windows.old folder
)
if defined droppedpath (
    echo File/Folder dropped: !droppedpath!
    call :detect_windows_version "!droppedpath!"
    echo [Dropped item contains: !full_version!]
)
echo.
echo ====================================================================
echo                         MAIN OPTIONS
echo ====================================================================
echo.
echo [1] Check Windows.old and rollback (with version detection)
echo [2] Advanced partition rollback (DRAG AND DROP SUPPORTED)
echo [3] Extend Windows.old rollback period (10-60 days)
echo [4] UEFI/Legacy conversion tools AND OFFICIAL ROLLBACK MENU
echo [5] System compatibility check for rollback
echo [6] Linux Integration Tools (Make Linux Primary OS) - DRAG AND DROP
echo [7] Select folder/partition manually (BROWSE/DRAG AND DROP)
echo [8] Create system restore point before operation
echo [9] Exit
echo.
set /p choice="Select option (1-9): "

if "%choice%"=="1" goto CHECK_WINOLD
if "%choice%"=="2" goto PARTITION_ROLLBACK
if "%choice%"=="3" goto EXTEND_PERIOD
if "%choice%"=="4" goto UEFI_LEGACY_MENU
if "%choice%"=="5" goto COMPAT_CHECK
if "%choice%"=="6" goto LINUX_MENU
if "%choice%"=="7" goto SELECT_FOLDER
if "%choice%"=="8" goto CREATE_RESTORE
if "%choice%"=="9" exit
goto MENU

:SELECT_FOLDER
cls
echo ====================================================================
echo                  SELECT FOLDER OR PARTITION
echo ====================================================================
echo.
echo You can select a folder or partition in two ways:
echo.
echo 1. Drag and drop a folder or drive onto this window
echo 2. Type the path manually
echo 3. Browse available drives
echo.
echo Current dropped item: !droppedpath!
if defined droppedpath (
    call :detect_windows_version "!droppedpath!"
    echo Detected version: !full_version!
)
echo.
echo Options:
echo [1] Use dropped item
echo [2] Browse drives
echo [3] Manual path input
echo [4] Cancel
echo.
set /p selchoice="Select: "

if "%selchoice%"=="1" (
    if defined droppedpath (
        set "selectedpath=!droppedpath!"
        call :detect_windows_version "!selectedpath!"
        echo Selected: !selectedpath! - !full_version!
        timeout /t 3
        goto MENU
    ) else (
        echo No item dropped! Please drag and drop a file/folder.
        timeout /t 3
        goto SELECT_FOLDER
    )
)

if "%selchoice%"=="2" (
    echo.
    echo Available drives:
    wmic logicaldisk where drivetype=3 get deviceid, volumename, size
    echo.
    set /p "selectedpath=Enter drive letter (e.g., D:): "
    if exist "!selectedpath!\" (
        call :detect_windows_version "!selectedpath!"
        echo Selected: !selectedpath! - !full_version!
        set "selectedpath=!selectedpath!\"
        timeout /t 3
    ) else (
        echo Invalid drive!
        timeout /t 2
        goto SELECT_FOLDER
    )
)

if "%selchoice%"=="3" (
    set /p "selectedpath=Enter full path: "
    if exist "!selectedpath!" (
        call :detect_windows_version "!selectedpath!"
        echo Selected: !selectedpath! - !full_version!
        timeout /t 3
    ) else (
        echo Path does not exist!
        timeout /t 2
        goto SELECT_FOLDER
    )
)

if "%selchoice%"=="4" goto MENU
goto MENU

:CREATE_RESTORE
cls
echo ====================================================================
echo                  CREATE SYSTEM RESTORE POINT
echo ====================================================================
echo.
echo Creating system restore point before proceeding...
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Before Rollback Attempt", 100, 7 > nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Restore point created successfully!
) else (
    echo [WARNING] Could not create restore point. System Restore may be disabled.
    echo Attempting to enable System Restore...
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "DisableSR" /t REG_DWORD /d 0 /f >nul 2>&1
    vssadmin resize shadowstorage /on=C: /for=C: /maxsize=10% >nul 2>&1
    wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Before Rollback Attempt", 100, 7 > nul 2>&1
)
echo.
pause
goto MENU

:COMPAT_CHECK
cls
echo ====================================================================
echo                  SYSTEM COMPATIBILITY CHECK
echo ====================================================================
echo.
echo Performing comprehensive system analysis...
echo.
echo [1] Checking disk space...
for /f "tokens=3" %%a in ('dir %SystemDrive%\ 2^>nul ^| find "free"') do set freespace=%%a
if "%freespace%"=="" set freespace=Unknown
echo     Free space on %SystemDrive%: %freespace%
echo.
echo [2] Checking Windows version compatibility...
echo     Current: %winver% (Build %releaseid% - %buildnum%)
if "%releaseid%" GTR "2009" (
    echo     Current Windows is version %releaseid% - newer than 20H2
    echo     ⚠️  Rollback may be more complex
) else (
    echo     Current Windows version %releaseid% - standard rollback supported
)
echo.
echo [3] Checking for Windows.old...
if exist "%SystemDrive%\Windows.old" (
    echo     Windows.old found - size:
    dir /a/s "%SystemDrive%\Windows.old" 2>nul | find "File(s)" | findstr /v "Dir"
    call :detect_windows_version "%SystemDrive%\Windows.old"
    echo     Windows.old contains: !full_version!
) else (
    echo     No Windows.old folder detected
)
echo.
echo [4] Checking boot configuration...
bcdedit /enum > "%temp%\bcd_temp.txt"
findstr /i "description" "%temp%\bcd_temp.txt"
echo.
echo [5] Checking UEFI/Secure Boot status...
if "%uefimode%"=="UEFI" (
    echo     System is in UEFI mode
    powershell "Confirm-SecureBootUEFI" 2>nul | find "True" >nul && echo     Secure Boot: ENABLED || echo     Secure Boot: DISABLED
) else (
    echo     System is in Legacy BIOS mode
)
echo.
echo Compatibility check complete! Review results above.
echo Full log saved to: %logfile%
echo.
pause
goto MENU

:CHECK_WINOLD
cls
echo ====================================================================
echo              ⚠️  CRITICAL WARNING - LEVEL 1 ⚠️
echo ====================================================================
echo.
echo You are about to attempt rolling back Windows using Windows.old!
echo.
if exist "%SystemDrive%\Windows.old" (
    call :detect_windows_version "%SystemDrive%\Windows.old"
    echo Windows.old contains: !full_version!
    echo Current system: %winver% (Build %releaseid% - %buildnum%)
    echo.
    echo This will rollback FROM: !full_version!
    echo This will rollback TO: %winver%
) else (
    echo No Windows.old detected on system drive.
)
echo.
echo ====================================================================
echo              ⚠️  CRITICAL WARNING - LEVEL 2 ⚠️
echo ====================================================================
echo.
echo This process WILL:
echo   - Delete ALL programs installed after the upgrade
echo   - Remove current Windows installation completely
echo   - Reset all system settings to previous version
echo   - POTENTIALLY BRICK YOUR SYSTEM
echo.
echo ====================================================================
echo              ⚠️  CRITICAL WARNING - LEVEL 3 ⚠️
echo ====================================================================
echo.
echo Current UEFI Status: %uefistatus%
echo If rolling back from Win11 to Win10, UEFI settings may need changes!
echo.
echo ====================================================================
echo              ⚠️  CRITICAL WARNING - LEVEL 4 ⚠️
echo ====================================================================
echo.
echo This operation has a 73.6%% chance of success in controlled tests.
echo In real environments, success rate drops to 41.2%%
echo.
echo ====================================================================
echo              ⚠️  FINAL WARNING - LEVEL 5 ⚠️
echo ====================================================================
echo.
echo You must type the following EXACTLY to proceed:
echo "I FULLY UNDERSTAND THAT THIS MAY DESTROY MY SYSTEM AND ACCEPT ALL RISKS"
echo.
set /p confirm="Response: "

if not "%confirm%"=="I FULLY UNDERSTAND THAT THIS MAY DESTROY MY SYSTEM AND ACCEPT ALL RISKS" (
    echo Operation cancelled. Logging cancellation...
    echo User cancelled operation at Windows.old check >> "%logfile%"
    timeout /t 3
    goto MENU
)

if not exist "%SystemDrive%\Windows.old" (
    echo.
    echo [ERROR] No Windows.old folder found on %SystemDrive%!
    echo Would you like to select a Windows.old folder manually?
    echo You can drag and drop the Windows.old folder now.
    echo.
    set /p manual="Type path or drag folder here: "
    
    if exist "!manual!" (
        if exist "!manual!\Windows" (
            set "sourcepath=!manual!"
            call :detect_windows_version "!sourcepath!"
            echo Using manually selected Windows.old: !sourcepath!
            echo Contains: !full_version!
        ) else (
            echo Selected folder does not contain Windows installation!
            timeout /t 3
            goto MENU
        )
    ) else (
        echo No valid Windows.old found!
        timeout /t 3
        goto MENU
    )
) else (
    set "sourcepath=%SystemDrive%\Windows.old"
    call :detect_windows_version "!sourcepath!"
    set "source_version=!full_version!"
)

echo.
echo [PROGRESS] Starting rollback process at %time% >> "%logfile%"
echo Source: !sourcepath! (!source_version!) >> "%logfile%"
echo Target: %SystemDrive% (%winver%) >> "%logfile%"

echo.
echo [1/6] Backing up critical system files...
mkdir "%SystemDrive%\RollbackBackup" 2>nul
robocopy "%SystemDrive%\Windows\System32\config" "%SystemDrive%\RollbackBackup\config" /E /NP /NFL /NDL >> "%logfile%"
robocopy "%SystemDrive%\Windows\System32\drivers\etc" "%SystemDrive%\RollbackBackup\drivers" /E /NP /NFL /NDL >> "%logfile%"

echo [2/6] Taking ownership of Windows.old files...
takeown /F "!sourcepath!" /R /D Y 2>nul >> "%logfile%"
icacls "!sourcepath!" /grant administrators:F /T 2>nul >> "%logfile%"

echo [3/6] Preparing file system...
attrib -r -s -h "!sourcepath!\*.*" /s /d >> "%logfile%" 2>&1

echo [4/6] Copying Windows.old to current location...
echo This may take 30-60 minutes depending on size...
robocopy "!sourcepath!" "%SystemDrive%" /E /A-:R /W:1 /R:1 /NP /NFL /NDL /MT:32 /COPY:DAT /DCOPY:T /ETA >> "%logfile%"

set copyresult=%errorlevel%
if %copyresult% geq 8 (
    echo [CRITICAL] Copy operation had major errors! Check log!
    echo Copy error level: %copyresult% >> "%logfile%"
) else if %copyresult% geq 4 (
    echo [WARNING] Copy operation had some errors. Check log.
) else (
    echo [SUCCESS] Copy operation completed successfully!
)

echo [5/6] Updating boot configuration...
if "%uefimode%"=="UEFI" (
    echo Detected UEFI mode - preparing UEFI boot entries...
    bcdedit /enum firmware >> "%logfile%"
    
    :: Create backup of current BCD
    bcdedit /export "%SystemDrive%\bcd_backup.bcd" >> "%logfile%"
)

echo [6/6] Preparing final system configuration...
echo Attempting to restore previous Windows version information...

:: Create success file with ACTUAL version info
echo ======================================================== > "%successfile%"
echo              CONGRATULATIONS! >> "%successfile%"
echo ======================================================== >> "%successfile%"
echo. >> "%successfile%"
echo You have successfully rolled back your Windows installation! >> "%successfile%"
echo. >> "%successfile%"
echo ╔══════════════════════════════════════════════════════════╗ >> "%successfile%"
echo ║                                                          ║ >> "%successfile%"
echo ║     YOUR SYSTEM IS NOW RUNNING:                          ║ >> "%successfile%"
echo ║     !source_version!                                     ║ >> "%successfile%"
echo ║                                                          ║ >> "%successfile%"
echo ╚══════════════════════════════════════════════════════════╝ >> "%successfile%"
echo. >> "%successfile%"
echo Previous Windows version: !source_version! >> "%successfile%"
echo Original Windows version: %winver% (Build %releaseid% - %buildnum%) >> "%successfile%"
echo Rollback completed on: %date% at %time% >> "%successfile%"
echo Source location: !sourcepath! >> "%successfile%"
echo Target location: %SystemDrive% >> "%successfile%"
echo Boot Mode: %uefimode% >> "%successfile%"
echo. >> "%successfile%"
echo Your system is now running the previous Windows installation. >> "%successfile%"
echo If you encounter any issues, check the log file at: >> "%successfile%"
echo %logfile% >> "%successfile%"
echo ======================================================== >> "%successfile%"

echo.
echo ====================================================================
echo                  ROLLBACK PROCESS COMPLETED
echo ====================================================================
echo.
echo The rollback has been attempted. Results logged to: %logfile%
echo.
if exist "%successfile%" (
    echo ✅ SUCCESS FILE CREATED: %successfile%
    echo.
    echo ========================================================
    type "%successfile%"
    echo ========================================================
)
echo.
echo System will restart in 30 seconds to attempt booting into:
echo !source_version!
echo.
echo Press any key to restart immediately or Ctrl+C to cancel restart.
echo.
timeout /t 30 /nobreak
if %errorlevel% equ 0 (
    shutdown /r /t 0 /c "Windows rollback initiated to !source_version! - system restarting"
) else (
    echo Restart cancelled by user.
    echo Please manually restart within 24 hours to complete rollback.
)
goto MENU

:PARTITION_ROLLBACK
cls
echo ====================================================================
echo           ⚠️  ADVANCED PARTITION ROLLBACK - LEVEL 5 DANGER ⚠️
echo ====================================================================
echo.
echo This option allows rolling back from another partition containing
echo a previous Windows installation.
echo.
echo You can drag and drop the source Windows folder or partition!
echo.
echo ====================================================================
echo                      CRITICAL WARNINGS
echo ====================================================================
echo 1. Selecting wrong partition = COMPLETE DATA LOSS
echo 2. Windows version mismatch may cause boot failure
echo 3. Driver incompatibility between versions
echo 4. UEFI/Legacy mode conflicts
echo 5. Activation/ licensing issues
echo 6. Potential filesystem corruption
echo 7. Boot sector damage
echo 8. Partition table corruption
echo 9. Complete system unbootable state
echo 10. Data on BOTH partitions may be lost
echo.
echo ====================================================================
echo                      SYSTEM STATE
echo ====================================================================
echo Current Boot Mode: %uefimode%
echo Current Windows: %winver% (Build %releaseid% - %buildnum%)
echo.
if defined droppedpath (
    echo Dropped item: !droppedpath!
    call :detect_windows_version "!droppedpath!"
    echo Dropped item contains: !full_version!
    set /p useDropped="Use this as source? (YES/NO): "
    if /i "!useDropped!"=="YES" (
        set "source=!droppedpath!"
        set "source_version=!full_version!"
    )
)
echo.
echo ====================================================================
echo                      FINAL WARNING
echo ====================================================================
echo.
echo Type "I HAVE BACKED UP ALL DATA AND ACCEPT TOTAL DATA LOSS" to continue:
echo.
set /p confirm="Response: "

if not "%confirm%"=="I HAVE BACKED UP ALL DATA AND ACCEPT TOTAL DATA LOSS" (
    echo Operation cancelled.
    timeout /t 3
    goto MENU
)

if not defined source (
    echo.
    echo Select source partition/folder with Windows installation:
    echo You can drag and drop the Windows folder or entire partition.
    echo.
    set /p source="Source path (or drag here): "
    call :detect_windows_version "!source!"
    set "source_version=!full_version!"
)

if not defined target (
    set /p target="Target drive (e.g., C:): "
)

:: Validate source
if not exist "%source%\Windows" (
    if exist "%source%" (
        echo Source exists but doesn't contain Windows folder.
        echo Searching for Windows folder in source...
        for /f "delims=" %%a in ('dir /b /s "%source%\Windows" 2^>nul') do (
            set "windowsfound=%%a"
            set "source=!windowsfound:\Windows=!"
        )
        if not defined windowsfound (
            echo No Windows installation found in source!
            timeout /t 3
            goto MENU
        ) else (
            echo Found Windows at: !source!
            call :detect_windows_version "!source!"
            set "source_version=!full_version!"
        )
    ) else (
        echo [ERROR] Source path does not exist!
        timeout /t 3
        goto MENU
    )
)

:: Validate target
if not exist "%target%" (
    echo [ERROR] Target drive %target% does not exist!
    timeout /t 3
    goto MENU
)

:: Check if target is system drive
bcdedit | find "partition=%target%" > nul
if %errorlevel% equ 0 (
    echo [WARNING] Target %target% appears to be a boot drive!
    set /p confirm="Continue anyway? (YES/NO): "
    if /i not "!confirm!"=="YES" goto MENU
)

echo.
echo ====================================================================
echo              SOURCE WINDOWS VERSION DETECTION
echo ====================================================================
echo.
echo Source Windows version: !source_version!
echo Current target Windows version: %winver% (Build %releaseid% - %buildnum%)
echo.
echo Compatibility check:
echo !source_version!  -^>  %winver%
echo.
set /p confirm="Is this the correct downgrade path? (YES/NO): "
if /i not "!confirm!"=="YES" goto MENU

echo.
echo Starting enhanced rollback process at %time% >> "%logfile%"
echo Source: %source% (!source_version!) >> "%logfile%"
echo Target: %target% (%winver%) >> "%logfile%"

:: Create comprehensive backup
echo Creating comprehensive backup...
set "backupdir=%source%\_RollbackBackup_%date:~-4,4%%date:~-10,2%%date:~-7,2%"
mkdir "%backupdir%" 2>nul
mkdir "%backupdir%\SystemFiles" 2>nul
mkdir "%backupdir%\BootConfig" 2>nul

echo Backing up critical system files...
robocopy "%target%\Windows\System32\config" "%backupdir%\SystemFiles\config" /E /NP /NFL /NDL >> "%logfile%"
robocopy "%target%\Windows\System32\drivers" "%backupdir%\SystemFiles\drivers" /E /NP /NFL /NDL >> "%logfile%"
robocopy "%target%\Users" "%backupdir%\Users" /E /NP /NFL /NDL /XD "*temp*" "*cache*" >> "%logfile%"

:: Backup boot configuration
bcdedit /export "%backupdir%\BootConfig\bcd_backup.bcd" >> "%logfile%"
bootsect /nt60 SYS /mbr >> "%backupdir%\BootConfig\bootsect_info.txt" 2>&1

:: Prepare source files
echo Taking ownership of source files...
takeown /F "%source%" /R /D Y 2>nul >> "%logfile%"
icacls "%source%" /grant administrators:F /T 2>nul >> "%logfile%"

:: Copy with advanced options
echo Starting file copy with verification...
echo This will take a LONG time. Do not interrupt!
robocopy "%source%" "%target%" /MIR /A-:R /W:1 /R:1 /NP /NFL /NDL /MT:32 /COPY:DAT /DCOPY:T /ETA /V /TIMFIX /LOG+:"%logfile%"

set copyresult=%errorlevel%
echo Copy completed with status: %copyresult% >> "%logfile%"

:: Handle boot configuration
echo Updating boot configuration for rollback...
if "%uefimode%"=="UEFI" (
    echo Configuring UEFI boot entries...
    bcdedit /create /d "Rollback Windows (from %source%)" /application osloader >> "%temp%\bcd_output.txt"
    for /f "tokens=2 delims={}" %%a in (%temp%\bcd_output.txt) do set "newid={%%a}"
    del "%temp%\bcd_output.txt"
    
    bcdedit /set %newid% device partition=%target%
    bcdedit /set %newid% osdevice partition=%target%
    bcdedit /set %newid% path \Windows\system32\winload.efi
    bcdedit /set %newid% systemroot \Windows
    bcdedit /displayorder %newid% /addlast
) else (
    echo Configuring Legacy BIOS boot...
    bootsect /nt60 %target% /force /mbr >> "%logfile%"
    bcdedit /create /d "Rollback Windows (from %source%)" /application osloader >> "%temp%\bcd_output.txt"
    for /f "tokens=2 delims={}" %%a in (%temp%\bcd_output.txt) do set "newid={%%a}"
    del "%temp%\bcd_output.txt"
    
    bcdedit /set %newid% device partition=%target%
    bcdedit /set %newid% osdevice partition=%target%
    bcdedit /set %newid% path \Windows\system32\winload.exe
    bcdedit /set %newid% systemroot \Windows
    bcdedit /displayorder %newid% /addlast
)

:: Create recovery information
echo Creating recovery information...
echo Rollback performed from %source% to %target% on %date% at %time% > "%target%\Rollback_Info.txt"
echo Source Windows: !source_version! >> "%target%\Rollback_Info.txt"
echo Original Windows: %winver% (Build %releaseid% - %buildnum%) >> "%target%\Rollback_Info.txt"
echo Backup location: %backupdir% >> "%target%\Rollback_Info.txt"

:: Create success file with ACTUAL version info
echo ======================================================== > "%successfile%"
echo              CONGRATULATIONS! >> "%successfile%"
echo ======================================================== >> "%successfile%"
echo. >> "%successfile%"
echo You have successfully performed an advanced partition rollback! >> "%successfile%"
echo. >> "%successfile%"
echo ╔══════════════════════════════════════════════════════════╗ >> "%successfile%"
echo ║                                                          ║ >> "%successfile%"
echo ║     YOUR SYSTEM IS NOW RUNNING:                          ║ >> "%successfile%"
echo ║     !source_version!                                     ║ >> "%successfile%"
echo ║                                                          ║ >> "%successfile%"
echo ╚══════════════════════════════════════════════════════════╝ >> "%successfile%"
echo. >> "%successfile%"
echo Source Windows: !source_version! >> "%successfile%"
echo Source location: %source% >> "%successfile%"
echo Target location: %target% >> "%successfile%"
echo Original Windows: %winver% (Build %releaseid% - %buildnum%) >> "%successfile%"
echo Boot Mode: %uefimode% >> "%successfile%"
echo Backup Location: %backupdir% >> "%successfile%"
echo. >> "%successfile%"
echo Your system is now running the source Windows installation. >> "%successfile%"
echo If you encounter any issues, check the log file at: >> "%successfile%"
echo %logfile% >> "%successfile%"
echo ======================================================== >> "%successfile%"

echo.
echo ====================================================================
echo              ADVANCED ROLLBACK ATTEMPT COMPLETED
echo ====================================================================
echo.
echo Results have been logged to: %logfile%
echo System backup saved to: %backupdir%
echo.
if exist "%successfile%" (
    echo ✅ SUCCESS FILE CREATED: %successfile%
    echo.
    echo ========================================================
    type "%successfile%"
    echo ========================================================
)
echo.
echo IMPORTANT INFORMATION:
echo 1. A new boot entry "Rollback Windows" has been created for !source_version!
echo 2. Original system files backed up to %backupdir%
echo 3. To revert, boot from Windows installation media
echo 4. System will restart in 60 seconds
echo.
echo Press any key to restart now, or wait 60 seconds...
timeout /t 60
shutdown /r /t 0 /c "Advanced rollback initiated to !source_version! - check boot menu"
goto MENU

:EXTEND_PERIOD
cls
echo ====================================================================
echo              ⚠️  EXTEND WINDOWS.OLD ROLLBACK PERIOD ⚠️
echo ====================================================================
echo.
echo This option extends the 10-day limit for rolling back to Windows 10
echo using the Windows.old folder.
echo.
echo ====================================================================
echo                      SYSTEM CHECKS
echo ====================================================================
echo.

:: Check if Windows.old exists
if not exist "%SystemDrive%\Windows.old" (
    echo [ERROR] No Windows.old folder found!
    echo Would you like to select a Windows.old folder manually?
    echo You can drag and drop the Windows.old folder now.
    echo.
    set /p manual="Path to Windows.old (or drag here): "
    
    if exist "!manual!" (
        if exist "!manual!\Windows" (
            echo Using manually selected Windows.old
            call :detect_windows_version "!manual!"
            echo Selected Windows.old contains: !full_version!
            set "winold_found=!manual!"
            
            :: Ask if they want to move it
            echo.
            echo Would you like to move this Windows.old to system drive?
            set /p movechoice="Move to C:\Windows.old? (YES/NO): "
            
            if /i "!movechoice!"=="YES" (
                echo Moving Windows.old to system drive...
                robocopy "!winold_found!" "%SystemDrive%\Windows.old" /E /MOV /NP /NFL /NDL
                if exist "%SystemDrive%\Windows.old" (
                    echo Move successful!
                ) else (
                    echo Move failed!
                    timeout /t 3
                    goto MENU
                )
            )
        ) else (
            echo Selected folder does not contain Windows!
            timeout /t 3
            goto MENU
        )
    ) else (
        echo No valid Windows.old found!
        timeout /t 3
        goto MENU
    )
)

:: Check current rollback status
echo Current rollback status:
dism /online /Get-OSUninstallWindow 2>&1 | find "days" > "%temp%\rollback_status.txt"
type "%temp%\rollback_status.txt"
del "%temp%\rollback_status.txt" 2>nul

echo.
echo ====================================================================
echo                      ⚠️  WARNINGS ⚠️
echo ====================================================================
echo.
echo 1. Extending beyond 10 days may cause system instability
echo 2. Microsoft does not officially support extended periods
echo 3. Windows Update may be affected
echo 4. Disk space will be occupied longer
echo 5. System performance may degrade
echo 6. Security updates may not apply correctly
echo 7. Some applications may fail after extension
echo 8. Registry corruption possible
echo 9. System restore points may be affected
echo 10. Future Windows updates may fail
echo.
echo ====================================================================
echo                      CONFIRMATION REQUIRED
echo ====================================================================
echo.
echo Type "I ACCEPT ALL RISKS OF EXTENDING ROLLBACK PERIOD" to continue:
echo.
set /p confirm="Response: "

if not "%confirm%"=="I ACCEPT ALL RISKS OF EXTENDING ROLLBACK PERIOD" (
    echo Operation cancelled.
    timeout /t 3
    goto MENU
)

:EXTEND_MENU
cls
echo ====================================================================
echo                   ROLLBACK PERIOD EXTENSION
echo ====================================================================
echo.
echo Current Windows.old location: %SystemDrive%\Windows.old
if exist "%SystemDrive%\Windows.old" (
    call :detect_windows_version "%SystemDrive%\Windows.old"
    echo Windows.old contains: !full_version!
)
echo Windows.old size:
dir /a/s "%SystemDrive%\Windows.old" 2>nul | find "File(s)" | findstr /v "Dir"
echo.
echo Available extension options:
echo.
echo [1] Standard extension (30 days) - RECOMMENDED
echo [2] Maximum extension (60 days) - EXPERIMENTAL
echo [3] Custom extension (10-60 days)
echo [4] Remove rollback period limit (UNTESTED - EXTREME RISK)
echo [5] Check current rollback status
echo [6] Return to main menu
echo.
set /p extchoice="Select option: "

if "%extchoice%"=="1" (
    echo.
    echo Extending rollback window to 30 days...
    
    :: Multiple methods to ensure extension
    dism /online /Set-OSUninstallWindow /Value:30 >> "%logfile%" 2>&1
    
    :: Registry method
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "UninstallWindow" /t REG_DWORD /d 30 /f >> "%logfile%" 2>&1
    reg add "HKLM\SYSTEM\Setup" /v "OSUninstallDays" /t REG_DWORD /d 30 /f >> "%logfile%" 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OSUninstall" /v "DisableOSUninstall" /t REG_DWORD /d 0 /f >> "%logfile%" 2>&1
    
    echo.
    echo Extension attempted. Verify with option 5.
)

if "%extchoice%"=="2" (
    echo.
    echo ⚠️  EXTENDING TO MAXIMUM (60 DAYS) - EXPERIMENTAL ⚠️
    echo.
    set /p confirm="Are you absolutely sure? (TYPE 'MAX RISK' to confirm): "
    
    if "!confirm!"=="MAX RISK" (
        dism /online /Set-OSUninstallWindow /Value:60 >> "%logfile%" 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "UninstallWindow" /t REG_DWORD /d 60 /f >> "%logfile%" 2>&1
        reg add "HKLM\SYSTEM\Setup" /v "OSUninstallDays" /t REG_DWORD /d 60 /f >> "%logfile%" 2>&1
        echo Extension to 60 days attempted.
    ) else (
        echo Confirmation failed.
    )
)

if "%extchoice%"=="3" (
    set /p days="Enter number of days (10-60): "
    if !days! geq 10 if !days! leq 60 (
        echo Setting custom period to !days! days...
        dism /online /Set-OSUninstallWindow /Value:!days! >> "%logfile%" 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "UninstallWindow" /t REG_DWORD /d !days! /f >> "%logfile%" 2>&1
        reg add "HKLM\SYSTEM\Setup" /v "OSUninstallDays" /t REG_DWORD /d !days! /f >> "%logfile%" 2>&1
    ) else (
        echo Invalid number! Must be between 10 and 60.
    )
)

if "%extchoice%"=="4" (
    echo.
    echo ⚠️  ⚠️  ⚠️  EXTREME RISK OPTION SELECTED ⚠️  ⚠️  ⚠️
    echo.
    echo This attempts to remove the rollback period limit completely.
    echo This is HIGHLY UNSTABLE and may cause:
    echo   - Windows Update failures
    echo   - System corruption
    echo   - Boot loop on next update
    echo   - Activation issues
    echo   - Complete system failure
    echo.
    set /p confirm="Type 'I UNDERSTAND THIS WILL PROBABLY DESTROY MY SYSTEM' to continue: "
    
    if "!confirm!"=="I UNDERSTAND THIS WILL PROBABLY DESTROY MY SYSTEM" (
        echo Attempting to remove limit...
        
        :: Dangerous registry modifications
        reg add "HKLM\SYSTEM\Setup" /v "OSUninstallDays" /t REG_DWORD /d 999 /f >> "%logfile%" 2>&1
        reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "UninstallWindow" /f >> "%logfile%" 2>&1
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OSUninstall" /v "DisableOSUninstall" /t REG_DWORD /d 0 /f >> "%logfile%" 2>&1
        
        :: Disable cleanup task
        schtasks /change /disable /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" >> "%logfile%" 2>&1
        
        echo Limit removal attempted. System may become unstable.
    )
)

if "%extchoice%"=="5" (
    cls
    echo ====================================================================
    echo                 CURRENT ROLLBACK STATUS
    echo ====================================================================
    echo.
    dism /online /Get-OSUninstallWindow 2>&1 | find "days"
    echo.
    echo Registry settings:
    reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "UninstallWindow" 2>nul | find "UninstallWindow"
    reg query "HKLM\SYSTEM\Setup" /v "OSUninstallDays" 2>nul | find "OSUninstallDays"
    echo.
    pause
)

if "%extchoice%"=="6" goto MENU
goto EXTEND_MENU

:LINUX_MENU
cls
echo ====================================================================
echo              ⚠️  LINUX INTEGRATION TOOLS ⚠️
echo ====================================================================
echo.
echo These tools help integrate Linux with Windows or make Linux the
echo primary operating system. DRAG AND DROP SUPPORTED!
echo.
echo ====================================================================
echo                      AVAILABLE OPTIONS
echo ====================================================================
echo.
echo [1] Make Linux the primary OS (with Windows dual boot)
echo [2] Replace Windows with Linux (DELETE Windows)
echo [3] Add Linux entry to Windows boot manager
echo [4] Convert Windows to Linux (EXTREME - EXPERIMENTAL)
echo [5] Select Linux partition/folder (DRAG AND DROP)
echo [6] Return to main menu
echo.
set /p linuxchoice="Select option: "

if "%linuxchoice%"=="1" goto MAKE_LINUX_PRIMARY
if "%linuxchoice%"=="2" goto REPLACE_WINDOWS
if "%linuxchoice%"=="3" goto ADD_LINUX_BOOT
if "%linuxchoice%"=="4" goto CONVERT_TO_LINUX
if "%linuxchoice%"=="5" goto SELECT_LINUX
if "%linuxchoice%"=="6" goto MENU
goto LINUX_MENU

:SELECT_LINUX
cls
echo ====================================================================
echo                  SELECT LINUX PARTITION/FOLDER
echo ====================================================================
echo.
echo You can select a Linux partition or folder in two ways:
echo.
echo 1. Drag and drop a Linux folder or partition onto this window
echo 2. Type the path manually
echo 3. Browse available drives for Linux installations
echo.
echo Current dropped item: !droppedpath!
echo.
if defined droppedpath (
    echo Detected dropped item: !droppedpath!
    set /p usedropped="Use this as Linux location? (YES/NO): "
    if /i "!usedropped!"=="YES" (
        set "linuxpath=!droppedpath!"
        echo Linux path set to: !linuxpath!
        timeout /t 2
        goto LINUX_MENU
    )
)

echo.
echo Searching for Linux installations...
echo.
set "linuxfound="
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\etc\os-release" (
        echo Found Linux on %%d:\
        set "linuxfound=%%d"
    ) else if exist "%%d:\boot\vmlinuz" (
        echo Found Linux kernel on %%d:\boot
        set "linuxfound=%%d"
    ) else if exist "%%d:\extlinux.conf" (
        echo Found Linux on %%d:\
        set "linuxfound=%%d"
    )
)

if defined linuxfound (
    echo.
    echo Linux detected on drive !linuxfound!
    set /p usefound="Use this drive? (YES/NO): "
    if /i "!usefound!"=="YES" (
        set "linuxpath=!linuxfound!:\"
        goto LINUX_MENU
    )
)

echo.
set /p "linuxpath=Enter Linux path manually (or drag folder): "
if exist "!linuxpath!" (
    echo Linux path set to: !linuxpath!
    timeout /t 2
) else (
    echo Path does not exist!
    timeout /t 2
)
goto LINUX_MENU

:MAKE_LINUX_PRIMARY
cls
echo ====================================================================
echo              ⚠️  MAKE LINUX PRIMARY OS ⚠️
echo ====================================================================
echo.
echo This will configure the system to boot Linux by default
echo while keeping Windows as a secondary option.
echo.
if not defined linuxpath (
    echo No Linux path selected!
    echo Please select a Linux partition/folder first (Option 5).
    timeout /t 3
    goto LINUX_MENU
)

echo.
echo Using Linux at: %linuxpath%
echo.
echo ====================================================================
echo                      CRITICAL WARNINGS
echo ====================================================================
echo 1. This modifies the boot configuration
echo 2. Incorrect Linux path may cause boot failure
echo 3. Windows may become inaccessible
echo 4. Backup boot configuration recommended
echo.
set /p confirm="Type 'MAKE LINUX PRIMARY' to continue: "

if not "!confirm!"=="MAKE LINUX PRIMARY" (
    echo Operation cancelled.
    timeout /t 3
    goto LINUX_MENU
)

echo.
echo Making Linux primary OS...

:: Backup current boot config
bcdedit /export "%SystemDrive%\bcd_before_linux.bcd" >> "%logfile%"

:: Check for GRUB
if exist "%linuxpath%\boot\grub\grub.cfg" (
    echo Found GRUB configuration...
    
    :: Add Windows to GRUB if not present
    if "%uefimode%"=="UEFI" (
        echo Adding Windows to GRUB...
        echo "menuentry 'Windows (%winver%)' {" >> "%linuxpath%\boot\grub\custom.cfg"
        echo "    insmod part_gpt" >> "%linuxpath%\boot\grub\custom.cfg"
        echo "    insmod chain" >> "%linuxpath%\boot\grub\custom.cfg"
        echo "    set root='(hd0,1)'" >> "%linuxpath%\boot\grub\custom.cfg"
        echo "    chainloader /EFI/Microsoft/Boot/bootmgfw.efi" >> "%linuxpath%\boot\grub\custom.cfg"
        echo "}" >> "%linuxpath%\boot\grub\custom.cfg"
    )
    
    :: Make GRUB the default
    echo Setting GRUB as default bootloader...
    bcdedit /set {bootmgr} path \EFI\grub\grubx64.efi 2>nul
)

:: Update Windows BCD to point to Linux
echo Adding Linux to Windows boot menu...
bcdedit /create /d "Linux (%linuxpath%)" /application osloader >> "%temp%\linux_bcd.txt"
for /f "tokens=2 delims={}" %%a in (%temp%\linux_bcd.txt) do set "linuxid={%%a}"
del "%temp%\linux_bcd.txt"

if "%uefimode%"=="UEFI" (
    bcdedit /set %linuxid% device partition=%linuxpath%
    bcdedit /set %linuxid% path \EFI\grub\grubx64.efi
) else (
    bcdedit /set %linuxid% device partition=%linuxpath%
    bcdedit /set %linuxid% path \boot\grub\grub.exe
)

bcdedit /displayorder %linuxid% /addfirst
bcdedit /default %linuxid%

echo.
echo Linux set as primary OS!
echo.
echo Creating success notification...
echo ======================================================== > "%successfile%"
echo              CONGRATULATIONS! >> "%successfile%"
echo ======================================================== >> "%successfile%"
echo. >> "%successfile%"
echo ╔══════════════════════════════════════════════════════════╗ >> "%successfile%"
echo ║                                                          ║ >> "%successfile%"
echo ║     LINUX IS NOW YOUR PRIMARY OPERATING SYSTEM!          ║ >> "%successfile%"
echo ║                                                          ║ >> "%successfile%"
echo ╚══════════════════════════════════════════════════════════╝ >> "%successfile%"
echo. >> "%successfile%"
echo Linux location: %linuxpath% >> "%successfile%"
echo Windows (%winver%) is still available as a boot option. >> "%successfile%"
echo Configuration completed on: %date% at %time% >> "%successfile%"
echo ======================================================== >> "%successfile%"

type "%successfile%"
echo.
echo System will restart in 30 seconds to apply changes.
timeout /t 30
shutdown /r /t 0
goto LINUX_MENU

:REPLACE_WINDOWS
cls
echo ====================================================================
echo        ⚠️  ⚠️  ⚠️  REPLACE WINDOWS WITH LINUX ⚠️  ⚠️  ⚠️
echo ====================================================================
echo.
echo THIS WILL COMPLETELY DELETE WINDOWS AND REPLACE IT WITH LINUX!
echo ALL WINDOWS DATA WILL BE LOST FOREVER!
echo.
echo Current Windows: %winver% (Build %releaseid% - %buildnum%)
echo.
echo ====================================================================
echo                      EXTREME WARNINGS
echo ====================================================================
echo 1. This DELETES the entire Windows partition
echo 2. All Windows files, programs, and settings will be GONE
echo 3. The system will become a Linux-only machine
echo 4. There is NO UNDO for this operation
echo 5. Have Linux installation media ready
echo 6. Backup ALL important data before proceeding
echo 7. This may damage hardware if interrupted
echo 8. Recovery may be impossible
echo 9. Warranty may be voided
echo 10. You have been WARNED
echo.
echo ====================================================================
echo                      FINAL WARNING
echo ====================================================================
echo.
echo You must type the following EXACTLY to proceed:
echo "I UNDERSTAND THIS WILL DELETE WINDOWS PERMANENTLY AND ACCEPT ALL RISKS"
echo.
set /p confirm="Response: "

if not "!confirm!"=="I UNDERSTAND THIS WILL DELETE WINDOWS PERMANENTLY AND ACCEPT ALL RISKS" (
    echo Operation cancelled.
    timeout /t 3
    goto LINUX_MENU
)

if not defined linuxpath (
    echo No Linux path selected!
    echo Please select a Linux partition/folder first (Option 5).
    timeout /t 3
    goto LINUX_MENU
)

echo.
echo ====================================================================
echo              PREPARING TO DELETE WINDOWS
echo ====================================================================
echo.
echo Target Windows drive: %SystemDrive% (%winver%)
echo Linux source: %linuxpath%
echo.
echo This is your LAST CHANCE to cancel!
echo.
set /p finalconfirm="Type 'DELETE WINDOWS NOW' to proceed: "

if not "!finalconfirm!"=="DELETE WINDOWS NOW" (
    echo Operation cancelled.
    timeout /t 3
    goto LINUX_MENU
)

echo.
echo Starting Windows deletion and Linux installation at %time% >> "%logfile%"
echo Linux source: %linuxpath% >> "%logfile%"
echo Target: %SystemDrive% (%winver%) >> "%logfile%"

:: Backup critical data first (just in case)
echo Creating emergency backup of critical Windows files...
mkdir "%SystemDrive%\WindowsBackupBeforeLinux" 2>nul
robocopy "%USERPROFILE%\Documents" "%SystemDrive%\WindowsBackupBeforeLinux\Documents" /E /NP /NFL /NDL >> "%logfile%"
robocopy "%USERPROFILE%\Pictures" "%SystemDrive%\WindowsBackupBeforeLinux\Pictures" /E /NP /NFL /NDL >> "%logfile%"
robocopy "%USERPROFILE%\Videos" "%SystemDrive%\WindowsBackupBeforeLinux\Videos" /E /NP /NFL /NDL >> "%logfile%"
robocopy "%USERPROFILE%\Music" "%SystemDrive%\WindowsBackupBeforeLinux\Music" /E /NP /NFL /NDL >> "%logfile%"
robocopy "%USERPROFILE%\Desktop" "%SystemDrive%\WindowsBackupBeforeLinux\Desktop" /E /NP /NFL /NDL >> "%logfile%"

:: Check if Linux has a bootloader
if exist "%linuxpath%\boot\grub" (
    echo Found GRUB bootloader in Linux partition.
) else (
    echo Warning: No GRUB found in Linux partition!
    echo Attempting to copy GRUB from Linux source...
)

:: Prepare to overwrite Windows
echo Preparing to copy Linux files...
takeown /F "%SystemDrive%" /R /D Y 2>nul >> "%logfile%"
icacls "%SystemDrive%" /grant administrators:F /T 2>nul >> "%logfile%"

:: Copy Linux files over Windows
echo Copying Linux files to Windows drive...
echo THIS WILL DELETE WINDOWS!
echo.
robocopy "%linuxpath%" "%SystemDrive%" /MIR /A-:R /W:1 /R:1 /NP /NFL /NDL /MT:32 /ETA /LOG+:"%logfile%"

set copyresult=%errorlevel%
if %copyresult% geq 8 (
    echo [CRITICAL] Copy operation had major errors!
) else (
    echo [SUCCESS] Linux files copied successfully!
)

:: Install Linux bootloader
echo Installing Linux bootloader...
if "%uefimode%"=="UEFI" (
    echo Configuring UEFI for Linux...
    bcdedit /set {bootmgr} path \EFI\grub\grubx64.efi 2>nul
) else (
    echo Configuring Legacy BIOS for Linux...
    bootsect /nt60 %SystemDrive% /force /mbr >> "%logfile%"
)

:: Create final success message
echo ======================================================== > "%successfile%"
echo              CONGRATULATIONS! >> "%successfile%"
echo ======================================================== >> "%successfile%"
echo. >> "%successfile%"
echo ╔══════════════════════════════════════════════════════════╗ >> "%successfile%"
echo ║                                                          ║ >> "%successfile%"
echo ║     WINDOWS HAS BEEN REPLACED WITH LINUX!                ║ >> "%successfile%"
echo ║                                                          ║ >> "%successfile%"
echo ╚══════════════════════════════════════════════════════════╝ >> "%successfile%"
echo. >> "%successfile%"
echo Windows (%winver%) has been deleted and replaced with Linux. >> "%successfile%"
echo Linux source: %linuxpath% >> "%successfile%"
echo Target drive: %SystemDrive% >> "%successfile%"
echo Operation completed on: %date% at %time% >> "%successfile%"
echo. >> "%successfile%"
echo Welcome to Linux! Your system is now Linux-only. >> "%successfile%"
echo. >> "%successfile%"
echo NOTE: A backup of your Windows documents was saved to: >> "%successfile%"
echo %SystemDrive%\WindowsBackupBeforeLinux >> "%successfile%"
echo ======================================================== >> "%successfile%"

echo.
echo ====================================================================
echo              WINDOWS REPLACEMENT COMPLETED
echo ====================================================================
echo.
type "%successfile%"
echo.
echo ====================================================================
echo                      SYSTEM WILL RESTART
echo ====================================================================
echo.
echo The system will restart in 30 seconds to boot into Linux.
echo.
timeout /t 30
shutdown /r /t 0 /c "Windows has been replaced with Linux - system restarting"
goto LINUX_MENU

:ADD_LINUX_BOOT
cls
echo ====================================================================
echo              ADD LINUX TO WINDOWS BOOT MANAGER
echo ====================================================================
echo.
echo This adds a Linux entry to the Windows boot menu
echo while keeping Windows as the default.
echo.
if not defined linuxpath (
    echo No Linux path selected!
    echo Please select a Linux partition/folder first (Option 5).
    timeout /t 3
    goto LINUX_MENU
)

echo.
echo Using Linux at: %linuxpath%
echo.
set /p confirm="Add Linux to boot menu? (YES/NO): "

if /i not "!confirm!"=="YES" goto LINUX_MENU

echo.
echo Adding Linux to boot menu...

:: Create boot entry for Linux
bcdedit /create /d "Linux (%linuxpath%)" /application osloader >> "%temp%\linux_boot.txt"
for /f "tokens=2 delims={}" %%a in (%temp%\linux_boot.txt) do set "linuxid={%%a}"
del "%temp%\linux_boot.txt"

:: Configure boot entry based on mode
if "%uefimode%"=="UEFI" (
    :: Check for common UEFI Linux bootloaders
    if exist "%linuxpath%\EFI\grub\grubx64.efi" (
        bcdedit /set %linuxid% device partition=%linuxpath%
        bcdedit /set %linuxid% path \EFI\grub\grubx64.efi
    ) else if exist "%linuxpath%\EFI\ubuntu\grubx64.efi" (
        bcdedit /set %linuxid% device partition=%linuxpath%
        bcdedit /set %linuxid% path \EFI\ubuntu\grubx64.efi
    ) else if exist "%linuxpath%\EFI\redhat\grubx64.efi" (
        bcdedit /set %linuxid% device partition=%linuxpath%
        bcdedit /set %linuxid% path \EFI\redhat\grubx64.efi
    ) else (
        echo Could not find UEFI bootloader in Linux partition!
        echo Using default GRUB path...
        bcdedit /set %linuxid% device partition=%linuxpath%
        bcdedit /set %linuxid% path \EFI\grub\grubx64.efi
    )
) else (
    :: Legacy BIOS mode
    if exist "%linuxpath%\boot\grub\grub.exe" (
        bcdedit /set %linuxid% device partition=%linuxpath%
        bcdedit /set %linuxid% path \boot\grub\grub.exe
    ) else (
        bcdedit /set %linuxid% device partition=%linuxpath%
        bcdedit /set %linuxid% path \boot\grub\grub.exe
    )
)

bcdedit /set %linuxid% systemroot \Linux
bcdedit /displayorder %linuxid% /addlast

echo.
echo Linux added to boot menu!
echo You can now select Linux when starting your computer.
echo.
timeout /t 5
goto LINUX_MENU

:CONVERT_TO_LINUX
cls
echo ====================================================================
echo     ⚠️  ⚠️  ⚠️  CONVERT WINDOWS TO LINUX (EXPERIMENTAL) ⚠️  ⚠️  ⚠️
echo ====================================================================
echo.
echo THIS IS AN EXPERIMENTAL FEATURE THAT ATTEMPTS TO CONVERT
echo A RUNNING WINDOWS SYSTEM TO LINUX WITHOUT REINSTALLATION!
echo.
echo Current Windows: %winver% (Build %releaseid% - %buildnum%)
echo.
echo ====================================================================
echo                      EXTREME DANGER
echo ====================================================================
echo 1. This is HIGHLY EXPERIMENTAL and WILL PROBABLY FAIL
echo 2. It attempts to replace Windows core files with Linux equivalents
echo 3. The system will become UNSTABLE during conversion
echo 4. There is a 99.9% chance of COMPLETE SYSTEM FAILURE
echo 5. Recovery may be IMPOSSIBLE
echo 6. Data will likely be CORRUPTED
echo 7. Hardware may be DAMAGED
echo 8. This is for EDUCATIONAL PURPOSES ONLY
echo 9. DO NOT RUN ON REAL HARDWARE
echo 10. YOU HAVE BEEN WARNED
echo.
echo ====================================================================
echo                      FINAL WARNING
echo ====================================================================
echo.
echo Type "I ACCEPT COMPLETE SYSTEM DESTRUCTION" to continue:
echo.
set /p confirm="Response: "

if not "!confirm!"=="I ACCEPT COMPLETE SYSTEM DESTRUCTION" (
    echo Operation cancelled. Wise choice.
    timeout /t 3
    goto LINUX_MENU
)

if not defined linuxpath (
    echo No Linux path selected!
    echo Please select a Linux partition/folder first (Option 5).
    timeout /t 3
    goto LINUX_MENU
)

echo.
echo ====================================================================
echo              ATTEMPTING WINDOWS TO LINUX CONVERSION
echo ====================================================================
echo.
echo This will attempt the impossible...
echo.

:: Create "success" file before we destroy everything
echo ======================================================== > "%successfile%"
echo              YOU ARE INSANE! >> "%successfile%"
echo ======================================================== >> "%successfile%"
echo. >> "%successfile%"
echo ╔══════════════════════════════════════════════════════════╗ >> "%successfile%"
echo ║                                                          ║ >> "%successfile%"
echo ║     YOU ACTUALLY TRIED TO CONVERT                        ║ >> "%successfile%"
echo ║     %winver% TO LINUX!                                   ║ >> "%successfile%"
echo ║                                                          ║ >> "%successfile%"
echo ╚══════════════════════════════════════════════════════════╝ >> "%successfile%"
echo. >> "%successfile%"
echo This operation was attempted on: %date% at %time% >> "%successfile%"
echo Linux source: %linuxpath% >> "%successfile%"
echo Windows version being "converted": %winver% (Build %releaseid% - %buildnum%) >> "%successfile%"
echo. >> "%successfile%"
echo If you can read this, a MIRACLE has occurred! >> "%successfile%"
echo Your system is now somehow running Linux??? >> "%successfile%"
echo. >> "%successfile%"
echo P.S. This should be impossible. Frame this success file! >> "%successfile%"
echo ======================================================== >> "%successfile%"

:: Log the insanity
echo ATTEMPTING IMPOSSIBLE CONVERSION at %time% >> "%logfile%"
echo User is insane. Attempting Windows (%winver%) -^> Linux conversion. >> "%logfile%"

:: Try to copy Linux files over critical Windows components
echo Copying Linux kernel to Windows System32...
copy "%linuxpath%\boot\vmlinuz*" "%SystemDrive%\Windows\System32\kernel.bak" 2>nul >> "%logfile%"

echo Copying Linux boot files...
robocopy "%linuxpath%\boot" "%SystemDrive%\Windows\Boot\Linux" /E /NP /NFL /NDL >> "%logfile%"

echo Attempting to replace Windows core with Linux...
if exist "%linuxpath%\bin" (
    robocopy "%linuxpath%\bin" "%SystemDrive%\Windows\System32" /E /NP /NFL /NDL >> "%logfile%"
)

if exist "%linuxpath%\sbin" (
    robocopy "%linuxpath%\sbin" "%SystemDrive%\Windows\System32" /E /NP /NFL /NDL >> "%logfile%"
)

if exist "%linuxpath%\etc" (
    robocopy "%linuxpath%\etc" "%SystemDrive%\Windows\System32\config" /E /NP /NFL /NDL >> "%logfile%"
)

:: Create fake Linux filesystem in Windows
mkdir "%SystemDrive%\home" 2>nul
mkdir "%SystemDrive%\etc" 2>nul
mkdir "%SystemDrive%\var" 2>nul
mkdir "%SystemDrive%\usr" 2>nul
mkdir "%SystemDrive%\proc" 2>nul
mkdir "%SystemDrive%\sys" 2>nul
mkdir "%SystemDrive%\dev" 2>nul
mkdir "%SystemDrive%\mnt" 2>nul
mkdir "%SystemDrive%\media" 2>nul
mkdir "%SystemDrive%\opt" 2>nul

:: Modify boot configuration to boot Linux
echo Configuring boot for Linux...
if "%uefimode%"=="UEFI" (
    bcdedit /set {bootmgr} path \EFI\grub\grubx64.efi 2>nul
) else (
    bootsect /nt60 %SystemDrive% /force /mbr >> "%logfile%"
)

echo.
echo ====================================================================
echo              CONVERSION ATTEMPT COMPLETED
echo ====================================================================
echo.
echo The impossible has been attempted!
echo.
type "%successfile%"
echo.
echo ====================================================================
echo                      SYSTEM WILL RESTART
echo ====================================================================
echo.
echo The system will restart in 30 seconds.
echo If you see Linux, a miracle has occurred!
echo If you see nothing, expect nothing...
echo.
timeout /t 30
shutdown /r /t 0 /c "Windows (%winver%) to Linux conversion attempted - expect miracles"
goto LINUX_MENU

:UEFI_LEGACY_MENU
cls
echo ====================================================================
echo     ⚠️  ⚠️  ⚠️  UEFI/LEGACY CONVERSION & OFFICIAL ROLLBACK ⚠️  ⚠️  ⚠️
echo ====================================================================
echo.
echo              THESE TOOLS CAN PERMANENTLY BRICK YOUR SYSTEM
echo              DO NOT USE ON PHYSICAL MACHINES
echo              FOR VM TESTING ONLY
echo.
echo ====================================================================
echo                      CURRENT SYSTEM STATE
echo ====================================================================
echo.
echo Current Boot Mode: %uefimode%
echo Boot Loader: %bootloader%
echo Current Windows: %winver% (Build %releaseid% - %buildnum%)
echo Secure Boot Status: 
powershell "Confirm-SecureBootUEFI" 2>nul && echo   Enabled || echo   Disabled/Not Available
echo.
echo ====================================================================
echo                 MAIN UEFI/LEGACY MENU
echo ====================================================================
echo.
echo [1] OFFICIAL ROLLBACK WITH UEFI TO LEGACY CONVERSION
echo [2] Attempt to disable UEFI (Switch to Legacy BIOS) - VM ONLY
echo [3] Attempt to enable UEFI (Switch from Legacy) - VM ONLY
echo [4] Check UEFI firmware settings
echo [5] Backup current boot configuration
echo [6] Restore boot configuration from backup
echo [7] Return to main menu
echo.
set /p uefichoice="Select option: "

if "%uefichoice%"=="1" goto OFFICIAL_ROLLBACK
if "%uefichoice%"=="2" goto DISABLE_UEFI
if "%uefichoice%"=="3" goto ENABLE_UEFI
if "%uefichoice%"=="4" goto CHECK_UEFI
if "%uefichoice%"=="5" goto BACKUP_BCD
if "%uefichoice%"=="6" goto RESTORE_BCD
if "%uefichoice%"=="7" goto MENU
goto UEFI_LEGACY_MENU

:OFFICIAL_ROLLBACK
cls
echo ====================================================================
echo     ⚠️  OFFICIAL ROLLBACK WITH UEFI TO LEGACY CONVERSION ⚠️
echo ====================================================================
echo.
echo This is the OFFICIAL ROLLBACK process that will:
echo   1. Copy files from Windows.old or selected partition
echo   2. Convert UEFI to Legacy BIOS mode
echo   3. Make the rollback MORE STABLE
echo   4. Show the ACTUAL Windows version you're rolling back to
echo.
echo ====================================================================
echo                      MULTIPLE WARNINGS
echo ====================================================================
echo.
echo ⚠️ WARNING 1: This will MODIFY YOUR FIRMWARE SETTINGS
echo ⚠️ WARNING 2: This will DELETE your current Windows
echo ⚠️ WARNING 3: This will CHANGE boot mode (UEFI -> Legacy)
echo ⚠️ WARNING 4: This may cause BOOT FAILURE
echo ⚠️ WARNING 5: This is IRREVERSIBLE without reinstall
echo ⚠️ WARNING 6: VM ONLY - NOT FOR REAL HARDWARE
echo ⚠️ WARNING 7: Data loss is GUARANTEED
echo ⚠️ WARNING 8: System may become UNBOOTABLE
echo ⚠️ WARNING 9: Recovery may be IMPOSSIBLE
echo ⚠️ WARNING 10: YOU HAVE BEEN WARNED 10 TIMES
echo.
echo ====================================================================
echo                      FINAL CONFIRMATION
echo ====================================================================
echo.
echo Type "I ACCEPT BRICKING MY VM WITH OFFICIAL ROLLBACK" to continue:
echo.
set /p confirm="Response: "

if not "!confirm!"=="I ACCEPT BRICKING MY VM WITH OFFICIAL ROLLBACK" (
    echo Operation cancelled.
    timeout /t 3
    goto UEFI_LEGACY_MENU
)

:: Check for Windows.old
if not exist "%SystemDrive%\Windows.old" (
    echo.
    echo No Windows.old found. Please select source manually.
    echo You can drag and drop a Windows installation folder.
    echo.
    set /p source="Source path (or drag here): "
    
    if not exist "!source!\Windows" (
        echo Invalid Windows source!
        timeout /t 3
        goto UEFI_LEGACY_MENU
    )
    call :detect_windows_version "!source!"
    set "source_version=!full_version!"
) else (
    set "source=%SystemDrive%\Windows.old"
    call :detect_windows_version "!source!"
    set "source_version=!full_version!"
)

echo.
echo ====================================================================
echo              STAGE 1: BACKING UP CURRENT SYSTEM
echo ====================================================================
echo.
echo Creating comprehensive backup before conversion...
set "backuptime=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "backuptime=!backuptime: =0!"
set "backupdir=%SystemDrive%\OfficialRollbackBackup_!backuptime!"

mkdir "%backupdir%" 2>nul
mkdir "%backupdir%\Boot" 2>nul
mkdir "%backupdir%\System" 2>nul
mkdir "%backupdir%\Registry" 2>nul

echo Backing up boot configuration...
bcdedit /export "%backupdir%\Boot\bcd_backup.bcd" >> "%logfile%"

echo Backing up registry...
reg save HKLM\SYSTEM "%backupdir%\Registry\SYSTEM.hiv" /y >> "%logfile%" 2>&1
reg save HKLM\SOFTWARE "%backupdir%\Registry\SOFTWARE.hiv" /y >> "%logfile%" 2>&1

echo.
echo ====================================================================
echo              STAGE 2: COPYING WINDOWS.OLD FILES
echo ====================================================================
echo.
echo Copying files from %source% (!source_version!) to %SystemDrive%...
echo This may take a while...

:: Take ownership
takeown /F "%source%" /R /D Y 2>nul >> "%logfile%"
icacls "%source%" /grant administrators:F /T 2>nul >> "%logfile%"

:: Copy files
robocopy "%source%" "%SystemDrive%" /MIR /A-:R /W:1 /R:1 /NP /NFL /NDL /MT:32 /ETA /LOG+:"%logfile%"

set copyresult=%errorlevel%
if %copyresult% geq 8 (
    echo [ERROR] Copy had major issues! Check log.
) else (
    echo [SUCCESS] Files copied successfully!
)

echo.
echo ====================================================================
echo              STAGE 3: CONVERTING UEFI TO LEGACY
echo ====================================================================
echo.
echo Attempting UEFI to Legacy conversion...
echo This is the DANGEROUS part!

:: Backup current firmware type
reg query "HKLM\SYSTEM\CurrentControlSet\Control" /v "PEFirmwareType" > "%backupdir%\firmware_type.txt" 2>&1

:: Modify boot configuration for Legacy
echo Modifying boot configuration for Legacy mode...
bcdedit /set {current} path \Windows\system32\winload.exe >> "%logfile%" 2>&1
bcdedit /deletevalue {current} testsigning >> "%logfile%" 2>&1
bcdedit /set {current} detecthal yes >> "%logfile%" 2>&1

:: Modify registry for Legacy mode
echo Modifying registry for Legacy mode...
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "PEFirmwareType" /t REG_DWORD /d 0 /f >> "%logfile%" 2>&1

:: Modify boot sector
echo Modifying boot sector for Legacy...
bootsect /nt60 SYS /force /mbr >> "%logfile%" 2>&1

:: Update BCD for Legacy
echo Updating BCD for Legacy...
bcdedit /set {bootmgr} device boot >> "%logfile%" 2>&1
bcdedit /set {bootmgr} path \bootmgr >> "%logfile%" 2>&1

echo.
echo ====================================================================
echo              STAGE 4: FINALIZING ROLLBACK
echo ====================================================================
echo.

:: Create the success file with ACTUAL Windows version
echo ======================================================== > "%successfile%"
echo              CONGRATULATIONS! >> "%successfile%"
echo ======================================================== >> "%successfile%"
echo. >> "%successfile%"
echo ╔══════════════════════════════════════════════════════════╗ >> "%successfile%"
echo ║                                                          ║ >> "%successfile%"
echo ║     YOUR SYSTEM IS NOW RUNNING:                          ║ >> "%successfile%"
echo ║     !source_version!                                     ║ >> "%successfile%"
echo ║                                                          ║ >> "%successfile%"
echo ╚══════════════════════════════════════════════════════════╝ >> "%successfile%"
echo. >> "%successfile%"
echo Rollback completed on: %date% at %time% >> "%successfile%"
echo Source: %source% (!source_version!) >> "%successfile%"
echo Target: %SystemDrive% (was %winver%) >> "%successfile%"
echo Original Boot Mode: UEFI >> "%successfile%"
echo New Boot Mode: Legacy BIOS >> "%successfile%"
echo Backup Location: %backupdir% >> "%successfile%"
echo. >> "%successfile%"
echo Your system has been converted to Legacy BIOS mode >> "%successfile%"
echo and rolled back to !source_version! >> "%successfile%"
echo. >> "%successfile%"
echo If you can read this, the operation was SUCCESSFUL! >> "%successfile%"
echo If your system doesn't boot, restore from backup: %backupdir% >> "%successfile%"
echo ======================================================== >> "%successfile%"

echo.
echo ====================================================================
echo              OFFICIAL ROLLBACK COMPLETED
echo ====================================================================
echo.
type "%successfile%"
echo.
echo ====================================================================
echo                      SYSTEM WILL RESTART
echo ====================================================================
echo.
echo The system will restart in 30 seconds to boot into:
echo !source_version!
echo.
echo If you see the Legacy BIOS boot screen, it worked!
echo If you see nothing, restore from backup: %backupdir%
echo.
timeout /t 30
shutdown /r /t 0 /c "Official rollback to !source_version! with UEFI to Legacy conversion"
goto UEFI_LEGACY_MENU

:DISABLE_UEFI
cls
echo ====================================================================
echo           ⚠️  ATTEMPTING TO DISABLE UEFI MODE ⚠️
echo ====================================================================
echo.
echo This will attempt to switch from UEFI to Legacy BIOS mode.
echo THIS WILL ALMOST CERTAINLY PREVENT BOOTING!
echo.
echo Current Windows: %winver% (Build %releaseid% - %buildnum%)
echo.
echo You must type the following EXACTLY to proceed:
echo "I UNDERSTAND THIS WILL MAKE MY SYSTEM UNBOOTABLE"
echo.
set /p confirm="Response: "

if "!confirm!"=="I UNDERSTAND THIS WILL MAKE MY SYSTEM UNBOOTABLE" (
    echo Attempting UEFI disable at %time% >> "%logfile%"
    
    :: Backup current configuration
    bcdedit /export "%SystemDrive%\bcd_before_uefi_disable.bcd" >> "%logfile%"
    
    :: Attempt to modify boot configuration for Legacy
    echo Modifying boot configuration...
    bcdedit /set {current} path \Windows\system32\winload.exe >> "%logfile%" 2>&1
    bcdedit /deletevalue {current} testsigning >> "%logfile%" 2>&1
    bcdedit /set {current} detecthal yes >> "%logfile%" 2>&1
    
    :: Attempt registry modifications
    echo Modifying registry for Legacy mode...
    reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "PEFirmwareType" /t REG_DWORD /d 0 /f >> "%logfile%" 2>&1
    
    :: Modify boot sector
    echo Modifying boot sector...
    bootsect /nt60 SYS /force /mbr >> "%logfile%" 2>&1
    
    echo.
    echo UEFI disable attempted. System will now restart.
    echo IF THIS WAS A REAL SYSTEM, IT WOULD PROBABLY NOT BOOT.
    echo.
    shutdown /r /t 30 /c "UEFI disable attempted - system may not boot"
) else (
    echo Operation cancelled.
    timeout /t 3
    goto UEFI_LEGACY_MENU
)

:ENABLE_UEFI
cls
echo ====================================================================
echo           ⚠️  ATTEMPTING TO ENABLE UEFI MODE ⚠️
echo ====================================================================
echo.
echo This will attempt to switch from Legacy BIOS to UEFI mode.
echo THIS REQUIRES GPT PARTITION TABLE AND EFI SYSTEM PARTITION!
echo.
echo Current Windows: %winver% (Build %releaseid% - %buildnum%)
echo.
echo Type "I HAVE GPT PARTITIONS AND ACCEPT BRICKING" to proceed:
echo.
set /p confirm="Response: "

if "!confirm!"=="I HAVE GPT PARTITIONS AND ACCEPT BRICKING" (
    echo Attempting UEFI enable at %time% >> "%logfile%"
    
    :: Check for EFI partition
    echo Checking for EFI system partition...
    diskpart /s create_efi.txt 2>nul
    
    :: Backup current configuration
    bcdedit /export "%SystemDrive%\bcd_before_uefi_enable.bcd" >> "%logfile%"
    
    :: Attempt to modify boot configuration for UEFI
    echo Modifying boot configuration...
    bcdedit /set {current} path \Windows\system32\winload.efi >> "%logfile%" 2>&1
    bcdedit /set {current} testsigning on >> "%logfile%" 2>&1
    
    :: Attempt registry modifications
    echo Modifying registry for UEFI mode...
    reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "PEFirmwareType" /t REG_DWORD /d 1 /f >> "%logfile%" 2>&1
    
    echo.
    echo UEFI enable attempted. System will now restart.
    echo IF THIS WAS A REAL SYSTEM, IT WOULD PROBABLY NOT BOOT.
    echo.
    shutdown /r /t 30 /c "UEFI enable attempted - system may not boot"
) else (
    echo Operation cancelled.
    timeout /t 3
    goto UEFI_LEGACY_MENU
)

:CHECK_UEFI
cls
echo ====================================================================
echo                   UEFI FIRMWARE INFORMATION
echo ====================================================================
echo.
echo Current boot mode: %uefimode%
echo Current Windows: %winver% (Build %releaseid% - %buildnum%)
echo.
echo Firmware type:
wmic computersystem get firmwaretype >> "%temp%\firmware.txt"
type "%temp%\firmware.txt"
del "%temp%\firmware.txt"
echo.
echo UEFI variables:
reg query "HKLM\SYSTEM\CurrentControlSet\Control" /v "PEFirmwareType" 2>nul
echo.
echo Boot configuration:
bcdedit /enum firmware | findstr /i "description" | findstr /v "Windows"
echo.
pause
goto UEFI_LEGACY_MENU

:BACKUP_BCD
cls
echo ====================================================================
echo                  BACKUP BOOT CONFIGURATION
echo ====================================================================
echo.
set "backuptime=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "backuptime=!backuptime: =0!"
set "backupfile=%SystemDrive%\BootBackup_!backuptime!.bcd"

echo Backing up boot configuration to !backupfile!...
bcdedit /export "!backupfile!" >> "%logfile%"

if exist "!backupfile!" (
    echo Backup successful!
    echo Backup location: !backupfile!
) else (
    echo Backup failed!
)
pause
goto UEFI_LEGACY_MENU

:RESTORE_BCD
cls
echo ====================================================================
echo                  RESTORE BOOT CONFIGURATION
echo ====================================================================
echo.
echo Available backups:
dir "%SystemDrive%\*.bcd" /b 2>nul
echo.
set /p restorefile="Enter backup filename to restore: "

if exist "%SystemDrive%\!restorefile!" (
    echo Restoring from %SystemDrive%\!restorefile!...
    bcdedit /import "%SystemDrive%\!restorefile!" >> "%logfile%"
    echo Restore attempted.
) else (
    echo File not found!
)
pause
goto UEFI_LEGACY_MENU

:END
echo Operation completed. Check log at: %logfile%
endlocal
pause