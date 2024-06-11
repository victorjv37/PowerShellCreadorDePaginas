begin {
  try {
    Connect-PnPOnline "https://tejiendored.sharepoint.com/sites/test2" -Interactive
  }
  catch {
    Write-Host "Error connecting to SharePoint site. Please check the Tenant and Site parameters." -ForegroundColor Red
    exit
  }

  # Page parameters
  $pageParams = @{
    Name             = "1704_236_083_02_comun_plantilla"
    Title            = "1704_236_083_02_comun_plantilla"
    HeaderLayoutType = "FullWidthImage"
  }
}

process {
  if ($CleanExistingPage) {
    try {
      Write-Host "Removing existing page..." -ForegroundColor Yellow
      Remove-PnPPage -Identity $pageParams.Name -Force -ErrorAction Stop
    }
    catch {
      Write-Host "Error removing existing page: $_" -ForegroundColor Red
    }
  }

  try {
    Write-Host "Adding new page..." -ForegroundColor Green
    $newPage = Add-PnPPage @pageParams -ErrorAction Stop
    Write-Host "Page added successfully: $($newPage.Name)" -ForegroundColor Green
  }
  catch {
    Write-Host "Error adding new page: $_" -ForegroundColor Red
    exit
  }

  # Set the header, topic, image
  Write-Host "Setting the header, topic, image"
  $newPage.PageHeader.ImageServerRelativeUrl = "https://www.telefonica.es/es/wp-content/uploads/sites/10/2021/12/telefonica-logo-horizontal-positivo-1250.jpeg"
  $newPage.PageHeader.TopicHeader = "Example"
  $newPage.Save()

  # Remove all existing navigation nodes
  Write-Host "Removing all existing navigation nodes..."
  $navigationNodes = Get-PnPNavigationNode -Location "QuickLaunch"
  foreach ($node in $navigationNodes) {
    Remove-PnPNavigationNode -Identity $node.Id -Force
  }

  # Load JSON from file
  $jsonContent = Get-Content -Path "C:\Users\victor.jimenezvaquer\Documents\PlexusTech\app-ENRIQUE\JSONS MIGRACION INTRANET\TELEFONICA\Área Producto\1704_236_083_02_comun_plantilla_json.txt" -Raw | ConvertFrom-Json

  # Definición del bloque de estilos CSS
  $styleBlock = @"
<style>
    .div {
        font-size: 16px !important;
    }
    p {
        font-size: inherit !important;
    }
</style>
"@

  # Crear la sección de índice
  function CreateIndexSection {
    param (
      [array]$items
    )

    $indexHtml = "<div id='indexSection' style='padding: 10px; border-radius: 15px;'>"
    $indexHtml += "<h2>Índice</h2><ul>"

    $counter = 1
    foreach ($item in $items) {
      $titulo = $item.titulo
      if ($titulo) {
        $indexHtml += "<li><a href='#section$counter'>$titulo</a></li>"
        $counter++
      }
    }

    $indexHtml += "</ul></div>"
    return $indexHtml
  }

  Write-Host "Adding sections from JSON..."
  $order = 1

  # Agregar la sección de estilos CSS como la primera sección
  try {
    $newPage | Add-PnPPageSection -SectionTemplate OneColumn -Order $order -ZoneEmphasis 1
    $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section $order -Text $styleBlock
  }
  catch {
    Write-Host "Error adding CSS style section: $_" -ForegroundColor Red
    exit
  }
  $order++

  # Agregar la sección del índice como la segunda sección
  try {
    $indexHtml = CreateIndexSection -items $jsonContent
    $newPage | Add-PnPPageSection -SectionTemplate OneColumn -Order $order -ZoneEmphasis 3
    $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section $order -Text $indexHtml
  }
  catch {
    Write-Host "Error adding index section: $_" -ForegroundColor Red
    exit
  }
  $order++

  # Function to get CSS style based on type
  function Get-Style {
    param ($tipo)
    switch ($tipo) {
      "nota_importante" { return "background-color: #FFFFCC; border-radius: 15px; padding: 10px;" }
      "contacto_comunicacion" { return "border-radius: 15px; padding: 10px;" }
      "procedimiento" { return "border-radius: 15px; padding: 10px;" }
      "configuracion_herramientas" { return "border-radius: 15px; padding: 10px;" }
      "recursos_documentacion" { return "border-radius: 15px; padding: 10px;" }
      "SLAs" {
        return "background-color: rgb(215, 219, 255); border-radius: 15px; padding: 10px;" 
      }
      default { return "" }
    }
  }

  Write-Host "Adding sections from JSON..."
  $sectionCounter = 1

  foreach ($item in $jsonContent) {
    $titulo = $item.titulo
    $texto = $item.texto
    $tipo = $item.tipo
    $style = Get-Style -tipo $tipo
    
    # Crear HTML content para esta sección
    $htmlContent = @"
<div class='div' style='$style' id='section$sectionCounter'>
  <h3>$titulo</h3>
  <div>$texto</div>
</div>
"@

    try {
      # Añadir una nueva sección a la página y añadir el contenido HTML
      $newPage | Add-PnPPageSection -SectionTemplate OneColumn -Order $order -ZoneEmphasis 2
      $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section $order -Text $htmlContent
    }
    catch {
      Write-Host "Error adding section for title '$titulo': $_" -ForegroundColor Red
      exit
    }
    $order++
    $sectionCounter++
  }

  Write-Host "Publishing Page and promoting Page as News..."
  try {
    $newPage | Set-PnPPage -PromoteAs NewsArticle -Publish
  }
  catch {
    Write-Host "Error publishing page: $_" -ForegroundColor Red
    exit
  }
}

end {
  Write-Host "Done! :)" -ForegroundColor Green
}