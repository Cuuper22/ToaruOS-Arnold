# ArnoldC Module Merger v4
# Reorders: constants → top-level variables → functions/comments → main
# ArnoldC grammar requires this exact order.

param(
    [string[]]$SourceFiles,
    [string]$OutputFile
)

$constants = [System.Collections.ArrayList]@()
$topVars = [System.Collections.ArrayList]@()
$funcLines = [System.Collections.ArrayList]@()
$seenConst = @{}
$seenVar = @{}
$seenFunc = @{}

foreach ($file in $SourceFiles) {
    if (-not (Test-Path $file)) { Write-Host "WARN: $file not found"; continue }
    Write-Host "Reading: $(Split-Path $file -Leaf)"
    
    $lines = Get-Content $file
    $inFunc = $false
    $skipFunc = $false
    $varBlock = [System.Collections.ArrayList]@()
    $collectingVar = $false
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $t = $line.TrimStart()
        
        # Constants → always go to constants section (dedup)
        if ($t.StartsWith("LET ME TELL YOU SOMETHING ")) {
            $name = ($t -replace '^LET ME TELL YOU SOMETHING\s+(\S+).*','$1')
            if ($name -and -not $seenConst.ContainsKey($name)) {
                $constants.Add($line) | Out-Null
                $seenConst[$name] = $true
            }
            continue
        }
        
        # Track function start/end
        if ($t -match '^LISTEN TO ME VERY CAREFULLY\s+(\S+)') {
            $fn = $Matches[1]
            $inFunc = $true
            if ($seenFunc.ContainsKey($fn)) {
                Write-Host "  DEDUP func: $fn"
                $skipFunc = $true
                continue
            }
            $seenFunc[$fn] = $true
            $skipFunc = $false
            $funcLines.Add($line) | Out-Null
            continue
        }
        
        if ($t -eq "HASTA LA VISTA, BABY") {
            $inFunc = $false
            if (-not $skipFunc) { $funcLines.Add($line) | Out-Null }
            $skipFunc = $false
            continue
        }
        
        # If we're inside a function being skipped, skip
        if ($skipFunc) { continue }
        
        # If inside a function, everything goes to funcLines
        if ($inFunc) {
            $funcLines.Add($line) | Out-Null
            continue
        }
        
        # Top-level HEY CHRISTMAS TREE → collect as variable block
        if ($t.StartsWith("HEY CHRISTMAS TREE ")) {
            $vname = ($t -replace '^HEY CHRISTMAS TREE\s+(\S+).*','$1')
            if ($seenVar.ContainsKey($vname)) {
                # Skip entire var block
                $i++
                while ($i -lt $lines.Count) {
                    $nt = $lines[$i].TrimStart()
                    if ($nt.StartsWith("HEY CHRISTMAS TREE") -or
                        $nt.StartsWith("LISTEN TO ME") -or
                        $nt.StartsWith("LET ME TELL") -or
                        $nt.StartsWith("TALK TO YOURSELF") -or
                        $nt -eq "IT'S SHOWTIME") { break }
                    # Skip array data and blank lines
                    if (-not ($nt -match '^[0-9x]' -or $nt.StartsWith("THIS IS A") -or
                        $nt.StartsWith("YOU SET US UP") -or $nt.StartsWith("LINE THEM UP") -or
                        $nt.StartsWith("HOW MANY") -or $nt.StartsWith("PUT THEM IN LINE") -or
                        [string]::IsNullOrWhiteSpace($nt))) { break }
                    $i++
                }
                $i-- # will be incremented by for loop
                continue
            }
            $seenVar[$vname] = $true
            $topVars.Add($line) | Out-Null
            # Collect subsequent init lines (THIS IS A, YOU SET US UP, LINE THEM UP, HOW MANY, PUT THEM IN LINE, hex data)
            $i++
            while ($i -lt $lines.Count) {
                $nt = $lines[$i].TrimStart()
                if ($nt.StartsWith("THIS IS A") -or 
                    $nt.StartsWith("YOU SET US UP") -or
                    $nt.StartsWith("LINE THEM UP") -or
                    $nt.StartsWith("HOW MANY") -or
                    $nt.StartsWith("PUT THEM IN LINE") -or
                    $nt -match '^[0-9x]' -or
                    [string]::IsNullOrWhiteSpace($nt)) {
                    $topVars.Add($lines[$i]) | Out-Null
                    $i++
                } else {
                    break
                }
            }
            $i-- # will be incremented by for loop
            continue
        }
        
        # IT'S SHOWTIME and everything after → funcLines (main is last)
        if ($t -eq "IT'S SHOWTIME") {
            while ($i -lt $lines.Count) {
                $funcLines.Add($lines[$i]) | Out-Null
                $i++
            }
            break
        }
        
        # TALK TO YOURSELF at top level → goes to appropriate section
        # If no functions seen yet, it's a header comment → topVars section
        # Otherwise → funcLines
        if ($seenFunc.Count -eq 0) {
            $topVars.Add($line) | Out-Null
        } else {
            $funcLines.Add($line) | Out-Null
        }
    }
}

# Assemble output
$sb = [System.Text.StringBuilder]::new(300000)
$sb.AppendLine('TALK TO YOURSELF "TOARUOS-ARNOLD V4.0 - AUTO-MERGED"') | Out-Null

# Constants
foreach ($c in $constants) { $sb.AppendLine($c) | Out-Null }
$sb.AppendLine('') | Out-Null

# Top-level variables
foreach ($v in $topVars) { $sb.AppendLine($v) | Out-Null }
$sb.AppendLine('') | Out-Null

# Functions + Main
foreach ($f in $funcLines) { $sb.AppendLine($f) | Out-Null }

$result = $sb.ToString()
Set-Content $OutputFile $result -NoNewline

Write-Host ""
Write-Host "Merged: $($seenConst.Count) constants, $($seenVar.Count) vars, $($seenFunc.Count) funcs"
Write-Host "Output: $($result.Length) bytes"
