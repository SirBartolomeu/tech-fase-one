param(
    [switch]$SkipClusterSetup,
    [switch]$SkipImageBuild,
    [switch]$KeepScaled,
    [switch]$Cleanup
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$clusterName = "oficina-local"
$namespace = "oficina"
$imageName = "oficina-mvp-api:local"
$postgresPassword = "OficinaPostgres123!"
$jwtKey = "oficina-local-jwt-key-with-more-than-32-characters"
$integrationToken = "oficina-integration-token-local-123456"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Invoke-Tool {
    param(
        [string]$Tool,
        [string[]]$Arguments,
        [switch]$IgnoreExitCode
    )

    & $Tool @Arguments
    $exitCode = $LASTEXITCODE
    if (-not $IgnoreExitCode -and $exitCode -ne 0) {
        throw "Command failed ($exitCode): $Tool $($Arguments -join ' ')"
    }
}

function Invoke-KubectlApplyFromText {
    param([string]$Yaml)

    $Yaml | & kubectl apply -f -
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Command failed ($exitCode): kubectl apply -f -"
    }
}

function Test-CommandAvailable {
    param([string]$CommandName)

    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $CommandName"
    }
}

Push-Location $repoRoot
try {
    Write-Step "Validando ferramentas locais"
    Test-CommandAvailable "docker"
    Test-CommandAvailable "kubectl"
    Test-CommandAvailable "terraform"
    Test-CommandAvailable "kind"
    Invoke-Tool "docker" @("info") | Out-Null

    if ($Cleanup) {
        Write-Step "Limpando demo Kubernetes local"
        Invoke-Tool "kubectl" @("delete", "-k", ".\k8s", "--ignore-not-found=true") -IgnoreExitCode
        Invoke-Tool "terraform" @("-chdir=infra/terraform", "destroy", "-auto-approve")
        Write-Host "Cleanup concluido." -ForegroundColor Green
        return
    }

    if (-not $SkipClusterSetup) {
        Write-Step "Criando ou atualizando cluster kind com Terraform"
        Invoke-Tool "terraform" @("-chdir=infra/terraform", "init")
        Invoke-Tool "terraform" @("-chdir=infra/terraform", "apply", "-auto-approve")
    }
    else {
        Write-Step "Pulando criacao do cluster por parametro"
    }

    Write-Step "Selecionando contexto Kubernetes"
    Invoke-Tool "kubectl" @("config", "use-context", "kind-$clusterName")

    Write-Step "Estado do cluster"
    Invoke-Tool "kind" @("get", "clusters")
    Invoke-Tool "kind" @("get", "nodes", "--name", $clusterName)
    Invoke-Tool "kubectl" @("cluster-info")

    if (-not $SkipImageBuild) {
        Write-Step "Build da imagem Docker da API"
        Invoke-Tool "docker" @("build", "-f", ".\src\OficinaMvp.Api\Dockerfile", "-t", $imageName, ".")
    }
    else {
        Write-Step "Pulando build da imagem por parametro"
    }

    Write-Step "Carregando imagem no cluster kind"
    Invoke-Tool "kind" @("load", "docker-image", $imageName, "--name", $clusterName)

    Write-Step "Criando namespace e secrets locais"
    Invoke-Tool "kubectl" @("apply", "-f", ".\k8s\namespace.yaml")

    $connectionString = "Host=oficina-postgres;Port=5432;Database=oficina;Username=oficina;Password=$postgresPassword"

    $postgresSecretYaml = & kubectl @(
        "-n", $namespace,
        "create", "secret", "generic", "oficina-postgres-secret",
        "--from-literal=POSTGRES_USER=oficina",
        "--from-literal=POSTGRES_PASSWORD=$postgresPassword",
        "--dry-run=client",
        "-o", "yaml"
    )
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to generate oficina-postgres-secret manifest."
    }
    Invoke-KubectlApplyFromText $postgresSecretYaml

    $apiSecretYaml = & kubectl @(
        "-n", $namespace,
        "create", "secret", "generic", "oficina-api-secret",
        "--from-literal=Jwt__Key=$jwtKey",
        "--from-literal=AdminCredentials__Password=Admin@123",
        "--from-literal=Integration__Token=$integrationToken",
        "--from-literal=ConnectionStrings__DefaultConnection=$connectionString",
        "--dry-run=client",
        "-o", "yaml"
    )
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to generate oficina-api-secret manifest."
    }
    Invoke-KubectlApplyFromText $apiSecretYaml

    Write-Step "Aplicando manifests Kubernetes"
    Invoke-Tool "kubectl" @("apply", "-k", ".\k8s")

    Write-Step "Aguardando PostgreSQL e API"
    Invoke-Tool "kubectl" @("-n", $namespace, "rollout", "status", "statefulset/oficina-postgres", "--timeout=180s")
    Invoke-Tool "kubectl" @("-n", $namespace, "rollout", "status", "deployment/oficina-api", "--timeout=180s")

    Write-Step "Estado atual dos recursos"
    Invoke-Tool "kubectl" @("-n", $namespace, "get", "pods,svc,hpa,pvc")

    Write-Step "Testando health e Swagger via port-forward temporario"
    $portForward = Start-Process `
        -FilePath "kubectl" `
        -ArgumentList @("-n", $namespace, "port-forward", "svc/oficina-api", "8080:80") `
        -PassThru `
        -WindowStyle Hidden

    try {
        Start-Sleep -Seconds 5
        $health = Invoke-WebRequest -Uri "http://localhost:8080/health/ready" -UseBasicParsing -TimeoutSec 10
        $swagger = Invoke-WebRequest -Uri "http://localhost:8080/swagger/v1/swagger.json" -UseBasicParsing -TimeoutSec 10
        Write-Host "Health status: $($health.StatusCode)" -ForegroundColor Green
        Write-Host "Swagger status: $($swagger.StatusCode)" -ForegroundColor Green
    }
    finally {
        if ($portForward -and -not $portForward.HasExited) {
            Stop-Process -Id $portForward.Id -Force
        }
    }

    Write-Step "Escalabilidade configurada pelo HPA"
    Invoke-Tool "kubectl" @("-n", $namespace, "get", "hpa", "oficina-api")

    Write-Step "Estado inicial da API"
    Invoke-Tool "kubectl" @("-n", $namespace, "get", "deployment", "oficina-api")
    Invoke-Tool "kubectl" @("-n", $namespace, "get", "pods", "-l", "app.kubernetes.io/name=oficina-api", "-o", "wide")

    Write-Step "Simulando aumento de carga com 3 replicas"
    Invoke-Tool "kubectl" @("-n", $namespace, "scale", "deployment", "oficina-api", "--replicas=3")
    Invoke-Tool "kubectl" @("-n", $namespace, "rollout", "status", "deployment/oficina-api", "--timeout=120s")
    Invoke-Tool "kubectl" @("-n", $namespace, "get", "pods", "-l", "app.kubernetes.io/name=oficina-api", "-o", "wide")

    if (-not $KeepScaled) {
        Write-Step "Retornando API para 1 replica"
        Invoke-Tool "kubectl" @("-n", $namespace, "scale", "deployment", "oficina-api", "--replicas=1")
        Invoke-Tool "kubectl" @("-n", $namespace, "get", "pods", "-l", "app.kubernetes.io/name=oficina-api")
    }

    Write-Step "Resumo para narrar no video"
    Write-Host "Deploy Kubernetes local concluido em cluster kind '$clusterName'."
    Write-Host "API respondeu health e Swagger via service Kubernetes."
    Write-Host "HPA configurado para 1 a 5 replicas por CPU/memoria."
    Write-Host "Escala manual demonstrou multiplas replicas da API."
    Write-Host ""
    Write-Host "Para limpar depois:" -ForegroundColor Yellow
    Write-Host "powershell -ExecutionPolicy Bypass -File .\scripts\demo-kubernetes-local.ps1 -Cleanup"
}
finally {
    Pop-Location
}
