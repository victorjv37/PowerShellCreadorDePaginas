begin {
    try {
        Connect-PnPOnline "https://tejiendored.sharepoint.com/sites/test2" -Interactive
    }
    catch {
        Write-Host "Error connecting to SharePoint site. Please check the Tenant and Site parameters." -ForegroundColor Red
        exit
    }

    # Page parameters
    $pageParams = @{
        Name             = "EJEMPLOCSRIPT.aspx"
        Title            = "Baking up a page"
        HeaderLayoutType = "ColorBlock"
    }

    try {
        $user = Get-PnPUser -Identity (Get-PnPUser -Identity "i:0#.f|membership|your.user@domain.com")
        if ($user -ne $null) {
            Write-Host "User has permissions to access the site." -ForegroundColor Green
        }
        else {
            Write-Host "User does not have permissions to access the site." -ForegroundColor Red
            exit
        }
    }
    catch {
        Write-Host "Error checking user permissions: $_" -ForegroundColor Red
        exit
    }
}


process {
    if ($CleanExistingPage) {
        try {
            Write-Host "Removing existing page..." -ForegroundColor Yellow
            Remove-PnPPage -Identity $pageParams.Name -Force -ErrorAction Stop
        }
        catch {
            Write-Host "Error removing existing page: $_" -ForegroundColor Red
        }
    }

    try {
        Write-Host "Adding new page..." -ForegroundColor Green
        $newPage = Add-PnPPage @pageParams -ErrorAction Stop
        Write-Host "Page added successfully: $($newPage.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "Error adding new page: $_" -ForegroundColor Red
        exit
    }


    # Set the header, topic, image, and person
    Write-Host "Setting the header, topic, image"
    
    $newPage.PageHeader.ImageServerRelativeUrl = "https://cdn.hubblecontent.osi.office.net/m365content/publish/3c506e10-e846-4698-a041-f133fc505b7b/1140201187.jpg"
    $newPage.PageHeader.TopicHeader = "Example"

    $newPage.Save()
    $newPage = Get-PnPPage $pageParams.Name

    Write-Host "Row 1 - Setting the section and web parts"
    $newPage | Add-PnPPageSection -SectionTemplate TwoColumnLeft -Order 1

    $textPart1 = @"
<h2>Welcome to the Page Bakery 😊</h2>
<p>Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas porttitor congue massa. Fusce posuere, magna sed pulvinar ultricies, purus lectus malesuada libero, sit amet commodo magna eros quis urna.</p>
<p><em>Nunc viverra imperdiet enim. Fusce est. Vivamus a tellus. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Proin pharetra nonummy pede. Mauris et orci. Aenean nec lorem. In porttitor. Donec laoreet nonummy augue.​​​​​​​</em></p>
"@

    $newPage | Add-PnPPageTextPart -Order 1 -Column 1 -Section 1 -Text $textPart1

    $propsBreadImg = '{"title": "Image", "description": "Image", "dataVersion": "1.8", "properties": {"imageSourceType":2,"altText":"","overlayText":"","imgWidth":5616,"imgHeight":3744,"fixAspectRatio":false}, "serverProcessedContent": {"searchablePlainTexts":{"captionText":"Baking a lovely page"},"imageSources":{"imageSource":"https://cdn.hubblecontent.osi.office.net/m365content/publish/005eb6ca-fe86-4433-921c-126cb23c7adb/576678384.jpg"},"links":{}}}'

    $newPage | Add-PnPPageWebPart -Order 1 -Column 2 -Section 1 -DefaultWebPartType Image -WebPartProperties $propsBreadImg

    Write-Host "Row 2 - Setting the section and web parts"
    $newPage | Add-PnPPageSection -SectionTemplate TwoColumnRight -Order 2 -ZoneEmphasis 2

    $propsBookImg = '{"title": "Image", "description": "Image", "dataVersion": "1.8", "properties": {"imageSourceType":2,"altText":"","overlayText":"","imgWidth":5616,"imgHeight":3744,"fixAspectRatio":false}, "serverProcessedContent": {"searchablePlainTexts":{"captionText":"Showing pages some love"},"imageSources":{"imageSource":"https://cdn.hubblecontent.osi.office.net/m365content/publish/0d3ff8a6-8854-4a6a-aee1-b1c7d04bb857/691081033.jpg"},"links":{}}}'

    $newPage | Add-PnPPageWebPart -Order 1 -Column 1 -Section 2 -DefaultWebPartType Image -WebPartProperties $propsBookImg

    $textPart2 = @"
<h2>How you can improve your pages?</h2>
<p>Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas porttitor congue massa. Fusce posuere, magna sed pulvinar ultricies, purus lectus malesuada libero, sit amet commodo magna eros quis urna.</p>
<p><strong><em>Nunc viverra imperdiet enim. Fusce est. Vivamus a tellus. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Proin pharetra nonummy pede. Mauris et orci. Aenean nec lorem. In porttitor. Donec laoreet nonummy augue.​​​​​​​<strong></em></p>
"@

    $newPage | Add-PnPPageTextPart -Order 1 -Column 2 -Section 2 -Text $textPart2

    Write-Host "Row 3 - Setting the section and web parts"
    $newPage | Add-PnPPageSection -SectionTemplate OneColumn -Order 3 -ZoneEmphasis 3

    $propsLinksWebPart = @"
    {
        "title": "Quick links",
        "description": "Show a collection of links to content such as documents, images, videos, and more in a variety of layouts with options for icons, images, and audience targeting.",
        "serverProcessedContent": {
          "searchablePlainTexts": {
            "title": "Interesting resources",
            "items[0].title": "How to make a page",
            "items[1].title": "Bringing pages into modern",
            "items[2].title": "Accessibility Considerations in Pages",
            "items[3].title": "Showing your page some love with images"
          },
          "links": {
            "baseUrl": "/sites/Intranet",
            "items[0].sourceItem.url": "/sites/Intranet/SitePages/Homepage-Example.aspx",
            "items[1].sourceItem.url": "/sites/Intranet/SitePages/Homepage-Example.aspx",
            "items[2].sourceItem.url": "/sites/Intranet/SitePages/Homepage-Example.aspx",
            "items[3].sourceItem.url": "/sites/Intranet/SitePages/Homepage-Example.aspx"
          }
        },
        "dataVersion": "2.2",
        "properties": {
          "items": [
            {
              "thumbnailType": 2,
              "id": 4,
              "description": "",
              "fabricReactIcon": { "iconName": "glimmer"},
              "altText": "",
              "rawPreviewImageMinCanvasWidth": 32767
            },
            {
              "thumbnailType": 2,
              "id": 3,
              "description": "",
              "fabricReactIcon": { "iconName": "webappbuilderfragment" },
              "altText": "",
              "rawPreviewImageMinCanvasWidth": 32767
            },
            {
              "thumbnailType": 2,
              "id": 2,
              "description": "",
              "fabricReactIcon": { "iconName": "group" },
              "altText": "",
              "rawPreviewImageMinCanvasWidth": 32767
            },
            {
              "thumbnailType": 2,
              "id": 1,
              "description": "",
              "fabricReactIcon": { "iconName": "heartfill" },
              "altText": "",
              "rawPreviewImageMinCanvasWidth": 32767
            }
          ],
          "isMigrated": true,
          "layoutId": "CompactCard",
          "shouldShowThumbnail": true,
          "imageWidth": 100,
          "buttonLayoutOptions": {
            "showDescription": false,
            "buttonTreatment": 2,
            "iconPositionType": 2,
            "textAlignmentVertical": 2,
            "textAlignmentHorizontal": 2,
            "linesOfText": 2
          },
          "listLayoutOptions": { "showDescription": false, "showIcon": true },
          "waffleLayoutOptions": { "iconSize": 1, "onlyShowThumbnail": false },
          "hideWebPartWhenEmpty": true,
          "dataProviderId": "QuickLinks",
          "iconPicker": "glimmer"
        }
      }
"@

    $newPage | Add-PnPPageWebPart -Order 1 -Column 1 -Section 3 -DefaultWebPartType QuickLinks -WebPartProperties $propsLinksWebPart

    Write-Host "Publishing Page and promote Page as News..."
    $newPage | Set-PnPPage -PromoteAs NewsArticle -Publish
}
end {
    Write-Host "Done! :)" -ForegroundColor Green
}