@echo off
setlocal

rem GALACTIC FRONTIER: one-command asset production and Unreal import.
rem Optional overrides:
rem   set BLENDER_EXE=C:\Path\To\blender.exe
rem   set UE_EDITOR_EXE=C:\Path\To\UnrealEditor.exe

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "BLENDER_SCRIPT=%ROOT%\scripts\blender\build_space_environment.py"
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
    "%ProgramFiles%\Epic Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor.exe"
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

echo [1/2] Generating deep-space backdrop and four planet models...
"%BLENDER_EXE%" --background --python "%BLENDER_SCRIPT%" -- --output-dir "%ROOT%\assets\models"
if errorlevel 1 (
  echo ERROR: Blender generation failed. Unreal import was not started.
  pause
  exit /b 5
)

echo [2/2] Launching Unreal Editor sequential import pipeline...
echo Queue: ships -^> environment -^> space -^> planets
start "GALACTIC FRONTIER Unreal Asset Pipeline" "%UE_EDITOR_EXE%" "%UE_PROJECT%" "-ExecutePythonScript=%UE_SCRIPT%"

echo Unreal Editor has been launched. Follow [GF Setup] PIPELINE messages in Output Log.
echo Final report: Unreal\Saved\GFAssetManifests\asset_pipeline_report.json
endlocal
