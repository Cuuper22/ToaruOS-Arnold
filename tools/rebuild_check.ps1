Set-Location "C:\Users\Acer\Desktop\ToaruOS-Arnold\build\gen"
Remove-Item kernel.asm -ErrorAction SilentlyContinue
java -jar "C:\Users\Acer\Desktop\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar" -asm "kernel.arnoldc" 2>&1 | Out-Null
Write-Host "ASM size: $((Get-Item kernel.asm).Length)"

# Check if clearScreen appears near initTerminal in the assembly
$lines = Get-Content kernel.asm
$found = $false
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match "call initTerminal") {
        Write-Host "initTerminal at line $i"
        # Show next 30 lines
        for ($j = $i; $j -lt [Math]::Min($i + 30, $lines.Length); $j++) {
            Write-Host "$j : $($lines[$j])"
        }
        $found = $true
        break
    }
}
if (-not $found) { Write-Host "initTerminal NOT FOUND in ASM!" }
