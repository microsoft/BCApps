Provides functions to interact with SharePoint.

Two clients are available:
- **SharePoint Client** - Legacy REST API v1
- **SharePoint Graph Client** - Modern Microsoft Graph API

---

# SharePoint Graph Client

Modern implementation using Microsoft Graph API. Provides simpler authentication, cleaner interfaces, and better performance.

## Authorization

Use Graph Authorization from the Graph module:

```al
var
    GraphAuth: Codeunit "Graph Authorization";
    GraphAuthorization: Interface "Graph Authorization";
begin
    GraphAuthorization := GraphAuth.CreateAuthorizationWithClientCredentials(
        '<MicrosoftEntraTenantId>', '<ClientId>', '<ClientSecret>',
        'https://graph.microsoft.com/.default');
```

## Initialize Client

```al
var
    SPGraphClient: Codeunit "SharePoint Graph Client";
begin
    SPGraphClient.Initialize('https://contoso.sharepoint.com/sites/MySite/', GraphAuthorization);
```

## Working with Lists

```al
var
    GraphList: Record "SharePoint Graph List" temporary;
    Response: Codeunit "SharePoint Graph Response";
begin
    // Get all lists
    Response := SPGraphClient.GetLists(GraphList);

    // Create a new list
    Response := SPGraphClient.CreateList('My List', 'Description', GraphList);
```

## Working with List Items

```al
var
    GraphListItem: Record "SharePoint Graph List Item" temporary;
begin
    // Get items from a list
    Response := SPGraphClient.GetListItems('<ListId>', GraphListItem);

    // Create a new item
    Response := SPGraphClient.CreateListItem('<ListId>', 'Item Title', GraphListItem);
```

## Working with Drives and Files

```al
var
    GraphDriveItem: Record "SharePoint Graph Drive Item" temporary;
    TempBlob: Codeunit "Temp Blob";
    FileInStream: InStream;
    Response: Codeunit "SharePoint Graph Response";
begin
    // Get root folder items
    Response := SPGraphClient.GetRootItems(GraphDriveItem);
    if not Response.IsSuccessful() then
        Error(Response.GetError());

    // Filter to files only and download first one
    GraphDriveItem.SetRange(IsFolder, false);
    if GraphDriveItem.FindFirst() then
        Response := SPGraphClient.DownloadFile(GraphDriveItem.Id, TempBlob);

    // Get items by path
    Response := SPGraphClient.GetItemsByPath('Documents/Folder1', GraphDriveItem);

    // Upload a file (empty path = root folder)
    Response := SPGraphClient.UploadFile('', 'file.pdf', FileInStream, GraphDriveItem);

    // Create a folder
    Response := SPGraphClient.CreateFolder('Documents', 'NewFolder', GraphDriveItem);
```

## Large File Operations

For files over 4MB, use chunked upload/download:

```al
begin
    // Upload large file (uses resumable upload session)
    Response := SPGraphClient.UploadLargeFile('Documents', 'largefile.zip', FileInStream, GraphDriveItem);

    // Download large file (uses 100MB chunks)
    Response := SPGraphClient.DownloadLargeFile('<ItemId>', TempBlob);
```

## Item Management

```al
var
    Exists: Boolean;
    Response: Codeunit "SharePoint Graph Response";
begin
    // Check if item exists
    Response := SPGraphClient.ItemExistsByPath('Documents/file.pdf', Exists);

    // Delete item
    Response := SPGraphClient.DeleteItemByPath('Documents/file.pdf');

    // Copy item (asynchronous operation)
    Response := SPGraphClient.CopyItemByPath('Documents/file.pdf', 'Archive', 'file_copy.pdf');

    // Move/rename item
    Response := SPGraphClient.MoveItemByPath('Documents/file.pdf', 'Archive', '');
```

## OData Query Parameters

```al
var
    OptionalParams: Codeunit "Graph Optional Parameters";
begin
    // Filter items
    SPGraphClient.SetODataFilter(OptionalParams, 'name eq ''document.docx''');

    // Select specific fields
    SPGraphClient.SetODataSelect(OptionalParams, 'id,name,size');

    // Order results
    SPGraphClient.SetODataOrderBy(OptionalParams, 'name asc');

    Response := SPGraphClient.GetRootItems(GraphDriveItem, OptionalParams);
```

