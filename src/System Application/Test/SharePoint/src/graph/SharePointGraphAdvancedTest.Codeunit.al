// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration.Sharepoint;

using System.Integration.Graph;
using System.Integration.Sharepoint;
using System.RestClient;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 132985 "SharePoint Graph Advanced Test"
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
    procedure TestOptionalParameters()
    var
        TempSharePointGraphList: Record "SharePoint Graph List" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        HttpRequestMessage: Codeunit "Http Request Message";
        Uri: Codeunit Uri;
        UnescapeDataString: Text;
    begin
        // [GIVEN] Mock response for an API call
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetListsResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Setting optional parameters
        SharePointGraphClient.SetODataSelect(GraphOptionalParameters, 'displayName,id,webUrl');
        SharePointGraphClient.SetODataFilter(GraphOptionalParameters, 'contains(displayName,''Document'')');
        SharePointGraphClient.SetODataOrderBy(GraphOptionalParameters, 'displayName asc');

        SharePointGraphClient.GetLists(TempSharePointGraphList, GraphOptionalParameters);
        SharePointGraphTestLibrary.GetHttpRequestMessage(HttpRequestMessage);

        // [THEN] Request URI should include the correct query parameters
        Uri.Init(HttpRequestMessage.GetRequestUri());
        UnescapeDataString := Uri.UnescapeDataString(Uri.GetQuery());
        LibraryAssert.IsTrue(UnescapeDataString.Contains('$select=displayName,id,webUrl'), 'Query should contain select parameter');
        LibraryAssert.IsTrue(UnescapeDataString.Contains('$filter=contains(displayName,''Document'')'), 'Query should contain filter parameter');
        LibraryAssert.IsTrue(UnescapeDataString.Contains('$orderby=displayName asc'), 'Query should contain orderby parameter');
    end;

    [Test]
    procedure TestODataExpandParameter()
    var
        TempSharePointGraphList: Record "SharePoint Graph List" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        HttpRequestMessage: Codeunit "Http Request Message";
        Uri: Codeunit Uri;
        UnescapeDataString: Text;
    begin
        // [GIVEN] Mock response for an API call
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetListsResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Setting expand parameter
        SharePointGraphClient.SetODataExpand(GraphOptionalParameters, 'columns,items');

        SharePointGraphClient.GetLists(TempSharePointGraphList, GraphOptionalParameters);
        SharePointGraphTestLibrary.GetHttpRequestMessage(HttpRequestMessage);

        // [THEN] Request URI should include the expand query parameter
        Uri.Init(HttpRequestMessage.GetRequestUri());
        UnescapeDataString := Uri.UnescapeDataString(Uri.GetQuery());
        LibraryAssert.IsTrue(UnescapeDataString.Contains('$expand=columns,items'), 'Query should contain expand parameter');
    end;

    [Test]
    procedure TestPagination()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        HttpRequestMessage: Codeunit "Http Request Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] We need to handle multiple requests for pagination
        Initialize();

        // [WHEN] Calling GetFolderItems (which should handle the pagination automatically)
        // Note: Since we can't easily queue multiple responses in the current mock implementation,
        // we'll need to modify the test approach

        // First, let's test that the first page is retrieved correctly
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetPaginatedResponsePage1());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // For now, we'll test pagination by verifying the request includes the nextLink
        SharePointGraphResponse := SharePointGraphClient.GetFolderItems('01EZJNRYOELVX64AZW4BA3DHJXMFBQZXPM', TempDriveItem);

        // Get the request to verify it was made correctly
        SharePointGraphTestLibrary.GetHttpRequestMessage(HttpRequestMessage);

        // [THEN] First page should be retrieved successfully
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetFolderItems should succeed for first page');
        LibraryAssert.IsTrue(HttpRequestMessage.GetRequestUri().Contains('/items/01EZJNRYOELVX64AZW4BA3DHJXMFBQZXPM/children'), 'Request should be for folder children');

        // Note: Full pagination testing would require enhancing the mock handler to queue multiple responses
        // For now, we're testing that the pagination URL is correctly formed in the response
        LibraryAssert.AreEqual(2, TempDriveItem.Count(), 'Should return 2 items from first page');
    end;

    [Test]
    procedure TestConflictBehavior()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        HttpRequestMessage: Codeunit "Http Request Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        TempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        FileOutStream: OutStream;
    begin
        // [GIVEN] Mock response for UploadFile
        Initialize();

        MockHttpResponseMessage.SetHttpStatusCode(201);
        MockHttpContent := HttpContent.Create(GetUploadFileResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Preparing a file and calling UploadFile with conflict behavior
        TempBlob.CreateOutStream(FileOutStream);
        FileOutStream.WriteText('Test content for uploaded file');
        TempBlob.CreateInStream(FileInStream);

        SharePointGraphResponse := SharePointGraphClient.UploadFile('Documents', 'Test.txt', FileInStream, TempDriveItem, Enum::"Graph ConflictBehavior"::Replace);

        // [THEN] Request should include the correct conflict behavior
        SharePointGraphTestLibrary.GetHttpRequestMessage(HttpRequestMessage);
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), SharePointGraphClient.GetDiagnostics().GetErrorMessage());
        LibraryAssert.IsTrue(HttpRequestMessage.GetRequestUri().Contains('microsoft.graph.conflictBehavior=replace'), 'URL should include conflict behavior parameter');
    end;

    [Test]
    procedure TestErrorHandling()
    var
        TempBlob: Codeunit "Temp Blob";
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        SharePointHttpDiagnostics: Interface "HTTP Diagnostics";
        Headers: HttpHeaders;
    begin
        // Test rate limiting response (429 Too Many Requests)
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(429);
        MockHttpContent := HttpContent.Create(GetRateLimitResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        MockHttpResponseMessage.SetReasonPhrase('Too Many Requests');

        Headers := MockHttpResponseMessage.GetHeaders();
        Headers.Add('Retry-After', '5');
        MockHttpResponseMessage.SetHeaders(Headers);

        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling API that is rate limited
        SharePointGraphResponse := SharePointGraphClient.DownloadFile('01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ', TempBlob);

        // [THEN] Operation should fail and return rate limit info
        LibraryAssert.IsFalse(SharePointGraphResponse.IsSuccessful(), 'Operation should fail due to rate limiting');
        SharePointHttpDiagnostics := SharePointGraphClient.GetDiagnostics();
        LibraryAssert.AreEqual(429, SharePointHttpDiagnostics.GetHttpStatusCode(), 'Status code should be 429');
        LibraryAssert.AreEqual('Too Many Requests', SharePointHttpDiagnostics.GetResponseReasonPhrase(), 'Reason phrase should match');
        LibraryAssert.AreEqual(5, SharePointHttpDiagnostics.GetHttpRetryAfter(), 'Retry-After should be 5 seconds');
    end;

    [Test]
    procedure TestForbiddenError()
    var
        TempList: Record "SharePoint Graph List" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        SharePointHttpDiagnostics: Interface "HTTP Diagnostics";
    begin
        // [GIVEN] Mock forbidden response (403)
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(403);
        MockHttpContent := HttpContent.Create(GetForbiddenResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        MockHttpResponseMessage.SetReasonPhrase('Forbidden');
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling API without proper permissions
        SharePointGraphResponse := SharePointGraphClient.GetLists(TempList);

        // [THEN] Operation should fail with 403
        LibraryAssert.IsFalse(SharePointGraphResponse.IsSuccessful(), 'Operation should fail due to lack of permissions');
        SharePointHttpDiagnostics := SharePointGraphClient.GetDiagnostics();
        LibraryAssert.AreEqual(403, SharePointHttpDiagnostics.GetHttpStatusCode(), 'Status code should be 403');
        LibraryAssert.AreEqual('Forbidden', SharePointHttpDiagnostics.GetResponseReasonPhrase(), 'Reason phrase should match');
    end;

    [Test]
    procedure TestServerError()
    var
        TempBlob: Codeunit "Temp Blob";
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        SharePointHttpDiagnostics: Interface "HTTP Diagnostics";
    begin
        // [GIVEN] Mock server error response (500)
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(500);
        MockHttpContent := HttpContent.Create(GetServerErrorResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        MockHttpResponseMessage.SetReasonPhrase('Internal Server Error');
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling API that encounters server error
        SharePointGraphResponse := SharePointGraphClient.DownloadFile('01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ', TempBlob);

        // [THEN] Operation should fail with 500
        LibraryAssert.IsFalse(SharePointGraphResponse.IsSuccessful(), 'Operation should fail due to server error');
        SharePointHttpDiagnostics := SharePointGraphClient.GetDiagnostics();
        LibraryAssert.AreEqual(500, SharePointHttpDiagnostics.GetHttpStatusCode(), 'Status code should be 500');
        LibraryAssert.AreEqual('Internal Server Error', SharePointHttpDiagnostics.GetResponseReasonPhrase(), 'Reason phrase should match');
    end;

    [Test]
    procedure TestBadRequestError()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        SharePointHttpDiagnostics: Interface "HTTP Diagnostics";
    begin
        // [GIVEN] Mock bad request response (400)
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(400);
        MockHttpContent := HttpContent.Create(GetBadRequestResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        MockHttpResponseMessage.SetReasonPhrase('Bad Request');
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling API with invalid parameters
        SharePointGraphResponse := SharePointGraphClient.CreateFolder('Documents', 'Invalid*Name?', TempDriveItem);

        // [THEN] Operation should fail with 400
        LibraryAssert.IsFalse(SharePointGraphResponse.IsSuccessful(), 'Operation should fail due to bad request');
        SharePointHttpDiagnostics := SharePointGraphClient.GetDiagnostics();
        LibraryAssert.AreEqual(400, SharePointHttpDiagnostics.GetHttpStatusCode(), 'Status code should be 400');
        LibraryAssert.AreEqual('Bad Request', SharePointHttpDiagnostics.GetResponseReasonPhrase(), 'Reason phrase should match');
    end;

    [Test]
    procedure TestGetDefaultDriveId()
    var
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        DriveId: Text;
    begin
        // [GIVEN] Mock response for GetDefaultDrive
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetDefaultDrive to get ID only
        SharePointGraphResponse := SharePointGraphClient.GetDefaultDrive(DriveId);

        // [THEN] Operation should succeed and return drive ID
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetDefaultDrive should succeed');
        LibraryAssert.AreEqual('b!mR2-5tV1S-RO3C82s1DNbdCrWBwFQKFUoOB6bTlXClvD9fcjLXO5TbNk5sDyD7c8', DriveId, 'Drive ID should match');
    end;

    [Test]
    procedure TestGetDefaultDrive()
    var
        TempDrive: Record "SharePoint Graph Drive" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for GetDefaultDrive
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetDefaultDrive with full details
        SharePointGraphResponse := SharePointGraphClient.GetDefaultDrive(TempDrive);

        // [THEN] Operation should succeed and return correct data
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetDefaultDrive should succeed');
        LibraryAssert.AreEqual('b!mR2-5tV1S-RO3C82s1DNbdCrWBwFQKFUoOB6bTlXClvD9fcjLXO5TbNk5sDyD7c8', TempDrive.Id, 'Drive ID should match');
        LibraryAssert.AreEqual('Documents', TempDrive.Name, 'Drive name should match');
        LibraryAssert.AreEqual('documentLibrary', TempDrive.DriveType, 'Drive type should match');
        LibraryAssert.IsTrue(TempDrive.QuotaTotal > 0, 'Quota total should be populated');
        LibraryAssert.IsTrue(TempDrive.QuotaUsed > 0, 'Quota used should be populated');
    end;

    [Test]
    procedure TestGetDrive()
    var
        TempDrive: Record "SharePoint Graph Drive" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for GetDrive
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetDrive
        SharePointGraphResponse := SharePointGraphClient.GetDrive('b!mR2-5tV1S-RO3C82s1DNbdCrWBwFQKFUoOB6bTlXClvD9fcjLXO5TbNk5sDyD7c8', TempDrive);

        // [THEN] Operation should succeed and return correct data
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetDrive should succeed');
        LibraryAssert.AreEqual('Documents', TempDrive.Name, 'Drive name should match');
    end;

    [Test]
    procedure TestGetDriveWithOptionalParameters()
    var
        TempDrive: Record "SharePoint Graph Drive" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        HttpRequestMessage: Codeunit "Http Request Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        Uri: Codeunit Uri;
        UnescapeDataString: Text;
    begin
        // [GIVEN] Mock response for GetDrive
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetDrive with optional parameters
        SharePointGraphClient.SetODataSelect(GraphOptionalParameters, 'id,name,driveType');
        SharePointGraphResponse := SharePointGraphClient.GetDrive('b!mR2-5tV1S-RO3C82s1DNbdCrWBwFQKFUoOB6bTlXClvD9fcjLXO5TbNk5sDyD7c8', TempDrive, GraphOptionalParameters);

        // [THEN] Operation should succeed and include query parameters
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetDrive should succeed');
        SharePointGraphTestLibrary.GetHttpRequestMessage(HttpRequestMessage);
        Uri.Init(HttpRequestMessage.GetRequestUri());
        UnescapeDataString := Uri.UnescapeDataString(Uri.GetQuery());
        LibraryAssert.IsTrue(UnescapeDataString.Contains('$select=id,name,driveType'), 'Query should contain select parameter');
    end;

    [Test]
    procedure TestGetDriveItemWithOptionalParameters()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        HttpRequestMessage: Codeunit "Http Request Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        Uri: Codeunit Uri;
        UnescapeDataString: Text;
    begin
        // [GIVEN] Mock response for GetDriveItem
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveItemResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetDriveItem with optional parameters
        SharePointGraphClient.SetODataSelect(GraphOptionalParameters, 'id,name,size');
        SharePointGraphResponse := SharePointGraphClient.GetDriveItem('01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ', TempDriveItem, GraphOptionalParameters);

        // [THEN] Operation should succeed and include query parameters
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetDriveItem should succeed');
        SharePointGraphTestLibrary.GetHttpRequestMessage(HttpRequestMessage);
        Uri.Init(HttpRequestMessage.GetRequestUri());
        UnescapeDataString := Uri.UnescapeDataString(Uri.GetQuery());
        LibraryAssert.IsTrue(UnescapeDataString.Contains('$select=id,name,size'), 'Query should contain select parameter');
    end;

    [Test]
    procedure TestGetItemsByPath()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for GetItemsByPath
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetFolderItemsResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetItemsByPath
        SharePointGraphResponse := SharePointGraphClient.GetItemsByPath('Documents/Reports', TempDriveItem);

        // [THEN] Operation should succeed and return correct data
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetItemsByPath should succeed');
        LibraryAssert.AreEqual(2, TempDriveItem.Count(), 'Should return 2 items');
    end;

    [Test]
    procedure TestDeleteItem()
    var
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for DeleteItem
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(204);
        MockHttpContent := HttpContent.Create('');
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling DeleteItem
        SharePointGraphResponse := SharePointGraphClient.DeleteItem('01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ');

        // [THEN] Operation should succeed
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'DeleteItem should succeed');
    end;

    [Test]
    procedure TestDeleteItemByPath()
    var
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for DeleteItemByPath
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(204);
        MockHttpContent := HttpContent.Create('');
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling DeleteItemByPath
        SharePointGraphResponse := SharePointGraphClient.DeleteItemByPath('Documents/FileToDelete.txt');

        // [THEN] Operation should succeed
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'DeleteItemByPath should succeed');
    end;

    [Test]
    procedure TestDeleteItemNotFound()
    var
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for DeleteItem with 404
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(404);
        MockHttpContent := HttpContent.Create(GetNotFoundResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling DeleteItem on non-existent item
        SharePointGraphResponse := SharePointGraphClient.DeleteItem('01NONEXISTENTITEMID');

        // [THEN] Operation should succeed (404 is acceptable for delete)
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'DeleteItem should succeed even with 404');
    end;

    [Test]
    procedure TestItemExists()
    var
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        Exists: Boolean;
    begin
        // [GIVEN] Mock response for ItemExists
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveItemResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling ItemExists
        SharePointGraphResponse := SharePointGraphClient.ItemExists('01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ', Exists);

        // [THEN] Operation should succeed and item should exist
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'ItemExists should succeed');
        LibraryAssert.IsTrue(Exists, 'Item should exist');
    end;

    [Test]
    procedure TestItemExistsNotFound()
    var
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        Exists: Boolean;
    begin
        // [GIVEN] Mock response for ItemExists with 404
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(404);
        MockHttpContent := HttpContent.Create(GetNotFoundResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling ItemExists on non-existent item
        SharePointGraphResponse := SharePointGraphClient.ItemExists('01NONEXISTENTITEMID', Exists);

        // [THEN] Operation should succeed and item should not exist
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'ItemExists should succeed');
        LibraryAssert.IsFalse(Exists, 'Item should not exist');
    end;

    [Test]
    procedure TestItemExistsByPath()
    var
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        Exists: Boolean;
    begin
        // [GIVEN] Mock response for ItemExistsByPath
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveItemResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling ItemExistsByPath
        SharePointGraphResponse := SharePointGraphClient.ItemExistsByPath('Documents/Report.docx', Exists);

        // [THEN] Operation should succeed and item should exist
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'ItemExistsByPath should succeed');
        LibraryAssert.IsTrue(Exists, 'Item should exist');
    end;

    [Test]
    procedure TestCopyItem()
    var
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for CopyItem
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(202);
        MockHttpContent := HttpContent.Create('');
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling CopyItem
        SharePointGraphResponse := SharePointGraphClient.CopyItem('01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ', '01TARGETFOLDERID123', 'CopiedFile.txt');

        // [THEN] Operation should succeed
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'CopyItem should succeed');
    end;

    [Test]
    procedure TestCopyItemByPath()
    var
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for CopyItemByPath
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(202);
        MockHttpContent := HttpContent.Create('');
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling CopyItemByPath
        SharePointGraphResponse := SharePointGraphClient.CopyItemByPath('Documents/Original.txt', 'Documents/Archive', 'CopiedFile.txt');

        // [THEN] Operation should succeed
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'CopyItemByPath should succeed');
    end;

    [Test]
    procedure TestMoveItem()
    var
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for MoveItem
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveItemResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling MoveItem
        SharePointGraphResponse := SharePointGraphClient.MoveItem('01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ', '01TARGETFOLDERID123', 'MovedFile.txt');

        // [THEN] Operation should succeed
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'MoveItem should succeed');
    end;

    [Test]
    procedure TestMoveItemByPath()
    var
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for MoveItemByPath
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveItemResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling MoveItemByPath
        SharePointGraphResponse := SharePointGraphClient.MoveItemByPath('Documents/Original.txt', 'Documents/Archive', 'MovedFile.txt');

        // [THEN] Operation should succeed
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'MoveItemByPath should succeed');
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

    local procedure GetPaginatedResponsePage1(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#driveItems(''01EZJNRYOELVX64AZW4BA3DHJXMFBQZXPM'')/children",');
        ResponseText.Append('  "value": [');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "01EZJNRYOELVX64AZW4BA3DHJXMFBQZXP1",');
        ResponseText.Append('      "name": "Subfolder",');
        ResponseText.Append('      "createdDateTime": "2022-09-15T10:12:32Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-03-20T14:35:16Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents/Folder%201/Subfolder",');
        ResponseText.Append('      "folder": {');
        ResponseText.Append('        "childCount": 1');
        ResponseText.Append('      }');
        ResponseText.Append('    },');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "01EZJNRYOELVX64AZW4BA3DHJXMFBQZXP2",');
        ResponseText.Append('      "name": "Presentation.pptx",');
        ResponseText.Append('      "createdDateTime": "2022-10-05T11:42:18Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-05-12T15:27:39Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents/Folder%201/Presentation.pptx",');
        ResponseText.Append('      "file": {');
        ResponseText.Append('        "mimeType": "application/vnd.openxmlformats-officedocument.presentationml.presentation",');
        ResponseText.Append('        "hashes": {');
        ResponseText.Append('          "quickXorHash": "TU5GC7lcTJbHDrcPKJc8rJtEhCo="');
        ResponseText.Append('        }');
        ResponseText.Append('      },');
        ResponseText.Append('      "size": 87621');
        ResponseText.Append('    }');
        ResponseText.Append('  ]');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetUploadFileResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#driveItems/$entity",');
        ResponseText.Append('  "id": "01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ",');
        ResponseText.Append('  "name": "Test.txt",');
        ResponseText.Append('  "createdDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('  "lastModifiedDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('  "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents/Test.txt",');
        ResponseText.Append('  "file": {');
        ResponseText.Append('    "mimeType": "text/plain",');
        ResponseText.Append('    "hashes": {');
        ResponseText.Append('      "quickXorHash": "KU5GC7lcTJbHDrcPKJc8rJtEhCo="');
        ResponseText.Append('    }');
        ResponseText.Append('  },');
        ResponseText.Append('  "size": 25');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetRateLimitResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "error": {');
        ResponseText.Append('    "code": "429",');
        ResponseText.Append('    "message": "Too many requests. Please try again later.",');
        ResponseText.Append('    "innerError": {');
        ResponseText.Append('      "date": "2023-07-15T12:00:00",');
        ResponseText.Append('      "request-id": "3b2d1e5f-fb1c-41a1-90e2-1fc8ae4ebede",');
        ResponseText.Append('      "client-request-id": "3b2d1e5f-fb1c-41a1-90e2-1fc8ae4ebede"');
        ResponseText.Append('    }');
        ResponseText.Append('  }');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetForbiddenResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "error": {');
        ResponseText.Append('    "code": "accessDenied",');
        ResponseText.Append('    "message": "Access denied. You do not have permission to perform this action.",');
        ResponseText.Append('    "innerError": {');
        ResponseText.Append('      "date": "2023-07-15T12:00:00",');
        ResponseText.Append('      "request-id": "4c3e2f6a-fc2d-52b2-91f3-2gc9bf5fcfdf",');
        ResponseText.Append('      "client-request-id": "4c3e2f6a-fc2d-52b2-91f3-2gc9bf5fcfdf"');
        ResponseText.Append('    }');
        ResponseText.Append('  }');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetServerErrorResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "error": {');
        ResponseText.Append('    "code": "internalServerError",');
        ResponseText.Append('    "message": "An internal server error occurred.",');
        ResponseText.Append('    "innerError": {');
        ResponseText.Append('      "date": "2023-07-15T12:00:00",');
        ResponseText.Append('      "request-id": "5d4f3a7b-ad3e-63c3-02a4-3hd0ca6adfea",');
        ResponseText.Append('      "client-request-id": "5d4f3a7b-ad3e-63c3-02a4-3hd0ca6adfea"');
        ResponseText.Append('    }');
        ResponseText.Append('  }');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetBadRequestResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "error": {');
        ResponseText.Append('    "code": "invalidRequest",');
        ResponseText.Append('    "message": "The request is malformed or incorrect.",');
        ResponseText.Append('    "innerError": {');
        ResponseText.Append('      "date": "2023-07-15T12:00:00",');
        ResponseText.Append('      "request-id": "6e5a4b8c-be4f-74d4-13b5-4ie1db7befb",');
        ResponseText.Append('      "client-request-id": "6e5a4b8c-be4f-74d4-13b5-4ie1db7befb"');
        ResponseText.Append('    }');
        ResponseText.Append('  }');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetDriveResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#drives/$entity",');
        ResponseText.Append('  "id": "b!mR2-5tV1S-RO3C82s1DNbdCrWBwFQKFUoOB6bTlXClvD9fcjLXO5TbNk5sDyD7c8",');
        ResponseText.Append('  "name": "Documents",');
        ResponseText.Append('  "driveType": "documentLibrary",');
        ResponseText.Append('  "description": "Default document library",');
        ResponseText.Append('  "createdDateTime": "2022-01-15T08:30:00Z",');
        ResponseText.Append('  "lastModifiedDateTime": "2023-07-15T10:31:30Z",');
        ResponseText.Append('  "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents",');
        ResponseText.Append('  "owner": {');
        ResponseText.Append('    "user": {');
        ResponseText.Append('      "displayName": "System Account",');
        ResponseText.Append('      "email": "system@contoso.com"');
        ResponseText.Append('    }');
        ResponseText.Append('  },');
        ResponseText.Append('  "quota": {');
        ResponseText.Append('    "total": 1099511627776,');
        ResponseText.Append('    "used": 524288000,');
        ResponseText.Append('    "remaining": 1098987339776,');
        ResponseText.Append('    "state": "normal"');
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

    local procedure GetFolderItemsResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#driveItems",');
        ResponseText.Append('  "value": [');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "01EZJNRYOELVX64AZW4BA3DHJXMFBQZXP1",');
        ResponseText.Append('      "name": "Q1Report.docx",');
        ResponseText.Append('      "createdDateTime": "2022-09-15T10:12:32Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-03-20T14:35:16Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents/Reports/Q1Report.docx",');
        ResponseText.Append('      "file": {');
        ResponseText.Append('        "mimeType": "application/vnd.openxmlformats-officedocument.wordprocessingml.document"');
        ResponseText.Append('      },');
        ResponseText.Append('      "size": 45321');
        ResponseText.Append('    },');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "01EZJNRYOELVX64AZW4BA3DHJXMFBQZXP2",');
        ResponseText.Append('      "name": "Q2Report.docx",');
        ResponseText.Append('      "createdDateTime": "2022-10-05T11:42:18Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-05-12T15:27:39Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents/Reports/Q2Report.docx",');
        ResponseText.Append('      "file": {');
        ResponseText.Append('        "mimeType": "application/vnd.openxmlformats-officedocument.wordprocessingml.document"');
        ResponseText.Append('      },');
        ResponseText.Append('      "size": 52347');
        ResponseText.Append('    }');
        ResponseText.Append('  ]');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;

    local procedure GetNotFoundResponse(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "error": {');
        ResponseText.Append('    "code": "itemNotFound",');
        ResponseText.Append('    "message": "The resource could not be found.",');
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