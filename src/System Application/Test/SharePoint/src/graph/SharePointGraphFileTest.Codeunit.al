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

codeunit 132983 "SharePoint Graph File Test"
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
    procedure TestUploadFile()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        TempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        FileOutStream: OutStream;
        ExpectedSize: BigInteger;
    begin
        // [GIVEN] Mock response for UploadFile
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(201);
        MockHttpContent := HttpContent.Create(GetUploadFileResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Preparing a file and calling UploadFile
        TempBlob.CreateOutStream(FileOutStream);
        FileOutStream.WriteText('Test content for uploaded file');
        TempBlob.CreateInStream(FileInStream);

        SharePointGraphResponse := SharePointGraphClient.UploadFile('Documents', 'Test.txt', FileInStream, TempDriveItem);

        // [THEN] Operation should succeed and return correct data
        ExpectedSize := 25;
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'UploadFile should succeed');
        LibraryAssert.AreEqual('Test.txt', TempDriveItem.Name, 'Name should match');
        LibraryAssert.IsFalse(TempDriveItem.IsFolder, 'Should be a file');
        LibraryAssert.AreEqual('01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ', TempDriveItem.Id, 'Id should match');
        LibraryAssert.AreEqual(ExpectedSize, TempDriveItem.Size, 'Size should match');
    end;

    [Test]
    procedure TestDownloadFile()
    var
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        TempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        Content: Text;
    begin
        // [GIVEN] Mock response for DownloadFile
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create('Downloaded file content');
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling DownloadFile
        SharePointGraphResponse := SharePointGraphClient.DownloadFile('01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ', TempBlob);

        // [THEN] Operation should succeed and return the file content
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'DownloadFile should succeed');
        TempBlob.CreateInStream(FileInStream);
        FileInStream.ReadText(Content);
        LibraryAssert.AreEqual('Downloaded file content', Content, 'File content should match');
    end;

    [Test]
    procedure TestDownloadFileByPath()
    var
        TempBlob: Codeunit "Temp Blob";
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        FileInStream: InStream;
        Content: Text;
    begin
        // [GIVEN] Mock response for DownloadFileByPath
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create('Downloaded file content by path');
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling DownloadFileByPath
        SharePointGraphResponse := SharePointGraphClient.DownloadFileByPath('Documents/Test.txt', TempBlob);

        // [THEN] Operation should succeed and return the file content
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'DownloadFileByPath should succeed');
        TempBlob.CreateInStream(FileInStream);
        FileInStream.ReadText(Content);
        LibraryAssert.AreEqual('Downloaded file content by path', Content, 'File content should match');
    end;

    [Test]
    procedure TestGetDriveItemByPath()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        ExpectedSize: BigInteger;
    begin
        // [GIVEN] Mock response for GetDriveItemByPath
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetDriveItemByPathResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetDriveItemByPath
        SharePointGraphResponse := SharePointGraphClient.GetDriveItemByPath('Documents/Report.docx', TempDriveItem);

        // [THEN] Operation should succeed and return correct data
        ExpectedSize := 45321;
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetDriveItemByPath should succeed');
        LibraryAssert.AreEqual('Report.docx', TempDriveItem.Name, 'Name should match');
        LibraryAssert.IsFalse(TempDriveItem.IsFolder, 'Should be a file');
        LibraryAssert.AreEqual('01EZJNRYQYENJ6SXVPCNBYA3QZRHKJWLNZ', TempDriveItem.Id, 'Id should match');
        LibraryAssert.AreEqual(ExpectedSize, TempDriveItem.Size, 'Size should match');
    end;

    [Test]
    procedure TestGetFolderItems()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        // [GIVEN] Mock response for GetFolderItems
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetFolderItemsResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // [WHEN] Calling GetFolderItems
        SharePointGraphResponse := SharePointGraphClient.GetFolderItems('01EZJNRYOELVX64AZW4BA3DHJXMFBQZXPM', TempDriveItem);

        // [THEN] Operation should succeed and return correct data
        LibraryAssert.IsTrue(SharePointGraphResponse.IsSuccessful(), 'GetFolderItems should succeed');
        LibraryAssert.AreEqual(3, TempDriveItem.Count(), 'Should return 3 items');

        TempDriveItem.FindSet();
        LibraryAssert.AreEqual('Subfolder', TempDriveItem.Name, 'Name should match');
        LibraryAssert.IsTrue(TempDriveItem.IsFolder, 'Should be a folder');

        TempDriveItem.Next();
        LibraryAssert.AreEqual('Presentation.pptx', TempDriveItem.Name, 'Name should match');
        LibraryAssert.IsFalse(TempDriveItem.IsFolder, 'Should be a file');

        TempDriveItem.Next();
        LibraryAssert.AreEqual('Budget.xlsx', TempDriveItem.Name, 'Name should match');
        LibraryAssert.IsFalse(TempDriveItem.IsFolder, 'Should be a file');
    end;

    [Test]
    procedure TestUploadFileNameEncoded()
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
        RequestUri: Text;
    begin
        // [GIVEN] Mock response and a file with special characters in its name
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(201);
        MockHttpContent := HttpContent.Create(GetDriveItemResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        TempBlob.CreateOutStream(FileOutStream);
        FileOutStream.WriteText('Test file content');
        TempBlob.CreateInStream(FileInStream);

        // [WHEN] Calling UploadFile with special characters in folder path and file name
        SharePointGraphResponse := SharePointGraphClient.UploadFile('My Folder', 'Report #2.txt', FileInStream, TempDriveItem);

        // [THEN] Special characters in both folder name and file name should be encoded
        SharePointGraphTestLibrary.GetHttpRequestMessage(HttpRequestMessage);
        RequestUri := HttpRequestMessage.GetRequestUri();
        LibraryAssert.IsTrue(RequestUri.Contains('My%20Folder'), 'Space in folder name should be percent-encoded');
        LibraryAssert.IsTrue(RequestUri.Contains('%23'), 'Hash in file name should be percent-encoded');
    end;

    [Test]
    procedure TestUploadRejectsUntrustedUploadUrl()
    var
        TempDriveItem: Record "SharePoint Graph Drive Item" temporary;
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        TempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        FileOutStream: OutStream;
    begin
        // [GIVEN] Mock CreateUploadSession response with an untrusted upload URL
        Initialize();
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetUploadSessionResponseWithUntrustedUrl());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        SharePointGraphTestLibrary.SetMockResponse(MockHttpResponseMessage);

        // Create a file stream with content
        TempBlob.CreateOutStream(FileOutStream);
        FileOutStream.WriteText('Test content for chunked upload');
        TempBlob.CreateInStream(FileInStream);

        // [WHEN] Calling UploadLargeFile (which internally calls UploadChunk with the untrusted URL)
        SharePointGraphResponse := SharePointGraphClient.UploadLargeFile('Documents', 'test.txt', FileInStream, TempDriveItem);

        // [THEN] Operation should fail because the upload URL points to an untrusted host
        LibraryAssert.IsFalse(SharePointGraphResponse.IsSuccessful(), 'UploadLargeFile should fail for untrusted upload URL');
        LibraryAssert.IsTrue(SharePointGraphResponse.GetError().Contains('Upload URL points to an untrusted host'), 'Error should mention untrusted host');
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

    local procedure GetUploadSessionResponseWithUntrustedUrl(): Text
    var
        ResponseText: TextBuilder;
    begin
        ResponseText.Append('{');
        ResponseText.Append('  "uploadUrl": "https://evil.com/upload-session-abc123",');
        ResponseText.Append('  "expirationDateTime": "2025-12-31T23:59:59.000Z"');
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

    local procedure GetDriveItemByPathResponse(): Text
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
        ResponseText.Append('    },');
        ResponseText.Append('    {');
        ResponseText.Append('      "id": "01EZJNRYOELVX64AZW4BA3DHJXMFBQZXP3",');
        ResponseText.Append('      "name": "Budget.xlsx",');
        ResponseText.Append('      "createdDateTime": "2022-11-10T09:33:44Z",');
        ResponseText.Append('      "lastModifiedDateTime": "2023-06-05T16:19:22Z",');
        ResponseText.Append('      "webUrl": "https://contoso.sharepoint.com/sites/test/Shared%20Documents/Folder%201/Budget.xlsx",');
        ResponseText.Append('      "file": {');
        ResponseText.Append('        "mimeType": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",');
        ResponseText.Append('        "hashes": {');
        ResponseText.Append('          "quickXorHash": "JU5GC7lcTJbHDrcPKJc8rJtEhCo="');
        ResponseText.Append('        }');
        ResponseText.Append('      },');
        ResponseText.Append('      "size": 52347');
        ResponseText.Append('    }');
        ResponseText.Append('  ]');
        ResponseText.Append('}');
        exit(ResponseText.ToText());
    end;
}