param(
    [string]$SiteUrl = "https://tejiendored.sharepoint.com/sites/test2",
    [string]$TargetPageName = "TELEFONICA"
)

# Conectar a SharePoint Online
try {
    Connect-PnPOnline -Url $SiteUrl -Interactive
}
catch {
    Write-Host "Error al conectar al sitio de SharePoint. Por favor, verifique el parámetro SiteUrl." -ForegroundColor Red
    exit
}

# Crear o limpiar la página de destino
try {
    $targetPage = Get-PnPPage -Identity $TargetPageName -ErrorAction SilentlyContinue
    if ($targetPage) {
        Remove-PnPPage -Identity $TargetPageName -Force
    }
    $targetPage = Add-PnPPage -Name $TargetPageName -Title $TargetPageName -HeaderLayoutType "FullWidthImage"
    Write-Host "Página de destino creada exitosamente: $($targetPage.Name)" -ForegroundColor Green
}
catch {
    Write-Host "Error al crear la página de destino: $_" -ForegroundColor Red
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

# Inicializar variables para su uso en el bloque try
$columnIndex = 1
$sectionIndex = 1
$pageTitle = ""
$pageUrl = ""
$webPartId = ""

# Adding links to the destination page in columns of 3
try {
    Add-PnPPageSection -Page $TargetPageName -SectionTemplate ThreeColumn
    Write-Host "Initial section created" -ForegroundColor Green
    foreach ($page in $pages) {
        $pageTitle = $page.FieldValues.FileLeafRef
        $pageUrl = $page.FieldValues.FileRef

        # Add a LinkPreview web part
        Add-PnPPageWebPart -Page $TargetPageName -DefaultWebPartType LinkPreview -Section $sectionIndex -Column $columnIndex
        Write-Host "Link added to column $columnIndex for page: $pageTitle" -ForegroundColor Green
        
        # Get the web part ID (GUID)
        $webPartId = $page.FieldValues.GUID

        # Set the web part property
        Set-PnPWebPartProperty -Page $TargetPageName -Identity $webPartId -Key "linkUrl" -Value $pageUrl

        $columnIndex++
        if ($columnIndex -gt 3) {
            $columnIndex = 1
            $sectionIndex++
            Add-PnPPageSection -Page $TargetPageName -SectionTemplate ThreeColumn
            Write-Host "New section created" -ForegroundColor Green
        }
    }

    $targetPage = Get-PnPPage -Identity $TargetPageName
    $targetPage | Set-PnPPage -PromoteAs NewsArticle -Publish
    Write-Host "Links successfully added to the target page and published." -ForegroundColor Green
}
catch {
    Write-Host "Error adding links to the target page: $_" -ForegroundColor Red
    Write-Host "Variables del último intento:" -ForegroundColor Yellow
    Write-Host "columnIndex: $columnIndex" -ForegroundColor Yellow
    Write-Host "sectionIndex: $sectionIndex" -ForegroundColor Yellow
    Write-Host "pageTitle: $pageTitle" -ForegroundColor Yellow
    Write-Host "pageUrl: $pageUrl" -ForegroundColor Yellow
    Write-Host "webPartId: $webPartId" -ForegroundColor Yellow
    exit
}

Write-Host "Done! :)" -ForegroundColor Green