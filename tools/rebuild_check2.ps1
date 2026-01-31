Set-Location "C:\Users\Acer\Desktop\ToaruOS-Arnold\build\gen"
Remove-Item kernel.asm -ErrorAction SilentlyContinue
Write-Host "Compiling..."
$output = java -jar "C:\Users\Acer\Desktop\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar" -asm "kernel.arnoldc" 2>&1
Write-Host "Compiler output:"
$output | ForEach-Object { Write-Host $_ }
Write-Host "---"
if (Test-Path kernel.asm) {
    Write-Host "ASM size: $((Get-Item kernel.asm).Length)"
} else {
    Write-Host "NO ASM FILE GENERATED - COMPILE FAILED!"
}
