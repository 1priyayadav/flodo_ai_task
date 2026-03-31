$ErrorActionPreference = "Continue"

Write-Host "Ensuring C:\src directory exists..."
if (-not (Test-Path -Path 'C:\src')) {
    New-Item -ItemType Directory -Force -Path 'C:\src' | Out-Null
}

Write-Host "Cloning Flutter Stable branch from GitHub..."
if (-not (Test-Path -Path 'C:\src\flutter')) {
    git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter
} else {
    Write-Host "Flutter folder already exists at C:\src\flutter"
}

$flutterBin = "C:\src\flutter\bin"
Write-Host "Checking User Path environment variable..."
$userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)

if ($userPath -notlike "*$flutterBin*") {
    Write-Host "Appending Flutter bin to User PATH..."
    if ($userPath -notmatch ";$") {
        $userPath += ";"
    }
    $newPath = $userPath + $flutterBin
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
    
    # Expose for this current session
    $env:PATH += ";$flutterBin"
} else {
    Write-Host "Flutter is already present in User PATH."
    $env:PATH += ";$flutterBin" # ensure current context just in case
}

Write-Host "Executing flutter doctor to complete initial SDK setup. This may take several minutes..."
flutter doctor
