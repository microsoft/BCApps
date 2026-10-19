// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.ExternalFileStorage;

using System.ExternalFileStorage;
using System.TestLibraries.Integration.Sharepoint;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 144586 "Ext. SP ResourcePath Test"
{
    Subtype = Test;
    TestHttpRequestPolicy = BlockOutboundRequests;
    TestPermissions = Disabled;

    var
        Connector: Codeunit "Ext. SharePoint Connector Impl";
        SharePointTestLibrary: Codeunit "SharePoint Test Library";
        Assert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDefaultRestBaseFolderPathFormatIsUrl()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        Initialize(Account);

        Assert.AreEqual(
            Enum::"Ext. SharePoint Path Format"::URL, Account."REST Base Folder Path Format",
            'New and upgraded accounts must default to the existing URL interpretation');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestEncodedAccountPathsDecodeOnlyConfiguration()
    var
        Account: Record "Ext. SharePoint Account";
        Stream: InStream;
    begin
        Initialize(Account);
        Account."SharePoint Url" := 'https://contoso.sharepoint.com/sites/Test%20Site';
        Account."Base Relative Folder Path" := '/sites/Test%20Site/Shared%20Documents';
        Account.Modify();

        Connector.GetFile(Account.Id, 'Invoice%20#50%.txt', Stream);

        AssertDecodedRequestPath('/sites/Test Site/Shared Documents/Invoice%20#50%.txt');
        Assert.IsTrue(SharePointTestLibrary.GetLastRawRequestUri().Contains('Invoice%2520%2350%25.txt'), 'The filename must retain its literal %20 sequence');
        Account.Get(Account.Id);
        Assert.AreEqual('/sites/Test%20Site/Shared%20Documents', Account."Base Relative Folder Path", 'Resolving a configured URL must not mutate the account');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDecodedBaseFolderPreservesLiteralPercentSequence()
    var
        Account: Record "Ext. SharePoint Account";
        Stream: InStream;
    begin
        Initialize(Account);
        Account."REST Base Folder Path Format" := Enum::"Ext. SharePoint Path Format"::"Decoded Path";
        Account."Base Relative Folder Path" := '/sites/test/Reports%20Archive';
        Account.Modify();

        Connector.GetFile(Account.Id, 'Invoice%23.pdf', Stream);

        AssertDecodedRequestPath('/sites/test/Reports%20Archive/Invoice%23.pdf');
        Assert.IsTrue(SharePointTestLibrary.GetLastRawRequestUri().Contains('Reports%2520Archive'), 'The decoded base folder must retain literal %20');
        Assert.IsTrue(SharePointTestLibrary.GetLastRawRequestUri().Contains('Invoice%2523.pdf'), 'The filename must retain literal %23');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestEncodedBaseFolderIsDecodedOnce()
    var
        Account: Record "Ext. SharePoint Account";
        Stream: InStream;
    begin
        Initialize(Account);
        Account."Base Relative Folder Path" := 'Shared%20Documents/Reports%2520Archive';
        Account.Modify();

        Connector.GetFile(Account.Id, 'file.txt', Stream);

        AssertDecodedRequestPath('/sites/test/Shared Documents/Reports%20Archive/file.txt');
        Assert.IsTrue(SharePointTestLibrary.GetLastRawRequestUri().Contains('Reports%2520Archive'), 'The encoded configuration must only be decoded once');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestConnectorSpecialCharacterFileAndFolderOperations()
    var
        Account: Record "Ext. SharePoint Account";
        TempContent: Record "File Account Content" temporary;
        Pagination: Codeunit "File Pagination Data";
        TempBlob: Codeunit "Temp Blob";
        Stream: InStream;
        ContentOutStream: OutStream;
        FileContent: Text;
        FileName: Text;
        BaseFolder: Text;
    begin
        Initialize(Account);
        Account."REST Base Folder Path Format" := Enum::"Ext. SharePoint Path Format"::"Decoded Path";
        BaseFolder := '/sites/test/Reports #50%/Literal%20Folder';
        Assert.IsTrue(StrLen(BaseFolder) <= MaxStrLen(Account."Base Relative Folder Path"), 'The complete special-character fixture must fit the account base folder without truncation');
        Account."Base Relative Folder Path" := CopyStr(BaseFolder, 1, MaxStrLen(Account."Base Relative Folder Path"));
        Account.Modify();
        FileName := 'Invoice #50%23.pdf';
        SharePointTestLibrary.SetResourcePathFileName(FileName);
        TempBlob.CreateOutStream(ContentOutStream);
        ContentOutStream.WriteText('content');
        TempBlob.CreateInStream(Stream);

        Connector.CreateFile(Account.Id, FileName, Stream);
        AssertDecodedRequestPath(BaseFolder);
        Assert.IsTrue(SharePointTestLibrary.GetLastRawRequestUri().Contains('/Files/AddUsingPath(decodedurl='), 'Upload must use AddUsingPath');
        Assert.IsTrue(SharePointTestLibrary.GetLastRawRequestUri().Contains('Invoice%20%2350%2523.pdf'), 'Upload must not decode the filename');

        Connector.GetFile(Account.Id, FileName, Stream);
        Stream.ReadText(FileContent);
        Assert.AreEqual('Dummy file content', FileContent, 'Content must survive the connector interface');
        AssertDecodedRequestPath(BaseFolder + '/' + FileName);

        Assert.IsTrue(Connector.FileExists(Account.Id, FileName), 'FileExists must match the literal special-character filename');
        AssertDecodedRequestPath(BaseFolder);
        Assert.IsFalse(Connector.FileExists(Account.Id, 'document.pdf'), 'FileExists must not match a different filename');
        AssertDecodedRequestPath(BaseFolder);

        Connector.ListFiles(Account.Id, '', Pagination, TempContent);
        Assert.RecordCount(TempContent, 1);
        AssertDecodedRequestPath(BaseFolder);

        SharePointTestLibrary.SetResourcePathFileName(FileName);
        Connector.CopyFile(Account.Id, FileName, 'Copy #50%23.pdf');
        Assert.IsTrue(SharePointTestLibrary.GetLastRawRequestUri().Contains('/Files/AddUsingPath(decodedurl='), 'Copy must finish by creating the target, not deleting the source');
        Assert.IsTrue(SharePointTestLibrary.GetLastRawRequestUri().Contains('Copy%20%2350%2523.pdf'), 'Copy must preserve the target filename');
        AssertDecodedRequestPath(BaseFolder);
        Assert.IsTrue(SharePointTestLibrary.GetLastDownloadRequestUri().Contains('Invoice%20%2350%2523.pdf'), 'Copy must download the literal source filename');
        Assert.AreEqual('', SharePointTestLibrary.GetLastDeleteRequestUri(), 'Copy must not delete the source');

        Connector.MoveFile(Account.Id, FileName, 'Move #50%23.pdf');
        Assert.IsTrue(SharePointTestLibrary.GetLastRawRequestUri().Contains('/GetFileByServerRelativePath('), 'Move must finish by addressing the source');
        AssertDecodedRequestPath(BaseFolder + '/' + FileName);
        Assert.IsTrue(SharePointTestLibrary.GetLastFileAddRequestUri().Contains('Move%20%2350%2523.pdf'), 'Move must create the literal target filename');
        Assert.IsTrue(SharePointTestLibrary.GetLastDeleteRequestUri().Contains('Invoice%20%2350%2523.pdf'), 'Move must delete the literal source filename');

        Connector.DeleteFile(Account.Id, FileName);
        AssertDecodedRequestPath(BaseFolder + '/' + FileName);
        Assert.IsTrue(SharePointTestLibrary.GetLastDeleteRequestUri().Contains('Invoice%20%2350%2523.pdf'), 'DeleteFile must issue a DELETE');

        Connector.CreateDirectory(Account.Id, 'New #50%');
        AssertDecodedRequestPath(BaseFolder + '/New #50%');
        Assert.IsTrue(SharePointTestLibrary.GetLastRawRequestUri().Contains('/Folders/AddUsingPath('), 'Folder creation must use AddUsingPath');

        Assert.IsTrue(Connector.DirectoryExists(Account.Id, 'New #50%'), 'DirectoryExists must parse a positive response');
        AssertDecodedRequestPath(BaseFolder + '/New #50%');
        SharePointTestLibrary.SetFolderExistsResponse(false);
        Assert.IsFalse(Connector.DirectoryExists(Account.Id, 'New #50%'), 'DirectoryExists must parse a negative response');

        TempContent.DeleteAll();
        Clear(Pagination);
        Connector.ListDirectories(Account.Id, '', Pagination, TempContent);
        Assert.RecordCount(TempContent, 1);
        AssertDecodedRequestPath(BaseFolder);

        Connector.DeleteDirectory(Account.Id, 'New #50%');
        AssertDecodedRequestPath(BaseFolder + '/New #50%');
        Assert.IsTrue(SharePointTestLibrary.GetLastDeleteRequestUri().Contains('/GetFolderByServerRelativePath('), 'DeleteDirectory must issue a DELETE for the folder');
    end;

    local procedure AssertDecodedRequestPath(ExpectedPath: Text)
    begin
        Assert.IsTrue(
            SharePointTestLibrary.GetLastRequestUri().Contains('decodedurl=''' + ExpectedPath + ''''),
            'The ResourcePath parameter must preserve the decoded path. Actual: ' + SharePointTestLibrary.GetLastRawRequestUri());
    end;

    local procedure Initialize(var Account: Record "Ext. SharePoint Account")
    begin
        if not IsInitialized then begin
            BindSubscription(SharePointTestLibrary);
            IsInitialized := true;
        end;
        SharePointTestLibrary.SetFolderExistsResponse(true);
        SharePointTestLibrary.SetResourcePathFileName('');

        Account.Init();
        Account.Id := CreateGuid();
        Account."SharePoint Url" := 'https://contoso.sharepoint.com/sites/test';
        Account."Tenant Id" := CreateGuid();
        Account."Client Id" := CreateGuid();
        Account.SetClientSecret(SecretStrSubstNo('mock-client-secret'));
        Account.Insert();
    end;
}
