#!/usr/bin/env bash

# First check if we have a good python binary to use
find_python_bin() {
  local possible_binaries=("python3.10" "python310" "python3" "python")

  for binary in "${possible_binaries[@]}"; do
    if command -v "$binary" >/dev/null 2>&1; then
      local version_output
      version_output=$($binary --version 2>&1)
      read -ra version_parts <<<"${version_output//./ }"
      local major=${version_parts[1]}
      local minor=${version_parts[2]}
      if [ "$major" -eq 3 ] && [ "$minor" -eq 10 ]; then
        # shellcheck disable=SC2086
        command -v $binary
        return 0
      fi
    fi
  done

  echo "No suitable Python binary found" >&2
  exit 1
}

if command -v deactivate >&/dev/null; then
  deactivate
elif [[ -n $VIRTUAL_ENV ]]; then
  echo "Detected virtual environment. Attempting to deactivate."

  # Remove the virtual environment's bin directory from PATH
  PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "$VIRTUAL_ENV/bin" | tr '\n' ':')

  # Unset the VIRTUAL_ENV variable
  unset VIRTUAL_ENV
fi

# If it is run with the sudo command, get the complete LD_LIBRARY_PATH environment variable of the system and assign it to the current environment,
# because it will be used later.
if [ -n "$SUDO_USER" ] || [ -n "$SUDO_COMMAND" ]; then
  echo "The sudo command resets the non-essential environment variables, we keep the LD_LIBRARY_PATH variable."
  export LD_LIBRARY_PATH=$(sudo -i printenv LD_LIBRARY_PATH)
fi

# This gets the directory the script is run from so pathing can work relative to the script where needed.
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
LAUNCHER="$SCRIPT_DIR/launcher.py"
PYTHON=$(find_python_bin)

echo "Selected Python binary: $PYTHON"

# Determine if --update or --repair or -u or -r is in the arguments
if [[ $* != *"--update"* && $* != *"--repair"* && $* != *"-u"* && $* != *"-r"* ]]; then
  # Run the launcher script with the selected Python binary and --no-setup
  if [ -f "$LAUNCHER" ]; then
    "$PYTHON" "$LAUNCHER" --no-setup "$@"
  else
    echo "Sorry, $LAUNCHER not found."
  fi
else
  # Run the launcher script with the selected Python binary
  if [ -f "$LAUNCHER" ]; then
    "$PYTHON" "$LAUNCHER" "$@"
  else
    echo "Sorry, $LAUNCHER not found."
  fi
fi
