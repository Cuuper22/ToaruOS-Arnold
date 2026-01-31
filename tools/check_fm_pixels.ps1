# Check file manager entry backgrounds
param($ppmFile = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build\fm_root.ppm")

$ppm = [IO.File]::ReadAllBytes($ppmFile)
$ds = 16; $w = 1024

# FM_TEXT_Y = 24, FM_ENTRY_H = 16
# Entry 0: y=24, Entry 1: y=40, Entry 2: y=56
foreach ($entry in @(0,1,2)) {
    $y = 24 + $entry * 16
    $idx = $ds + ($y * $w + 4) * 3
    $r = $ppm[$idx]; $g = $ppm[$idx+1]; $b = $ppm[$idx+2]
    Write-Host "Entry $entry (y=$y col=4): R=$r G=$g B=$b"
}

# Check for SELECT_BG color: R=51 G=68 B=102
$selFound = 0
for ($row = 24; $row -lt 80; $row++) {
    for ($col = 0; $col -lt 100; $col++) {
        $idx = $ds + ($row * $w + $col) * 3
        $r = $ppm[$idx]; $g = $ppm[$idx+1]; $b = $ppm[$idx+2]
        if ($r -eq 51 -and $g -eq 68 -and $b -eq 102) { $selFound++ }
    }
}
Write-Host "SELECT_BG pixels found: $selFound"
