if (-not(Test-Path -Path 'libraries\setup_build_env.ps1' -PathType Leaf)) {
  Write-Host "Invoke this script from the root repository of the checkout."
  Write-Host "FAILED"
  exit 1
}


if ($(pwd) -like "* *") {
  Write-Host "This script doesn't work with paths that contain spaces."
  Write-Host "FAILED"
  exit 1
}


Write-Host "Setting up repository at $(pwd)"


if (-not($env:windowjs_visual_studio_ready -eq "1")) {
  Write-Host ""
  Write-Host "Setting up Visual Studio build tools environment"
  Write-Host ""

  try {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $vcvarspath = &$vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath

    # Find the latest installed Windows SDK version
    $sdkPath = "C:\Program Files (x86)\Windows Kits\10\Include"
    $sdkVersions = Get-ChildItem $sdkPath -Directory | Where-Object { $_.Name -match "^10\.\d+\.\d+\.\d+$" } | Sort-Object Name -Descending
    $latestSdk = $sdkVersions[0].Name
    Write-Host "Using Windows SDK: $latestSdk"

    # Set Windows SDK environment variables before calling vcvarsall
    $sdkBase = "C:\Program Files (x86)\Windows Kits\10"
    $env:WindowsSDKDir = "$sdkBase\"
    $env:WindowsSDKVersion = "$latestSdk\"
    $env:UCRTVersion = $latestSdk
    $env:UniversalCRTSdkDir = "$sdkBase\"
    # Call vcvarsall with SDK version as positional argument
    cmd.exe /c "call `"$vcvarspath\VC\Auxiliary\Build\vcvarsall.bat`" x64 $latestSdk && set > %temp%\vcvars.txt"

    Get-Content "$env:temp\vcvars.txt" | Foreach-Object {
      if ($_ -match "^(.*?)=(.*)$") {
        Set-Content "env:\$($matches[1])" $matches[2]
      }
    }

    # Patch INCLUDE and LIB to use the correct SDK version if vcvarsall picked a different one
    $sdkPattern = "10\.0\.\d+\.\d+"
    if ($env:INCLUDE -match $sdkPattern -and $env:INCLUDE -notmatch [regex]::Escape($latestSdk)) {
      $oldSdk = [regex]::Match($env:INCLUDE, $sdkPattern).Value
      Write-Host "Patching SDK version in environment: $oldSdk -> $latestSdk"
      $env:INCLUDE = $env:INCLUDE -replace [regex]::Escape($oldSdk), $latestSdk
      $env:LIB = $env:LIB -replace [regex]::Escape($oldSdk), $latestSdk
      $env:LIBPATH = $env:LIBPATH -replace [regex]::Escape($oldSdk), $latestSdk
    }
  } catch {
    Write-Host ""
    Write-Host "Failed to locate Visual Studio -- is it installed?"
    Write-Host ""
    Write-Host "FAILED"
    exit 1
  }

  $env:windowjs_visual_studio_ready = "1"
}


try {
  Write-Host ""
  Write-Host "Checking CMake version"
  Write-Host ""
  cmake --version
} catch {
  Write-Host ""
  Write-Host "Failed to check cmake -- is it installed?"
  Write-Host ""
  Write-Host "FAILED"
  exit 1
}

if (-not(Test-Path -Path 'libraries\depot_tools' -PathType Container)) {
  Write-Host ""
  Write-Host "Checking out the Chrome depot_tools at libraries\depot_tools"
  Write-Host ""
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git libraries/depot_tools
}


$depot_tools = "$(pwd)/libraries/depot_tools"

$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"

Write-Host ""
Write-Host "Verifying depot_tools gclient version (this may download additional tools)"
Write-Host ""

try {
  Invoke-Expression "${depot_tools}/gclient.bat validate --version"
} catch {
  Write-Host ""
  Write-Host "Failed to initialize gclient."
  Write-Host ""
  Write-Host "FAILED"
  exit 1
}


# Check if ninja is already available in PATH (e.g., installed via package manager)
$systemNinja = Get-Command ninja -ErrorAction SilentlyContinue
if ($systemNinja) {
  Write-Host ""
  Write-Host "Using system ninja: $($systemNinja.Source)"
  Write-Host ""
} else {
  if (-not(Test-Path -Path 'libraries\ninja' -PathType Container)) {
    Write-Host ""
    Write-Host "Checking out the ninja build tool"
    Write-Host ""
    git clone https://github.com/ninja-build/ninja libraries/ninja
  }


  if (-not(Test-Path -Path 'libraries\ninja\ninja.exe' -PathType Leaf)) {
    Write-Host ""
    Write-Host "Building the ninja build tool"
    Write-Host ""
    pushd libraries\ninja
    try {
      Invoke-Expression "${depot_tools}/python.bat configure.py --bootstrap"
      popd
    } catch {
      Write-Host ""
      Write-Host "Ninja build failed."
      Write-Host ""
      Write-Host "FAILED"
      exit 1
    }
  }
}


# Check if gn is already available in PATH (e.g., installed via package manager)
$systemGn = Get-Command gn -ErrorAction SilentlyContinue
if ($systemGn) {
  Write-Host ""
  Write-Host "Using system gn: $($systemGn.Source)"
  Write-Host ""
} else {
  if (-not(Test-Path -Path 'libraries\gn' -PathType Container)) {
    Write-Host ""
    Write-Host "Checking out the gn build tool"
    Write-Host ""
    git clone https://gn.googlesource.com/gn libraries\gn
  }


  if (-not(Test-Path -Path 'libraries\gn\out\gn.exe' -PathType Leaf)) {
    Write-Host ""
    Write-Host "Building the gn build tool"
    Write-Host ""
    pushd libraries\gn
    try {
      Invoke-Expression "${depot_tools}/python.bat build/gen.py"
      # Use system ninja if available, otherwise use local build
      if ($systemNinja) {
        ninja -C out gn.exe
      } else {
        Invoke-Expression "${depot_tools}/../ninja/ninja.exe -C out gn.exe"
      }
      popd
    } catch {
      Write-Host ""
      Write-Host "GN build failed."
      Write-Host ""
      Write-Host "FAILED"
      exit 1
    }
  }
}

Write-Host ""
Write-Host "Updating PATH to use depot_tools and gn"
# Only run update_path.py if we built local gn/ninja (not using system tools)
if (-not $systemGn -or -not $systemNinja) {
  $env:path = Invoke-Expression "${depot_tools}\python.bat libraries\update_path.py $(pwd)"
} else {
  # Just ensure depot_tools is in PATH for gclient
  $env:path = "${depot_tools};$env:path"
}

Write-Host ""
Write-Host "Verifying gn and ninja in PATH"
Write-Host ""

try {
  gn --version
} catch {
  Write-Host ""
  Write-Host "Failed to verify GN version."
  Write-Host ""
  Write-Host "FAILED"
  exit 1
}

try {
  ninja --version
} catch {
  Write-Host ""
  Write-Host "Failed to verify Ninja version."
  Write-Host ""
  Write-Host "FAILED"
  exit 1
}

Write-Host ""
Write-Host "FINISHED -- ready to fetch dependencies with libraries\sync.ps1"