## Error Handling

All methods return `SharePoint Graph Response` codeunit:

```al
var
    Response: Codeunit "SharePoint Graph Response";
begin
    Response := SPGraphClient.GetLists(GraphList);
    if not Response.IsSuccessful() then
        Error(Response.GetError());
```

---

# SharePoint Client (Legacy REST API)

Legacy implementation using SharePoint REST API v1.

## Authorization

Use "SharePoint Authorization module".

## Example
```
    var
        SharePointAuth: Codeunit "SharePoint Auth.";
        SharePointAuthorization: Interface "SharePoint Authorization";
    begin
        SharePointAuthorization := SharePointAuth.CreateAuthorizationCode('<MicrosoftEntraTenantId>', '<ClientId>', '<ClientSecret>', '<Scope>');
```

# SharePoint API

## Initialize client
Prepare client.
> provide SharePoint site/subsite address i.e. '<myaddres>.sharepoint.com/sites/Test/'.

> Authorization Codeunit.

## Example
```
    var
        SPClient: Codeunit "SharePoint Client";
    begin        
        SPClient.Initialize('<BaseUrl>', SharePointAuthorization);
```

## Working with lists
### Retrieve all lists available on the site
Returns temporary table containing all available lists.
```
    var
        SharePointList: Record "SharePoint List" temporary;
    begin
        SPClient.GetLists(SharePointList);
```
### Create a new list
Returns single temporary record with information on created list.
```
    var
        SharePointList: Record "SharePoint List" temporary;
    begin
        SPClient.CreateList('List Title', 'List Description', SharePointList);
```

## Working with list items
### Retrieve list items for given list (by list title)
Returns temporary table containing list items.
```
    var
        SharePointList: Record "SharePoint List" temporary;
        SharePointListItem: Record "SharePoint List Item" temporary;
    begin
        SPClient.GetListItems(SharePointList.Title, SharePointListItem);
```

### Retrieve list items for given list (by list id)
Returns temporary table containing list items.
```
    var
        SharePointList: Record "SharePoint List" temporary;
        SharePointListItem: Record "SharePoint List Item" temporary;
    begin
        SPClient.GetListItems(SharePointList.Id, SharePointListItem);
```

### Create list item for given list (by list title)
Returns single temporary record with information on created list item.
```
    var
        SharePointList: Record "SharePoint List" temporary;
        SharePointListItem: Record "SharePoint List Item" temporary;
    begin
        SPClient.CreateListItem(SharePointList.Title, SharePointList."List Item Entity Type", '<ListItemName>', SharePointListItem);
```

### Create list item for given list (by list id)
Returns single temporary record with information on created list item.
```
    var
        SharePointList: Record "SharePoint List" temporary;
        SharePointListItem: Record "SharePoint List Item" temporary;
    begin
        SPClient.CreateListItem(SharePointList.Id, SharePointList."List Item Entity Type", '<ListItemName>', SharePointListItem);
```

## Working with list item attachments

### Retrieve attachments for given list item
Returns temporary table containing attachment data.
Procedure using list title instead of list id is also available, list title is not available directly in "SharePoint List Item" table.
```
    var
        SharePointListItemAttachment: Record "SharePoint List Item Atch" temporary;
        SharePointListItem: Record "SharePoint List Item" temporary;
    begin
        SPClient.GetListItemAttachments(SharePointListItem."List Id", SharePointListItem.Id, SharePointListItemAttachment);
```

### Upload an attachment 
Returns single temporary record with information on created list item attachment.
Procedure using list title instead of list id is also available, list title is not available directly in "SharePoint List Item" table.
File upload dialog will pop up.
```
    var
        SharePointListItemAttachment: Record "SharePoint List Item Atch" temporary;
        SharePointListItem: Record "SharePoint List Item" temporary;
    begin   
        SPClient.CreateListItemAttachment(SharePointListItem."List Id", SharePointListItem.Id, SharePointListItemAttachment);
```

