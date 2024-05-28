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
    Name             = "236_029_00_lan_telefonica"
    Title            = "236_029_00_lan_telefonica"
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
  $newPage.PageHeader.ImageServerRelativeUrl = "https://i1.wp.com/bolsadigital.org/wp-content/uploads/2015/01/1558px-Telefonica_Logo.svg_.png?resize=1558%2C806"
  $newPage.PageHeader.TopicHeader = "Example"

  $newPage.Save()
  $newPage = Get-PnPPage $pageParams.Name

  # Cargar el JSON desde el archivo
  $jsonContent = Get-Content -Path "C:\Users\victor.jimenezvaquer\Documents\PlexusTech\app-ENRIQUE\JSONS MIGRACION INTRANET\TELEFONICA\236_029_00_lan_telefonica_json.txt" -Raw | ConvertFrom-Json

  # Función para obtener el estilo CSS según el tipo
  function Get-Style {
    param ($tipo)
    switch ($tipo) {
      "nota_importante" { return "background-color: yellow;" }
      "contacto_comunicacion" { return "background-color: lightgreen;" }
      "procedimiento" { return "background-color: lightblue;" }
      "configuracion_herramientas" { return "background-color: lightcoral;" }
      "recursos_documentacion" { return "background-color: lightgray;" }
      "SLAs" { return "background-color: coral;" }
      default { return "" }
    }
  }

  Write-Host "Adding sections from JSON..."
  $order = 1
  foreach ($item in $jsonContent) {
    $titulo = $item.titulo
    $texto = $item.texto
    $tipo = $item.tipo
    $style = Get-Style -tipo $tipo

    # Crear contenido HTML para esta sección
    $htmlContent = @"
<div style='$style'>
  <h3>$titulo</h3>
  <div>$texto</div>
</div>
"@

    # Añadir una nueva sección a la página y agregar el contenido HTML
    $newPage | Add-PnPPageSection -SectionTemplate OneColumn -Order $order
    $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section $order -Text $htmlContent
    $order++
  }

  Write-Host "Publishing Page and promote Page as News..."
  $newPage | Set-PnPPage -PromoteAs NewsArticle -Publish
}
end {
  Write-Host "Done! :)" -ForegroundColor Green
}