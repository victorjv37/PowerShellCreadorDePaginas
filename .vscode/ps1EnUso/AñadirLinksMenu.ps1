param(
    [string]$SiteUrl = "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA"
)

# Conectar a SharePoint Online
try {
    Connect-PnPOnline -Url $SiteUrl -Interactive
}
catch {
    Write-Host "Error al conectar al sitio de SharePoint. Por favor, verifique el parámetro SiteUrl." -ForegroundColor Red
    exit
}

# Cargar todas las páginas que contienen "884" en su nombre
# try {
#     $pagesLibrary = Get-PnPList -Identity "SitePages"
#     $pages = Get-PnPListItem -List $pagesLibrary -PageSize 1000 | Where-Object { $_.FieldValues.FileLeafRef -match "884" }
# }
# catch {
#     Write-Host "Error al cargar las páginas: $_" -ForegroundColor Red
#     exit
# }

# Remove all existing navigation nodes
Write-Host "Removing all existing navigation nodes..."
try {
    $navigationNodes = Get-PnPNavigationNode -Location "QuickLaunch"
    foreach ($node in $navigationNodes) {
        Remove-PnPNavigationNode -Identity $node.Id -Force
        Write-Host "Removed navigation node: $($node.Title)" -ForegroundColor Green
    }
}
catch {
    Write-Host "Error removing navigation nodes: $_" -ForegroundColor Red
    exit
}

# Add the main nodes for "PROYECTOS", "EVOLUTIVOS", and "SOLUCIONES"
Write-Host "Adding main navigation nodes..."
try {
    #Inicio
    Add-PnPNavigationNode -Title "Inicio" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/Inicio.aspx" -Location "QuickLaunch"
    $mainNodeProyectos = Add-PnPNavigationNode -Title "PROYECTOS" -Location "QuickLaunch" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/Inicio.aspx" 
    $mainNodeEvolutivos = Add-PnPNavigationNode -Title "EVOLUTIVOS" -Location "QuickLaunch" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/Inicio.aspx"
    $mainNodeSoluciones = Add-PnPNavigationNode -Title "SOLUCIONES" -Location "QuickLaunch" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/Inicio.aspx"
    Write-Host "Added main navigation nodes for 'PROYECTOS', 'EVOLUTIVOS', and 'SOLUCIONES'" -ForegroundColor Green
}
catch {
    Write-Host "Error adding main navigation nodes: $_" -ForegroundColor Red
    exit
}

# Add new custom links under the main nodes
Write-Host "Adding custom links to main nodes..."
try {
    # Proyectos
    $seccion13 = Add-PnPNavigationNode -Title "884-013-Mutua-Gallega-Fase-II-Quenda-Anblick" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/884-013-Mutua-Gallega-Fase-II-Quenda-Anblick(HW-SW)(L-V-8-20h-Except.-Fest-Nacio-y-Auto).aspx" -Location "QuickLaunch" -Parent $mainNodeProyectos.Id
    Add-PnPNavigationNode -Title "1704_884_009_desarrollo" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/1704_884_009_desarrollo.aspx" -Location "QuickLaunch" -Parent $seccion13.Id
    Add-PnPNavigationNode -Title "1704_884_013_comun" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/1704_884_013_comun.aspx" -Location "QuickLaunch" -Parent $seccion13.Id
    Add-PnPNavigationNode -Title "1704_884_013_soporte" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/1704_884_013_soporte.aspx" -Location "QuickLaunch" -Parent $seccion13.Id
    $seccion14 = Add-PnPNavigationNode -Title "884-014---Mutua-Gallega-QM-Anblick" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/884-014---Mutua-Gallega-QM-Anblick(HW-SW)(L-V-8-20h-Except.-Fest.Nacio).aspx" -Location "QuickLaunch" -Parent $mainNodeProyectos.Id
    Add-PnPNavigationNode -Title "1704_884_014_comun" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/1704_884_014_comun.aspx" -Location "QuickLaunch" -Parent $seccion14.Id
    Add-PnPNavigationNode -Title "1704_884_014_desarrollo" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/1704_884_014_desarrollo.aspx" -Location "QuickLaunch" -Parent $seccion14.Id
    Add-PnPNavigationNode -Title "1704_884_014_soporte" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/1704_884_014_soporte.aspx" -Location "QuickLaunch" -Parent $seccion14.Id

    # Evolutivos
    Add-PnPNavigationNode -Title "1704_884_evolutivos" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/1704_884_evolutivos.aspx" -Location "QuickLaunch" -Parent $mainNodeEvolutivos.Id

    # Soluciones
    Add-PnPNavigationNode -Title "1704_884_seccion_general_plantilla" -Url "https://grupoplexus.sharepoint.com/sites/884-MUTUA-GALLEGA/SitePages/1704_884_seccion_general.aspx" -Location "QuickLaunch" -Parent $mainNodeSoluciones.Id

    Write-Host "Added navigation links for pages." -ForegroundColor Green
}
catch {
    Write-Host "Error adding navigation links: $_" -ForegroundColor Red
}

Write-Host "DONE!! :)" -ForegroundColor Green