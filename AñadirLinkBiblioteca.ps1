# Parameters
$SiteUrl = "https://grupoplexus.sharepoint.com/sites/236-Telefonica/"
$PageName = "ProjectHome.aspx"
$DocumentLibraryName = "Documentos"
$SectionTitle = "Demo Biblioteca"
$ZoneId = "Main"
$ZoneIndex = 1

# Connect to SharePoint Online
Connect-PnPOnline -Url $SiteUrl -Interactive

# Get the XML definition of the document library web part
$xml = @"
<webParts>
  <webPart xmlns="http://schemas.microsoft.com/WebPart/v3">
    <metaData>
      <type name="Microsoft.SharePoint.WebPartPages.XsltListViewWebPart, Microsoft.SharePoint, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" />
      <importErrorMessage>Cannot import this Web Part.</importErrorMessage>
    </metaData>
    <data>
      <properties>
        <property name="Title" type="string">$SectionTitle</property>
        <property name="ListId" type="string">GUID_OF_YOUR_DOCUMENT_LIBRARY</property>
        <property name="ChromeType" type="chrometype">TitleOnly</property>
      </properties>
    </data>
  </webPart>
</webParts>
"@

# Replace GUID_OF_YOUR_DOCUMENT_LIBRARY with the actual GUID of your document library
$library = Get-PnPList -Identity $DocumentLibraryName
$xml = $xml.Replace("GUID_OF_YOUR_DOCUMENT_LIBRARY", $library.Id.ToString())
# Add the web part to the target page
Add-PnPWebPartToWebPartPage -ServerRelativePageUrl "/sites/236-Telefonica/SitePages/$PageName" -Xml $xml -ZoneId $ZoneId -ZoneIndex $ZoneIndex

Write-Host "Se ha añadido la biblioteca de documentos '$DocumentLibraryName' a la página '$PageName' en la sección '$SectionTitle'." -ForegroundColor Green