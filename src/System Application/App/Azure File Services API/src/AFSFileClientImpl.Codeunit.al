// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Storage.Files;

using System.Azure.Storage;
using System.Utilities;

codeunit 8951 "AFS File Client Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AFSOperationPayload: Codeunit "AFS Operation Payload";
        AFSHttpContentHelper: Codeunit "AFS HttpContent Helper";
        AFSWebRequestHelper: Codeunit "AFS Web Request Helper";
        AFSFormatHelper: Codeunit "AFS Format Helper";
        CreateFileOperationNotSuccessfulErr: Label 'Could not create file %1 in %2.', Comment = '%1 = File Name; %2 = File Share Name';
        PutFileOperationNotSuccessfulErr: Label 'Could not put file %1 ranges in %2.', Comment = '%1 = File Name; %2 = File Share Name';
        CreateDirectoryOperationNotSuccessfulErr: Label 'Could not create directory %1 in %2.', Comment = '%1 = Directory Name; %2 = File Share Name';
        GetFileOperationNotSuccessfulErr: Label 'Could not get File %1.', Comment = '%1 = File Path';
        GetFileMetadataOperationNotSuccessfulErr: Label 'Could not get File %1 metadata.', Comment = '%1 = File Path';
        SetFileMetadataOperationNotSuccessfulErr: Label 'Could not set File %1 metadata.', Comment = '%1 = File Path';
        CopyFileOperationNotSuccessfulErr: Label 'Could not copy File %1.', Comment = '%1 = File Path';
        DeleteFileOperationNotSuccessfulErr: Label 'Could not %3 File %1 in file share %2.', Comment = '%1 = File Name; %2 = File Share Name, %3 = Delete/Undelete';
        DeleteDirectoryOperationNotSuccessfulErr: Label 'Could not delete directory %1 in file share %2.', Comment = '%1 = File Name; %2 = File Share Name';
        AbortCopyFileOperationNotSuccessfulErr: Label 'Could not abort copy of File %1.', Comment = '%1 = File Path';
        LeaseOperationNotSuccessfulErr: Label 'Could not %1 lease for %2 %3.', Comment = '%1 = Lease Action, %2 = Type (File or Share), %3 = Name';
        ListDirectoryOperationNotSuccessfulErr: Label 'Could not list directory %1 in file share %2.', Comment = '%1 = Directory Name; %2 = File Share Name';
        ListHandlesOperationNotSuccessfulErr: Label 'Could not list handles of %1 in file share %2.', Comment = '%1 = Path; %2 = File Share Name';
        RenameFileOperationNotSuccessfulErr: Label 'Could not rename file %1 to %2 on file share %3.', Comment = '%1 = Source Path; %2 = Destination Path; %3 = File Share Name';
        ParameterMissingErr: Label 'You need to specify %1 (%2)', Comment = '%1 = Parameter Name, %2 = Header Identifer';
        LeaseAcquireLbl: Label 'acquire';
        LeaseBreakLbl: Label 'break';
        LeaseChangeLbl: Label 'change';
        LeaseReleaseLbl: Label 'release';
        FileLbl: Label 'File';

        AzureFileShareTxt: Label 'Azure File Share', Locked = true;
        CreatingFileTxt: Label 'Creating a new file at path %1.', Locked = true;
        FileCreatedTxt: Label 'File was created at path %1.', Locked = true;
        FileCreationFailedTxt: Label 'File at path %1 was not created. Operation returned error %2.', Locked = true;
        CreatingDirectoryTxt: Label 'Creating a new directory at path %1.', Locked = true;
        DirectoryCreatedTxt: Label 'Directory was created at path %1.', Locked = true;
        DirectoryCreationFailedTxt: Label 'Directory was not created at path %1. Operation returned error %2', Locked = true;
        DeletingDirectoryTxt: Label 'Deleting a directory at %1.', Locked = true;
        DirectoryDeletedTxt: Label 'Directory %1 was deleted.', Locked = true;
        DirectoryDeletionFailedTxt: Label 'Directory %1 was not deleted. Operation returned error %2.', Locked = true;
        ListingDirectoryTxt: Label 'Listing contents of directory %1.', Locked = true;
        DirectoryListedTxt: Label 'The contents of directory %1 were listed.', Locked = true;
        DirectoryListingFailedTxt: Label 'The contents of directory %1 could not be listed. Operation returned error %2.', Locked = true;
        ListingFileHandlesTxt: Label 'Listing open file handles for path %1.', Locked = true;
        FileHandlesListedTxt: Label 'The handles for path %1 were listed.', Locked = true;
        ListingFileHandlesFailedTxt: Label 'Handles for path %1 could not be listed. Operation returned error %2.', Locked = true;
        RenamingFileTxt: Label 'Renaming file from %1 to %2.', Locked = true;
        FileRenamedTxt: Label 'File %1 was renamed to %2.', Locked = true;
        FileRenamingFailedTxt: Label 'File %1 was not renamed to %2. Operation returned error %3.', Locked = true;
        GettingFileAsFileTxt: Label 'Getting file %1 as a directly downloaded file.', Locked = true;
        FileRetrievedAsFileTxt: Label 'File %1 was retrieved and downloaded.', Locked = true;
        GettingFileAsFileFailedTxt: Label 'File %1 was not downloaded. Operation returned error %2.', Locked = true;
        GettingFileAsStreamTxt: Label 'Getting file %1 as a stream.', Locked = true;
        FileRetrievedAsStreamTxt: Label 'File %1 was retrieved as a stream.', Locked = true;
        GettingFileAsStreamFailedTxt: Label 'File %1 was not retrieved as a stream. Operation returned error %2.', Locked = true;
        GettingFileAsTextTxt: Label 'Getting file %1 as text.', Locked = true;
        FileRetrievedAsTextTxt: Label 'File %1 was retrieved as text.', Locked = true;
        GettingFileAsTextFailedTxt: Label 'File %1 was not retrieved as text. Operation returned error %2.', Locked = true;
        GettingFileMetadataTxt: Label 'Getting file %1 metadata.', Locked = true;
        FileMetadataRetrievedTxt: Label 'File %1 metadata was retrieved.', Locked = true;
        GettingFileMetadataFailedTxt: Label 'File %1 metadata was not retrieved. Operation returned error %2.', Locked = true;
        SettingFileMetadataTxt: Label 'Setting file %1 metadata.', Locked = true;
        FileMetadataSetTxt: Label 'File %1 metadata was set.', Locked = true;
        SettingFileMetadataFailedTxt: Label 'File %1 metadata was not set. Operation returned error %2.', Locked = true;
        PuttingFileUITxt: Label 'Putting file through UI.', Locked = true;
        FileSentUITxt: Label 'File %1 was sent through UI.', Locked = true;
        PuttingFileUIFailedTxt: Label 'File %1 was not sent through UI. Operation returned error %2.', Locked = true;
        PuttingFileUIAbortedTxt: Label 'Putting file was aborted by the user.', Locked = true;
        PuttingFileStreamTxt: Label 'Putting file %1 as stream.', Locked = true;
        FileSentStreamTxt: Label 'File %1 was sent as stream.', Locked = true;
        PuttingFileStreamFailedTxt: Label 'File %1 was not sent as stream. Operation returned error %2.', Locked = true;
        PuttingFileTextTxt: Label 'Putting file %1 as text.', Locked = true;
        FileSentTextTxt: Label 'File %1 was sent as text.', Locked = true;
        PuttingFileTextFailedTxt: Label 'File %1 was not sent as text. Operation returned error %2.', Locked = true;
        DeletingFileTxt: Label 'Deleting file %1.', Locked = true;
        FileDeletedTxt: Label 'File %1 was deleted.', Locked = true;
        DeletingFileFailedTxt: Label 'File %1 was not deleted. Operation returned error %2.', Locked = true;
        FileCopyingTxt: Label 'Copying file %1 to %2.', Locked = true;
        FileCopiedTxt: Label 'File %1 was copied to %2.', Locked = true;
        FileCopyingFailedTxt: Label 'File %1 was not copied to %2. Operation returned error %3.', Locked = true;
        AbortingCopyTxt: Label 'Aborting copying operation with copy id %1 to file %2.', Locked = true;
        CopyingAbortedTxt: Label 'Copying operation with copy id %1 of file %2 was aborted.', Locked = true;
        AbortingCopyFailedTxt: Label 'Copying operation with copy id %1 of file %2 was not aborted. Operation returned error %3.', Locked = true;
        AcquiringLeaseTxt: Label 'Acquiring lease for file %1.', Locked = true;
        LeaseAcquiredTxt: Label 'Lease %1 for file %2 was acquired.', Locked = true;
        AcquiringLeaseFailedTxt: Label 'Lease for file %1 was not acquired. Operation returned error %2.', Locked = true;
        ReleasingLeaseTxt: Label 'Releasing lease %1 for file %2.', Locked = true;
        LeaseReleasedTxt: Label 'Lease %1 for file %2 was released.', Locked = true;
        ReleasingLeaseFailedTxt: Label 'Lease %1 for file %2 was not released. Operation returned error %3.', Locked = true;
        BreakingLeaseTxt: Label 'Breaking lease %1 for file %2.', Locked = true;
        LeaseBrokenTxt: Label 'Lease %1 for file %2 was broken.', Locked = true;
        BreakingLeaseFailedTxt: Label 'Lease %1 for file %2 was not broken. Operation returned error %3.', Locked = true;
        ChangingLeaseTxt: Label 'Changing lease %1 to %2 for file %3.', Locked = true;
        LeaseChangedTxt: Label 'Lease was changed to %1 for file %2.', Locked = true;
        ChangingLeaseFailedTxt: Label 'Lease was not changed to %1 for file %2. Operation returned error %3.', Locked = true;

    [NonDebuggable]
    procedure Initialize(StorageAccountName: Text; FileShare: Text; Path: Text; Authorization: Interface "Storage Service Authorization"; ApiVersion: Enum "Storage Service API Version")
    begin
        AFSOperationPayload.Initialize(StorageAccountName, FileShare, Path, Authorization, ApiVersion);
    end;

    procedure SetBaseUrl(BaseUrl: Text)
    begin
        AFSOperationPayload.SetBaseUrl(BaseUrl);
    end;

    procedure CreateDirectory(DirectoryPath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(CreatingDirectoryTxt, DirectoryPath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::CreateDirectory);
        AFSOperationPayload.SetPath(DirectoryPath);
        AFSOperationPayload.AddRequestHeader('x-ms-file-attributes', 'Directory');
        AFSOperationPayload.AddRequestHeader('x-ms-file-creation-time', 'now');
        AFSOperationPayload.AddRequestHeader('x-ms-file-last-write-time', 'now');
        AFSOperationPayload.AddRequestHeader('x-ms-file-permission', 'inherit');
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, StrSubstNo(CreateDirectoryOperationNotSuccessfulErr, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(DirectoryCreatedTxt, DirectoryPath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(DirectoryCreationFailedTxt, DirectoryPath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure DeleteDirectory(DirectoryPath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(DeletingDirectoryTxt, DirectoryPath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::DeleteDirectory);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(DirectoryPath);

        AFSOperationResponse := AFSWebRequestHelper.DeleteOperation(AFSOperationPayload, StrSubstNo(DeleteDirectoryOperationNotSuccessfulErr, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(DirectoryDeletedTxt, DirectoryPath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(DirectoryDeletionFailedTxt, DirectoryPath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);

        exit(AFSOperationResponse);
    end;

    procedure ListDirectory(DirectoryPath: Text[2048]; var AFSDirectoryContent: Record "AFS Directory Content"; PreserveDirectoryContent: Boolean; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSHelperLibrary: Codeunit "AFS Helper Library";
        AFSOperation: Enum "AFS Operation";
        ResponseText: Text;
        NodeList: XmlNodeList;
        DirectoryURI: Text;
    begin
        LogMessage('0000AFS', StrSubstNo(ListingDirectoryTxt, DirectoryPath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::ListDirectory);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(DirectoryPath);

        AFSOperationResponse := AFSWebRequestHelper.GetOperationAsText(AFSOperationPayload, ResponseText, StrSubstNo(ListDirectoryOperationNotSuccessfulErr, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(DirectoryListedTxt, DirectoryPath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(DirectoryListingFailedTxt, DirectoryPath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);

        NodeList := AFSHelperLibrary.CreateDirectoryContentNodeListFromResponse(ResponseText);
        DirectoryURI := AFSHelperLibrary.GetDirectoryPathFromResponse(ResponseText);

        AFSHelperLibrary.DirectoryContentNodeListToTempRecord(DirectoryURI, DirectoryPath, NodeList, PreserveDirectoryContent, AFSDirectoryContent);

        exit(AFSOperationResponse);
    end;

    procedure ListFileHandles(Path: Text; var AFSHandle: Record "AFS Handle"; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSHelperLibrary: Codeunit "AFS Helper Library";
        AFSOperation: Enum "AFS Operation";
        ResponseText: Text;
        NodeList: XmlNodeList;
    begin
        LogMessage('0000AFS', StrSubstNo(ListingFileHandlesTxt, Path), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::ListFileHandles);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(Path);

        AFSOperationResponse := AFSWebRequestHelper.GetOperationAsText(AFSOperationPayload, ResponseText, StrSubstNo(ListHandlesOperationNotSuccessfulErr, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(FileHandlesListedTxt, Path), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(ListingFileHandlesFailedTxt, Path, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);

        NodeList := AFSHelperLibrary.CreateHandleNodeListFromResponse(ResponseText);
        AFSHelperLibrary.HandleNodeListToTempRecord(NodeList, AFSHandle);
        AFSHandle."Next Marker" := CopyStr(AFSHelperLibrary.GetNextMarkerFromResponse(ResponseText), 1, MaxStrLen(AFSHandle."Next Marker"));
        AFSHandle.Modify();

        exit(AFSOperationResponse);
    end;

    procedure RenameFile(SourceFilePath: Text; DestinationFilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(RenamingFileTxt, SourceFilePath, DestinationFilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::RenameFile);
        AFSOperationPayload.AddRequestHeader('x-ms-file-rename-source', SourceFilePath);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(DestinationFilePath);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, StrSubstNo(RenameFileOperationNotSuccessfulErr, SourceFilePath, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(FileRenamedTxt, SourceFilePath, DestinationFilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(FileRenamingFailedTxt, SourceFilePath, DestinationFilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure CreateFile(FilePath: Text; InStream: InStream; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    begin
        exit(CreateFile(FilePath, AFSHttpContentHelper.GetContentLength(InStream), AFSOptionalParameters));
    end;

    procedure CreateFile(FilePath: Text; FileSize: Integer; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(CreatingFileTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::CreateFile);
        AFSOperationPayload.SetPath(FilePath);
        AFSOperationPayload.AddRequestHeader('x-ms-type', 'file');
        AFSOperationPayload.AddRequestHeader('x-ms-file-attributes', 'None');
        AFSOperationPayload.AddRequestHeader('x-ms-file-creation-time', 'now');
        AFSOperationPayload.AddRequestHeader('x-ms-file-last-write-time', 'now');
        AFSOperationPayload.AddRequestHeader('x-ms-file-permission', 'inherit');
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);

        AFSHttpContentHelper.AddFilePutContentHeaders(AFSOperationPayload, FileSize, '', 0, 0);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, StrSubstNo(CreateFileOperationNotSuccessfulErr, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(FileCreatedTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(FileCreationFailedTxt, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);

        exit(AFSOperationResponse);
    end;

    procedure GetFileAsFile(FilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        TargetInStream: InStream;
    begin
        LogMessage('0000AFS', StrSubstNo(GettingFileAsFileTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationResponse := GetFileAsStream(FilePath, TargetInStream, AFSOptionalParameters);

        if AFSOperationResponse.IsSuccessful() then begin
            FilePath := AFSOperationPayload.GetPath();
            DownloadFromStream(TargetInStream, '', '', '', FilePath);
            LogMessage('0000AFS', StrSubstNo(FileRetrievedAsFileTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        end else
            LogMessage('0000AFS', StrSubstNo(GettingFileAsFileFailedTxt, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure GetFileAsStream(FilePath: Text; var TargetInStream: InStream; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(GettingFileAsStreamTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);

        AFSOperationPayload.SetOperation(AFSOperation::GetFile);
        AFSOperationPayload.SetPath(FilePath);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);

        AFSOperationResponse := AFSWebRequestHelper.GetOperationAsStream(AFSOperationPayload, TargetInStream, StrSubstNo(GetFileOperationNotSuccessfulErr, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(FileRetrievedAsStreamTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(GettingFileAsStreamFailedTxt, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure GetFileAsText(FilePath: Text; var TargetText: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(GettingFileAsTextTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);

        AFSOperationPayload.SetOperation(AFSOperation::GetFile);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := AFSWebRequestHelper.GetOperationAsText(AFSOperationPayload, TargetText, StrSubstNo(GetFileOperationNotSuccessfulErr, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(FileRetrievedAsTextTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(GettingFileAsTextFailedTxt, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure GetFileMetadata(FilePath: Text; var TargetMetadata: Dictionary of [Text, Text]; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSHttpHeaderHelper: Codeunit "AFS HttpHeader Helper";
        AFSOperation: Enum "AFS Operation";
        TargetText: Text;
    begin
        LogMessage('0000AFS', StrSubstNo(GettingFileMetadataTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::GetFileMetadata);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := AFSWebRequestHelper.GetOperationAsText(AFSOperationPayload, TargetText, StrSubstNo(GetFileMetadataOperationNotSuccessfulErr, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(FileMetadataRetrievedTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(GettingFileMetadataFailedTxt, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        TargetMetadata := AFSHttpHeaderHelper.GetMetadataHeaders(AFSOperationResponse.GetHeaders());
        exit(AFSOperationResponse);
    end;

    procedure SetFileMetadata(FilePath: Text; Metadata: Dictionary of [Text, Text]; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
        MetadataKey: Text;
        MetadataValue: Text;
    begin
        LogMessage('0000AFS', StrSubstNo(SettingFileMetadataTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::SetFileMetadata);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(FilePath);

        foreach MetadataKey in Metadata.Keys() do begin
            MetadataValue := Metadata.Get(MetadataKey);
            if not MetadataKey.StartsWith('x-ms-meta-') then
                MetadataKey := 'x-ms-meta-' + MetadataKey;
            AFSOperationPayload.AddRequestHeader(MetadataKey, MetadataValue);
        end;

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, StrSubstNo(SetFileMetadataOperationNotSuccessfulErr, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(FileMetadataSetTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(SettingFileMetadataFailedTxt, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure PutFileUI(AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        Filename: Text;
        SourceInStream: InStream;
    begin
        LogMessage('0000AFS', PuttingFileUITxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        if UploadIntoStream('', '', '', FileName, SourceInStream) then begin
            AFSOperationResponse := PutFileStream(Filename, SourceInStream, AFSOptionalParameters);
            if AFSOperationResponse.IsSuccessful() then
                LogMessage('0000AFS', StrSubstNo(FileSentUITxt, Filename), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
            else
                LogMessage('0000AFS', StrSubstNo(PuttingFileUIFailedTxt, Filename, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        end else
            LogMessage('0000AFS', PuttingFileUIAbortedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure PutFileStream(FilePath: Text; var SourceInStream: InStream; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        SourceContentVariant: Variant;
    begin
        LogMessage('0000AFS', PuttingFileStreamTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        SourceContentVariant := SourceInStream;
        AFSOperationResponse := PutFile(FilePath, AFSOptionalParameters, SourceContentVariant);
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(FileSentStreamTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(PuttingFileStreamFailedTxt, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure PutFileText(FilePath: Text; SourceText: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        SourceContentVariant: Variant;
    begin
        LogMessage('0000AFS', PuttingFileTextTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        SourceContentVariant := SourceText;
        AFSOperationResponse := PutFile(FilePath, AFSOptionalParameters, SourceContentVariant);
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(FileSentTextTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(PuttingFileTextFailedTxt, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    local procedure PutFile(FilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"; var SourceContentVariant: Variant): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        TextTempBlob: Codeunit "Temp Blob";
        AFSOperation: Enum "AFS Operation";
        HttpContent: HttpContent;
        SourceInStream: InStream;
        SourceText: Text;
        SourceTextStream: InStream;
        SourceTextOutStream: OutStream;
    begin
        AFSOperationPayload.SetOperation(AFSOperation::PutRange);
        AFSOperationPayload.SetPath(FilePath);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);

        case true of
            SourceContentVariant.IsInStream():
                begin
                    SourceInStream := SourceContentVariant;

                    PutFileRanges(AFSOperationResponse, HttpContent, SourceInStream);
                end;
            SourceContentVariant.IsText():
                begin
                    SourceText := SourceContentVariant;
                    TextTempBlob.CreateOutStream(SourceTextOutStream);
                    SourceTextOutStream.WriteText(SourceText);
                    TextTempBlob.CreateInStream(SourceTextStream);

                    PutFileRanges(AFSOperationResponse, HttpContent, SourceTextStream);
                end;
        end;

        exit(AFSOperationResponse);
    end;

    local procedure PutFileRanges(var AFSOperationResponse: Codeunit "AFS Operation Response"; var HttpContent: HttpContent; var SourceInStream: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
        PuttingFileRangesTxt: Label 'Putting file %1 ranges.', Locked = true;
        FileRangeSentTxt: Label 'File %1 range: %2-%3 was sent.', Locked = true;
        PuttingFileRangesFailedTxt: Label 'File %1 range %2-%3 was not sent. Operation returned error %4', Locked = true;
        MaxAllowedRange: Integer;
        CurrentPostion: Integer;
        BytesToWrite: Integer;
        BytesLeftToWrite: Integer;
        SmallerStream: InStream;
        SmallerOutStream: OutStream;
        ResponseIndex: Integer;
    begin
        LogMessage('0000AFS', StrSubstNo(PuttingFileRangesTxt, AFSOperationPayload.GetPath()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        MaxAllowedRange := AFSHttpContentHelper.GetMaxRange();
        BytesLeftToWrite := AFSHttpContentHelper.GetContentLength(SourceInStream);
        CurrentPostion := 0;
        while BytesLeftToWrite > 0 do begin
            ResponseIndex += 1;
            if BytesLeftToWrite > MaxAllowedRange then
                BytesToWrite := MaxAllowedRange
            else
                BytesToWrite := BytesLeftToWrite;

            Clear(TempBlob);
            Clear(SmallerStream);
            Clear(SmallerOutStream);
            TempBlob.CreateOutStream(SmallerOutStream);
            CopyStream(SmallerOutStream, SourceInStream, BytesToWrite);
            TempBlob.CreateInStream(SmallerStream);
            AFSHttpContentHelper.AddFilePutContentHeaders(HttpContent, AFSOperationPayload, SmallerStream, CurrentPostion, CurrentPostion + BytesToWrite - 1);
            AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, HttpContent, StrSubstNo(PutFileOperationNotSuccessfulErr, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName()));
            if AFSOperationResponse.IsSuccessful() then
                LogMessage('0000AFS', StrSubstNo(FileRangeSentTxt, AFSOperationPayload.GetPath(), CurrentPostion, CurrentPostion + BytesToWrite - 1), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
            else
                LogMessage('0000AFS', StrSubstNo(PuttingFileRangesFailedTxt, AFSOperationPayload.GetPath(), CurrentPostion, CurrentPostion + BytesToWrite - 1, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
            CurrentPostion += BytesToWrite;
            BytesLeftToWrite -= BytesToWrite;

            // A way to handle multiple responses
            OnPutFileRangesAfterPutOperation(ResponseIndex, AFSOperationResponse);
        end;
    end;

    procedure DeleteFile(FilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(DeletingFileTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::DeleteFile);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := AFSWebRequestHelper.DeleteOperation(AFSOperationPayload, StrSubstNo(DeleteFileOperationNotSuccessfulErr, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName(), 'Delete'));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(FileDeletedTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(DeletingFileFailedTxt, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);

        exit(AFSOperationResponse);
    end;

    procedure CopyFile(SourceFileURI: Text; DestinationFilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(FileCopyingTxt, SourceFileURI, DestinationFilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::CopyFile);
        AFSOperationPayload.AddRequestHeader('x-ms-copy-source', SourceFileURI);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(DestinationFilePath);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, StrSubstNo(CopyFileOperationNotSuccessfulErr, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(FileCopiedTxt, SourceFileURI, DestinationFilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(FileCopyingFailedTxt, SourceFileURI, DestinationFilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure AbortCopyFile(DestinationFilePath: Text; CopyID: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(AbortingCopyTxt, CopyID, DestinationFilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::AbortCopyFile);
        AFSOperationPayload.AddRequestHeader('x-ms-copy-action', 'abort');
        AFSOperationPayload.AddUriParameter('copyid', CopyID);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(DestinationFilePath);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, StrSubstNo(AbortCopyFileOperationNotSuccessfulErr, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(CopyingAbortedTxt, CopyID, DestinationFilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(AbortingCopyFailedTxt, CopyID, DestinationFilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure FileAcquireLease(FilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"; ProposedLeaseId: Guid; var LeaseId: Guid): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(AcquiringLeaseTxt, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::LeaseFile);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := AcquireLease(AFSOptionalParameters, ProposedLeaseId, LeaseId, StrSubstNo(LeaseOperationNotSuccessfulErr, LeaseAcquireLbl, FileLbl, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(LeaseAcquiredTxt, LeaseId, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(AcquiringLeaseFailedTxt, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure FileReleaseLease(FilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"; LeaseId: Guid): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(ReleasingLeaseTxt, LeaseId, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::LeaseFile);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := ReleaseLease(AFSOptionalParameters, LeaseId, StrSubstNo(LeaseOperationNotSuccessfulErr, LeaseReleaseLbl, FileLbl, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(LeaseReleasedTxt, LeaseId, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(ReleasingLeaseFailedTxt, LeaseId, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure FileBreakLease(FilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"; LeaseId: Guid): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(BreakingLeaseTxt, LeaseId, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::LeaseFile);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := BreakLease(AFSOptionalParameters, LeaseId, StrSubstNo(LeaseOperationNotSuccessfulErr, LeaseBreakLbl, FileLbl, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(LeaseBrokenTxt, LeaseId, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(BreakingLeaseFailedTxt, LeaseId, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    procedure FileChangeLease(FilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"; var LeaseId: Guid; ProposedLeaseId: Guid): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        LogMessage('0000AFS', StrSubstNo(ChangingLeaseTxt, LeaseId, ProposedLeaseId, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        AFSOperationPayload.SetOperation(AFSOperation::LeaseFile);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := ChangeLease(AFSOptionalParameters, LeaseId, ProposedLeaseId, StrSubstNo(LeaseOperationNotSuccessfulErr, LeaseChangeLbl, FileLbl, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            LogMessage('0000AFS', StrSubstNo(LeaseChangedTxt, LeaseId, FilePath), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt)
        else
            LogMessage('0000AFS', StrSubstNo(ChangingLeaseFailedTxt, ProposedLeaseId, FilePath, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureFileShareTxt);
        exit(AFSOperationResponse);
    end;

    #region Private Lease-functions
    local procedure AcquireLease(AFSOptionalParameters: Codeunit "AFS Optional Parameters"; ProposedLeaseId: Guid; var LeaseId: Guid; OperationNotSuccessfulErr: Text): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        LeaseAction: Enum "AFS Lease Action";
        DurationSeconds: Integer;
    begin
        DurationSeconds := -1;

        AFSOptionalParameters.LeaseAction(LeaseAction::Acquire);
        AFSOptionalParameters.LeaseDuration(DurationSeconds);
        if not IsNullGuid(ProposedLeaseId) then
            AFSOptionalParameters.ProposedLeaseId(ProposedLeaseId);

        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, OperationNotSuccessfulErr);
        if AFSOperationResponse.IsSuccessful() then
            LeaseId := AFSFormatHelper.RemoveCurlyBracketsFromString(AFSOperationResponse.GetHeaderValueFromResponseHeaders('x-ms-lease-id'));
        exit(AFSOperationResponse);
    end;

    local procedure ReleaseLease(AFSOptionalParameters: Codeunit "AFS Optional Parameters"; LeaseId: Guid; OperationNotSuccessfulErr: Text): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        LeaseAction: Enum "AFS Lease Action";
    begin
        AFSOptionalParameters.LeaseAction(LeaseAction::Release);

        CheckGuidNotNull(LeaseId, 'LeaseId', 'x-ms-lease-id');

        AFSOptionalParameters.LeaseId(LeaseId);

        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, OperationNotSuccessfulErr);
        exit(AFSOperationResponse);
    end;

    local procedure BreakLease(AFSOptionalParameters: Codeunit "AFS Optional Parameters"; LeaseId: Guid; OperationNotSuccessfulErr: Text): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        LeaseAction: Enum "AFS Lease Action";
    begin
        AFSOptionalParameters.LeaseAction(LeaseAction::Break);

        if not IsNullGuid(LeaseId) then
            AFSOptionalParameters.LeaseId(LeaseId);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, OperationNotSuccessfulErr);
        exit(AFSOperationResponse);
    end;

    local procedure ChangeLease(AFSOptionalParameters: Codeunit "AFS Optional Parameters"; var LeaseId: Guid; ProposedLeaseId: Guid; OperationNotSuccessfulErr: Text): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        LeaseAction: Enum "AFS Lease Action";
    begin
        AFSOptionalParameters.LeaseAction(LeaseAction::Change);

        CheckGuidNotNull(LeaseId, 'LeaseId', 'x-ms-lease-id');
        CheckGuidNotNull(ProposedLeaseId, 'ProposedLeaseId', 'x-ms-proposed-lease-id');

        AFSOptionalParameters.LeaseId(LeaseId);
        AFSOptionalParameters.ProposedLeaseId(ProposedLeaseId);

        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, OperationNotSuccessfulErr);
        LeaseId := AFSFormatHelper.RemoveCurlyBracketsFromString(AFSOperationResponse.GetHeaderValueFromResponseHeaders('x-ms-lease-id'));
        exit(AFSOperationResponse);
    end;

    local procedure CheckGuidNotNull(ValueVariant: Variant; ParameterName: Text; HeaderIdentifer: Text)
    begin
        if ValueVariant.IsGuid() then
            if IsNullGuid(ValueVariant) then
                Error(ParameterMissingErr, ParameterName, HeaderIdentifer);
    end;
    #endregion

    [IntegrationEvent(false, false)]
    local procedure OnPutFileRangesAfterPutOperation(ResponseIndex: Integer; var AFSOperationResponse: Codeunit "AFS Operation Response")
    begin
    end;
}