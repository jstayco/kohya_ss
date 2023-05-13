<#
.SYNOPSIS
A script to run kohya_ss' launcher.py in a specific environment.

.DESCRIPTION
This script detects and deactivates a Python virtual environment if one is active. 
It then locates the system-wide Python 3.10 binary and uses it to run the launcher script.
It also reads arguments for the launcher script from a file if it exists.
It will then run launcher.py which handles all of the pip validations and virtual env handling.
#>

<#
.SYNOPSIS
Deactivates a Python virtual environment.

.DESCRIPTION
Removes the virtual environment's directories from the PATH and unsets the VIRTUAL_ENV environment variable.

.EXAMPLE
Remove-Venv
#>
function Remove-Venv {
    if ($IsWindows) {
        $env:Path = ($env:Path.Split(";") | Where-Object { $_ -notmatch "venv" }) -join ";"
    }
    else {
        $env:PATH = ($env:PATH.Split(":") | Where-Object { $_ -notmatch "venv" }) -join ":"
    }

    Remove-Variable -Name VIRTUAL_ENV -ErrorAction SilentlyContinue
    Remove-Variable -Name _OLD_VIRTUAL_PATH -ErrorAction SilentlyContinue
}
  
<#
.SYNOPSIS
Finds the system-wide Python 3.10 binary.

.DESCRIPTION
Searches for a Python 3.10 binary in the system's PATH.
Returns the path to the binary if found, or exits with an error if not.

.EXAMPLE
$pythonBin = Find-PythonBin
#>
function Find-PythonBin {
    $possibleBinaries = @("python3.10", "python310", "python3", "python")
    if ($IsWindows) {
        $possibleBinaries = $possibleBinaries | ForEach-Object { $_ + ".exe" }
    }
  
    foreach ($binary in $possibleBinaries) {
        if (Get-Command $binary -ErrorAction SilentlyContinue) {
            $versionOutput = & $binary --version 2>&1
            $versionParts = $versionOutput.Split(" ")
  
            Write-Host "Checking binary: $binary" 
            Write-Host "Version output: $versionOutput" 
  
            $version = $versionParts[1]
            $versionSubParts = $version.Split(".")
            $major = $versionSubParts[0]
            $minor = $versionSubParts[1]
  
            Write-Host "Major: $major" 
            Write-Host "Minor: $minor" 
  
            if ($major -eq 3 -and $minor -eq 10) {
                return (Get-Command $binary).Source
            }
        }
    }
  
    Write-Error "No suitable Python binary found. Checked binaries: $($possibleBinaries -join ', ')"
    exit 1
}
  
# This gets the directory the script is run from so pathing can work relative to the script where needed.
$launcher = Join-Path -Path $PSScriptRoot -ChildPath "launcher.py"
  
# Detect and deactivate a Python virtual environment if it's activated
if ($null -ne $env:VIRTUAL_ENV) {
    Write-Host "Detected virtual environment. Attempting to deactivate."
    Remove-Venv
}
  
$python = Find-PythonBin
  
if ($null -eq $python) {
    Write-Error "Python 3.10 is not found on this system."
    exit 1
}
  
Write-Host "Selected Python binary: $python"
  
# Read arguments from gui_parameters.txt if it exists
if (Test-Path ".\gui_parameters.txt") {
    $argsFromFile = Get-Content ".\gui_parameters.txt" -Encoding UTF8 | Where-Object { $_ -notmatch "^#" } | Foreach-Object { $_ -split " " }
    $args += $argsFromFile
}

# Ensure Torch is in PATH
$env:PATH += ";$($MyInvocation.MyCommand.Path)\venv\Lib\site-packages\torch\lib"
  
# Determine if --update or --repair or -u or -r is in the arguments
if ($args -notcontains '--update' -and $args -notcontains '--repair' -and $args -notcontains '-u' -and $args -notcontains '-r') {
    # Run the launcher script with the selected Python binary and --no-setup
    if (Test-Path $launcher) {
        & $python $launcher --no-setup $args
    }
    else {
        Write-Error "Sorry, $launcher not found."
    }
}
else {
    # Run the launcher script with the selected Python binary
    if (Test-Path $launcher) {
        & $python $launcher $args
    }
    else {
        Write-Error "Sorry, $launcher not found."
    }
}
  