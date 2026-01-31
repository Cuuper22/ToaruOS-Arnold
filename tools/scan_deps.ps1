# Scan function calls in game modules
$games = Get-ChildItem "C:\Users\Acer\Desktop\ToaruOS-Arnold\kernel\games\*.arnoldc"
foreach ($g in $games) {
    Write-Host "=== $($g.Name) ==="
    $content = Get-Content $g.FullName
    $calls = @()
    foreach ($line in $content) {
        if ($line -match '^\s*DO IT NOW\s+(\S+)') {
            $calls += $Matches[1]
        }
    }
    $calls | Sort-Object -Unique | ForEach-Object { Write-Host "  call: $_" }
    Write-Host ""
}

# Also check what functions v3 kernel defines
Write-Host "=== v3 kernel functions ==="
$v3 = Get-Content "C:\Users\Acer\Desktop\ToaruOS-Arnold\kernel\kernel_v3.arnoldc"
foreach ($line in $v3) {
    if ($line -match '^LISTEN TO ME VERY CAREFULLY\s+(\S+)') {
        Write-Host "  func: $($Matches[1])"
    }
}
