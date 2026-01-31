$games = @('breakout','chopper','memory','skynet','tictactoe')
foreach ($g in $games) {
    $path = "C:\Users\Acer\Desktop\ToaruOS-Arnold\kernel\games\$g.arnoldc"
    Write-Host "=== $g ==="
    Select-String -Path $path -Pattern 'LISTEN TO ME VERY CAREFULLY' | ForEach-Object {
        Write-Host ("  " + $_.Line.Trim())
    }
    Write-Host ""
}
