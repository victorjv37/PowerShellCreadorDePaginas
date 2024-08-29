$wikiUrl = "https://grupoplexus.sharepoint.com/sites/wiki"
$siteName = "OtraPrueba!"
$listNameClientes = "LISTADO CLIENTES"
$desiredSiteUrl = "https://grupoplexus.sharepoint.com/sites/$siteName"

# Conectar al sitio Wiki (sitio concentrador)
Connect-PnPOnline -Url $wikiUrl -Interactive

# Comprobar si el sitio ya está en la lista LISTADO CLIENTES
$existingItem = Get-PnPListItem -List $listNameClientes -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$siteName</Value></Eq></Where></Query></View>"

if ($null -eq $existingItem) {
    # Crear un nuevo sitio de comunicación si no existe
    $newSite = New-PnPSite -Type CommunicationSite -Title $siteName -Url $desiredSiteUrl
    $siteUrl = $newSite.SiteUrl
    Write-Host "Nuevo sitio de comunicación creado en: $siteUrl"

    # Esperar un momento para asegurar que el sitio se haya creado correctamente
    Start-Sleep -Seconds 10

    # Verificar si la URL se ha asignado correctamente
    if (-not $siteUrl) {
        $siteUrl = (Get-PnPTenantSite -Url $desiredSiteUrl).Url
    }

    # Agregar el nuevo sitio a la lista LISTADO CLIENTES
    Add-PnPListItem -List $listNameClientes -Values @{"Title" = $siteName; "SitioProyecto" = $siteUrl }
    Write-Host "Sitio $siteName agregado a la lista $listNameClientes."
}
else {
    Write-Host "El sitio $siteName ya existe en la lista $listNameClientes."
}