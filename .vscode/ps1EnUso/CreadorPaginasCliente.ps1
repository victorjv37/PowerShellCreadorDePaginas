$wikiUrl = "https://grupoplexus.sharepoint.com/sites/wiki"
$targetSiteUrl = "https://grupoplexus.sharepoint.com/sites/884-MutuaGallega"
$listNameProyectos = "Proyectos"
$jsonFolderPath = "C:\Users\victor.jimenezvaquer\Documents\PlexusTech\app-ENRIQUE\PROYECTO_WIKI\JSONS\884-Mutua-Gallega"
$nombreCliente = "884 - Mutua Gallega"  # Nombre del cliente a buscar

# Step 1: Conectar al sitio "wiki" para obtener la lista de clientes
Connect-PnPOnline -Url $wikiUrl -Interactive

# Obtener todos los elementos de la lista "LISTADO CLIENTES"
$clientes = Get-PnPListItem -List "LISTADO CLIENTES" -Fields "ID", "CodigoCliente", "Title"

# Buscar el ID del cliente correspondiente al nombre dado
$clienteId = $null
foreach ($cliente in $clientes) {
  $nombreCompletoCliente = $cliente["Title"]

  # Comparar el nombre completo con el nombre buscado
  if ($nombreCompletoCliente -eq $nombreCliente) {
    $clienteId = $cliente["ID"]
    Write-Host "Cliente encontrado: $nombreCliente con ID: $clienteId" -ForegroundColor Green
    break
  }
}

if ($null -ne $clienteId) {
  # Step 2: Conectar al sitio del cliente y crear la página de inicio
  Connect-PnPOnline -Url $targetSiteUrl -Interactive

  # Crear la página de inicio si no existe
  $existingHomePage = Get-PnPPage -Identity "Inicio.aspx" -ErrorAction SilentlyContinue
  if ($null -eq $existingHomePage) {
    $pageParams = @{
      Name             = "Inicio"
      Title            = "Inicio"
      HeaderLayoutType = "FullWidthImage"
    }

    Write-Host "Adding new page: $pageName" -ForegroundColor Green
    $newPage = Add-PnPPage @pageParams -ErrorAction Stop
    
  }
  else {
    Write-Host "Home page $homePageName already exists. Skipping creation." -ForegroundColor Yellow
  }

  # Procesar archivos y carpetas en la carpeta principal
  $items = Get-ChildItem -Path $jsonFolderPath

  foreach ($item in $items) {
    if ($item.PSIsContainer) {
      $folderName = $item.Name
      $mainPageName = $folderName

      # $existingPage = Get-PnPPage -Identity "$mainPageName.aspx" -ErrorAction SilentlyContinue
      if ($null -eq $existingPage) {
        $pageParams = @{
          Name             = $mainPageName
          Title            = $mainPageName
          HeaderLayoutType = "FullWidthImage"
        }

        Write-Host "Creating empty page for folder: $folderName" -ForegroundColor Green
        # $mainPage = Add-PnPPage @pageParams -ErrorAction Stop
        Write-Host "Empty page created: $($mainPage.Name)" -ForegroundColor Green

      }
      else {
        Write-Host "Page $mainPageName already exists. Skipping creation." -ForegroundColor Yellow
      }
    }
    else {
      $pageName = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)

      $existingPage = Get-PnPPage -Identity "$pageName.aspx" -ErrorAction SilentlyContinue
      if ($null -eq $existingPage) {
        $jsonContent = Get-Content -Path $item.FullName -Raw | ConvertFrom-Json

        $pageParams = @{
          Name             = $pageName
          Title            = $pageName
          HeaderLayoutType = "FullWidthImage"
        }

        Write-Host "Adding new page: $pageName" -ForegroundColor Green
        $newPage = Add-PnPPage @pageParams -ErrorAction Stop

        $order = 1
        foreach ($section in $jsonContent) {
          $titulo = $section.titulo
          $texto = $section.texto

          $htmlContent = @"
<div id='section'>
  <h4>$titulo</h4>
  <div style='overflow-x: auto !important; font-size: 16px !important;'>$texto</div>
</div>
"@

          try {
            $newPage | Add-PnPPageSection -SectionTemplate OneColumn -Order $order -ZoneEmphasis 2
            $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section $order -Text $htmlContent
          }
          catch {
            Write-Host "Error adding section for title '$titulo': $_" -ForegroundColor Red
            exit
          }
          $order++
        }

        Write-Host "Publishing page and promoting as News..." -ForegroundColor Green
        $newPage | Set-PnPPage -PromoteAs NewsArticle -Publish
      }
      else {
        Write-Host "Page $pageName already exists. Skipping creation." -ForegroundColor Yellow
      }
    }
  }

  # Conectar al sitio objetivo para obtener todas las páginas creadas
  Connect-PnPOnline -Url $targetSiteUrl -Interactive

  # Recopilar todas las páginas ya creadas desde la biblioteca SitePages
  Write-Host "Retrieving all pages from SitePages to update the 'proyectos' list..." -ForegroundColor Green
  $pages = Get-PnPListItem -List "SitePages" -Fields "FileLeafRef", "FileRef"

  # Conectar al sitio Wiki para actualizar la lista de proyectos
  Connect-PnPOnline -Url $wikiUrl -Interactive

  foreach ($page in $pages) {
    $pageName = $page["FileLeafRef"]
    $pageUrl = $page["FileRef"]

    # Corregir la URL para evitar la duplicación del sitio base
    $correctedUrl = $pageUrl -replace "^/sites/884-MutuaGallega/", "/"

    # Verificar si la página ya existe en la lista "Proyectos"
    $existingProject = Get-PnPListItem -List $listNameProyectos -Query "<View><Query><Where><And><Eq><FieldRef Name='Title'/><Value Type='Text'>$pageName</Value></Eq><Eq><FieldRef Name='Cliente'/><Value Type='Lookup'>$clienteId</Value></Eq></And></Where></Query></View>" -Fields "ID"

    if ($null -eq $existingProject) {
      Write-Host "Adding page: $pageName to the 'proyectos' list..." -ForegroundColor Green

      Add-PnPListItem -List $listNameProyectos -Values @{
        "Cliente"           = $clienteId   # Usar el ID del cliente encontrado
        "Title"             = $pageName    # Título del proyecto
        "EspacioDocumental" = "$targetSiteUrl$correctedUrl" # URL corregida del documento
      }
    }
    else {
      Write-Host "Page $pageName already exists in the 'proyectos' list. Skipping..." -ForegroundColor Yellow
    }
  }
}

Write-Host "Done! :)" -ForegroundColor Green