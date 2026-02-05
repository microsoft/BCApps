// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.DataAdministration;
using System.SFTPClient;
using System.Text;
using System.Utilities;

codeunit 4621 "Ext. SFTP Connector Impl" implements "External File Storage Connector"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Ext. SFTP Account" = rimd;

    var
        ConnectorDescriptionTxt: Label 'Use SFTP Server to store and retrieve files.', MaxLength = 250;
        NotRegisteredAccountErr: Label 'We could not find the account. Typically, this is because the account has been deleted.';
        PathSeparatorTok: Label '/', Locked = true;

    /// <summary>
    /// Gets a List of Files stored on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to get the file.</param>
    /// <param name="Path">The file path to list.</param>
    /// <param name="FilePaginationData">Defines the pagination data.</param>
    /// <param name="TempFileAccountContent">A list with all files stored in the path.</param>
    procedure ListFiles(AccountId: Guid; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary)
    var
        FolderContent: Record "SFTP Folder Content";
        SFTPClient: Codeunit "SFTP Client";
        Response: Codeunit "SFTP Operation Response";
        OrginalPath: Text;
    begin
        OrginalPath := Path;
        InitPath(AccountId, Path);
        InitSFTPClient(AccountId, SFTPClient);
        Response := SFTPClient.ListFiles(Path, FolderContent);
        SFTPClient.Disconnect();

        if Response.IsError() then
            ShowError(Response);

        FilePaginationData.SetEndOfListing(true);

        FolderContent.SetRange("Is Directory", false);
        if not FolderContent.FindSet() then
            exit;

        repeat
            TempFileAccountContent.Init();
            TempFileAccountContent.Name := FolderContent.Name;
            TempFileAccountContent.Type := TempFileAccountContent.Type::"File";
            TempFileAccountContent."Parent Directory" := CopyStr(OrginalPath, 1, MaxStrLen(TempFileAccountContent."Parent Directory"));
            TempFileAccountContent.Insert();
        until FolderContent.Next() = 0;
    end;

    /// <summary>
    /// Gets a file from the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to get the file.</param>
    /// <param name="Path">The file path inside the file account.</param>
    /// <param name="Stream">The Stream were the file is read to.</param>
    procedure GetFile(AccountId: Guid; Path: Text; Stream: InStream)
    var
        SFTPClient: Codeunit "SFTP Client";
        Response: Codeunit "SFTP Operation Response";
        Content: HttpContent;
        TempBlobStream: InStream;
    begin
        InitPath(AccountId, Path);
        InitSFTPClient(AccountId, SFTPClient);

        Response := SFTPClient.GetFileAsStream(Path, TempBlobStream);
        SFTPClient.Disconnect();

        if Response.IsError() then
            ShowError(Response);

        // Platform fix: For some reason the Stream from GetFileAsStream dies after leaving the interface
        Content.WriteFrom(TempBlobStream);
        Content.ReadAs(Stream);
    end;

    /// <summary>
    /// Create a file in the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="Path">The file path inside the file account.</param>
    /// <param name="Stream">The Stream were the file is read from.</param>
    procedure CreateFile(AccountId: Guid; Path: Text; Stream: InStream)
    var
        SFTPClient: Codeunit "SFTP Client";
        Response: Codeunit "SFTP Operation Response";
    begin
        InitPath(AccountId, Path);
        InitSFTPClient(AccountId, SFTPClient);

        Response := SFTPClient.PutFileStream(Path, Stream);
        SFTPClient.Disconnect();

        if Response.IsError() then
            ShowError(Response);
    end;

    /// <summary>
    /// Copies as file inside the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="SourcePath">The source file path.</param>
    /// <param name="TargetPath">The target file path.</param>
    procedure CopyFile(AccountId: Guid; SourcePath: Text; TargetPath: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Stream: InStream;
    begin
        TempBlob.CreateInStream(Stream);

        GetFile(AccountId, SourcePath, Stream);
        CreateFile(AccountId, TargetPath, Stream);
    end;

    /// <summary>
    /// Move as file inside the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="SourcePath">The source file path.</param>
    /// <param name="TargetPath">The target file path.</param>
    procedure MoveFile(AccountId: Guid; SourcePath: Text; TargetPath: Text)
    var
        SFTPClient: Codeunit "SFTP Client";
        Response: Codeunit "SFTP Operation Response";
    begin
        InitSFTPClient(AccountId, SFTPClient);
        InitPath(AccountId, SourcePath);
        InitPath(AccountId, TargetPath);

        Response := SFTPClient.MoveFile(SourcePath, TargetPath);
        SFTPClient.Disconnect();

        if Response.IsError() then
            ShowError(Response);
    end;

    /// <summary>
    /// Checks if a file exists on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="Path">The file path inside the file account.</param>
    /// <returns>Returns true if the file exists</returns>
    procedure FileExists(AccountId: Guid; Path: Text) Result: Boolean
    var
        SFTPClient: Codeunit "SFTP Client";
        Response: Codeunit "SFTP Operation Response";
    begin
        InitPath(AccountId, Path);
        InitSFTPClient(AccountId, SFTPClient);

        Response := SFTPClient.FileExists(Path, Result);
        SFTPClient.Disconnect();

        if Response.IsError() then
            ShowError(Response);
    end;

    /// <summary>
    /// Deletes a file exists on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="Path">The file path inside the file account.</param>
    procedure DeleteFile(AccountId: Guid; Path: Text)
    var
        SFTPClient: Codeunit "SFTP Client";
        Response: Codeunit "SFTP Operation Response";
    begin
        InitPath(AccountId, Path);
        InitSFTPClient(AccountId, SFTPClient);

        Response := SFTPClient.DeleteFile(Path);
        SFTPClient.Disconnect();

        if Response.IsError() then
            ShowError(Response);
    end;

    /// <summary>
    /// Gets a List of Directories stored on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to get the file.</param>
    /// <param name="Path">The file path to list.</param>
    /// <param name="FilePaginationData">Defines the pagination data.</param>
    /// <param name="Files">A list with all directories stored in the path.</param>
    procedure ListDirectories(AccountId: Guid; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary)
    var
        FolderContent: Record "SFTP Folder Content";
        SFTPClient: Codeunit "SFTP Client";
        Response: Codeunit "SFTP Operation Response";
        OrginalPath: Text;
    begin
        OrginalPath := Path;
        InitPath(AccountId, Path);
        InitSFTPClient(AccountId, SFTPClient);
        Response := SFTPClient.ListFiles(Path, FolderContent);
        SFTPClient.Disconnect();

        if Response.IsError() then
            ShowError(Response);

        FilePaginationData.SetEndOfListing(true);

        FolderContent.SetRange("Is Directory", true);
        FolderContent.SetFilter(Name, '<>%1&<>%2', '.', '..'); // Exclude . and ..
        if not FolderContent.FindSet() then
            exit;

        repeat
            TempFileAccountContent.Init();
            TempFileAccountContent.Name := FolderContent.Name;
            TempFileAccountContent.Type := TempFileAccountContent.Type::Directory;
            TempFileAccountContent."Parent Directory" := CopyStr(OrginalPath, 1, MaxStrLen(TempFileAccountContent."Parent Directory"));
            TempFileAccountContent.Insert();
        until FolderContent.Next() = 0;
    end;

    /// <summary>
    /// Creates a directory on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="Path">The directory path inside the file account.</param>
    procedure CreateDirectory(AccountId: Guid; Path: Text)
    var
        SFTPClient: Codeunit "SFTP Client";
        Response: Codeunit "SFTP Operation Response";
    begin
        InitPath(AccountId, Path);
        InitSFTPClient(AccountId, SFTPClient);
        Response := SFTPClient.CreateDirectory(Path);
        SFTPClient.Disconnect();

        if Response.IsError() then
            ShowError(Response);
    end;

    /// <summary>
    /// Checks if a directory exists on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="Path">The directory path inside the file account.</param>
    /// <returns>Returns true if the directory exists</returns>
    procedure DirectoryExists(AccountId: Guid; Path: Text) Result: Boolean
    begin
        exit(FileExists(AccountId, Path));
    end;

    /// <summary>
    /// Deletes a directory exists on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="Path">The directory path inside the file account.</param>
    procedure DeleteDirectory(AccountId: Guid; Path: Text)
    begin
        DeleteFile(AccountId, Path);
    end;

    /// <summary>
    /// Gets the registered accounts for the SFTP connector.
    /// </summary>
    /// <param name="TempAccounts">Out parameter holding all the registered accounts for the SFTP connector.</param>
    procedure GetAccounts(var TempAccounts: Record "File Account" temporary)
    var
        Account: Record "Ext. SFTP Account";
    begin
        if not Account.FindSet() then
            exit;

        repeat
            TempAccounts."Account Id" := Account.Id;
            TempAccounts.Name := Account.Name;
            TempAccounts.Connector := Enum::"Ext. File Storage Connector"::"SFTP";
            TempAccounts.Insert();
        until Account.Next() = 0;
    end;

    /// <summary>
    /// Shows accounts information.
    /// </summary>
    /// <param name="AccountId">The ID of the account to show.</param>
    procedure ShowAccountInformation(AccountId: Guid)
    var
        AccountLocal: Record "Ext. SFTP Account";
    begin
        if not AccountLocal.Get(AccountId) then
            Error(NotRegisteredAccountErr);

        AccountLocal.SetRecFilter();
        Page.Run(Page::"Ext. SFTP Account", AccountLocal);
    end;

    /// <summary>
    /// Register an file account for the SFTP connector.
    /// </summary>
    /// <param name="TempAccount">Out parameter holding details of the registered account.</param>
    /// <returns>True if the registration was successful; false - otherwise.</returns>
    procedure RegisterAccount(var TempAccount: Record "File Account" temporary): Boolean
    var
        AccountWizard: Page "Ext. SFTP Account Wizard";
    begin
        AccountWizard.RunModal();

        exit(AccountWizard.GetAccount(TempAccount));
    end;

    /// <summary>
    /// Deletes an file account for the SFTP connector.
    /// </summary>
    /// <param name="AccountId">The ID of the SFTP account</param>
    /// <returns>True if an account was deleted.</returns>
    procedure DeleteAccount(AccountId: Guid): Boolean
    var
        AccountLocal: Record "Ext. SFTP Account";
    begin
        if AccountLocal.Get(AccountId) then
            exit(AccountLocal.Delete());

        exit(false);
    end;

    /// <summary>
    /// Gets a description of the SFTP connector.
    /// </summary>
    /// <returns>A short description of the SFTP connector.</returns>
    procedure GetDescription(): Text[250]
    begin
        exit(ConnectorDescriptionTxt);
    end;

    /// <summary>
    /// Gets the SFTP connector logo.
    /// </summary>
    /// <returns>A base64-formatted image to be used as logo.</returns>
    procedure GetLogoAsBase64(): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        Stream: InStream;
    begin
        NavApp.GetResource('connector-logo.png', Stream);
        exit(Base64Convert.ToBase64(Stream));
    end;

    internal procedure IsAccountValid(var TempAccount: Record "Ext. SFTP Account" temporary): Boolean
    begin
        if TempAccount.Name = '' then
            exit(false);

        if TempAccount."Hostname" = '' then
            exit(false);

        if TempAccount."Base Relative Folder Path" = '' then
            exit(false);

        if TempAccount.Username = '' then
            exit(false);

        if TempAccount.Port = 0 then
            exit(false);

        exit(true);
    end;

    internal procedure CreateAccount(var AccountToCopy: Record "Ext. SFTP Account"; Password: SecretText; Certificate: Text; CertificatePassword: SecretText; var TempFileAccount: Record "File Account" temporary)
    var
        NewAccount: Record "Ext. SFTP Account";
    begin
        NewAccount.TransferFields(AccountToCopy);
        NewAccount.Id := CreateGuid();

        case NewAccount."Authentication Type" of
            Enum::"Ext. SFTP Auth Type"::Password:
                NewAccount.SetPassword(Password);
            Enum::"Ext. SFTP Auth Type"::Certificate:
                begin
                    NewAccount.SetCertificate(Certificate);
                    NewAccount.SetCertificatePassword(CertificatePassword);
                end;
        end;

        NewAccount.Insert();

        TempFileAccount."Account Id" := NewAccount.Id;
        TempFileAccount.Name := NewAccount.Name;
        TempFileAccount.Connector := Enum::"Ext. File Storage Connector"::"SFTP";
    end;

    [NonDebuggable]
    local procedure InitSFTPClient(var AccountId: Guid; var SFTPClient: Codeunit "SFTP Client")
    var
        SFTPAccount: Record "Ext. SFTP Account";
        Response: Codeunit "SFTP Operation Response";
        Stream: InStream;
        AccountDisabledErr: Label 'The account "%1" is disabled.', Comment = '%1 - Account Name';
    begin
        SFTPAccount.Get(AccountId);
        if SFTPAccount.Disabled then
            Error(AccountDisabledErr, SFTPAccount.Name);

        AddFingerprints(SFTPAccount."Fingerprints", SFTPClient);

        case SFTPAccount."Authentication Type" of
            Enum::"Ext. SFTP Auth Type"::Password:
                Response := SFTPClient.Initialize(SFTPAccount.Hostname, SFTPAccount.Port, SFTPAccount.Username, SFTPAccount.GetPassword(SFTPAccount."Password Key"));
            Enum::"Ext. SFTP Auth Type"::Certificate:
                begin
                    SFTPAccount.GetCertificate(SFTPAccount."Certificate Key").CreateInStream(Stream);
                    if IsNullGuid(SFTPAccount."Certificate Password Key") then
                        Response := SFTPClient.Initialize(SFTPAccount.Hostname, SFTPAccount.Port, SFTPAccount.Username, Stream)
                    else
                        Response := SFTPClient.Initialize(SFTPAccount.Hostname, SFTPAccount.Port, SFTPAccount.Username, Stream, SFTPAccount.GetCertificatePassword(SFTPAccount."Certificate Password Key"));
                end;
        end;

        if Response.IsError() then
            ShowError(Response);
    end;

    local procedure ShowError(var Response: Codeunit "SFTP Operation Response")
    var
        ErrorOccurredErr: Label 'An error occurred.\%1', Comment = '%1 - Error message from SFTP Server';
    begin
        Error(ErrorOccurredErr, Response.GetError());
    end;

    local procedure InitPath(AccountId: Guid; var Path: Text)
    var
        SFTPAccount: Record "Ext. SFTP Account";
    begin
        SFTPAccount.Get(AccountId);
        Path := CombinePath(SFTPAccount."Base Relative Folder Path", Path);
    end;

    local procedure CombinePath(Parent: Text; Child: Text): Text
    var
        JoinPathTok: Label '%1/%2', Locked = true;
    begin
        if Parent = '' then
            exit(Child);

        if Child = '' then
            exit(Parent);

        exit(StrSubstNo(JoinPathTok, Parent.TrimEnd(PathSeparatorTok), Child.TrimStart(PathSeparatorTok)));
    end;

    local procedure AddFingerprints(Fingerprints: Text; var SFTPClient: Codeunit "SFTP Client")
    var
        Fingerprint: Text;
    begin
        foreach Fingerprint in Fingerprints.Split(',') do
            AddFingerprint(Fingerprint, SFTPClient);
    end;

    local procedure AddFingerprint(Fingerprint: Text; var SFTPClient: Codeunit "SFTP Client")
    var
        SHA256PrefixTok: Label 'sha256:', Locked = true;
        MD5PrefixTok: Label 'md5:', Locked = true;
        InvalidFingerprintErr: Label 'Fingerprint must start with "md5:" or "sha256:".';
    begin
        Fingerprint := Fingerprint.Trim();
        if Fingerprint = '' then
            exit;

        case true of
            Fingerprint.StartsWith(SHA256PrefixTok):
                SFTPClient.AddFingerprintSHA256(Fingerprint.Substring(StrLen(SHA256PrefixTok) + 1));
            Fingerprint.StartsWith(MD5PrefixTok):
                SFTPClient.AddFingerprintMD5(Fingerprint.Substring(StrLen(MD5PrefixTok) + 1));
            else
                Error(InvalidFingerprintErr);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", OnClearCompanyConfig, '', false, false)]
    local procedure EnvironmentCleanup_OnClearCompanyConfig(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    var
        Account: Record "Ext. SFTP Account";
    begin
        Account.SetRange(Disabled, false);
        if Account.IsEmpty() then
            exit;

        Account.ModifyAll(Disabled, true);
    end;
}