$templateSiteUrl = "https://grupoplexus.sharepoint.com/sites/884-MutuaGallega"
$targetSiteUrl = "https://grupoplexus.sharepoint.com/sites/236-Telefonica"
$txtFolderPath = "C:\Users\victor.jimenezvaquer\Documents\PlexusTech\app-ENRIQUE\PROYECTO_WIKI\JSONS\007 - Conceillo De Santiago"
#$nombreCliente = "236-Telefonica"  # Nombre del cliente a buscar

# Definir las credenciales directamente
$username = "intranet@plexus.tech"
$password = "b)Q5J@(n8qETfR"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

# Conectar al sitio de la plantilla y exportar la página
Connect-PnPOnline -Url $templateSiteUrl -ClientId a4c5532e-a48a-4045-a4fe-294fe6edf004 -Credentials $Cred

# Copiar la página de inicio desde el sitio de Mutua Gallega al sitio de destino
$PageName = "Inicio.aspx"
$TempFile = [System.IO.Path]::GetTempFileName()

# Exportar la página de inicio del sitio de Mutua Gallega
Export-PnPPage -Force -Identity $PageName -Out $TempFile

# Conectar al sitio de destino e importar la página
Connect-PnPOnline -Url $targetSiteUrl -ClientId a4c5532e-a48a-4045-a4fe-294fe6edf004 -Credentials $Cred
Invoke-PnPSiteTemplate -Path $TempFile

Write-Host "Página de inicio copiada exitosamente al sitio de destino." -ForegroundColor Green

# Función para crear o actualizar una página
function Set-ClientePage {
  param (
    [string]$PageName,
    [string]$TxtPath
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

  if (Test-Path -LiteralPath $TxtPath) {
    try {
      $htmlContent = Get-Content -LiteralPath $TxtPath -Raw -ErrorAction Stop
      
      # Imprimir contenido para depuración
      Write-Host "Contenido del archivo $PageName :" -ForegroundColor Cyan
      Write-Host $htmlContent

      $sections = [regex]::Matches($htmlContent, '(?s)<section>(.*?)</section>')
      
      # Imprimir número de secciones encontradas
      Write-Host "Número de secciones encontradas: $($sections.Count)" -ForegroundColor Cyan

      if ($sections.Count -eq 0) {
        # Si no hay secciones, añadir todo el contenido como una sección
        $newPage | Add-PnPPageSection -SectionTemplate OneColumn -Order 1 -ZoneEmphasis 2
        $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section 1 -Text $htmlContent
      }
      else {
        # Procesar secciones como antes
        $order = 1
        foreach ($section in $sections) {
          $sectionContent = $section.Groups[1].Value.Trim()
          if ($sectionContent) {
            try {
              $newPage | Add-PnPPageSection -SectionTemplate OneColumn -Order $order -ZoneEmphasis 2
              $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section $order -Text $sectionContent
            }
            catch {
              Write-Host "Error al añadir sección $order : $($_.Exception.Message)" -ForegroundColor Red
            }
            $order++
          }
        }
      
        # Procesar contenido fuera de las etiquetas section
        $remainingContent = $htmlContent -replace '(?s)<section>.*?</section>', ''
        $remainingContent = $remainingContent.Trim()
        if ($remainingContent) {
          try {
            $newPage | Add-PnPPageSection -SectionTemplate OneColumn -Order $order -ZoneEmphasis 2
            $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section $order -Text $remainingContent
          }
          catch {
            Write-Host "Error al añadir sección adicional: $_" -ForegroundColor Red
          }
        }
      }
    }
    catch {
      Write-Host "Error al procesar el archivo $TxtPath : $($_.Exception.Message)" -ForegroundColor Red
      return
    }
  }
  else {
    Write-Host "El archivo $TxtPath no existe o no es accesible." -ForegroundColor Red
    return
  }

  Write-Host "Publicando página y promocionando como Noticia..." -ForegroundColor Green
  $newPage | Set-PnPPage -PromoteAs NewsArticle -Publish
}

# Procesar archivos y carpetas
Get-ChildItem -LiteralPath $txtFolderPath -Filter *.txt -Recurse | ForEach-Object {
  $pageName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
  Write-Host "Procesando archivo: $($_.FullName)" -ForegroundColor Cyan
  Set-ClientePage -PageName $pageName -TxtPath $_.FullName
}

Write-Host "¡Listo! :)" -ForegroundColor Green
