# Conectar al sitio de grupo (origen) y exportar la página
Connect-PnPOnline -Url "https://grupoplexus.sharepoint.com/sites/1388-HospitalUniversitarioSantJoandeReus" -Interactive 
Get-PnPSiteTemplate -Out "C:\Users\victor.jimenezvaquer\Documents\PlexusTech\app-ENRIQUE\PROYECTO_WIKI\RUTAS APROVISIONAMIENTO" 

# Conectar al sitio de comunicación (destino) y aplicar la página
# Connect-PnPOnline -Url "https://grupoplexus.sharepoint.com/sites/pruebafacil" -Interactive
# Invoke-PnPSiteTemplate -Path "C:\Users\victor.jimenezvaquer\Documents\PlexusTech\app-ENRIQUE\PROYECTO_WIKI\RUTAS APROVISIONAMIENTO\Aprovisionamiento.xml"