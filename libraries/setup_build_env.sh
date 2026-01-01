#!/bin/sh


if [ ! -f "libraries/setup_build_env.sh" ]; then
  echo "Invoke this script from the root directory of the checkout."
  echo
  echo "FAILED"
  return 1
fi


echo "Setting up repository at $PWD"


echo
echo Checking CMake version
echo
cmake --version

if [ $? -ne 0 ]; then
  echo
  echo "Failed to check cmake -- is it installed?"
  echo
  echo "FAILED"
  return 1
fi


echo
echo "Checking Clang version"
echo
clang++ --version

if [ $? -ne 0 ]; then
  echo
  echo "Failed to check clang -- is it installed?"
  echo
  echo FAILED
  return 1
fi


if [ ! -d "libraries/depot_tools" ]; then
  echo
  echo "Checking out the Chrome depot_tools at libraries/depot_tools"
  echo
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git libraries/depot_tools
  if [ $? -ne 0 ]; then
    echo
    echo FAILED
    return 1
  fi
fi

depot_tools="$PWD/libraries/depot_tools"

# Update PATH before the gclient --version check, to use cipd.
export PATH="${depot_tools}:$PATH"

echo
echo "Verifying depot_tools gclient version (this may download additional tools)"
echo
"${depot_tools}/gclient" validate --version

if [ $? -ne 0 ]; then
  echo
  echo "Failed to initialize gclient tools"
  echo
  echo FAILED
  return 1
fi


# Check if ninja is already available in PATH (e.g., installed via package manager)
if command -v ninja >/dev/null 2>&1; then
  echo
  echo "Using system ninja: $(which ninja)"
  ninja --version
else
  if [ ! -d "libraries/ninja" ]; then
    echo
    echo "Checking out the ninja build tool"
    echo
    git clone https://github.com/ninja-build/ninja libraries/ninja
    if [ $? -ne 0 ]; then
      echo
      echo FAILED
      return 1
    fi
  fi

  if [ ! -f "libraries/ninja/ninja" ]; then
    echo
    echo "Building the ninja build tool"
    echo
    pushd libraries/ninja
    python3 configure.py --bootstrap
    popd
  fi

  if [ ! -f "libraries/ninja/ninja" ]; then
    echo
    echo "Ninja build failed."
    echo
    echo FAILED
    return 1
  fi
fi


# Download gn using cipd (Chrome Infrastructure Package Deployment)
# This is more reliable than depot_tools' gn wrapper which may try to build from source
echo
echo "Setting up gn build tool"
echo

gn_dir="$PWD/libraries/gn_bin"
if [ ! -f "${gn_dir}/gn" ]; then
  mkdir -p "${gn_dir}"

  # Detect platform
  case "$(uname -s)" in
    Linux*)  gn_platform="linux-amd64" ;;
    Darwin*)
      case "$(uname -m)" in
        arm64) gn_platform="mac-arm64" ;;
        *)     gn_platform="mac-amd64" ;;
      esac
      ;;
    *)       gn_platform="linux-amd64" ;;
  esac

  echo "Downloading gn for ${gn_platform}..."
  "${depot_tools}/cipd" install gn/gn/${gn_platform} -root "${gn_dir}"

  if [ $? -ne 0 ]; then
    echo
    echo "Failed to download gn via cipd"
    echo
    echo FAILED
    return 1
  fi
fi


echo
echo "Updating PATH to use gn, depot_tools, and ninja"
echo

# Add gn to PATH
export PATH="${gn_dir}:$PATH"

# Add local ninja to PATH if built from source
if [ -f "libraries/ninja/ninja" ]; then
  export PATH="$PWD/libraries/ninja:$PATH"
fi

# depot_tools provides gclient and other tools
export PATH="${depot_tools}:$PATH"

# Forgets all remembered locations:
hash -r


echo
echo "Verifying gn and ninja in PATH"
echo

gn --version

if [ $? -ne 0 ]; then
  echo
  echo "Failed to check GN version"
  echo
  echo FAILED
  return 1
fi

ninja --version

if [ $? -ne 0 ]; then
  echo
  echo "Failed to check ninja version"
  echo
  echo FAILED
  return 1
fi


export CC=clang
export CXX=clang++


echo
echo "FINISHED -- ready to fetch dependencies with ./libraries/sync.sh"
