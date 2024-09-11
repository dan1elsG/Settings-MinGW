# Verifica se o script esta sendo executado como administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Se nao estiver como administrador, relanca o PowerShell como administrador
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runas -ArgumentList $arguments
    exit
}

# Diretoria padrao do MinGW
$pathMingw = "C:\MinGW\bin\gcc.exe"

# Verificar se esta instalado
if (Test-Path $pathMingw) {
    Write-Host "MinGW ja esta instalado..." -ForegroundColor Red
} else {
    Write-Host "Instalando MinGW..." -ForegroundColor Green

    $caminhoMinGW = "C:\MinGW"
    $caminhoXZ = "$($env:TEMP)\mingw-get-0.6.2-mingw32-beta-20131004-1-bin.tar.xz"
    $caminhoTAR = "$($env:TEMP)\mingw-get-0.6.2-mingw32-beta-20131004-1-bin.tar"
    $log = "$env:TEMP\install-log.txt"

    # Remove instalacao anterior do MinGW
    if (Test-Path $caminhoMinGW) {
        Write-Host "Removendo instalacao existente do MinGW..."
        Remove-Item $caminhoMinGW -Recurse -Force
    }

    # Baixar o instalador do MinGW
    Write-Host "Baixando o instalador..."
    (New-Object Net.WebClient).DownloadFile('http://sourceforge.net/projects/mingw/files/Installer/mingw-get/mingw-get-0.6.2-beta-20131004-1/mingw-get-0.6.2-mingw32-beta-20131004-1-bin.tar.xz/download', $caminhoXZ)

    # Verificar se o arquivo foi baixado corretamente
    if (-not (Test-Path $caminhoXZ)) {
        Write-Host "Erro: Arquivo de instalacao nao baixado corretamente." -ForegroundColor Red
        exit 1
    }

    # Descompactar e extrair o arquivo
    Write-Host "Extraindo o arquivo..."
    7z x $caminhoXZ -y -o"$env:TEMP" | Out-Null

    if (-not (Test-Path $caminhoTAR)) {
        Write-Host "Erro: Arquivo .tar nao encontrado apos a extracao." -ForegroundColor Red
        exit 1
    }

    Write-Host "Descompactando..."
    7z x $caminhoTAR -y -o"$caminhoMinGW" | Out-Null

    # Remover arquivos temporarios
    Remove-Item $caminhoXZ -ErrorAction SilentlyContinue
    Remove-Item $caminhoTAR -ErrorAction SilentlyContinue

    # Verificar se o mingw-get.exe existe
    $caminhoExecutavel = "$caminhoMinGW\bin\mingw-get.exe"
    if (-not (Test-Path $caminhoExecutavel)) {
        Write-Host "Erro: mingw-get.exe nao encontrado. A extracao falhou." -ForegroundColor Red
        exit 1
    }

    # Funcao para instalar os pacotes
    function InstalarPacote {
        param (
            [string]$nomePacote
        )
        Write-Host "Instalando pacote $nomePacote..." -NoNewline
        & "$caminhoExecutavel" install $nomePacote 1> $log 2>&1
        Write-Host "OK" -ForegroundColor Green
    }

    # Instalar os pacotes necessarios
    InstalarPacote mingw32-base
    InstalarPacote gcc

    # Remover arquivo de log, se existir
    Remove-Item $log -ErrorAction SilentlyContinue

    Write-Host "MinGW instalado com sucesso!" -ForegroundColor Green
}

Write-Host "Configurando MinGW..."
# Diretorio de instalacao do MinGW
$mingwDir = "C:\MinGW\bin"

# Verifica se o diretorio existe
if (Test-Path -Path $mingwDir) {
    # Obtem o PATH atual do sistema
    $currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

    # Verifica se o MinGW ja esta no PATH
    if ($currentPath -notlike "*$mingwDir*") {
        # Adiciona o diretorio do MinGW ao PATH
        $newPath = "$currentPath;$mingwDir"
        [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)

        Write-Host "MinGW foi adicionado ao PATH com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "MinGW ja esta configurado no PATH." -ForegroundColor Red
    }
} else {
    Write-Host "O diretorio do MinGW nao foi encontrado. Verifique o caminho de instalacao." -ForegroundColor Red
}

Pause
