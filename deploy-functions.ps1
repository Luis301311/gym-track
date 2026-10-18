# Publica la Cloud Function del coach con IA.
# Requisitos (una sola vez):
#   1. Proyecto de Firebase en plan Blaze (pago por uso, con cuota gratis).
#   2. firebase functions:secrets:set ANTHROPIC_API_KEY   (pega tu llave)
# Uso:
#   powershell -ExecutionPolicy Bypass -File deploy-functions.ps1
$ErrorActionPreference = 'Stop'

Write-Host "1/2 Compilando funciones..." -ForegroundColor Cyan
npm --prefix functions install
npm --prefix functions run build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "2/2 Publicando..." -ForegroundColor Cyan
firebase deploy --only functions
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Listo. Compila la app con --dart-define=AI_COACH=cloud para usarla." -ForegroundColor Green
