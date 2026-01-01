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

    cmd.exe /c "call `"$vcvarspath\VC\Auxiliary\Build\vcvars64.bat`" && set > %temp%\vcvars.txt"

    Get-Content "$env:temp\vcvars.txt" | Foreach-Object {
      if ($_ -match "^(.*?)=(.*)$") {
        Set-Content "env:\$($matches[1])" $matches[2]
      }
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


$depot_tools = "$(pwd)\libraries\depot_tools"

$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"

# Add depot_tools to PATH early so cipd is available
$env:path = "${depot_tools};$env:path"

Write-Host ""
Write-Host "Verifying depot_tools gclient version (this may download additional tools)"
Write-Host ""

try {
  & "${depot_tools}\gclient.bat" validate --version
} catch {
  Write-Host ""
  Write-Host "Failed to initialize gclient."
  Write-Host ""
  Write-Host "FAILED"
  exit 1
}


# Check if ninja is already available in PATH (e.g., installed via package manager)
$ninjaCmd = Get-Command ninja -ErrorAction SilentlyContinue
if ($ninjaCmd) {
  Write-Host ""
  Write-Host "Using system ninja: $($ninjaCmd.Source)"
  ninja --version
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
      python configure.py --bootstrap
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


# Download gn using cipd (Chrome Infrastructure Package Deployment)
# This is more reliable than depot_tools' gn wrapper which may try to build from source
Write-Host ""
Write-Host "Setting up gn build tool"
Write-Host ""

$gn_dir = "$(pwd)\libraries\gn_bin"
if (-not(Test-Path -Path "${gn_dir}\gn.exe" -PathType Leaf)) {
  New-Item -ItemType Directory -Force -Path $gn_dir | Out-Null

  Write-Host "Downloading gn for windows-amd64..."
  & "${depot_tools}\cipd.bat" install gn/gn/windows-amd64 -root $gn_dir

  if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Failed to download gn via cipd"
    Write-Host ""
    Write-Host "FAILED"
    exit 1
  }
}


Write-Host ""
Write-Host "Updating PATH to use gn, depot_tools, and ninja"

# Add gn to PATH
$env:path = "${gn_dir};$env:path"

# Add local ninja to PATH if built from source
if (Test-Path -Path 'libraries\ninja\ninja.exe' -PathType Leaf) {
  $env:path = "$(pwd)\libraries\ninja;$env:path"
}

# depot_tools provides gclient and other tools
$env:path = "${depot_tools};$env:path"

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
