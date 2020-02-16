param([String]$arch)
<#
  This script is executed by `npm install`, and builds things required by gpii-windows.
#>
# Turn verbose on, change to "SilentlyContinue" for default behaviour.
$VerbosePreference = "continue"

if (!$arch) {
    throw "Argument '-arch' (architecture) must be passed to this script.  Valid options are: [x86, AMD64, arm64]"
}

switch ($arch) {
  "x86" {
    echo "Building Windows executables for Intel 32 (i.e. IA32/x86) architecture"
    $targetArchitecture = "x86"
  }
  "AMD64" {
    echo "Building Windows executables for Intel 64 (i.e. AMD64/x64/x86_64) architecture"
    $targetArchitecture = "x64"
  }
  "arm64" {
    echo "Building Windows executables for ARM64 architecture"
    $targetArchitecture = "ARM64"
  }
  default {
    throw "Invalid architecture '$($arch)'.  Valid options are: [x86, AMD64, arm64]"
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir

if (${Env:ProgramFiles(x86)}) {
  $programFilesX86Path = ${Env:ProgramFiles(x86)}
} else {
  # This is required for compatibility with Intel 32-bit systems (since the ProgramFiles(x86) environment variable does not exist on 32-bit Windows)
  $programFilesX86Path = ${Env:ProgramFiles}
}
$programFilesPath = ${Env:ProgramFiles}

# Include main Provisioning module.
Import-Module (Join-Path $scriptDir 'Provisioning.psm1') -Force -Verbose

# Capture the full file path of MSBuild; we will accept any version >=15.0 and <16.0 (i.e. VS2017)
$msbuild = Get-MSBuild "[15.0,16.0)"

# # Build the settings helper
# $settingsHelperDir = Join-Path $rootDir "settingsHelper"
# Invoke-Command $msbuild "SettingsHelper.sln /p:Configuration=Release /p:Platform=`"Any CPU`" /p:FrameworkPathOverride=`"C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.5.1`"" $settingsHelperDir

$volumeControlDir = Join-Path $rootDir "gpii\node_modules\nativeSettingsHandler\nativeSolutions\VolumeControl"
switch ($targetArchitecture) {
  "x86" {
    Invoke-Command $msbuild "VolumeControl.sln /p:Configuration=Release /p:Platform=`"$($targetArchitecture)`" /p:FrameworkPathOverride=`"$($programFilesX86Path)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.5.1`"" $volumeControlDir
  }
  "x64" {
    Invoke-Command $msbuild "VolumeControl.sln /p:Configuration=Release /p:Platform=`"$($targetArchitecture)`" /p:FrameworkPathOverride=`"$($programFilesPath)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.5.1`"" $volumeControlDir
  }
  "ARM64" {
    # NOTE: the VolumeControl project uses the Windows 8.1 SDK, so it's not possible to compile for ARM64.  Therefore we compile for x86 instead (and use x86 on ARM64 emulation)
    Invoke-Command $msbuild "VolumeControl.sln /p:Configuration=Release /p:Platform=`"x86`" /p:FrameworkPathOverride=`"$($programFilesX86Path)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.5.1`"" $volumeControlDir
  }
}

# # Build the process test helper
# $testProcessHandlingDir = Join-Path $rootDir "gpii\node_modules\processHandling\test"
# $csc = Join-Path -Path (Split-Path -Parent $msbuild) csc.exe
# Invoke-Command $csc "/target:exe /out:test-window.exe test-window.cs" $testProcessHandlingDir

# # Build the Windows Service
# $serviceDir = Join-Path $rootDir "gpii-service"
# Invoke-Command "npm" "install" $serviceDir
