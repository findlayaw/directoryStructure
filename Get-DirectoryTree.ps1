# Get-DirectoryTree.ps1
# Script to generate a directory tree with full paths and copy to clipboard
# Respects .gitignore rules

# Get the current directory (where the command is run from, not where the script is located)
$currentDir = Get-Location
$currentDirPath = $currentDir.Path

# Check if .gitignore exists
$gitignorePath = Join-Path -Path $currentDirPath -ChildPath ".gitignore"
$ignorePatterns = @()

if (Test-Path -Path $gitignorePath) {
    # Read and parse .gitignore file
    $ignorePatterns = Get-Content -Path $gitignorePath | Where-Object {
        $_ -and -not $_.StartsWith('#') -and -not [string]::IsNullOrWhiteSpace($_)
    }
}

# Function to check if a path should be ignored based on .gitignore patterns
function Should-Ignore {
    param (
        [string]$path
    )

    # Get relative path from the current directory
    $relativePath = $path.Substring($currentDirPath.Length).TrimStart('\', '/')
    if ([string]::IsNullOrEmpty($relativePath)) { return $false }

    foreach ($pattern in $ignorePatterns) {
        # Handle exact matches
        if ($relativePath -eq $pattern) { return $true }

        # Handle directory matches (patterns ending with /)
        if ($pattern.EndsWith('/') -or $pattern.EndsWith('\')) {
            $dirPattern = $pattern.TrimEnd('/', '\')
            if ($relativePath -eq $dirPattern -or $relativePath.StartsWith("$dirPattern\")) { return $true }
        }

        # Handle wildcard matches
        if ($pattern.Contains('*')) {
            $regex = [WildcardPattern]::new($pattern, [System.Management.Automation.WildcardOptions]::IgnoreCase)
            if ($regex.IsMatch($relativePath)) { return $true }
        }

        # Handle simple path matches
        if ($relativePath.StartsWith($pattern) -or $relativePath.EndsWith($pattern)) { return $true }
    }

    return $false
}

# Function to get all files and directories recursively
function Get-DirectoryStructure {
    param (
        [string]$path
    )

    # Get all items (files and directories)
    $items = Get-ChildItem -Path $path -Force

    foreach ($item in $items) {
        # Skip if the item should be ignored based on .gitignore
        if (Should-Ignore -path $item.FullName) { continue }

        # Output the relative path
        $relativePath = $item.FullName.Substring($currentDirPath.Length).TrimStart('\', '/')
        if (-not [string]::IsNullOrEmpty($relativePath)) {
            $relativePath
        }

        # If it's a directory, recursively get its contents
        if ($item.PSIsContainer) {
            Get-DirectoryStructure -path $item.FullName
        }
    }
}

# Get the directory structure
$dirTree = @(Get-DirectoryStructure -path $currentDirPath)

# Create XML output
$xmlOutput = "<directory>`n"
$xmlOutput += $dirTree -join "`n"
$xmlOutput += "`n</directory>"

# Copy to clipboard
$xmlOutput | Set-Clipboard

# Display in console
Write-Output $xmlOutput

# Notify user
Write-Output ""
Write-Output "Directory tree has been copied to clipboard!"
