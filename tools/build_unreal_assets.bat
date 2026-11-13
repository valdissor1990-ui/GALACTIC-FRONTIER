@echo off
setlocal

rem GALACTIC FRONTIER: one-command asset production and Unreal import.
rem Optional overrides:
rem   set BLENDER_EXE=C:\Path\To\blender.exe
rem   set UE_EDITOR_EXE=C:\Path\To\UnrealEditor.exe

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "BLENDER_SCRIPT=%ROOT%\scripts\blender\build_space_environment.py"
set "BUILD_DIR=%ROOT%\build\unreal-assets"
set "VALIDATION_REPORT=%BUILD_DIR%\fleet-validation.json"
set "UE_PROJECT=%ROOT%\Unreal\GalacticFrontier.uproject"
set "UE_SCRIPT=%ROOT%\Unreal\Content\Python\setup_galactic_frontier.py"

if not defined BLENDER_EXE (
  for %%I in (
    "%ProgramFiles%\Blender Foundation\Blender 4.5\blender.exe"
    "%ProgramFiles%\Blender Foundation\Blender 4.4\blender.exe"
  ) do if exist "%%~I" set "BLENDER_EXE=%%~I"
)
if not defined BLENDER_EXE (
  where blender.exe >nul 2>nul
  if not errorlevel 1 for /f "delims=" %%I in ('where blender.exe') do if not defined BLENDER_EXE set "BLENDER_EXE=%%I"
)
if not defined BLENDER_EXE (
  echo ERROR: Blender 4.5 was not found.
  echo Install Blender: https://www.blender.org/download/
  echo Or set BLENDER_EXE to the full path of blender.exe.
  pause
  exit /b 2
)

if not defined UE_EDITOR_EXE (
  for %%I in (
    "%ProgramFiles%\Epic Games\UE_5.8\Engine\Binaries\Win64\UnrealEditor.exe"
  ) do if exist "%%~I" set "UE_EDITOR_EXE=%%~I"
)
if not defined UE_EDITOR_EXE (
  echo ERROR: UnrealEditor.exe was not found.
  echo Install Unreal Engine 5.8 from https://www.unrealengine.com/download
  echo Or set UE_EDITOR_EXE to the full path of UnrealEditor.exe.
  pause
  exit /b 3
)

if not exist "%UE_PROJECT%" (
  echo ERROR: Unreal project not found: %UE_PROJECT%
  pause
  exit /b 4
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

echo [1/5] Building Player Fighter Mk.I...
"%BLENDER_EXE%" --background --python "%ROOT%\scripts\blender\build_player_fighter.py" -- --output-dir "%BUILD_DIR%"
if errorlevel 1 goto :build_failed

echo [2/5] Building Raider Interceptor...
"%BLENDER_EXE%" --background --python "%ROOT%\scripts\blender\build_enemy_interceptor.py" -- --output-dir "%BUILD_DIR%"
if errorlevel 1 goto :build_failed

echo [3/5] Building Heavy Fighter, Bomber, Cargo Hauler, Frigate and Cruiser in sequence...
"%BLENDER_EXE%" --background --python "%ROOT%\scripts\blender\build_fleet_expansion.py" -- --output-dir "%BUILD_DIR%"
if errorlevel 1 goto :build_failed

echo [4/5] Validating all seven ship builds before replacing source assets...
"%BLENDER_EXE%" --background --python "%ROOT%\scripts\blender\validate_fleet_assets.py" -- --output-dir "%BUILD_DIR%" --report "%VALIDATION_REPORT%"
if errorlevel 1 (
  echo ERROR: Fleet validation failed. Existing source assets were not replaced.
  echo Review: %VALIDATION_REPORT%
  pause
  exit /b 6
)

echo Publishing the validated ship set to the project asset folders...
if not exist "%ROOT%\art_source\ships" mkdir "%ROOT%\art_source\ships"
if not exist "%ROOT%\assets\models\ships" mkdir "%ROOT%\assets\models\ships"
if not exist "%ROOT%\assets\previews" mkdir "%ROOT%\assets\previews"
for %%S in (player_fighter enemy_fighter heavy_fighter bomber cargo_hauler frigate cruiser) do (
  copy /y "%BUILD_DIR%\%%S.blend" "%ROOT%\art_source\ships\%%S.blend" >nul || goto :publish_failed
  copy /y "%BUILD_DIR%\%%S.glb" "%ROOT%\assets\models\ships\%%S.glb" >nul || goto :publish_failed
  copy /y "%BUILD_DIR%\%%S_preview.png" "%ROOT%\assets\previews\%%S_preview.png" >nul || goto :publish_failed
)

echo [5/5] Building the space backdrop and four planets...
"%BLENDER_EXE%" --background --python "%BLENDER_SCRIPT%" -- --output-dir "%ROOT%\assets\models"
if errorlevel 1 goto :build_failed

echo Launching Unreal Editor sequential import pipeline...
echo Queue: ships -^> environment props -^> space backdrop -^> planets
start "GALACTIC FRONTIER Unreal Asset Pipeline" "%UE_EDITOR_EXE%" "%UE_PROJECT%" "-ExecutePythonScript=%UE_SCRIPT%"

echo Unreal Editor has been launched. Follow [GF Setup] PIPELINE messages in Output Log.
echo Final report: Unreal\Saved\GFAssetManifests\asset_pipeline_report.json
endlocal
exit /b 0

:build_failed
echo ERROR: Blender asset production failed. Later stages were not started.
pause
exit /b 7

:publish_failed
echo ERROR: Could not publish a validated model to the source asset folders.
pause
exit /b 8
