param(
    [string]$InputFile = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build\test_phase3_menu.ppm",
    [string]$OutputFile = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build\test_phase3_menu.png"
)

Add-Type -AssemblyName System.Drawing

$bytes = [System.IO.File]::ReadAllBytes($InputFile)

# Parse PPM P6 header
$headerEnd = 0
$newlines = 0
for ($i = 0; $i -lt $bytes.Length; $i++) {
    if ($bytes[$i] -eq 10) { $newlines++ }
    if ($newlines -eq 3) { $headerEnd = $i + 1; break }
}

$width = 1024
$height = 768

$bmp = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

$rect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
$bmpData = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, $bmp.PixelFormat)

$stride = $bmpData.Stride
$pixelData = New-Object byte[] ($stride * $height)

for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        $srcIdx = $headerEnd + ($y * $width + $x) * 3
        $dstIdx = $y * $stride + $x * 3
        # PPM is RGB, BMP is BGR
        $pixelData[$dstIdx] = $bytes[$srcIdx + 2]     # B
        $pixelData[$dstIdx + 1] = $bytes[$srcIdx + 1] # G
        $pixelData[$dstIdx + 2] = $bytes[$srcIdx]     # R
    }
}

[System.Runtime.InteropServices.Marshal]::Copy($pixelData, 0, $bmpData.Scan0, $pixelData.Length)
$bmp.UnlockBits($bmpData)
$bmp.Save($OutputFile, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host "Converted $InputFile -> $OutputFile"
