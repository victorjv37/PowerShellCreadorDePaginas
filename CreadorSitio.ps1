# param(
#     [string]$siteName
# )

# Conectar a SharePoint
try {
    Connect-PnPOnline "https://grupoplexus.sharepoint.com/sites/demoAdeslasCLIENTE" -Interactive
}
catch {
    Write-Host "Error connecting to SharePoint site. Please check the Tenant and Site parameters." -ForegroundColor Red
    exit
}

# Crear un nuevo sitio de comunicación
New-PnPSite -Type TeamSite -Title "884-MUTUA-GALLEGA" -Owners "victor.jimenezvaquero@plexus.es" -Alias "884-MUTUA-GALLEGA"

# Conectar al sitio que quieres asociar
# try {
#     Connect-PnPOnline "https://grupoplexus-admin.sharepoint.com/sites/ejemploScript" -Interactive
# }
# catch {
#     Write-Host "Error connecting to SharePoint site. Please check the Tenant and Site parameters." -ForegroundColor Red
#     exit
# }
# # Asociar al Hub Site
# Add-PnPHubSiteAssociation -Site "https://grupoplexus-admin.sharepoint.com/sites/ejemploScript" -HubSite "https://grupoplexus.sharepoint.com/sites/Inicio"