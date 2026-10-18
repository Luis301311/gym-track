# Publica GymTrack en Firebase Hosting (y las reglas de Firestore).
# Uso (PowerShell, en la carpeta del proyecto):
#   powershell -ExecutionPolicy Bypass -File deploy.ps1
$ErrorActionPreference = 'Stop'

Write-Host "1/2 Compilando la app web con Firebase..." -ForegroundColor Cyan
flutter build web --release --dart-define=BACKEND=firebase --no-web-resources-cdn
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "2/2 Publicando en Firebase Hosting..." -ForegroundColor Cyan
firebase deploy --only "hosting,firestore:rules"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Listo: https://gymtrack-7d27c.web.app" -ForegroundColor Green
