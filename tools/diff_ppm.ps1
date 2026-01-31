param($f1, $f2)
$p1 = [IO.File]::ReadAllBytes($f1)
$p2 = [IO.File]::ReadAllBytes($f2)
$diff = 0
$len = [Math]::Min($p1.Length, $p2.Length)
for ($i = 0; $i -lt $len; $i++) {
    if ($p1[$i] -ne $p2[$i]) { $diff++ }
}
Write-Host "Different bytes: $diff / $len"
