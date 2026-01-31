$f = "C:\Users\Acer\Desktop\ToaruOS-Arnold\kernel\kernel_v3.arnoldc"
$ifs = (Select-String -Path $f -Pattern 'BECAUSE I').Count
$endifs = (Select-String -Path $f -Pattern 'YOU HAVE NO RESPECT').Count
$whiles = (Select-String -Path $f -Pattern 'STICK AROUND').Count
$endwhiles = (Select-String -Path $f -Pattern '^    CHILL$|^CHILL$|^\s+CHILL$').Count
Write-Host "IF=$ifs ENDIF=$endifs WHILE=$whiles ENDWHILE=$endwhiles"
