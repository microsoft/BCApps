// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.ExternalFileStorage;

using System.ExternalFileStorage;
using System.Test.Integration.Sharepoint;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>
/// Tests the Graph helper using platform-level HTTP mocking ([HttpClientHandler]).
/// A mock "Graph Authorization" is injected because token acquisition goes through the
/// platform OAuth stack and cannot be intercepted by test HTTP handlers.
/// </summary>
codeunit 144585 "Ext. SP Graph Helper Test"
{
    Subtype = Test;
    TestHttpRequestPolicy = BlockOutboundRequests;
    TestPermissions = Disabled;

    var
        GraphHelper: Codeunit "Ext. SharePoint Graph Helper";
        GraphAuthMock: Codeunit "SharePoint Graph Auth Mock";
        Assert: Codeunit "Library Assert";
        LastPath: Text;
        LastMethod: HttpRequestType;
        ReturnNotFound: Boolean;
        ReturnServerError: Boolean;
        UploadSessionCreated: Boolean;
        ChunkUploadCount: Integer;
        SharePointUrlLbl: Label 'https://contoso.sharepoint.com/sites/test', Locked = true;

    #region File Operations

    [Test]
    [HandlerFunctions('ListItemsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestListFilesReturnsOnlyFiles()
    var
        Account: Record "Ext. SharePoint Account";
        TempContent: Record "File Account Content" temporary;
        Pagination: Codeunit "File Pagination Data";
    begin
        // [GIVEN] Mock returns 1 folder + 2 files
        Initialize(Account);

        // [WHEN]
        GraphHelper.ListFiles(Account, '', Pagination, TempContent);

        // [THEN] Only the 2 files are in the result, with the right names and type
        Assert.RecordCount(TempContent, 2);
        TempContent.SetRange(Type, TempContent.Type::"File");
        Assert.RecordCount(TempContent, 2);
        TempContent.SetRange(Name, 'Report.pdf');
        Assert.RecordCount(TempContent, 1);
        TempContent.SetRange(Name, 'Budget.xlsx');
        Assert.RecordCount(TempContent, 1);
    end;

    [Test]
    [HandlerFunctions('ListItemsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestListDirectoriesReturnsOnlyFolders()
    var
        Account: Record "Ext. SharePoint Account";
        TempContent: Record "File Account Content" temporary;
        Pagination: Codeunit "File Pagination Data";
    begin
        // [GIVEN] Same mixed response
        Initialize(Account);

        // [WHEN]
        GraphHelper.ListDirectories(Account, '', Pagination, TempContent);

        // [THEN] Only the 1 folder
        Assert.RecordCount(TempContent, 1);
        TempContent.FindFirst();
        Assert.AreEqual('Subfolder', TempContent.Name, 'Folder name should match');
        Assert.AreEqual(TempContent.Type::Directory, TempContent.Type, 'Should be Directory type');
    end;

    [Test]
    [HandlerFunctions('ListItemsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestListFilesAppliesBaseRelativeFolderPath()
    var
        Account: Record "Ext. SharePoint Account";
        TempContent: Record "File Account Content" temporary;
        Pagination: Codeunit "File Pagination Data";
    begin
        // [GIVEN] An account with a base relative folder path
        Initialize(Account);
        Account."Base Relative Folder Path" := 'Docs/Base';

        // [WHEN] Listing a subfolder
        GraphHelper.ListFiles(Account, 'Sub', Pagination, TempContent);

        // [THEN] The request path combines base path and subfolder
        Assert.IsTrue(LastPath.Contains('Docs/Base/Sub'), 'Request should target the combined path. Actual: ' + LastPath);

        // [THEN] The parent directory reflects the original (relative) path, not the combined one
        TempContent.FindFirst();
        Assert.AreEqual('Sub', TempContent."Parent Directory", 'Parent Directory should be the original path');
    end;

    [Test]
    [HandlerFunctions('ListItemsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestBasePathWithTrailingSlashDoesNotDoubleSlash()
    var
        Account: Record "Ext. SharePoint Account";
        TempContent: Record "File Account Content" temporary;
        Pagination: Codeunit "File Pagination Data";
    begin
        // [GIVEN] A base path ending with a slash
        Initialize(Account);
        Account."Base Relative Folder Path" := 'Docs/Base/';

        // [WHEN]
        GraphHelper.ListFiles(Account, 'Sub', Pagination, TempContent);

        // [THEN] The combined path has no double slash
        Assert.IsTrue(LastPath.Contains('Docs/Base/Sub'), 'Request should target the combined path. Actual: ' + LastPath);
        Assert.IsFalse(LastPath.Contains('Base//Sub'), 'Combined path must not contain a double slash. Actual: ' + LastPath);
    end;

    [Test]
    [HandlerFunctions('GetFileHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestGetFileDownloadsContent()
    var
        Account: Record "Ext. SharePoint Account";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        FileContent: Text;
    begin
        // [GIVEN] Mock provides file metadata (size=5) then chunk body 'HELLO'
        Initialize(Account);
        TempBlob.CreateInStream(InStream);

        // [WHEN]
        GraphHelper.GetFile(Account, 'file.txt', InStream);

        // [THEN] The downloaded content survives the stream hand-over
        InStream.ReadText(FileContent);
        Assert.AreEqual('HELLO', FileContent, 'Downloaded file content should match the mocked response');
    end;

    [Test]
    [HandlerFunctions('SimpleSuccessHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCreateFileUsesSimpleUploadForSmallFiles()
    var
        Account: Record "Ext. SharePoint Account";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        // [GIVEN] A file under the 4 MB simple-upload limit
        Initialize(Account);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('hello');
        TempBlob.CreateInStream(InStream);

        // [WHEN]
        GraphHelper.CreateFile(Account, 'folder/test.txt', InStream);

        // [THEN] The file is PUT directly to the content endpoint (no upload session)
        Assert.IsTrue(LastPath.Contains('folder/test.txt:/content'), 'Small files should use the simple :/content upload. Actual: ' + LastPath);
        Assert.IsFalse(LastPath.Contains('createUploadSession'), 'Small files should not create an upload session');
    end;

    [Test]
    [HandlerFunctions('SimpleSuccessHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCreateFileInRootSplitsPath()
    var
        Account: Record "Ext. SharePoint Account";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        // [GIVEN] A file path without any folder
        Initialize(Account);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('hello');
        TempBlob.CreateInStream(InStream);

        // [WHEN]
        GraphHelper.CreateFile(Account, 'rootfile.txt', InStream);

        // [THEN] The file lands in the drive root
        Assert.IsTrue(LastPath.Contains('rootfile.txt:/content'), 'Root files should upload to the drive root. Actual: ' + LastPath);
    end;

    [Test]
    [HandlerFunctions('LargeUploadHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCreateLargeFileUsesUploadSession()
    var
        Account: Record "Ext. SharePoint Account";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        OneKbTxt: Text;
        Index: Integer;
    begin
        // [GIVEN] A file over the 4 MB simple-upload limit
        Initialize(Account);
        TempBlob.CreateOutStream(OutStream);
        OneKbTxt := PadStr('', 1024, 'A');
        for Index := 1 to 4097 do // 4097 KB > 4 MB
            OutStream.WriteText(OneKbTxt);
        TempBlob.CreateInStream(InStream);

        // [WHEN]
        GraphHelper.CreateFile(Account, 'folder/big.txt', InStream);

        // [THEN] The chunked upload session flow is used
        Assert.IsTrue(UploadSessionCreated, 'Files over 4 MB should create an upload session');
        Assert.IsTrue(ChunkUploadCount >= 1, 'At least one chunk should be uploaded to the session URL');
    end;

    [Test]
    [HandlerFunctions('CopyFileHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCopyFileUsesNativeGraphCopy()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] Mock supplies target folder item, source item, copy response
        Initialize(Account);

        // [WHEN]
        GraphHelper.CopyFile(Account, 'source.txt', 'TargetFolder/source.txt');

        // [THEN] The last request path contains '/copy' — native Graph copy, not Get+Create
        Assert.IsTrue(LastPath.Contains('/copy'), 'CopyFile should use the native Graph /copy endpoint');
    end;

    [Test]
    [HandlerFunctions('MoveFileHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestMoveFileUsesGraphPatch()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN]
        Initialize(Account);

        // [WHEN]
        GraphHelper.MoveFile(Account, 'source.txt', 'TargetFolder/source.txt');

        // [THEN] Last request was PATCH
        Assert.IsTrue(LastMethod = HttpRequestType::PATCH, 'MoveFile should use a PATCH request');
    end;

    [Test]
    [HandlerFunctions('ItemExistsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestFileExistsTrueOn200()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] The item request succeeds (200)
        Initialize(Account);

        // [WHEN] / [THEN]
        Assert.IsTrue(GraphHelper.FileExists(Account, 'file.txt'), 'FileExists should return true on 200');
    end;

    [Test]
    [HandlerFunctions('ItemExistsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestFileExistsFalseOn404()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] The item request returns 404
        Initialize(Account);
        ReturnNotFound := true;

        // [WHEN] / [THEN] 404 means "does not exist" — no error
        Assert.IsFalse(GraphHelper.FileExists(Account, 'missing.txt'), 'FileExists should return false on 404');
    end;

    [Test]
    [HandlerFunctions('ItemExistsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestFileExistsFailsOnServerError()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] The item request fails with 500 (throttling, auth, outage, ...)
        Initialize(Account);
        ReturnServerError := true;

        // [WHEN] / [THEN] FileExists raises an error instead of reporting "does not exist"
        asserterror GraphHelper.FileExists(Account, 'file.txt');
        Assert.IsTrue(GetLastErrorText().Contains('An error occurred.'), 'A server error must surface as an error, not as a negative exists-check');
    end;

    [Test]
    [HandlerFunctions('SimpleSuccessHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDeleteFileSendsDeleteRequest()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN]
        Initialize(Account);

        // [WHEN] Deleting a file
        GraphHelper.DeleteFile(Account, 'file.txt');

        // [THEN] A DELETE request targeted the file
        Assert.IsTrue(LastMethod = HttpRequestType::DELETE, 'DeleteFile should send a DELETE request');
        Assert.IsTrue(LastPath.Contains('file.txt'), 'The DELETE request should target the file. Actual: ' + LastPath);
    end;

    #endregion

    #region Directory Operations

    [Test]
    [HandlerFunctions('SimpleSuccessHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCreateDirectorySendsPostRequest()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN]
        Initialize(Account);

        // [WHEN] Creating a directory
        GraphHelper.CreateDirectory(Account, 'NewFolder');

        // [THEN] The folder was created via a POST request
        Assert.IsTrue(LastMethod = HttpRequestType::POST, 'CreateDirectory should send a POST request');
    end;

    [Test]
    [HandlerFunctions('ItemExistsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDirectoryExistsTrueOn200()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] The item request succeeds (200)
        Initialize(Account);

        // [WHEN] / [THEN]
        Assert.IsTrue(GraphHelper.DirectoryExists(Account, 'MyFolder'), 'DirectoryExists should return true on 200');
    end;

    [Test]
    [HandlerFunctions('ItemExistsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDirectoryExistsFalseOn404()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] The item request returns 404
        Initialize(Account);
        ReturnNotFound := true;

        // [WHEN] / [THEN] 404 means "does not exist" — no error
        Assert.IsFalse(GraphHelper.DirectoryExists(Account, 'MissingFolder'), 'DirectoryExists should return false on 404');
    end;

    [Test]
    [HandlerFunctions('SimpleSuccessHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDeleteDirectorySendsDeleteRequest()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN]
        Initialize(Account);

        // [WHEN] Deleting a directory
        GraphHelper.DeleteDirectory(Account, 'OldFolder');

        // [THEN] A DELETE request targeted the folder
        Assert.IsTrue(LastMethod = HttpRequestType::DELETE, 'DeleteDirectory should send a DELETE request');
        Assert.IsTrue(LastPath.Contains('OldFolder'), 'The DELETE request should target the folder. Actual: ' + LastPath);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDisabledAccountThrowsError()
    var
        Account: Record "Ext. SharePoint Account";
        TempContent: Record "File Account Content" temporary;
        Pagination: Codeunit "File Pagination Data";
    begin
        // [GIVEN] A disabled account
        Initialize(Account);
        Account.Disabled := true;

        // [WHEN] / [THEN] Any operation fails before any HTTP traffic
        asserterror GraphHelper.ListFiles(Account, '', Pagination, TempContent);
        Assert.IsTrue(GetLastErrorText().Contains('is disabled'), 'A disabled account should raise the disabled-account error');
    end;

    #endregion

    #region HTTP Handlers

    [HttpClientHandler]
    procedure ListItemsHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        LastPath := Request.Path;
        LastMethod := Request.RequestType;
        if TryHandleDiscovery(Request, Response) then
            exit;

        // items listing
        Response.Content.WriteFrom('{"value":[' +
            '{"id":"1","name":"Subfolder","folder":{"childCount":0}},' +
            '{"id":"2","name":"Report.pdf","file":{"mimeType":"application/pdf"},"size":1000},' +
            '{"id":"3","name":"Budget.xlsx","file":{"mimeType":"application/vnd.ms-excel"},"size":2000}' +
            ']}');
    end;

    [HttpClientHandler]
    procedure GetFileHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        LastPath := Request.Path;
        LastMethod := Request.RequestType;
        if TryHandleDiscovery(Request, Response) then
            exit;

        if Request.Path.Contains(':/content') then
            // chunk download — return small body
            Response.Content.WriteFrom('HELLO')
        else
            // GetDriveItemByPath for file size
            Response.Content.WriteFrom('{"id":"f1","name":"file.txt","file":{"mimeType":"text/plain"},"size":5}');
    end;

    [HttpClientHandler]
    procedure SimpleSuccessHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        LastPath := Request.Path;
        LastMethod := Request.RequestType;
        if TryHandleDiscovery(Request, Response) then
            exit;

        Response.Content.WriteFrom('{"id":"result-id","name":"item"}');
    end;

    [HttpClientHandler]
    procedure LargeUploadHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        LastPath := Request.Path;
        LastMethod := Request.RequestType;
        if TryHandleDiscovery(Request, Response) then
            exit;

        case true of
            Request.Path.Contains('createUploadSession'):
                begin
                    UploadSessionCreated := true;
                    // Upload URL host must be a trusted Microsoft host to pass validation
                    Response.Content.WriteFrom('{"uploadUrl":"https://contoso.sharepoint.com/upload-session/test-session"}');
                end;
            Request.Path.Contains('upload-session'):
                begin
                    ChunkUploadCount += 1;
                    // Every chunk response carries the item so the final chunk completes the upload
                    Response.Content.WriteFrom('{"id":"large-item-id","name":"big.txt","size":4195328,"file":{"mimeType":"application/octet-stream"}}');
                end;
            else
                Response.Content.WriteFrom('{"id":"result-id","name":"item"}');
        end;
    end;

    [HttpClientHandler]
    procedure CopyFileHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        LastPath := Request.Path;
        LastMethod := Request.RequestType;
        if TryHandleDiscovery(Request, Response) then
            exit;

        if Request.Path.Contains('/copy') then
            Response.Content.WriteFrom('{}')
        else
            // GetDriveItemByPath calls for target and source
            Response.Content.WriteFrom('{"id":"item-id","name":"item","folder":{"childCount":0}}');
    end;

    [HttpClientHandler]
    procedure MoveFileHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        LastPath := Request.Path;
        LastMethod := Request.RequestType;
        if TryHandleDiscovery(Request, Response) then
            exit;

        if Request.RequestType = HttpRequestType::PATCH then
            Response.Content.WriteFrom('{}')
        else
            // GetDriveItemByPath for source and target
            Response.Content.WriteFrom('{"id":"item-id","name":"item","folder":{"childCount":0}}');
    end;

    [HttpClientHandler]
    procedure ItemExistsHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        LastPath := Request.Path;
        LastMethod := Request.RequestType;
        if TryHandleDiscovery(Request, Response) then
            exit;

        case true of
            ReturnServerError:
                begin
                    Response.HttpStatusCode := 500;
                    Response.Content.WriteFrom('{"error":{"code":"generalException","message":"Something went wrong"}}');
                end;
            ReturnNotFound:
                begin
                    Response.HttpStatusCode := 404;
                    Response.Content.WriteFrom('{"error":{"code":"itemNotFound","message":"Item not found"}}');
                end;
            else
                Response.Content.WriteFrom('{"id":"f1","name":"file.txt","file":{},"size":10}');
        end;
    end;

    #endregion

    #region Handler Helpers

    local procedure TryHandleDiscovery(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if IsSiteDiscovery(Request) then begin
            Response.Content.WriteFrom('{"id":"test-site-id"}');
            exit(true);
        end;
        if IsDriveDiscovery(Request) then begin
            Response.Content.WriteFrom('{"id":"test-drive-id"}');
            exit(true);
        end;
        exit(false);
    end;

    local procedure IsSiteDiscovery(Request: TestHttpRequestMessage): Boolean
    begin
        // Site discovery: graph.microsoft.com/v1.0/sites/hostname:/path:
        // No /drive, no /root, no /items
        exit(
            Request.Path.Contains('graph.microsoft.com') and
            Request.Path.Contains('/sites/') and
            not Request.Path.Contains('/drive') and
            not Request.Path.Contains('/items') and
            not Request.Path.Contains('/root'));
    end;

    local procedure IsDriveDiscovery(Request: TestHttpRequestMessage): Boolean
    begin
        // Drive discovery: graph.microsoft.com/v1.0/sites/{siteId}/drive?select=id
        exit(
            Request.Path.Contains('graph.microsoft.com') and
            Request.Path.Contains('/drive') and
            not Request.Path.Contains('/drives/') and
            not Request.Path.Contains('/root'));
    end;

    #endregion

    #region Setup

    local procedure Initialize(var Account: Record "Ext. SharePoint Account")
    begin
        Clear(GraphHelper);
        GraphHelper.SetAuthorizationForTest(GraphAuthMock);

        LastPath := '';
        ReturnNotFound := false;
        ReturnServerError := false;
        UploadSessionCreated := false;
        ChunkUploadCount := 0;

        Account.Init();
        Account.Id := CreateGuid();
        Account."SharePoint Url" := SharePointUrlLbl;
        Account."Tenant Id" := CreateGuid();
        Account."Client Id" := CreateGuid();
        Account."Authentication Type" := Enum::"Ext. SharePoint Auth Type"::"Client Secret";
        Account."Use legacy REST API" := false;
        Account.Insert();
    end;

    #endregion
}
