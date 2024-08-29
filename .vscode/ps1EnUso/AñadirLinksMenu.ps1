param(
    [string]$SiteUrl = "https://tejiendored.sharepoint.com/sites/PruebaSitioComunicacion"
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
    Add-PnPNavigationNode -Title "Inicio" -Url "https://tejiendored.sharepoint.com/sites/PruebaSitioComunicacion" -Location "QuickLaunch"
    # Secciones generales
    # Add-PnPNavigationNode -Title "898_correos_seccion_general" -Url "https://grupoplexus.sharepoint.com/sites/898-Correos/SitePages/898_correos_seccion_general.aspx" -Location "QuickLaunch" 
    # Nodos grupales
    $mainNodeProyectos = Add-PnPNavigationNode -Title "PROYECTOS" -Location "QuickLaunch" -Url "https://tejiendored.sharepoint.com/sites/PruebaSitioComunicacion" 
    # $mainNodeEvolutivos = Add-PnPNavigationNode -Title "EVOLUTIVOS" -Location "QuickLaunch" -Url "https://grupoplexus.sharepoint.com/sites/898-Correos/SitePages/Inicio.aspx"
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
    $seccion13 = Add-PnPNavigationNode -Title "898-011-Correos-QuendaCita-previaAnblick2000H-Sop.Evol(247)" -Url "https://tejiendored.sharepoint.com/sites/PruebaSitioComunicacion" -Location "QuickLaunch" -Parent $mainNodeProyectos.Id
    Add-PnPNavigationNode -Title "898_011_desarrollo" -Url "https://tejiendored.sharepoint.com/sites/PruebaSitioComunicacion" -Location "QuickLaunch" -Parent $seccion13.Id
    Add-PnPNavigationNode -Title "898_011_comun" -Url "https://tejiendored.sharepoint.com/sites/PruebaSitioComunicacion" -Location "QuickLaunch" -Parent $seccion13.Id
    Add-PnPNavigationNode -Title "898_011_soporte" -Url "https://tejiendored.sharepoint.com/sites/PruebaSitioComunicacion" -Location "QuickLaunch" -Parent $seccion13.Id
    # Evolutivos
    # Add-PnPNavigationNode -Title "898_evolutivos" -Url "https://grupoplexus.sharepoint.com/sites/898-Correos/SitePages/898_evolutivos.aspx" -Location "QuickLaunch" -Parent $mainNodeEvolutivos.Id
    Write-Host "Added navigation links for pages." -ForegroundColor Green
}
catch {
    Write-Host "Error adding navigation links: $_" -ForegroundColor Red
}

Write-Host "DONE!! :)" -ForegroundColor Green