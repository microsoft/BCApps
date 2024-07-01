// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Storage.Files;

using System.Azure.Storage;
using System.Utilities;
using System.Telemetry;

codeunit 8951 "AFS File Client Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AFSOperationPayload: Codeunit "AFS Operation Payload Impl.";
        AFSHttpContentHelper: Codeunit "AFS HttpContent Helper";
        AFSWebRequestHelper: Codeunit "AFS Web Request Helper";
        AFSFormatHelper: Codeunit "AFS Format Helper";
        Telemetry: Codeunit Telemetry;
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

        CreatingFileTxt: Label 'Creating a new file.', Locked = true;
        FileCreatedTxt: Label 'File was created.', Locked = true;
        FileCreationFailedTxt: Label 'File was not created. Operation returned error %1.', Locked = true;
        CreatingDirectoryTxt: Label 'Creating a new directory.', Locked = true;
        DirectoryCreatedTxt: Label 'Directory was created.', Locked = true;
        DirectoryCreationFailedTxt: Label 'Directory was not created. Operation returned error %1', Locked = true;
        DeletingDirectoryTxt: Label 'Deleting a directory.', Locked = true;
        DirectoryDeletedTxt: Label 'Directory was deleted.', Locked = true;
        DirectoryDeletionFailedTxt: Label 'Directory was not deleted. Operation returned error %1.', Locked = true;
        ListingDirectoryTxt: Label 'Listing contents of directory.', Locked = true;
        DirectoryListedTxt: Label 'The contents of directory were listed.', Locked = true;
        DirectoryListingFailedTxt: Label 'The contents of directory could not be listed. Operation returned error %1.', Locked = true;
        ListingFileHandlesTxt: Label 'Listing open file handles.', Locked = true;
        FileHandlesListedTxt: Label 'The handles were listed.', Locked = true;
        ListingFileHandlesFailedTxt: Label 'Handles could not be listed. Operation returned error %1.', Locked = true;
        RenamingFileTxt: Label 'Renaming file.', Locked = true;
        FileRenamedTxt: Label 'File was renamed.', Locked = true;
        FileRenamingFailedTxt: Label 'File was not renamed. Operation returned error %1.', Locked = true;
        GettingFileAsFileTxt: Label 'Getting file as a directly downloaded file.', Locked = true;
        FileRetrievedAsFileTxt: Label 'File was retrieved and downloaded.', Locked = true;
        GettingFileAsFileFailedTxt: Label 'File was not downloaded. Operation returned error %1.', Locked = true;
        GettingFileAsStreamTxt: Label 'Getting file as a stream.', Locked = true;
        FileRetrievedAsStreamTxt: Label 'File was retrieved as a stream.', Locked = true;
        GettingFileAsStreamFailedTxt: Label 'File was not retrieved as a stream. Operation returned error %1.', Locked = true;
        GettingFileAsTextTxt: Label 'Getting file as text.', Locked = true;
        FileRetrievedAsTextTxt: Label 'File was retrieved as text.', Locked = true;
        GettingFileAsTextFailedTxt: Label 'File was not retrieved as text. Operation returned error %1.', Locked = true;
        GettingFileMetadataTxt: Label 'Getting file metadata.', Locked = true;
        FileMetadataRetrievedTxt: Label 'File metadata was retrieved.', Locked = true;
        GettingFileMetadataFailedTxt: Label 'File metadata was not retrieved. Operation returned error %1.', Locked = true;
        SettingFileMetadataTxt: Label 'Setting file metadata.', Locked = true;
        FileMetadataSetTxt: Label 'File metadata was set.', Locked = true;
        SettingFileMetadataFailedTxt: Label 'File metadata was not set. Operation returned error %1.', Locked = true;
        PuttingFileUITxt: Label 'Putting file through UI.', Locked = true;
        FileSentUITxt: Label 'File was sent through UI.', Locked = true;
        PuttingFileUIFailedTxt: Label 'File was not sent through UI. Operation returned error %1.', Locked = true;
        PuttingFileUIAbortedTxt: Label 'Putting file was aborted by the user.', Locked = true;
        PuttingFileStreamTxt: Label 'Putting file as stream.', Locked = true;
        FileSentStreamTxt: Label 'File was sent as stream.', Locked = true;
        PuttingFileStreamFailedTxt: Label 'File was not sent as stream. Operation returned error %1.', Locked = true;
        PuttingFileTextTxt: Label 'Putting file as text.', Locked = true;
        FileSentTextTxt: Label 'File was sent as text.', Locked = true;
        PuttingFileTextFailedTxt: Label 'File was not sent as text. Operation returned error %1.', Locked = true;
        DeletingFileTxt: Label 'Deleting file.', Locked = true;
        FileDeletedTxt: Label 'File was deleted.', Locked = true;
        DeletingFileFailedTxt: Label 'File was not deleted. Operation returned error %1.', Locked = true;
        FileCopyingTxt: Label 'Copying file.', Locked = true;
        FileCopiedTxt: Label 'File was copied.', Locked = true;
        FileCopyingFailedTxt: Label 'File was not copied. Operation returned error %1.', Locked = true;
        AbortingCopyTxt: Label 'Aborting copying operation with copy id %1.', Locked = true;
        CopyingAbortedTxt: Label 'Copying operation with copy id %1 was aborted.', Locked = true;
        AbortingCopyFailedTxt: Label 'Copying operation with copy id %1 was not aborted. Operation returned error %2.', Locked = true;
        AcquiringLeaseTxt: Label 'Acquiring lease for file.', Locked = true;
        LeaseAcquiredTxt: Label 'Lease %1 for file was acquired.', Locked = true;
        AcquiringLeaseFailedTxt: Label 'Lease for file was not acquired. Operation returned error %1.', Locked = true;
        ReleasingLeaseTxt: Label 'Releasing lease %1 for file.', Locked = true;
        LeaseReleasedTxt: Label 'Lease %1 for file was released.', Locked = true;
        ReleasingLeaseFailedTxt: Label 'Lease %1 for file was not released. Operation returned error %2.', Locked = true;
        BreakingLeaseTxt: Label 'Breaking lease %1 for file.', Locked = true;
        LeaseBrokenTxt: Label 'Lease %1 for file was broken.', Locked = true;
        BreakingLeaseFailedTxt: Label 'Lease %1 for file was not broken. Operation returned error %2.', Locked = true;
        ChangingLeaseTxt: Label 'Changing lease %1 to %2 for file.', Locked = true;
        LeaseChangedTxt: Label 'Lease was changed to %1 for file.', Locked = true;
        ChangingLeaseFailedTxt: Label 'Lease was not changed to %1 for file. Operation returned error %2.', Locked = true;
        PuttingFileRangesTxt: Label 'Putting file ranges.', Locked = true;
        FileRangeSentTxt: Label 'File range: %1-%2 was sent.', Locked = true;
        PuttingFileRangesFailedTxt: Label 'File range %1-%2 was not sent. Operation returned error %3', Locked = true;

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
        Telemetry.LogMessage('0000M1R', CreatingDirectoryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::CreateDirectory);
        AFSOperationPayload.SetPath(DirectoryPath);
        AFSOperationPayload.AddRequestHeader('x-ms-file-attributes', 'Directory');
        AFSOperationPayload.AddRequestHeader('x-ms-file-creation-time', 'now');
        AFSOperationPayload.AddRequestHeader('x-ms-file-last-write-time', 'now');
        AFSOperationPayload.AddRequestHeader('x-ms-file-permission', 'inherit');
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, StrSubstNo(CreateDirectoryOperationNotSuccessfulErr, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M1S', DirectoryCreatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M1T', StrSubstNo(DirectoryCreationFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
        exit(AFSOperationResponse);
    end;

    procedure DeleteDirectory(DirectoryPath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        Telemetry.LogMessage('0000M1U', DeletingDirectoryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::DeleteDirectory);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(DirectoryPath);

        AFSOperationResponse := AFSWebRequestHelper.DeleteOperation(AFSOperationPayload, StrSubstNo(DeleteDirectoryOperationNotSuccessfulErr, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M1V', DirectoryDeletedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M1W', StrSubstNo(DirectoryDeletionFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);

        exit(AFSOperationResponse);
    end;

    procedure ListDirectory(DirectoryPath: Text[2048]; var AFSDirectoryContent: Record "AFS Directory Content"; PreserveDirectoryContent: Boolean; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSHelperLibrary: Codeunit "XML Utility Impl.";
        AFSOperation: Enum "AFS Operation";
        ResponseText: Text;
        NodeList: XmlNodeList;
        DirectoryURI: Text;
    begin
        Telemetry.LogMessage('0000M1X', ListingDirectoryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::ListDirectory);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(DirectoryPath);

        AFSOperationResponse := AFSWebRequestHelper.GetOperationAsText(AFSOperationPayload, ResponseText, StrSubstNo(ListDirectoryOperationNotSuccessfulErr, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M1Y', DirectoryListedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M1Z', StrSubstNo(DirectoryListingFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);

        NodeList := AFSHelperLibrary.CreateDirectoryContentNodeListFromResponse(ResponseText);
        DirectoryURI := AFSHelperLibrary.GetDirectoryPathFromResponse(ResponseText);

        AFSHelperLibrary.DirectoryContentNodeListToTempRecord(DirectoryURI, DirectoryPath, NodeList, PreserveDirectoryContent, AFSDirectoryContent);

        if AFSOperationResponse.IsSuccessful() and (AFSDirectoryContent."Entry No." <> 0) then begin
            AFSDirectoryContent."Next Marker" := CopyStr(AFSHelperLibrary.GetNextMarkerFromResponse(ResponseText), 1, MaxStrLen(AFSDirectoryContent."Next Marker"));
            AFSDirectoryContent.Modify();
        end;

        exit(AFSOperationResponse);
    end;

    procedure ListFileHandles(Path: Text; var AFSHandle: Record "AFS Handle"; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSHelperLibrary: Codeunit "XML Utility Impl.";
        AFSOperation: Enum "AFS Operation";
        ResponseText: Text;
        NodeList: XmlNodeList;
    begin
        Telemetry.LogMessage('0000M20', ListingFileHandlesTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::ListFileHandles);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(Path);

        AFSOperationResponse := AFSWebRequestHelper.GetOperationAsText(AFSOperationPayload, ResponseText, StrSubstNo(ListHandlesOperationNotSuccessfulErr, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M21', FileHandlesListedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M22', StrSubstNo(ListingFileHandlesFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);

        NodeList := AFSHelperLibrary.CreateHandleNodeListFromResponse(ResponseText);
        AFSHelperLibrary.HandleNodeListToTempRecord(NodeList, AFSHandle);

        if AFSOperationResponse.IsSuccessful() and (AFSHandle."Entry No." <> 0) then begin
            AFSHandle."Next Marker" := CopyStr(AFSHelperLibrary.GetNextMarkerFromResponse(ResponseText), 1, MaxStrLen(AFSHandle."Next Marker"));
            AFSHandle.Modify();
        end;

        exit(AFSOperationResponse);
    end;

    procedure RenameFile(SourceFilePath: Text; DestinationFilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        Telemetry.LogMessage('0000M23', RenamingFileTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::RenameFile);
        AFSOperationPayload.AddRequestHeader('x-ms-file-rename-source', SourceFilePath);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(DestinationFilePath);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, StrSubstNo(RenameFileOperationNotSuccessfulErr, SourceFilePath, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M24', FileRenamedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M25', StrSubstNo(FileRenamingFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
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
        Telemetry.LogMessage('0000M26', CreatingFileTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
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
            Telemetry.LogMessage('0000M27', FileCreatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M28', StrSubstNo(FileCreationFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);

        exit(AFSOperationResponse);
    end;

    procedure GetFileAsFile(FilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        TargetInStream: InStream;
    begin
        Telemetry.LogMessage('0000M29', GettingFileAsFileTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationResponse := GetFileAsStream(FilePath, TargetInStream, AFSOptionalParameters);

        if AFSOperationResponse.IsSuccessful() then begin
            FilePath := AFSOperationPayload.GetPath();
            DownloadFromStream(TargetInStream, '', '', '', FilePath);
            Telemetry.LogMessage('0000M2A', FileRetrievedAsFileTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        end else
            Telemetry.LogMessage('0000M2B', StrSubstNo(GettingFileAsFileFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
        exit(AFSOperationResponse);
    end;

    procedure GetFileAsStream(FilePath: Text; var TargetInStream: InStream; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        Telemetry.LogMessage('0000M2C', GettingFileAsStreamTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);

        AFSOperationPayload.SetOperation(AFSOperation::GetFile);
        AFSOperationPayload.SetPath(FilePath);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);

        AFSOperationResponse := AFSWebRequestHelper.GetOperationAsStream(AFSOperationPayload, TargetInStream, StrSubstNo(GetFileOperationNotSuccessfulErr, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M2D', FileRetrievedAsStreamTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M2E', StrSubstNo(GettingFileAsStreamFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
        exit(AFSOperationResponse);
    end;

    procedure GetFileAsText(FilePath: Text; var TargetText: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        Telemetry.LogMessage('0000M2F', GettingFileAsTextTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);

        AFSOperationPayload.SetOperation(AFSOperation::GetFile);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := AFSWebRequestHelper.GetOperationAsText(AFSOperationPayload, TargetText, StrSubstNo(GetFileOperationNotSuccessfulErr, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M2G', FileRetrievedAsTextTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M2H', StrSubstNo(GettingFileAsTextFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
        exit(AFSOperationResponse);
    end;

    procedure GetFileMetadata(FilePath: Text; var TargetMetadata: Dictionary of [Text, Text]; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSHttpHeaderHelper: Codeunit "AFS HttpHeader Helper";
        AFSOperation: Enum "AFS Operation";
        TargetText: Text;
    begin
        Telemetry.LogMessage('0000M2I', GettingFileMetadataTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::GetFileMetadata);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := AFSWebRequestHelper.GetOperationAsText(AFSOperationPayload, TargetText, StrSubstNo(GetFileMetadataOperationNotSuccessfulErr, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M2J', FileMetadataRetrievedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M2K', StrSubstNo(GettingFileMetadataFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
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
        Telemetry.LogMessage('0000M2L', SettingFileMetadataTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
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
            Telemetry.LogMessage('0000M2M', FileMetadataSetTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M2N', StrSubstNo(SettingFileMetadataFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
        exit(AFSOperationResponse);
    end;

    procedure PutFileUI(AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        Filename: Text;
        SourceInStream: InStream;
    begin
        Telemetry.LogMessage('0000M2O', PuttingFileUITxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        if UploadIntoStream('', '', '', FileName, SourceInStream) then begin
            AFSOperationResponse := PutFileStream(Filename, SourceInStream, AFSOptionalParameters);
            if AFSOperationResponse.IsSuccessful() then
                Telemetry.LogMessage('0000M2P', FileSentUITxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
            else
                Telemetry.LogMessage('0000M2Q', StrSubstNo(PuttingFileUIFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
        end else
            Telemetry.LogMessage('0000M2R', PuttingFileUIAbortedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        exit(AFSOperationResponse);
    end;

    procedure PutFileStream(FilePath: Text; var SourceInStream: InStream; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        SourceContentVariant: Variant;
    begin
        Telemetry.LogMessage('0000M2S', PuttingFileStreamTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        SourceContentVariant := SourceInStream;
        AFSOperationResponse := PutFile(FilePath, AFSOptionalParameters, SourceContentVariant);
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M2T', FileSentStreamTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M2U', StrSubstNo(PuttingFileStreamFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
        exit(AFSOperationResponse);
    end;

    procedure PutFileText(FilePath: Text; SourceText: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        SourceContentVariant: Variant;
    begin
        Telemetry.LogMessage('0000M2V', PuttingFileTextTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        SourceContentVariant := SourceText;
        AFSOperationResponse := PutFile(FilePath, AFSOptionalParameters, SourceContentVariant);
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M2W', FileSentTextTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M2X', StrSubstNo(PuttingFileTextFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
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
        MaxAllowedRange: Integer;
        CurrentPostion: Integer;
        BytesToWrite: Integer;
        BytesLeftToWrite: Integer;
        SmallerStream: InStream;
        SmallerOutStream: OutStream;
        ResponseIndex: Integer;
    begin
        Telemetry.LogMessage('0000M2Y', PuttingFileRangesTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
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
                Telemetry.LogMessage('0000M2Z', StrSubstNo(FileRangeSentTxt, CurrentPostion, CurrentPostion + BytesToWrite - 1), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
            else
                Telemetry.LogMessage('0000M30', StrSubstNo(PuttingFileRangesFailedTxt, CurrentPostion, CurrentPostion + BytesToWrite - 1, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
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
        Telemetry.LogMessage('0000M31', DeletingFileTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::DeleteFile);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := AFSWebRequestHelper.DeleteOperation(AFSOperationPayload, StrSubstNo(DeleteFileOperationNotSuccessfulErr, AFSOperationPayload.GetPath(), AFSOperationPayload.GetFileShareName(), 'Delete'));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M32', FileDeletedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M33', StrSubstNo(DeletingFileFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);

        exit(AFSOperationResponse);
    end;

    procedure CopyFile(SourceFileURI: Text; DestinationFilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        Telemetry.LogMessage('0000M34', FileCopyingTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::CopyFile);
        AFSOperationPayload.AddRequestHeader('x-ms-copy-source', SourceFileURI);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(DestinationFilePath);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, StrSubstNo(CopyFileOperationNotSuccessfulErr, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M35', FileCopiedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M36', StrSubstNo(FileCopyingFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
        exit(AFSOperationResponse);
    end;

    procedure AbortCopyFile(DestinationFilePath: Text; CopyID: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        Telemetry.LogMessage('0000M37', StrSubstNo(AbortingCopyTxt, CopyID), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::AbortCopyFile);
        AFSOperationPayload.AddRequestHeader('x-ms-copy-action', 'abort');
        AFSOperationPayload.AddUriParameter('copyid', CopyID);
        AFSOperationPayload.SetOptionalParameters(AFSOptionalParameters);
        AFSOperationPayload.SetPath(DestinationFilePath);

        AFSOperationResponse := AFSWebRequestHelper.PutOperation(AFSOperationPayload, StrSubstNo(AbortCopyFileOperationNotSuccessfulErr, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M38', StrSubstNo(CopyingAbortedTxt, CopyID), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M39', StrSubstNo(AbortingCopyFailedTxt, CopyID, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
        exit(AFSOperationResponse);
    end;

    procedure FileAcquireLease(FilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"; ProposedLeaseId: Guid; var LeaseId: Guid): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        Telemetry.LogMessage('0000M3A', AcquiringLeaseTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::LeaseFile);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := AcquireLease(AFSOptionalParameters, ProposedLeaseId, LeaseId, StrSubstNo(LeaseOperationNotSuccessfulErr, LeaseAcquireLbl, FileLbl, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M3B', StrSubstNo(LeaseAcquiredTxt, LeaseId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M3C', StrSubstNo(AcquiringLeaseFailedTxt, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
        exit(AFSOperationResponse);
    end;

    procedure FileReleaseLease(FilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"; LeaseId: Guid): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        Telemetry.LogMessage('0000M3D', StrSubstNo(ReleasingLeaseTxt, LeaseId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::LeaseFile);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := ReleaseLease(AFSOptionalParameters, LeaseId, StrSubstNo(LeaseOperationNotSuccessfulErr, LeaseReleaseLbl, FileLbl, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M3E', StrSubstNo(LeaseReleasedTxt, LeaseId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M3F', StrSubstNo(ReleasingLeaseFailedTxt, LeaseId, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
        exit(AFSOperationResponse);
    end;

    procedure FileBreakLease(FilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"; LeaseId: Guid): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        Telemetry.LogMessage('0000M3G', StrSubstNo(BreakingLeaseTxt, LeaseId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::LeaseFile);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := BreakLease(AFSOptionalParameters, LeaseId, StrSubstNo(LeaseOperationNotSuccessfulErr, LeaseBreakLbl, FileLbl, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M3H', StrSubstNo(LeaseBrokenTxt, LeaseId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M3I', StrSubstNo(BreakingLeaseFailedTxt, LeaseId, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
        exit(AFSOperationResponse);
    end;

    procedure FileChangeLease(FilePath: Text; AFSOptionalParameters: Codeunit "AFS Optional Parameters"; var LeaseId: Guid; ProposedLeaseId: Guid): Codeunit "AFS Operation Response"
    var
        AFSOperationResponse: Codeunit "AFS Operation Response";
        AFSOperation: Enum "AFS Operation";
    begin
        Telemetry.LogMessage('0000M3J', StrSubstNo(ChangingLeaseTxt, LeaseId, ProposedLeaseId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
        AFSOperationPayload.SetOperation(AFSOperation::LeaseFile);
        AFSOperationPayload.SetPath(FilePath);

        AFSOperationResponse := ChangeLease(AFSOptionalParameters, LeaseId, ProposedLeaseId, StrSubstNo(LeaseOperationNotSuccessfulErr, LeaseChangeLbl, FileLbl, AFSOperationPayload.GetPath()));
        if AFSOperationResponse.IsSuccessful() then
            Telemetry.LogMessage('0000M3K', StrSubstNo(LeaseChangedTxt, LeaseId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All)
        else
            Telemetry.LogMessage('0000M3L', StrSubstNo(ChangingLeaseFailedTxt, ProposedLeaseId, AFSOperationResponse.GetError()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All);
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
