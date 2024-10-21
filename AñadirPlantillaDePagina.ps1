# Definir los valores directamente en el script
$SourceSiteURL = "https://grupoplexus.sharepoint.com/sites/TemplateWIKI2"
$HubSiteURL = "https://grupoplexus.sharepoint.com/sites/wiki"
$PageName = "Proyecto-InfraestructuraCentralizada.aspx"

# Definir las credenciales directamente
$username = "intranet@plexus.tech"
$password = "b)Q5J@(n8qETfR"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

# Variables
$LogFileName = "add_spopagetemplates_" + $(get-date -f filedatetime) + ".txt"

#####################
Start-Transcript -Path .\logs\$LogFileName -NoClobber 

try {
    # Conectar al sitio de la plantilla y exportar la página
    Write-Host "Conectando al sitio de la plantilla: $SourceSiteURL"
    Connect-PnPOnline -Url $SourceSiteURL -ClientId a4c5532e-a48a-4045-a4fe-294fe6edf004 -Credentials $Cred
    
    $TempFile = [System.IO.Path]::GetTempFileName()
    Export-PnPPage -Force -Identity $PageName -Out $TempFile
    Write-Host "Plantilla exportada a archivo temporal"
    
    Disconnect-PnPOnline

    # Conectar al sitio concentrador
    Write-Host "Conectando al sitio concentrador: $HubSiteURL"
    Connect-PnPOnline -Url $HubSiteURL -ClientId a4c5532e-a48a-4045-a4fe-294fe6edf004 -Credentials $Cred

    # Obtener todos los sitios asociados
    Write-Host "Obteniendo sitios asociados..."
    $sitiosAsociados = Get-PnPHubSiteChild -Identity $HubSiteURL

    if ($null -eq $sitiosAsociados -or $sitiosAsociados.Count -eq 0) {
        Write-Host "No se encontraron sitios asociados. Verifica que $HubSiteURL sea un sitio concentrador válido."
        return
    }

    Write-Host "Sitios asociados encontrados: $($sitiosAsociados.Count)"
    foreach ($sitio in $sitiosAsociados) {
        Write-Host "Sitio asociado: $sitio"
    }

    # Iterar sobre cada sitio asociado y añadir la plantilla
    foreach ($sitio in $sitiosAsociados) {
        if ([string]::IsNullOrEmpty($sitio)) {
            Write-Host "URL del sitio es nula o vacía. Saltando este sitio."
            continue
        }

        Write-Host "Procesando sitio: $sitio"
        Connect-PnPOnline -Url $sitio -ClientId a4c5532e-a48a-4045-a4fe-294fe6edf004 -Credentials $Cred
        
        # Comprobar si existe la carpeta de plantillas y si contiene la plantilla
        $carpetaPlantillas = Get-PnPFolder -Url "SitePages/Plantillas" -ErrorAction SilentlyContinue
        if ($null -ne $carpetaPlantillas) {
            $plantillaExistente = Get-PnPFile -Url "SitePages/Plantillas/$PageName" -ErrorAction SilentlyContinue
            if ($null -ne $plantillaExistente) {
                Write-Host "La plantilla ya existe en la carpeta de plantillas de $sitio. Pasando al siguiente sitio."
                Disconnect-PnPOnline
                continue
            }
        }
        
        # Comprobar si la página ya existe en la raíz de SitePages
        $paginaExistente = Get-PnPClientSidePage -Identity $PageName -ErrorAction SilentlyContinue
        
        if ($null -eq $paginaExistente) {
            # Si la página no existe, la importamos
            Invoke-PnPSiteTemplate -Path $TempFile
            Write-Host "Plantilla añadida a $sitio"
            
            # Obtener la página y establecer el título correcto
            $pagina = Get-PnPClientSidePage -Identity $PageName
            $tituloCorregido = $PageName -replace '\.aspx$', ''  # Elimina la extensión .aspx si existe
            $pagina.PageTitle = $tituloCorregido
            $pagina.Save()
            $pagina.Publish()
            
            # Promover la página como plantilla con el título correcto
            Set-PnPPage -Identity $PageName -PromoteAs Template -Title $tituloCorregido
            Write-Host "Página promovida como plantilla en $sitio con el título: $tituloCorregido"

            # Eliminar la página original fuera de la carpeta de plantillas
            Remove-PnPFile -ServerRelativeUrl "/sites/$($sitio.Split('/')[-1])/SitePages/$PageName" -Force
            Write-Host "Página original eliminada de la raíz de SitePages en $sitio"
        }
        else {
            Write-Host "La plantilla ya existe en la raíz de SitePages de $sitio"
        }
        
        Disconnect-PnPOnline
    }
}
catch {
    Write-Host "Se produjo un error: $_"
    Write-Host "StackTrace: $($_.ScriptStackTrace)"
}
finally {
    # Eliminar el archivo temporal
    if (Test-Path $TempFile) {
        Remove-Item -Path $TempFile -Force
    }
    #####################
    Stop-Transcript
}
