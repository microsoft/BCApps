// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration.Sharepoint;

using System.Integration.Graph;
using System.Integration.Sharepoint;
using System.RestClient;
using System.TestLibraries.Utilities;

codeunit 132984 "SharePoint Graph Client Test"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SharePointGraphAuthMock: Codeunit "SharePoint Graph Auth Mock";
        SharePointGraphTestLibrary: Codeunit "SharePoint Graph Test Library";
        SharePointGraphClient: Codeunit "SharePoint Graph Client";
        LibraryAssert: Codeunit "Library Assert";
        SharePointUrlLbl: Label 'https://contoso.sharepoint.com/sites/test', Locked = true;
        IsInitialized: Boolean;

    [Test]
    procedure TestAuthorizationInvoked()
    var
        TempList: Record "SharePoint Graph List" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
    begin
        // [GIVEN] Mock response for an API call
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetListsResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Initialize the client and make an API call
        SharePointGraphClient.GetLists(TempList);

        // [THEN] Authorization should be invoked
        LibraryAssert.IsTrue(SharePointGraphAuthMock.IsInvoked(), 'Authorization should be invoked');
    end;

    [Test]
    procedure TestRequestUriFormat()
    var
        TempList: Record "SharePoint Graph List" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        HttpRequestMessage: Codeunit "Http Request Message";
    begin
        // [GIVEN] Mock response for an API call
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetListsResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Initialize the client and make an API call
        SharePointGraphClient.GetLists(TempList);

        // [THEN] Request URI should be correct
        SharePointGraphTestLibrary.GetHttpRequestMessage(HttpRequestMessage);
        LibraryAssert.IsTrue(HttpRequestMessage.GetRequestUri().Contains('https://graph.microsoft.com/v1.0/sites/'), 'Request URI should contain the correct endpoint');
    end;

    [Test]
    procedure TestGetLists()
    var
        TempList: Record "SharePoint Graph List" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for GetLists
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetListsResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetLists
        SharePointGraphResponse := SharePointGraphClient.GetLists(TempList);

        // [THEN] Operation should succeed and return correct data
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetLists should succeed');
        LibraryAssert.AreEqual(2, TempList.Count(), 'Should return 2 lists');

        TempList.FindFirst();
        LibraryAssert.AreEqual('Test Documents', TempList.DisplayName, 'DisplayName should match');
        LibraryAssert.AreEqual('Test library for documents', TempList.Description, 'Description should match');

        TempList.FindLast();
        LibraryAssert.AreEqual('HR Documents', TempList.DisplayName, 'DisplayName should match');
    end;

    [Test]
    procedure TestCreateList()
    var
        TempList: Record "SharePoint Graph List" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for CreateList
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(201);
        MockHttpContent := HttpContent.Create(GetCreateListResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling CreateList
        SharePointGraphResponse := SharePointGraphClient.CreateList('New Test List', 'Created for testing', TempList);

        // [THEN] Operation should succeed and return correct data
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'CreateList should succeed');
        LibraryAssert.AreEqual('New Test List', TempList.DisplayName, 'DisplayName should match');
        LibraryAssert.AreEqual('Created for testing', TempList.Description, 'Description should match');
        LibraryAssert.AreEqual('01bjtwww-5j35-426b-a4d5-608f6e2a9f84', TempList.Id, 'Id should match');
    end;

    [Test]
    procedure TestGetListItems()
    var
        TempListItem: Record "SharePoint Graph List Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for GetListItems
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetListItemsResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetListItems
        SharePointGraphResponse := SharePointGraphClient.GetListItems('01bjtwww-5j35-426b-a4d5-608f6e2a9f84', TempListItem);

        // [THEN] Operation should succeed and return correct data
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetListItems should succeed');
        LibraryAssert.AreEqual(2, TempListItem.Count(), 'Should return 2 list items');

        TempListItem.FindFirst();
        LibraryAssert.AreEqual('Test Item 1', TempListItem.Title, 'Title should match');

        TempListItem.FindLast();
        LibraryAssert.AreEqual('Test Item 2', TempListItem.Title, 'Title should match');
    end;

    [Test]
    procedure TestCreateListItem()
    var
        TempListItem: Record "SharePoint Graph List Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        FieldsJson: JsonObject;
    begin
        // [GIVEN] Mock response for CreateListItem
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(201);
        MockHttpContent := HttpContent.Create(GetCreateListItemResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling CreateListItem
        FieldsJson.Add('Title', 'New Test Item');
        SharePointGraphResponse := SharePointGraphClient.CreateListItem('01bjtwww-5j35-426b-a4d5-608f6e2a9f84', FieldsJson, TempListItem);

        // [THEN] Operation should succeed and return correct data
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'CreateListItem should succeed');
        LibraryAssert.AreEqual('New Test Item', TempListItem.Title, 'Title should match');
        LibraryAssert.AreEqual('3', TempListItem.Id, 'Id should match');
    end;

    [Test]
    procedure TestGetDrives()
    var
        TempDrive: Record "SharePoint Graph Drive" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for GetDrives
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDrivesResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetDrives
        SharePointGraphResponse := SharePointGraphClient.GetDrives(TempDrive);

        // [THEN] Operation should succeed and return correct data
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetDrives should succeed');
        LibraryAssert.AreEqual(2, TempDrive.Count(), 'Should return 2 drives');

        TempDrive.FindFirst();
        LibraryAssert.AreEqual('Documents', TempDrive.Name, 'Name should match');
        LibraryAssert.AreEqual('b!mR2-5tV1S-RO3C82s1DNbdCrWBwFQKFUoOB6bTlXClvD9fcjLXO5TbNk5sDyD7c8', TempDrive.Id, 'Id should match');

        TempDrive.FindLast();
        LibraryAssert.AreEqual('HR Files', TempDrive.Name, 'Name should match');
    end;

    [Test]
    procedure TestGetRootItems()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for GetRootItems
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveItemsResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetRootItems
        SharePointGraphResponse := SharePointGraphClient.GetRootItems(TempDriveItem);

        // [THEN] Operation should succeed and return correct data
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetRootItems should succeed');
        LibraryAssert.AreEqual(2, TempDriveItem.Count(), 'Should return 2 items');

        TempDriveItem.FindFirst();
        LibraryAssert.AreEqual('Folder 1', TempDriveItem.Name, 'Name should match');
        LibraryAssert.IsTrue(TempDriveItem.IsFolder, 'Should be a folder');

        TempDriveItem.FindLast();
        LibraryAssert.AreEqual('Document.docx', TempDriveItem.Name, 'Name should match');
        LibraryAssert.IsFalse(TempDriveItem.IsFolder, 'Should be a file');
    end;

    [Test]
    procedure TestCreateFolder()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for CreateFolder
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(201);
        MockHttpContent := HttpContent.Create(GetCreateFolderResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling CreateFolder
        SharePointGraphResponse := SharePointGraphClient.CreateFolder('Documents', 'New Folder', TempDriveItem);

        // [THEN] Operation should succeed and return correct data
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'CreateFolder should succeed');
        LibraryAssert.AreEqual('New Folder', TempDriveItem.Name, 'Name should match');
        LibraryAssert.IsTrue(TempDriveItem.IsFolder, 'Should be a folder');
        LibraryAssert.AreEqual('01EZJNRYOELVX64AZW4BC2WGFBGY2D2MAE', TempDriveItem.Id, 'Id should match');
    end;

    [Test]
    procedure TestCreateFolderToSpecificDrive()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for CreateFolder to specific drive
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(201);
        MockHttpContent := HttpContent.Create(GetCreateFolderResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling CreateFolder to a specific drive
        SharePointGraphResponse := SharePointGraphClient.CreateFolder('b!specificDriveId123', 'Documents', 'New Folder', TempDriveItem);

        // [THEN] Operation should succeed
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'CreateFolder to specific drive should succeed');
        LibraryAssert.AreEqual('New Folder', TempDriveItem.Name, 'Name should match');
    end;

    [Test]
    procedure TestCreateListItemWithTitle()
    var
        TempListItem: Record "SharePoint Graph List Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for CreateListItem with title
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(201);
        MockHttpContent := HttpContent.Create(GetCreateListItemResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling CreateListItem with simple title
        SharePointGraphResponse := SharePointGraphClient.CreateListItem('01bjtwww-5j35-426b-a4d5-608f6e2a9f84', 'New Test Item', TempListItem);

        // [THEN] Operation should succeed and return correct data
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'CreateListItem with title should succeed');
        LibraryAssert.AreEqual('New Test Item', TempListItem.Title, 'Title should match');
    end;

    [Test]
    procedure TestErrorResponse()
    var
        TempList: Record "SharePoint Graph List" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        SharePointHttpDiagnostics: Interface "HTTP Diagnostics";
    begin
        // [GIVEN] Mock error response
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(401);
        MockHttpContent := HttpContent.Create(GetErrorResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        MockHttpResponseMessage.SetReasonPhrase('Unauthorized');
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling API
        SharePointGraphResponse := SharePointGraphClient.GetLists(TempList);

        // [THEN] Operation should fail and return correct error info
        LibraryAssert.IsFalse(SharePointGraphResponse.IsSuccessful(), 'GetLists should fail');
        SharePointHttpDiagnostics := SharePointGraphClient.GetDiagnostics();
        LibraryAssert.AreEqual(401, SharePointHttpDiagnostics.GetHttpStatusCode(), 'Status code should match');
        LibraryAssert.AreEqual('Unauthorized', SharePointHttpDiagnostics.GetResponseReasonPhrase(), 'Reason phrase should match');
    end;

    [Test]
    procedure TestValidSharePointUrl()
    var
        MockHttpClientHandler: Interface "Http Client Handler";
    begin
        // [GIVEN] A valid SharePoint URL with site path
        MockHttpClientHandler := SharePointGraphTestLibrary.GetMockHandler();

        // [WHEN] Initializing with a valid SharePoint URL
        // [THEN] No error should occur
        SharePointGraphClient.Initialize('https://contoso.sharepoint.com/sites/test', Enum::"Graph API Version"::"v1.0", SharePointGraphAuthMock, MockHttpClientHandler);
    end;

    [Test]
    procedure TestValidSharePointUrlWithoutPath()
    var
        MockHttpClientHandler: Interface "Http Client Handler";
    begin
        // [GIVEN] A valid SharePoint URL without a path
        MockHttpClientHandler := SharePointGraphTestLibrary.GetMockHandler();

        // [WHEN] Initializing with a valid SharePoint URL without path
        // [THEN] No error should occur
        SharePointGraphClient.Initialize('https://contoso.sharepoint.com', Enum::"Graph API Version"::"v1.0", SharePointGraphAuthMock, MockHttpClientHandler);
    end;

    [Test]
    procedure TestInvalidUrlNonSharePointDomain()
    var
        MockHttpClientHandler: Interface "Http Client Handler";
    begin
        // [GIVEN] A non-SharePoint URL
        MockHttpClientHandler := SharePointGraphTestLibrary.GetMockHandler();

        // [WHEN] Initializing with a non-SharePoint URL
        // [THEN] An error should occur
        asserterror SharePointGraphClient.Initialize('https://evil-site.com/sites/test', Enum::"Graph API Version"::"v1.0", SharePointGraphAuthMock, MockHttpClientHandler);
        LibraryAssert.ExpectedError('Invalid SharePoint URL');
    end;

    [Test]
    procedure TestInvalidUrlHttpNotHttps()
    var
        MockHttpClientHandler: Interface "Http Client Handler";
    begin
        // [GIVEN] A SharePoint URL using HTTP instead of HTTPS
        MockHttpClientHandler := SharePointGraphTestLibrary.GetMockHandler();

        // [WHEN] Initializing with an HTTP URL
        // [THEN] An error should occur because only HTTPS is allowed
        asserterror SharePointGraphClient.Initialize('http://contoso.sharepoint.com/sites/test', Enum::"Graph API Version"::"v1.0", SharePointGraphAuthMock, MockHttpClientHandler);
        LibraryAssert.ExpectedError('Invalid SharePoint URL');
    end;

    [Test]
    procedure TestInvalidUrlSharePointSubdomain()
    var
        MockHttpClientHandler: Interface "Http Client Handler";
    begin
        // [GIVEN] A URL that includes sharepoint.com as a subdomain of another domain
        MockHttpClientHandler := SharePointGraphTestLibrary.GetMockHandler();

        // [WHEN] Initializing with a spoofed SharePoint URL
        // [THEN] An error should occur
        asserterror SharePointGraphClient.Initialize('https://contoso.sharepoint.com.evil.com/sites/test', Enum::"Graph API Version"::"v1.0", SharePointGraphAuthMock, MockHttpClientHandler);
        LibraryAssert.ExpectedError('Invalid SharePoint URL');
    end;

    [Test]
    procedure TestInvalidUrlNoTenantSubdomain()
    var
        MockHttpClientHandler: Interface "Http Client Handler";
    begin
        // [GIVEN] A SharePoint URL without a tenant subdomain
        MockHttpClientHandler := SharePointGraphTestLibrary.GetMockHandler();

        // [WHEN] Initializing with sharepoint.com directly (no tenant prefix)
        // [THEN] An error should occur
        asserterror SharePointGraphClient.Initialize('https://sharepoint.com/sites/test', Enum::"Graph API Version"::"v1.0", SharePointGraphAuthMock, MockHttpClientHandler);
        LibraryAssert.ExpectedError('Invalid SharePoint URL');
    end;

    [Test]
    procedure TestInvalidUrlEmptyString()
    var
        MockHttpClientHandler: Interface "Http Client Handler";
    begin
        // [GIVEN] An empty URL
        MockHttpClientHandler := SharePointGraphTestLibrary.GetMockHandler();

        // [WHEN] Initializing with an empty URL
        // [THEN] An error should occur
        asserterror SharePointGraphClient.Initialize('', Enum::"Graph API Version"::"v1.0", SharePointGraphAuthMock, MockHttpClientHandler);
        LibraryAssert.ExpectedError('Invalid SharePoint URL');
    end;

    [Test]
    procedure TestItemIdWithPathTraversalIsEncoded()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        HttpRequestMessage: Codeunit "Http Request Message";
        RequestUri: Text;
    begin
        // [GIVEN] Mock response and an item ID containing path traversal characters
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveItemResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetDriveItem with a malicious ID containing ../
        SharePointGraphClient.GetDriveItem('../sensitive-data', TempDriveItem);

        // [THEN] The forward slash in the ID should be percent-encoded to prevent path traversal
        SharePointGraphTestLibrary.GetHttpRequestMessage(HttpRequestMessage);
        RequestUri := HttpRequestMessage.GetRequestUri();
        LibraryAssert.IsTrue(RequestUri.Contains('..%2Fsensitive-data'), 'Forward slash in item ID should be encoded as %2F');
        LibraryAssert.IsFalse(RequestUri.Contains('/items/../'), 'Path traversal should not be present in the URL');
    end;

    [Test]
    procedure TestPathWithSpecialCharsIsEncoded()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        HttpRequestMessage: Codeunit "Http Request Message";
        RequestUri: Text;
    begin
        // [GIVEN] Mock response and a path with special characters
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveItemResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetDriveItemByPath with a path containing # and spaces
        SharePointGraphClient.GetDriveItemByPath('Documents/Report #1.docx', TempDriveItem);

        // [THEN] Special characters should be encoded but path separators preserved
        SharePointGraphTestLibrary.GetHttpRequestMessage(HttpRequestMessage);
        RequestUri := HttpRequestMessage.GetRequestUri();
        LibraryAssert.IsTrue(RequestUri.Contains('%23'), 'Hash character should be percent-encoded');
        LibraryAssert.IsTrue(RequestUri.Contains('%20'), 'Space character should be percent-encoded');
        LibraryAssert.IsTrue(RequestUri.Contains('Documents/Report'), 'Path separator between segments should be preserved');
    end;

    local procedure Initialize()
    var
        MockHttpClientHandler: Interface "Http Client Handler";
    begin
        if IsInitialized then
            exit;

        // Get the mock handler from the test library
        MockHttpClientHandler := SharePointGraphTestLibrary.GetMockHandler();

        // Initialize with the mock handler
        SharePointGraphClient.Initialize(SharePointUrlLbl, Enum::"Graph API Version"::"v1.0", SharePointGraphAuthMock, MockHttpClientHandler);

        // Set test IDs to prevent HTTP calls for site and drive discovery
        SharePointGraphClient.SetSiteIdForTesting('contoso.sharepoint.com,e6991d99-75d5-4be4-4ede-2c82b1d40cd6,1b58abad-4105-4125-a0e0-7a6d39571a5b');
        SharePointGraphClient.SetDefaultDriveIdForTesting('b!mR2-5tV1S-RO3C82s1DNbdCrWBwFQKFUoOB6bTlXClvD9fcjLXO5TbNk5sDyD7c8');

        IsInitialized := true;
    end;

    local procedure GetListsResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#Collection(microsoft.graph.list)",');
        ResponseText.Append('  "value": [');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "01bjtwww-5j35-426b-a4d5-608f6e2a9f84",');
        ResponseText.Append('      "displayName": "Test Documents",');
        ResponseText.Append('      "description": "Test library for documents",');
        ResponseText.Append('      "list": {');
        ResponseText.Append('        "template": "documentLibrary",');
        ResponseText.Append('        "hidden": false,');
        ResponseText.Append('        "contentTypesEnabled": true');
        ResponseText.Append('      },');
        ResponseText.Append('      "createdDateTime": "2022-05-23T12:16:04Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents"');
        ResponseText.Append('    },');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "27c78f81-f4d9-4ee9-85bd-5d57ade1b5f4",');
        ResponseText.Append('      "displayName": "HR Documents",');
        ResponseText.Append('      "description": "HR library for documents",');
        ResponseText.Append('      "list": {');
        ResponseText.Append('        "template": "documentLibrary",');
        ResponseText.Append('        "hidden": false,');
        ResponseText.Append('        "contentTypesEnabled": true');
        ResponseText.Append('      },');
        ResponseText.Append('      "createdDateTime": "2022-05-23T12:16:04Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/HR%20Documents"');
        ResponseText.Append('    }');
        ResponseText.Append('  ]');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetCreateListResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#sites(''root'')/lists/$entity",');
        ResponseText.Append('  "id": "01bjtwww-5j35-426b-a4d5-608f6e2a9f84",');
        ResponseText.Append('  "displayName": "New Test List",');
        ResponseText.Append('  "description": "Created for testing",');
        ResponseText.Append('  "list": {');
        ResponseText.Append('    "template": "genericList",');
        ResponseText.Append('    "hidden": false,');
        ResponseText.Append('    "contentTypesEnabled": true');
        ResponseText.Append('  },');
        ResponseText.Append('  "createdDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('  "lastModifiedDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('  "webUrl": "https://contoso.sharepoint.com/sites/test/Lists/New%20Test%20List"');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetListItemsResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#sites(''root'')/lists(''01bjtwww-5j35-426b-a4d5-608f6e2a9f84'')/items",');
        ResponseText.Append('  "value": [');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "1",');
        ResponseText.Append('      "createdDateTime": "2023-05-15T08:12:39Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-06-20T14:45:12Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/Lists/Test%20List/1_.000",');
        ResponseText.Append('      "fields": {');
        ResponseText.Append('        "Title": "Test Item 1",');
        ResponseText.Append('        "Description": "This is a test item",');
        ResponseText.Append('        "Priority": "High"');
        ResponseText.Append('      }');
        ResponseText.Append('    },');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "2",');
        ResponseText.Append('      "createdDateTime": "2023-05-20T09:21:17Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-06-21T10:15:48Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/Lists/Test%20List/2_.000",');
        ResponseText.Append('      "fields": {');
        ResponseText.Append('        "Title": "Test Item 2",');
        ResponseText.Append('        "Description": "This is another test item",');
        ResponseText.Append('        "Priority": "Medium"');
        ResponseText.Append('      }');
        ResponseText.Append('    }');
        ResponseText.Append('  ]');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetCreateListItemResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#sites(''root'')/lists(''01bjtwww-5j35-426b-a4d5-608f6e2a9f84'')/items/$entity",');
        ResponseText.Append('  "id": "3",');
        ResponseText.Append('  "createdDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('  "lastModifiedDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('  "webUrl": "https://contoso.sharepoint.com/sites/test/Lists/Test%20List/3_.000",');
        ResponseText.Append('  "fields": {');
        ResponseText.Append('    "Title": "New Test Item"');
        ResponseText.Append('  }');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetDrivesResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#sites(''root'')/drives",');
        ResponseText.Append('  "value": [');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "b!mR2-5tV1S-RO3C82s1DNbdCrWBwFQKFUoOB6bTlXClvD9fcjLXO5TbNk5sDyD7c8",');
        ResponseText.Append('      "name": "Documents",');
        ResponseText.Append('      "driveType": "documentLibrary",');
        ResponseText.Append('      "createdDateTime": "2021-08-17T21:43:32Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents"');
        ResponseText.Append('    },');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "b!mR2-5tV1S-RO3C82s1DNbdCrWBwFQKFUoOB6bTlXClvD9fcjLXO5TbNk5sDyD7c9",');
        ResponseText.Append('      "name": "HR Files",');
        ResponseText.Append('      "driveType": "documentLibrary",');
        ResponseText.Append('      "createdDateTime": "2021-08-17T21:43:32Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/HR%20Files"');
        ResponseText.Append('    }');
        ResponseText.Append('  ]');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetDriveItemsResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#sites(''root'')/drives(''b!mR2-5tV1S-RO3C82s1DNbdCrWBwFQKFUoOB6bTlXClvD9fcjLXO5TbNk5sDyD7c8'')/root/children",');
        ResponseText.Append('  "value": [');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "01EZJNRYOELVX64AZW4BA3DHJXMFBQZXPM",');
        ResponseText.Append('      "name": "Folder 1",');
        ResponseText.Append('      "createdDateTime": "2022-08-10T14:24:11Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-03-15T09:58:42Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents/Folder%201",');
        ResponseText.Append('      "folder": {');
        ResponseText.Append('        "childCount": 3');
        ResponseText.Append('      }');
        ResponseText.Append('    },');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ",');
        ResponseText.Append('      "name": "Document.docx",');
        ResponseText.Append('      "createdDateTime": "2022-09-05T10:12:32Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-05-20T11:42:18Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents/Document.docx",');
        ResponseText.Append('      "file": {');
        ResponseText.Append('        "mimeType": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",');
        ResponseText.Append('        "hashes": {');
        ResponseText.Append('          "quickXorHash": "KU5GC7lcTJbHDrcPKJc8rJtEhCo="');
        ResponseText.Append('        }');
        ResponseText.Append('      },');
        ResponseText.Append('      "size": 12345');
        ResponseText.Append('    }');
        ResponseText.Append('  ]');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetCreateFolderResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#driveItems/$entity",');
        ResponseText.Append('  "id": "01EZJNRYOELVX64AZW4BC2WGFBGY2D2MAE",');
        ResponseText.Append('  "name": "New Folder",');
        ResponseText.Append('  "createdDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('  "lastModifiedDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('  "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents/New%20Folder",');
        ResponseText.Append('  "folder": {');
        ResponseText.Append('    "childCount": 0');
        ResponseText.Append('  }');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetDriveItemResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#driveItems/$entity",');
        ResponseText.Append('  "id": "01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ",');
        ResponseText.Append('  "name": "Report.docx",');
        ResponseText.Append('  "createdDateTime": "2023-05-10T14:25:37Z",');
        ResponseText.Append('  "lastModifiedDateTime": "2023-06-20T09:42:13Z",');
        ResponseText.Append('  "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents/Report.docx",');
        ResponseText.Append('  "file": {');
        ResponseText.Append('    "mimeType": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",');
        ResponseText.Append('    "hashes": {');
        ResponseText.Append('      "quickXorHash": "dF5GC7lcTJbHDrcPKJc8rJtEhCo="');
        ResponseText.Append('    }');
        ResponseText.Append('  },');
        ResponseText.Append('  "size": 45321');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetErrorResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "error": {');
        ResponseText.Append('    "code": "InvalidAuthenticationToken",');
        ResponseText.Append('    "message": "Access token has expired or is not yet valid.",');
        ResponseText.Append('    "innerError": {');
        ResponseText.Append('      "date": "2023-07-15T12:00:00",');
        ResponseText.Append('      "request-id": "3b2d1e5f-fb1c-41a1-90e2-1fc8ae4ebede",');
        ResponseText.Append('      "client-request-id": "3b2d1e5f-fb1c-41a1-90e2-1fc8ae4ebede"');
        ResponseText.Append('    }');
        ResponseText.Append('  }');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

}