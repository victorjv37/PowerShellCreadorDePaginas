# Paso 1: Instalar el módulo PnP PowerShell (solo necesario la primera vez)
Install-Module -Name "PnP.PowerShell"

# Paso 2: Conectarse a SharePoint Online
Connect-PnPOnline -Url "https://tu-dominio.sharepoint.com/sites/tu-sitio" -Interactive

# Paso 3: Definir Variables de la Plantilla
$siteTitle = "Mi Sitio Personalizado"
$siteDescription = "Este es un sitio de prueba con variables"
$ownerEmail = "owner@tu-dominio.com"

# Paso 4: Crear la Plantilla de Aprovisionamiento (Exportar la estructura actual del sitio)
$templatePath = "C:\Templates\MySiteTemplate.xml"
Get-PnPSiteTemplate -Out $templatePath

# Paso 5: Modificar la Plantilla (Abre el archivo XML exportado y modifica según sea necesario)
# Ejemplo de cómo podría verse una sección en el archivo XML modificado:
# 
# <pnp:ProvisioningTemplate ID="MysiteTemplate" Version="1" xmlns:pnp="http://schemas.dev.office.com/PnP/2020/12/ProvisioningSchema">
#   <pnp:Preferences Generator="OfficeDevPnP.Core, Version=3.20.2004.0, Culture=neutral, PublicKeyToken=5e633289e95c321e" />
#   <pnp:WebSettings Title="{sitioTitle}" Description="{sitioDescription}" />
#   <pnp:Security>
#     <pnp:SiteGroups>
#       <pnp:SiteGroup Title="Owners" Description="Site Owners" Owner="{ownerEmail}">
#         <pnp:Members>
#           <pnp:User Name="{ownerEmail}" />
#         </pnp:Members>
#       </pnp:SiteGroup>
#     </pnp:SiteGroups>
#   </pnp:Security>
# </pnp:ProvisioningTemplate>

# Paso 6: Aplicar la Plantilla con Variables
$parameters = @{
    "sitioTitle"       = $siteTitle
    "sitioDescription" = $siteDescription
    "ownerEmail"       = $ownerEmail
}

Apply-PnPTenantTemplate -Path $templatePath -Parameters $parameters

# Paso 7: Desconectar la sesión
Disconnect-PnPOnline