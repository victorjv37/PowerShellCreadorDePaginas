param(
    [string]$SiteUrl = "https://tejiendored.sharepoint.com/sites/test2"
)

# Conectar a SharePoint Online
try {
    Connect-PnPOnline -Url $SiteUrl -Interactive
}
catch {
    Write-Host "Error al conectar al sitio de SharePoint. Por favor, verifique el parámetro SiteUrl." -ForegroundColor Red
    exit
}

# Cargar todas las páginas que contienen "236" en su nombre
try {
    $pagesLibrary = Get-PnPList -Identity "SitePages"
    $pages = Get-PnPListItem -List $pagesLibrary -PageSize 1000 | Where-Object { $_.FieldValues.FileLeafRef -match "236" }
}
catch {
    Write-Host "Error al cargar las páginas: $_" -ForegroundColor Red
    exit
}

# Remove existing navigation nodes for pages containing "236"
Write-Host "Removing existing navigation nodes for pages containing '236'..."
try {
    $navigationNodes = Get-PnPNavigationNode -Location "QuickLaunch"
    foreach ($page in $pages) {
        $pageTitle = $page.FieldValues.FileLeafRef
        $pageNodes = $navigationNodes | Where-Object { $_.Title -eq $pageTitle }
        foreach ($node in $pageNodes) {
            Remove-PnPNavigationNode -Identity $node.Id -Force
        }
        Write-Host "Removed navigation nodes for page: $($pageTitle)" -ForegroundColor Green
    }
}
catch {
    Write-Host "Error removing navigation nodes: $_" -ForegroundColor Red
    exit
}

# Add new custom links for pages containing "236"
Write-Host "Adding custom links to navigation..."
foreach ($page in $pages) {
    $pageTitle = $page.FieldValues.FileLeafRef
    $pageUrl = $page.FieldValues.FileRef
    try {
        Add-PnPNavigationNode -Title $pageTitle -Url $pageUrl -Location "QuickLaunch"
        Write-Host "Added navigation link for page: $($pageTitle)" -ForegroundColor Green
    }
    catch {
        Write-Host "Error adding navigation link for page: $($pageTitle): $_" -ForegroundColor Red
    }
}