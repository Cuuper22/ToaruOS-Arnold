# Check pixels in editor text area
param($ppmFile = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build\dbg1.ppm")

$ppm = [IO.File]::ReadAllBytes($ppmFile)
$ds = 16; $w = 1024
$found = 0
for ($row = 20; $row -lt 36; $row++) {
    for ($col = 0; $col -lt 200; $col++) {
        $idx = $ds + ($row * $w + $col) * 3
        $rv = $ppm[$idx]; $gv = $ppm[$idx+1]; $bv = $ppm[$idx+2]
        if ($rv -gt 20 -or $gv -gt 30 -or $bv -gt 50) {
            if ($found -lt 80) {
                Write-Host "ROW=$row COL=$col RGB=$rv,$gv,$bv"
            }
            $found++
        }
    }
}
Write-Host "Total text pixels in rows 20-35, cols 0-199: $found"
