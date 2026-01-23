param(
    [string]$Action = "build",
    [switch]$Lite
)

$ErrorActionPreference = "Stop"

function Test-Command {
    param([string]$Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    return $null -ne $command
}

function Resolve-ProjectRoot {
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) {
        return (Get-Location).Path
    }
    return (Split-Path -Parent $scriptPath)
}

function Ensure-DockerImage {
    param(
        [string]$ImageName,
        [string]$Dockerfile
    )

    if (-not (Test-Command "docker")) {
        return $false
    }

    $imageId = docker images -q $ImageName 2>$null
    if (-not $imageId) {
        Write-Host "[Docker] Building image $ImageName..."
        docker build -t $ImageName -f $Dockerfile .
    }

    return $true
}

function Invoke-DockerMake {
    param(
        [string]$ImageName,
        [string]$ProjectRoot,
        [string]$Target
    )

    $volumeArg = "${ProjectRoot}:/kernel"
    docker run --rm -v $volumeArg $ImageName make $Target
}

function Invoke-DockerShell {
    param(
        [string]$ImageName,
        [string]$ProjectRoot
    )

    $volumeArg = "${ProjectRoot}:/kernel"
    docker run --rm -it -v $volumeArg $ImageName /bin/bash
}

function Invoke-WslMake {
    param([string]$Target)

    if (-not (Test-Command "wsl")) {
        throw "WSL is not available. Install Docker or WSL."
    }
    wsl make $Target
}

function Ensure-Qemu {
    $qemu = Get-Command "qemu-system-i386" -ErrorAction SilentlyContinue
    return $qemu
}

$projectRoot = Resolve-ProjectRoot
Set-Location $projectRoot

$dockerfile = if ($Lite) { "Dockerfile.lite" } else { "Dockerfile" }
$imageName = if ($Lite) { "toaruos-arnold-lite:latest" } else { "toaruos-arnold-builder:latest" }

if (-not (Test-Path $dockerfile)) {
    throw "Dockerfile not found: $dockerfile"
}

$useDocker = Ensure-DockerImage -ImageName $imageName -Dockerfile $dockerfile

switch ($Action.ToLowerInvariant()) {
    "build" {
        if ($useDocker) {
            Invoke-DockerMake -ImageName $imageName -ProjectRoot $projectRoot -Target ""
        } else {
            Invoke-WslMake -Target ""
        }
    }
    "clean" {
        if ($useDocker) {
            Invoke-DockerMake -ImageName $imageName -ProjectRoot $projectRoot -Target "clean"
        } else {
            Invoke-WslMake -Target "clean"
        }
    }
    "iso" {
        if ($useDocker) {
            Invoke-DockerMake -ImageName $imageName -ProjectRoot $projectRoot -Target "iso"
        } else {
            Invoke-WslMake -Target "iso"
        }
    }
    "run" {
        if ($useDocker) {
            Invoke-DockerMake -ImageName $imageName -ProjectRoot $projectRoot -Target ""
        } else {
            Invoke-WslMake -Target ""
        }

        $qemu = Ensure-Qemu
        if (-not $qemu) {
            Write-Host "QEMU not found. Install qemu-system-i386 or run via WSL." -ForegroundColor Yellow
            exit 0
        }
        & $qemu.Path -m 128M -serial stdio -vga std -kernel "build/toaruos-arnold.elf"
    }
    "run-iso" {
        if ($useDocker) {
            Invoke-DockerMake -ImageName $imageName -ProjectRoot $projectRoot -Target "iso"
        } else {
            Invoke-WslMake -Target "iso"
        }

        $qemu = Ensure-Qemu
        if (-not $qemu) {
            Write-Host "QEMU not found. Install qemu-system-i386 or run via WSL." -ForegroundColor Yellow
            exit 0
        }
        & $qemu.Path -m 128M -serial stdio -vga std -cdrom "build/toaruos-arnold.iso"
    }
    "debug" {
        if ($useDocker) {
            Invoke-DockerMake -ImageName $imageName -ProjectRoot $projectRoot -Target ""
        } else {
            Invoke-WslMake -Target ""
        }

        $qemu = Ensure-Qemu
        if (-not $qemu) {
            Write-Host "QEMU not found. Install qemu-system-i386 or run via WSL." -ForegroundColor Yellow
            exit 0
        }
        & $qemu.Path -m 128M -serial stdio -vga std -kernel "build/toaruos-arnold.elf" -s -S
    }
    "shell" {
        if ($useDocker) {
            Invoke-DockerShell -ImageName $imageName -ProjectRoot $projectRoot
        } else {
            Write-Host "Docker not available. Use WSL shell: wsl" -ForegroundColor Yellow
        }
    }
    "help" {
        Write-Host "Usage: .\build.ps1 [build|run|debug|iso|run-iso|clean|shell] [-Lite]"
        Write-Host "  build   : Build the kernel (default)"
        Write-Host "  run     : Build and run with QEMU"
        Write-Host "  debug   : Build and run QEMU with GDB stub"
        Write-Host "  iso     : Build bootable ISO"
        Write-Host "  run-iso : Build ISO and boot with QEMU"
        Write-Host "  clean   : Clean build artifacts"
        Write-Host "  shell   : Open interactive Docker shell"
        Write-Host "  -Lite   : Use Dockerfile.lite"
    }
    default {
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Write-Host "Run: .\build.ps1 help"
        exit 1
    }
}
