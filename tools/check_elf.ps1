# Check ELF multiboot header
$elf = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build\toaruos-arnold.elf"
if (-not (Test-Path $elf)) { Write-Host "ELF NOT FOUND"; exit 1 }

$bytes = [System.IO.File]::ReadAllBytes($elf)
Write-Host "ELF size: $($bytes.Length) bytes"
Write-Host "ELF magic: $($bytes[0]) $($bytes[1]) $($bytes[2]) $($bytes[3]) (expect 127 69 76 70)"

# Search for multiboot magic 0x1BADB002 = little-endian 02 B0 AD 1B
$found = $false
for ($i = 0; $i -lt [Math]::Min(8192, $bytes.Length - 3); $i++) {
    if ($bytes[$i] -eq 0x02 -and $bytes[$i+1] -eq 0xB0 -and $bytes[$i+2] -eq 0xAD -and $bytes[$i+3] -eq 0x1B) {
        $flags = [BitConverter]::ToUInt32($bytes, $i + 4)
        $checksum = [BitConverter]::ToUInt32($bytes, $i + 8)
        $sum = 0x1BADB002 + $flags + $checksum
        Write-Host ""
        Write-Host "MULTIBOOT HEADER FOUND at file offset 0x$($i.ToString('X4'))"
        Write-Host "  Magic:    0x1BADB002"
        Write-Host "  Flags:    0x$($flags.ToString('X8'))"
        Write-Host "  Checksum: 0x$($checksum.ToString('X8'))"
        Write-Host "  Sum:      0x$($sum.ToString('X8')) (must be 0x00000000 or 0x100000000)"
        
        # Show next 36 bytes (rest of header)
        Write-Host "  Full header (48 bytes):"
        for ($j = 0; $j -lt 48; $j += 4) {
            $val = [BitConverter]::ToUInt32($bytes, $i + $j)
            Write-Host ("    +{0:D2}: 0x{1:X8}" -f $j, $val)
        }
        
        # Check alignment within 8KB
        Write-Host ""
        if ($i -lt 8192) {
            Write-Host "  PASS: Header within first 8KB (required by multiboot spec)"
        } else {
            Write-Host "  FAIL: Header NOT within first 8KB!"
        }
        
        if (($sum -band 0xFFFFFFFF) -eq 0) {
            Write-Host "  PASS: Checksum valid"
        } else {
            Write-Host "  FAIL: Checksum invalid!"
        }
        
        $found = $true
        break
    }
}
if (-not $found) { Write-Host "MULTIBOOT MAGIC NOT FOUND in first 8KB!" }

# Check ELF entry point
$entryPoint = [BitConverter]::ToUInt32($bytes, 24)
Write-Host ""
Write-Host "ELF entry point: 0x$($entryPoint.ToString('X8'))"

# Check program headers
$phOff = [BitConverter]::ToUInt32($bytes, 28)
$phSize = [BitConverter]::ToUInt16($bytes, 42)
$phNum = [BitConverter]::ToUInt16($bytes, 44)
Write-Host "Program headers: $phNum at offset 0x$($phOff.ToString('X4')), size $phSize each"

for ($p = 0; $p -lt $phNum; $p++) {
    $off = $phOff + ($p * $phSize)
    $pType = [BitConverter]::ToUInt32($bytes, $off)
    $pVaddr = [BitConverter]::ToUInt32($bytes, $off + 8)
    $pFilesz = [BitConverter]::ToUInt32($bytes, $off + 16)
    $pMemsz = [BitConverter]::ToUInt32($bytes, $off + 20)
    $typeName = switch ($pType) { 0 {"NULL"} 1 {"LOAD"} default {"OTHER($pType)"} }
    Write-Host "  [$p] $typeName vaddr=0x$($pVaddr.ToString('X8')) filesz=$pFilesz memsz=$pMemsz"
}
