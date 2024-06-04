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
    Name             = "conector de lantelefonica"
    Title            = "236_029_00_lan_telefonica12"
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

  # Conectar a SharePoint
  try {
    Connect-PnPOnline "https://tejiendored.sharepoint.com/sites/test2" -Interactive
  }
  catch {
    Write-Host "Error connecting to SharePoint site. Please check the Tenant and Site parameters." -ForegroundColor Red
    exit
  }

  # Obtener la navegación lateral
  $navigation = Get-PnPNavigationNode -Location "QuickLaunch"

  # Función para eliminar un nodo por título
  function Remove-NavigationNodeByTitle {
    param (
      [string]$title
    )
    $node = $navigation | Where-Object { $_.Title -eq $title }
    if ($node) {
      Remove-PnPNavigationNode -Identity $node.Id -Force
    }
  }

  # Obtener la navegación lateral y eliminar todos los nodos existentes
  Write-Host "Removing all existing navigation nodes..."
  $navigationNodes = Get-PnPNavigationNode -Location "QuickLaunch"
  foreach ($node in $navigationNodes) {
    Remove-PnPNavigationNode -Identity $node.Id -Force
  }

  # Añadir nuevos enlaces personalizados
  Add-PnPNavigationNode -Title "236_029_00_lan_telefonica" -Url "/sites/test2/SitePages/236_029_00_lan_telefonica.aspx" -Location "QuickLaunch"

  Write-Host "Navigation updated successfully." -ForegroundColor Green
  
  # Load JSON from file
  $jsonContent = Get-Content -Path "C:\Users\victor.jimenezvaquer\Documents\PlexusTech\app-ENRIQUE\JSONS MIGRACION INTRANET\TELEFONICA\236_029_00_lan_telefonica_json.txt" -Raw | ConvertFrom-Json

  # Function to get CSS style based on type
  function Get-Style {
    param ($tipo)
    switch ($tipo) {
      "nota_importante" { return "background-color: yellow;" }
      "contacto_comunicacion" { return "background-color: lightgreen;" }
      "procedimiento" { return "background-color: lightblue;" }
      "configuracion_herramientas" { return "background-color: lightcoral;" }
      "recursos_documentacion" { return "background-color: lightgray;" }
      "SLAs" {
        return "background-color: black;" 
      }
      default { return "" }
    }
  }

  Write-Host "Adding sections from JSON..."
  $order = 1

  # Add a left column section for links to other pages
  Write-Host "Adding a left section with links..."
  $newPage | Add-PnPPageSection -SectionTemplate TwoColumn -Order $order -ZoneEmphasis 2

  # Links to other pages
  $linksHtml = @"
<div>
  <h3>Related Pages</h3>
  <ul>
    <li><a href='/sites/test2/SitePages/236_029_00_lan_telefonica.aspx'>236_029_00_lan_telefonica.aspx</a></li>
  </ul>
</div>
"@

  # Add links to the left column
  $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section $order -Text $linksHtml

  foreach ($item in $jsonContent) {
    $titulo = $item.titulo
    $texto = $item.texto
    $tipo = $item.tipo
    $style = Get-Style -tipo $tipo

    # Create HTML content for this section
    $htmlContent = @"
<div style='$style'>
  <h3>$titulo</h3>
  <div>$texto</div>
</div>
"@

    # Add a new section to the page and add the HTML content
    $newPage | Add-PnPPageSection -SectionTemplate OneColumn -Order ($order + 1) -ZoneEmphasis 2
    $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section ($order + 1) -Text $htmlContent
    $order++
  }

  Write-Host "Publishing Page and promote Page as News..."
  $newPage | Set-PnPPage -PromoteAs NewsArticle -Publish
}
end {
  Write-Host "Done! :)" -ForegroundColor Green
}