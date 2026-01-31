# Check PPM file for non-black pixels
param([string]$ppmFile = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build\test_term20.ppm")

$bytes = [IO.File]::ReadAllBytes($ppmFile)
Write-Host "File size: $($bytes.Length) bytes"

# Find end of PPM header (3 newlines: P6\n, width height\n, maxval\n)
$nlCount = 0
$dataStart = 0
for ($i = 0; $i -lt 100; $i++) {
    if ($bytes[$i] -eq 10) {
        $nlCount++
        if ($nlCount -eq 3) {
            $dataStart = $i + 1
            break
        }
    }
}

$header = [Text.Encoding]::ASCII.GetString($bytes, 0, $dataStart)
Write-Host "Header: '$($header.Trim())'"
Write-Host "Data starts at byte: $dataStart"
Write-Host "Pixel data: $($bytes.Length - $dataStart) bytes"

# Scan for non-black pixels in first 500 rows
$found = 0
$maxFind = 20
for ($row = 0; $row -lt 500 -and $found -lt $maxFind; $row++) {
    for ($col = 0; $col -lt 1024; $col++) {
        $off = $dataStart + ($row * 1024 + $col) * 3
        $r = $bytes[$off]
        $g = $bytes[$off + 1]
        $b = $bytes[$off + 2]
        if ($g -gt 0 -or $r -gt 0 -or $b -gt 0) {
            Write-Host "  ROW=$row COL=$col : R=$r G=$g B=$b"
            $found++
            if ($found -ge $maxFind) { break }
        }
    }
}

if ($found -eq 0) {
    Write-Host "NO non-black pixels found in first 500 rows!"
    # Check rows 500-600 (below terminal area)
    Write-Host "Checking rows 500-600..."
    for ($row = 500; $row -lt 600 -and $found -lt $maxFind; $row++) {
        for ($col = 0; $col -lt 1024; $col++) {
            $off = $dataStart + ($row * 1024 + $col) * 3
            $r = $bytes[$off]
            $g = $bytes[$off + 1]
            $b = $bytes[$off + 2]
            if ($g -gt 0 -or $r -gt 0 -or $b -gt 0) {
                Write-Host "  ROW=$row COL=$col : R=$r G=$g B=$b"
                $found++
                if ($found -ge $maxFind) { break }
            }
        }
    }
}

Write-Host "Total non-black pixels found: $found"
