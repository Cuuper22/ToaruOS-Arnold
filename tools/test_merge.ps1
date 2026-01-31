$root = "C:\Users\Acer\Desktop\ToaruOS-Arnold"
$files = @(
    "$root\kernel\lib\random.arnoldc",
    "$root\kernel\lib\timer.arnoldc",
    "$root\kernel\lib\speaker.arnoldc",
    "$root\kernel\games\snake.arnoldc",
    "$root\kernel\kernel_v3.arnoldc"
)
& "$root\tools\merge_modules.ps1" -SourceFiles $files -OutputFile "$root\build\gen\kernel.arnoldc"
