// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.ExternalFileStorage;

using System.ExternalFileStorage;
using System.TestLibraries.Integration.Sharepoint;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>
/// Tests the REST helper using platform-level HTTP mocking ([HttpClientHandler]).
/// A dummy "SharePoint Authorization" is injected because token acquisition goes through the
/// platform OAuth stack and cannot be intercepted by test HTTP handlers.
/// Every handler records the requests it sees (verb, URL, download/add/delete legs) so tests
/// can assert what the helper actually asked SharePoint to do, not just that no error occurred.
/// </summary>
codeunit 144586 "Ext. SP REST Helper Test"
{
    Subtype = Test;
    TestHttpRequestPolicy = BlockOutboundRequests;
    TestPermissions = Disabled;

    var
        RestHelper: Codeunit "Ext. SharePoint REST Helper";
        DummySharePointAuthorization: Codeunit "Dummy SharePoint Authorization";
        Assert: Codeunit "Library Assert";
        LastPath: Text;
        LastMethod: HttpRequestType;
        DownloadPath: Text;
        FileAddPath: Text;
        DeletePath: Text;
        ReturnFolderExists: Boolean;
        ReturnFileExists: Boolean;
        SharePointUrlLbl: Label 'https://contoso.sharepoint.com/sites/test', Locked = true;

    #region File Operations

    [Test]
    [HandlerFunctions('ListFilesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestListFilesReturnsFiles()
    var
        Account: Record "Ext. SharePoint Account";
        TempContent: Record "File Account Content" temporary;
        Pagination: Codeunit "File Pagination Data";
    begin
        // [GIVEN] The folder listing returns 2 files
        Initialize(Account);

        // [WHEN] Listing files
        RestHelper.ListFiles(Account, '', Pagination, TempContent);

        // [THEN] Both files are returned with the right names
        Assert.RecordCount(TempContent, 2);
        TempContent.SetRange(Type, TempContent.Type::"File");
        Assert.RecordCount(TempContent, 2);
        TempContent.SetRange(Name, 'document.pdf');
        Assert.RecordCount(TempContent, 1);
        TempContent.SetRange(Name, 'budget.xlsx');
        Assert.RecordCount(TempContent, 1);
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
        // [GIVEN] The download endpoint returns 'Hello World'
        Initialize(Account);
        TempBlob.CreateInStream(InStream);

        // [WHEN] Getting the file
        RestHelper.GetFile(Account, 'file.txt', InStream);

        // [THEN] The downloaded content survives the stream hand-over
        InStream.ReadText(FileContent);
        Assert.AreEqual('Hello World', FileContent, 'Downloaded file content should match the mocked response');
    end;

    [Test]
    [HandlerFunctions('CreateFileHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCreateFileUploadsToFolder()
    var
        Account: Record "Ext. SharePoint Account";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        // [GIVEN] A file to upload
        Initialize(Account);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('content');
        TempBlob.CreateInStream(InStream);

        // [WHEN] Creating the file
        RestHelper.CreateFile(Account, 'file.txt', InStream);

        // [THEN] The file was uploaded via the Files/add endpoint under its own name
        Assert.IsTrue(FileAddPath.Contains('/Files/add(url='), 'CreateFile should upload via the Files/add endpoint. Actual: ' + FileAddPath);
        Assert.IsTrue(FileAddPath.Contains('file.txt'), 'The upload should target the requested file name. Actual: ' + FileAddPath);
    end;

    [Test]
    [HandlerFunctions('CopyFileHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCopyFileDownloadsSourceAndCreatesTargetWithoutDelete()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] The REST stack has no native copy: CopyFile = GetFile + CreateFile
        Initialize(Account);

        // [WHEN] Copying source.txt to dest.txt
        RestHelper.CopyFile(Account, 'source.txt', 'dest.txt');

        // [THEN] The source was downloaded and the target created
        Assert.IsTrue(DownloadPath.Contains('source.txt'), 'CopyFile should download the source file. Actual: ' + DownloadPath);
        Assert.IsTrue(FileAddPath.Contains('dest.txt'), 'CopyFile should create the target file. Actual: ' + FileAddPath);

        // [THEN] The source was NOT deleted — that is what distinguishes copy from move
        Assert.AreEqual('', DeletePath, 'CopyFile must not delete the source file');
    end;

    [Test]
    [HandlerFunctions('MoveFileHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestMoveFileCreatesTargetAndDeletesSource()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] The REST stack has no native move: MoveFile = GetFile + CreateFile + DeleteFile
        Initialize(Account);

        // [WHEN] Moving source.txt to dest.txt
        RestHelper.MoveFile(Account, 'source.txt', 'dest.txt');

        // [THEN] The source was downloaded, the target created, and the source deleted
        Assert.IsTrue(DownloadPath.Contains('source.txt'), 'MoveFile should download the source file. Actual: ' + DownloadPath);
        Assert.IsTrue(FileAddPath.Contains('dest.txt'), 'MoveFile should create the target file. Actual: ' + FileAddPath);
        Assert.IsTrue(DeletePath.Contains('source.txt'), 'MoveFile must delete the source file. Actual: ' + DeletePath);
    end;

    [Test]
    [HandlerFunctions('FileExistsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestFileExistsTrue()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] The parent folder listing contains the file
        Initialize(Account);
        ReturnFileExists := true;

        // [WHEN] / [THEN]
        Assert.IsTrue(RestHelper.FileExists(Account, 'file.txt'), 'FileExists should return true');
    end;

    [Test]
    [HandlerFunctions('FileExistsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestFileExistsFalse()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] The parent folder listing does not contain the file
        Initialize(Account);
        ReturnFileExists := false;

        // [WHEN] / [THEN]
        Assert.IsFalse(RestHelper.FileExists(Account, 'file.txt'), 'FileExists should return false');
    end;

    [Test]
    [HandlerFunctions('DeleteHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDeleteFileSendsDeleteRequest()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN]
        Initialize(Account);

        // [WHEN] Deleting a file
        RestHelper.DeleteFile(Account, 'file.txt');

        // [THEN] A DELETE request targeted the file
        Assert.IsTrue(DeletePath.Contains('file.txt'), 'DeleteFile should send a DELETE request for the file. Actual: ' + DeletePath);
    end;

    #endregion

    #region Directory Operations

    [Test]
    [HandlerFunctions('ListDirectoriesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestListDirectoriesReturnsFolders()
    var
        Account: Record "Ext. SharePoint Account";
        TempContent: Record "File Account Content" temporary;
        Pagination: Codeunit "File Pagination Data";
    begin
        // [GIVEN] The folder listing returns 1 subfolder
        Initialize(Account);

        // [WHEN] Listing directories
        RestHelper.ListDirectories(Account, '', Pagination, TempContent);

        // [THEN] The folder is returned with the right name and type
        Assert.RecordCount(TempContent, 1);
        TempContent.FindFirst();
        Assert.AreEqual('Subfolder', TempContent.Name, 'Folder name should match');
        Assert.AreEqual(TempContent.Type::Directory, TempContent.Type, 'Type should be Directory');
    end;

    [Test]
    [HandlerFunctions('CreateDirectoryHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCreateDirectoryPostsToFoldersEndpoint()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN]
        Initialize(Account);

        // [WHEN] Creating a directory
        RestHelper.CreateDirectory(Account, 'NewFolder');

        // [THEN] A POST went to the folders endpoint
        Assert.IsTrue(LastPath.Contains('/Web/folders'), 'CreateDirectory should POST to the folders endpoint. Actual: ' + LastPath);
        Assert.IsTrue(LastMethod = HttpRequestType::POST, 'CreateDirectory should send a POST request');
    end;

    [Test]
    [HandlerFunctions('DirectoryExistsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDirectoryExistsTrue()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] The folder exists on the server
        Initialize(Account);
        ReturnFolderExists := true;

        // [WHEN] / [THEN]
        Assert.IsTrue(RestHelper.DirectoryExists(Account, 'MyFolder'), 'DirectoryExists should return true');
    end;

    [Test]
    [HandlerFunctions('DirectoryExistsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDirectoryExistsFalse()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] The folder does not exist on the server
        Initialize(Account);
        ReturnFolderExists := false;

        // [WHEN] / [THEN]
        Assert.IsFalse(RestHelper.DirectoryExists(Account, 'MissingFolder'), 'DirectoryExists should return false');
    end;

    [Test]
    [HandlerFunctions('DeleteHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDeleteDirectorySendsDeleteRequest()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN]
        Initialize(Account);

        // [WHEN] Deleting a directory
        RestHelper.DeleteDirectory(Account, 'OldFolder');

        // [THEN] A DELETE request targeted the folder
        Assert.IsTrue(DeletePath.Contains('OldFolder'), 'DeleteDirectory should send a DELETE request for the folder. Actual: ' + DeletePath);
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
        asserterror RestHelper.ListFiles(Account, '', Pagination, TempContent);
        Assert.IsTrue(GetLastErrorText().Contains('is disabled'), 'A disabled account should raise the disabled-account error');
    end;

    #endregion

    #region HTTP Handlers

    [HttpClientHandler]
    procedure ListFilesHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        TrackRequest(Request);
        case true of
            IsContextInfo(Request):
                WriteContextInfoResponse(Response);
            Request.Path.Contains('/Files') and (Request.RequestType = HttpRequestType::GET):
                Response.Content.WriteFrom(GetFilesJson());
            else
                Response.Content.WriteFrom('{}');
        end;
    end;

    [HttpClientHandler]
    procedure GetFileHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        TrackRequest(Request);
        case true of
            IsFileDownload(Request):
                Response.Content.WriteFrom('Hello World');
            else
                Response.Content.WriteFrom('{}');
        end;
    end;

    [HttpClientHandler]
    procedure CreateFileHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        TrackRequest(Request);
        case true of
            IsContextInfo(Request):
                WriteContextInfoResponse(Response);
            Request.Path.Contains('/Files/add(url='):
                Response.Content.WriteFrom(GetFileItemJson('file.txt'));
            else
                Response.Content.WriteFrom('{}');
        end;
    end;

    [HttpClientHandler]
    procedure CopyFileHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        TrackRequest(Request);
        case true of
            IsContextInfo(Request):
                WriteContextInfoResponse(Response);
            IsFileDownload(Request):
                Response.Content.WriteFrom('file content');
            Request.Path.Contains('/Files/add(url='):
                Response.Content.WriteFrom(GetFileItemJson('dest.txt'));
            else
                Response.Content.WriteFrom('{}');
        end;
    end;

    [HttpClientHandler]
    procedure MoveFileHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        TrackRequest(Request);
        case true of
            IsContextInfo(Request):
                WriteContextInfoResponse(Response);
            IsFileDownload(Request):
                Response.Content.WriteFrom('file content');
            Request.Path.Contains('/Files/add(url='):
                Response.Content.WriteFrom(GetFileItemJson('dest.txt'));
            Request.RequestType = HttpRequestType::DELETE:
                Response.Content.WriteFrom('{}');
            else
                Response.Content.WriteFrom('{}');
        end;
    end;

    [HttpClientHandler]
    procedure FileExistsHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        TrackRequest(Request);
        case true of
            Request.Path.Contains('/Files') and (Request.RequestType = HttpRequestType::GET):
                // FileExists lists the parent folder and filters by name, so the positive
                // response must contain the file name the test asks for ('file.txt').
                if ReturnFileExists then
                    Response.Content.WriteFrom('{"odata.metadata":"","value":[' +
                        '{"odata.type":"SP.File","UniqueId":"44444444-4444-4444-4444-444444444444","Name":"file.txt","ServerRelativeUrl":"/sites/test/file.txt","Length":"100"}' +
                        ']}')
                else
                    Response.Content.WriteFrom('{"odata.metadata":"","value":[]}');
            else
                Response.Content.WriteFrom('{}');
        end;
    end;

    [HttpClientHandler]
    procedure DeleteHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        TrackRequest(Request);
        case true of
            IsContextInfo(Request):
                WriteContextInfoResponse(Response);
            else
                Response.Content.WriteFrom('{}');
        end;
    end;

    [HttpClientHandler]
    procedure ListDirectoriesHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        TrackRequest(Request);
        case true of
            Request.Path.Contains('/Folders') and (Request.RequestType = HttpRequestType::GET):
                Response.Content.WriteFrom(GetFoldersJson());
            else
                Response.Content.WriteFrom('{}');
        end;
    end;

    [HttpClientHandler]
    procedure CreateDirectoryHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        TrackRequest(Request);
        case true of
            IsContextInfo(Request):
                WriteContextInfoResponse(Response);
            Request.Path.Contains('/_api/Web/folders') and (Request.RequestType = HttpRequestType::POST):
                Response.Content.WriteFrom('{"d":{"__metadata":{"type":"SP.Folder"},"Name":"NewFolder","Exists":true}}');
            else
                Response.Content.WriteFrom('{}');
        end;
    end;

    [HttpClientHandler]
    procedure DirectoryExistsHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        TrackRequest(Request);
        case true of
            Request.Path.Contains('/Exists'):
                if ReturnFolderExists then
                    Response.Content.WriteFrom('{"value":true}')
                else
                    Response.Content.WriteFrom('{"value":false}');
            else
                Response.Content.WriteFrom('{}');
        end;
    end;

    #endregion

    #region Handler Helpers

    local procedure TrackRequest(Request: TestHttpRequestMessage)
    begin
        LastPath := Request.Path;
        LastMethod := Request.RequestType;
        if Request.RequestType = HttpRequestType::DELETE then
            DeletePath := Request.Path;
        if IsFileDownload(Request) then
            DownloadPath := Request.Path;
        if Request.Path.Contains('/Files/add(url=') then
            FileAddPath := Request.Path;
    end;

    local procedure IsContextInfo(Request: TestHttpRequestMessage): Boolean
    begin
        exit(Request.Path.Contains('contextinfo') and (Request.RequestType = HttpRequestType::POST));
    end;

    local procedure IsFileDownload(Request: TestHttpRequestMessage): Boolean
    begin
        // The URI builder escapes '$value' to '%24value' when building the download URL
        exit((Request.Path.Contains('/$value') or Request.Path.Contains('%24value')) and (Request.RequestType = HttpRequestType::GET));
    end;

    local procedure WriteContextInfoResponse(var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom('{"d":{"GetContextWebInformation":{"FormDigestValue":"fake-digest","FormDigestTimeoutSeconds":1800,"LibraryVersion":"16.0.0.0","SiteFullUrl":"https://contoso.sharepoint.com/sites/test","WebFullUrl":"https://contoso.sharepoint.com/sites/test"}}}');
    end;

    local procedure GetFilesJson(): Text
    begin
        // UniqueId is the primary key of the "SharePoint File" buffer — every entry needs a distinct value
        exit('{"odata.metadata":"","value":[' +
            '{"odata.type":"SP.File","UniqueId":"11111111-1111-1111-1111-111111111111","Name":"document.pdf","ServerRelativeUrl":"/sites/test/document.pdf","Length":"1024"},' +
            '{"odata.type":"SP.File","UniqueId":"22222222-2222-2222-2222-222222222222","Name":"budget.xlsx","ServerRelativeUrl":"/sites/test/budget.xlsx","Length":"2048"}' +
            ']}');
    end;

    local procedure GetFoldersJson(): Text
    begin
        exit('{"odata.metadata":"","value":[' +
            '{"odata.type":"SP.Folder","UniqueId":"33333333-3333-3333-3333-333333333333","Name":"Subfolder","ServerRelativeUrl":"/sites/test/Subfolder","ItemCount":0}' +
            ']}');
    end;

    local procedure GetFileItemJson(FileName: Text): Text
    begin
        exit('{"d":{"__metadata":{"type":"SP.File"},"Name":"' + FileName + '","ServerRelativeUrl":"/sites/test/' + FileName + '"}}');
    end;

    #endregion

    #region Setup

    local procedure Initialize(var Account: Record "Ext. SharePoint Account")
    begin
        Clear(RestHelper);
        RestHelper.SetAuthorizationForTest(DummySharePointAuthorization);

        LastPath := '';
        DownloadPath := '';
        FileAddPath := '';
        DeletePath := '';
        ReturnFileExists := false;
        ReturnFolderExists := false;

        Account.Init();
        Account.Id := CreateGuid();
        Account."SharePoint Url" := SharePointUrlLbl;
        Account."Tenant Id" := CreateGuid();
        Account."Client Id" := CreateGuid();
        Account."Authentication Type" := Enum::"Ext. SharePoint Auth Type"::"Client Secret";
        Account."Use legacy REST API" := true;
        Account.Insert();
    end;

    #endregion
}
