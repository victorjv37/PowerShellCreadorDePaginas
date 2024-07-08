begin {
  try {
    Connect-PnPOnline "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA" -Interactive
  }
  catch {
    Write-Host "Error connecting to SharePoint site. Please check the Tenant and Site parameters." -ForegroundColor Red
    exit
  }

  # Page parameters
  $pageParams = @{
    Name             = "PRUEBA"
    Title            = "PRUEBA"
    HeaderLayoutType = "FullWidthImage"
  }
}

process {
  try {
    Write-Host "Adding new page..." -ForegroundColor Green
    $newPage = Add-PnPPage @pageParams -ErrorAction Stop
    Write-Host "Page added successfully: $($newPage.Name)" -ForegroundColor Green
  }
  catch {
    Write-Host "Error adding new page: $_" -ForegroundColor Red
    exit
  }

  # Load JSON from file
  $jsonContent = Get-Content -Path "C:\Users\victor.jimenezvaquer\Documents\PlexusTech\app-ENRIQUE\PROYECTO_WIKI\JSONS\884-Mutua-Gallega\PRUEBA.txt" -Raw | ConvertFrom-Json

  # Function to get CSS style based on type
  function Get-Style {
    param ($tipo)
    switch ($tipo) {
      "nota_importante" { return "background-color: #FFFFCC !important; border-radius: 15px !important; padding: 10px !important;" }
      "contacto_comunicacion" { return "border-radius: 15px !important; padding: 10px !important;" }
      "procedimiento" { return "border-radius: 15px !important; padding: 10px !important;" }
      "configuracion_herramientas" { return "border-radius: 15px !important; padding: 10px !important;" }
      "recursos_documentacion" { return "border-radius: 15px !important; padding: 10px !important;" }
      "SLA's" {
        return "background-color: rgb(215, 219, 255) !important; border-radius: 15px !important; padding: 10px !important;" 
      }
      default { return "" }
    }
  }

  Write-Host "Adding sections from JSON..."
  $order = 1

  # Define the URL of the external CSS file
  $externalCssUrl = "https://grupoplexus.sharepoint.com/:u:/r/sites/884-MUTUA-GALLEGA/Archivos%20de%20las%20pginas/misEstilos.css?csf=1&web=1&e=oU3EaT"

  # Create the index section
  function CreateIndexSection {
    param ([array]$items)

    $indexHtml = "<div id='indexSection'>"
    $indexHtml += "<h2>Índice</h2><ul>"

    foreach ($item in $items) {
      $titulo = $item.titulo
      if ($titulo) {
        $titulolimpiado = $titulo.Tolower() -replace ' ', '-' 
        $indexHtml += "<li><a href='#$titulolimpiado'>$titulo</a></li>"
      }
    }

    $indexHtml += "</ul></div>"
    return $indexHtml
  }
  
  # Add the CSS link as the first content of the page
  try {
    $cssLinkHtml = "<a rel='stylesheet' type='text/css' href='$externalCssUrl'></a>"
    $newPage | Add-PnPPageSection -SectionTemplate OneColumn -Order $order -ZoneEmphasis 3
    $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section $order -Text $cssLinkHtml
  }
  catch {
    Write-Host "Error adding CSS link: $_" -ForegroundColor Red
    exit
  }
  $order++

  # Add the index section
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

  $sectionCounter = 1

  foreach ($item in $jsonContent) {
    $titulo = $item.titulo
    $texto = $item.texto
    $tipo = $item.tipo
    $style = Get-Style -tipo $tipo

    # Create HTML content for this section
    $htmlContent = @"
<div id='section' style='$style'>
  <h4>$titulo</h4>
  <div style='overflow-x: auto !important; font-size: 16px !important;'>$texto</div>
</div>
"@

    try {
      # Add a new section to the page and add the HTML content
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