### Upload an attachment (no UI)
Returns single temporary record with information on created list item attachment.
Procedure using list title instead of list id is also available, list title is not available directly in "SharePoint List Item" table.
```
    var
        SharePointListItemAttachment: Record "SharePoint List Item Atch" temporary;
        SharePointListItem: Record "SharePoint List Item" temporary;
        FileInStream: InStream;
    begin   
        SPClient.CreateListItemAttachment(SharePointListItem."List Id", SharePointListItem.Id, '<FileName>', InStream, SharePointListItemAttachment);
```
### Download attachment
Downloads attachment to the client.
Procedure using list title instead of list id is also available, list title is not available directly in "SharePoint List Item Attachment" table.
Procedure using OdataId instead of list name/is is also available.
```
    var
        SharePointListItemAttachment: Record "SharePoint List Item Atch" temporary;
    begin
        SPClient.DownloadListItemAttachmentContent(SharePointListItemAttachment."List Id", SharePointListItemAttachment."List Item Id", SharePointListItemAttachment."File Name");    
```

## Working with folders

### Get Root Folder for a list
Returns single record with root folder data.
```
    var
        SharePointList: Record "SharePoint List" temporary;
        SharePointFolder: Record "SharePoint Folder" temporary;
    begin
        SPClient.GetDocumentLibraryRootFolder(SharePointList.OdataId, SharePointFolder);
```

### Get sub folders for given folder
Returns temporary table with all sub folders for the given folder.
```
    var
        ParentSharePointFolder, SharePointFolder: Record "SharePoint Folder";
    begin
        SPClient.GetSubFoldersByServerRelativeUrl(ParentSharePointFolder."Server Relative Url", SharePointFolder);
```

### Create sub folders in the given folders
Returns temporary table with the created sub folder data.
```
    var
        ParentSharePointFolder, SharePointFolder: Record "SharePoint Folder";
    begin
        SPClient.CreateFolder(ParentSharePointFolder."Server Relative Url" + '/<SubFolderName>', SharePointFolder);
```

## Working with files

### Get files in folder
Returns temporary table with data of all files for in the given folder.
```
    var
        SharePointFolder: Record "SharePoint Folder";
        SharePointFile: Record "SharePoint File";
    begin
        SPClient.GetFolderFilesByServerRelativeUrl(SharePointFolder."Server Relative Url", SharePointFile);
```

### Upload file to folder
Returns single temporary record with data of created file.
File selection dialog will pop up.
```
    var
        SharePointFolder: Record "SharePoint Folder";
        SharePointFile: Record "SharePoint File";
    begin
        SPClient.AddFileToFolder(SharePointFolder."Server Relative Url", SharePointFile);
```

### Upload file to folder (no UI)
Returns single temporary record with data of created file.
```
    var
        SharePointFolder: Record "SharePoint Folder";
        SharePointFile: Record "SharePoint File";
        FileInStream: InStream;
    begin
        SPClient.AddFileToFolder(SharePointFolder."Server Relative Url", '<FileName>', FileInStream, SharePointFile);
```

### Download file
Downloads specified file to the client.
```
    var
        SharePointFile: Record "SharePoint File";
    begin
        SPClient.DownloadFileContent(SharePointFile.OdataId, SharePointFile.Name); 
```

### Update Metadata for a list item (including a file)
Updates specific metadata field for list item.
In order to update metadata of a file it needs to be accessed as list item.
```
    var
        SharePointFile: Record "SharePoint File";
    begin
        SharePointClient.UpdateListItemMetaDataField('Maintenance', 10, 'SP.Data.MaintenanceItem', 'WorkOrderNo', 'TEST0001'); 
```

## Error handling

### Retrieve diagnostic information
Diagnostics Codeunit contains details on last api call including:
> IsSuccessStatusCode.

> HttpStatusCode.

> Retry-After header value in case request has been throttled.

> ErrorMessage.

> ResponseReasonPhrase.

```
    var
        SharePointList: Record "SharePoint List" temporary;
        SharePointFolder: Record "SharePoint Folder" temporary;
        SharePointDiagnostics: Codeunit "SharePoint  Diagnostics";
    begin
        if not SPClient.GetDocumentLibraryRootFolder(SharePointList.OdataId, SharePointFolder) then
            SharePointDiagnostics := SpClient.GetDiagnostics();        
```
