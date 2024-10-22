$templateSiteUrl = "https://grupoplexus.sharepoint.com/sites/884-MutuaGallega"
$targetSiteUrl = "https://grupoplexus.sharepoint.com/sites/236-Telefonica"
$txtFolderPath = "C:\Users\victor.jimenezvaquer\Desktop\PROYECTOS_PLEXUS\PROYECTO_WIKI\JSONS\236 - Telefonica\[SECCIÓN DESARROLLO] 236-082 Telefónica Movistar Quenda CloudAnblick Cloud(HWSW).html"
#$nombreCliente = "236-Telefonica"  # Nombre del cliente a buscar

# Definir las credenciales directamente
$username = "intranet@plexus.tech"
$password = "b)Q5J@(n8qETfR"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

# Conectar al sitio de destino
Connect-PnPOnline -Url $targetSiteUrl -ClientId a4c5532e-a48a-4045-a4fe-294fe6edf004 -Credentials $Cred

# Función para crear o actualizar una página
function Set-ClientePage {
  param (
    [string]$PageName,
    [string]$HtmlPath
  )
    
  $existingPage = Get-PnPPage -Identity "$PageName.aspx" -ErrorAction SilentlyContinue
  if ($null -eq $existingPage) {
    $pageParams = @{
      Name             = $PageName
      Title            = $PageName
      HeaderLayoutType = "FullWidthImage"
    }
    Write-Host "Creando nueva página: $PageName" -ForegroundColor Green
    $newPage = Add-PnPPage @pageParams -ErrorAction Stop
  }
  else {
    Write-Host "Actualizando página existente: $PageName" -ForegroundColor Yellow
    $newPage = $existingPage
  }

  if (Test-Path -LiteralPath $HtmlPath) {
    try {
      $htmlContent = Get-Content -LiteralPath $HtmlPath -Raw -ErrorAction Stop
      
      # Procesar las etiquetas de imagen especiales
      $htmlContent = $htmlContent -replace '<img alt="media" loading="lazy" src="([^"]+)" width="400">',
      '<img src="$1" alt="media" width="400">'
      
      $sections = $htmlContent -split '(?=<section)'
      $sectionCount = 0

      foreach ($section in $sections) {
        if ($section.Trim() -ne "" -and $section.Trim() -match '^<section') {
          $sectionCount++
          $newPage | Add-PnPPageSection -SectionTemplate OneColumn -Order $sectionCount -ZoneEmphasis 2
          $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section $sectionCount -Text $section
        }
      }
    }
    catch {
      Write-Host "Error al procesar el archivo $HtmlPath : $($_.Exception.Message)" -ForegroundColor Red
      return
    }
  }
  else {
    Write-Host "El archivo $HtmlPath no existe o no es accesible." -ForegroundColor Red
    return
  }

  Write-Host "Publicando página y promocionando como Noticia..." -ForegroundColor Green
  $newPage | Set-PnPPage -PromoteAs NewsArticle -Publish
}

# Procesar archivos HTML
Get-ChildItem -LiteralPath $txtFolderPath -Filter *.html -File | ForEach-Object {
  $pageName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
  Set-ClientePage -PageName $pageName -HtmlPath $_.FullName
}

Write-Host "Páginas del cliente creadas exitosamente." -ForegroundColor Green

# Ahora copiar la página de inicio
Connect-PnPOnline -Url $templateSiteUrl -ClientId a4c5532e-a48a-4045-a4fe-294fe6edf004 -Credentials $Cred

$PageName = "Inicio.aspx"
$TempFile = [System.IO.Path]::GetTempFileName()

# Exportar la página de inicio del sitio de Mutua Gallega
Export-PnPPage -Force -Identity $PageName -Out $TempFile

# Reconectar al sitio de destino e importar la página
Connect-PnPOnline -Url $targetSiteUrl -ClientId a4c5532e-a48a-4045-a4fe-294fe6edf004 -Credentials $Cred
Invoke-PnPSiteTemplate -Path $TempFile

Write-Host "Página de inicio copiada exitosamente al sitio de destino." -ForegroundColor Green

Write-Host "¡Listo! :)" -ForegroundColor Green
