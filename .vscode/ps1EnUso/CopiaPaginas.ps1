#Parameters
$SourceSiteURL = "https://grupoplexus.sharepoint.com/sites/TemplateWIKI2"
$DestinationSiteURL = "https://grupoplexus.sharepoint.com/sites/wiki"
$PageName = "PlantillaCentralizada.aspx"
 
#Connect to Source Site
Connect-PnPOnline -Url $SourceSiteURL -Interactive -ClientId a4c5532e-a48a-4045-a4fe-294fe6edf004
 
#Export the Source page
$TempFile = [System.IO.Path]::GetTempFileName()
Export-PnPPage -Force -Identity $PageName -Out $TempFile
 
#Import the page to the destination site
Connect-PnPOnline -Url $DestinationSiteURL -Interactive -ClientId a4c5532e-a48a-4045-a4fe-294fe6edf004
Invoke-PnPSiteTemplate -Path $TempFile

