param(
    [string]$Keys = "",
    [string]$OutFile = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build\screenshot.ppm",
    [string]$PngFile = "",
    [int]$DelayMs = 300
)

$c = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 4444)
$s = $c.GetStream()
$w = New-Object System.IO.StreamWriter($s)

foreach ($key in $Keys.Split(',')) {
    $k = $key.Trim()
    if ($k -ne "") {
        $w.WriteLine("sendkey $k")
        $w.Flush()
        Start-Sleep -Milliseconds $DelayMs
    }
}

# Wait a bit for rendering
Start-Sleep -Milliseconds 500

$w.WriteLine("screendump $OutFile")
$w.Flush()
Start-Sleep -Milliseconds 1000
$c.Close()

Write-Host "Keys sent, screenshot saved to $OutFile"

# Convert to PNG if requested
if ($PngFile -ne "") {
    Add-Type -AssemblyName System.Drawing
    $bytes = [System.IO.File]::ReadAllBytes($OutFile)
    $headerEnd = 0
    $newlines = 0
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -eq 10) { $newlines++ }
        if ($newlines -eq 3) { $headerEnd = $i + 1; break }
    }
    $width = 1024; $height = 768
    $bmp = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
    $bmpData = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, $bmp.PixelFormat)
    $stride = $bmpData.Stride
    $pixelData = New-Object byte[] ($stride * $height)
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $srcIdx = $headerEnd + ($y * $width + $x) * 3
            $dstIdx = $y * $stride + $x * 3
            $pixelData[$dstIdx] = $bytes[$srcIdx + 2]
            $pixelData[$dstIdx + 1] = $bytes[$srcIdx + 1]
            $pixelData[$dstIdx + 2] = $bytes[$srcIdx]
        }
    }
    [System.Runtime.InteropServices.Marshal]::Copy($pixelData, 0, $bmpData.Scan0, $pixelData.Length)
    $bmp.UnlockBits($bmpData)
    $bmp.Save($PngFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Converted to $PngFile"
}
