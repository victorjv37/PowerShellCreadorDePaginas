# Variables de configuración
$targetSiteUrl = "https://grupoplexus.sharepoint.com/sites/1226-AguasdeCoruaEMALCSA" # URL del sitio donde se crearán las páginas
$wikiUrl = "https://grupoplexus.sharepoint.com/sites/wiki" # URL del sitio concentrador para la lista 'proyectos'
$listNameProyectos = "Proyectos"
$jsonFolderPath = "C:\Users\victor.jimenezvaquer\Documents\PlexusTech\app-ENRIQUE\PROYECTO_WIKI\JSONS\1226- Aguas de Coruña (EMALCSA)"
$cliente = "1226-AguasdeCoruaEMALCSA"

# Conectar al sitio donde se crearán las páginas
Connect-PnPOnline -Url $targetSiteUrl -Interactive

# Procesar archivos y carpetas en la carpeta principal
$items = Get-ChildItem -Path $jsonFolderPath

foreach ($item in $items) {
  if ($item.PSIsContainer) {
    $folderName = $item.Name
    $mainPageName = $folderName

    $existingPage = Get-PnPPage -Identity "$mainPageName.aspx" -ErrorAction SilentlyContinue
    if ($null -eq $existingPage) {
      $pageParams = @{
        Name             = $mainPageName
        Title            = $mainPageName
        HeaderLayoutType = "FullWidthImage"
      }

      Write-Host "Creating empty page for folder: $folderName" -ForegroundColor Green
      $mainPage = Add-PnPPage @pageParams -ErrorAction Stop
      Write-Host "Empty page created: $($mainPage.Name)" -ForegroundColor Green

      Write-Host "Publishing empty page and promoting as News..." -ForegroundColor Green
      $mainPage | Set-PnPPage -PromoteAs NewsArticle -Publish
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

# Obtener el ID del cliente en la lista "LISTADO CLIENTES"
$clienteItem = Get-PnPListItem -List "LISTADO CLIENTES" -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$cliente</Value></Eq></Where></Query></View>"

if ($null -ne $clienteItem) {
  $clienteId = $clienteItem[0].Id

  foreach ($page in $pages) {
    $pageName = $page["FileLeafRef"]
    # $pageUrl = $page["FileRef"]

    Write-Host "Adding page: $pageName to the 'proyectos' list..." -ForegroundColor Green

    Add-PnPListItem -List $listNameProyectos -Values @{
      "Cliente"  = $clienteId; # Usar el ID en lugar del texto
      "Proyecto" = $pageName;
      "Link"     = "$targetSiteUrl$pageUrl"
    }
  }
}
else {
  Write-Host "Error: El cliente '$cliente' no fue encontrado en la lista 'LISTADO CLIENTES'." -ForegroundColor Red
}

Write-Host "Done! :)" -ForegroundColor Green