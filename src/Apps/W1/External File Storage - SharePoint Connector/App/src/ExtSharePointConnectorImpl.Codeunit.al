// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.Text;
using System.DataAdministration;

codeunit 4580 "Ext. SharePoint Connector Impl" implements "External File Storage Connector"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Ext. SharePoint Account" = rimd;

    var
        RestHelper: Codeunit "Ext. SharePoint REST Helper";
        GraphHelper: Codeunit "Ext. SharePoint Graph Helper";
        ConnectorDescriptionTxt: Label 'Use SharePoint to store and retrieve files.', MaxLength = 250;
        NotRegisteredAccountErr: Label 'We could not find the account. Typically, this is because the account has been deleted.';

    #region File Operations

    /// <summary>
    /// Gets a List of Files stored on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to get the file.</param>
    /// <param name="Path">The file path to list.</param>
    /// <param name="FilePaginationData">Defines the pagination data.</param>
    /// <param name="TempFileAccountContent">A list with all files stored in the path.</param>
    procedure ListFiles(AccountId: Guid; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary)
    begin
        if GetUseGraphAPI(AccountId) then
            GraphHelper.ListFiles(AccountId, Path, FilePaginationData, TempFileAccountContent)
        else
            RestHelper.ListFiles(AccountId, Path, FilePaginationData, TempFileAccountContent);
    end;

    /// <summary>
    /// Gets a file from the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to get the file.</param>
    /// <param name="Path">The file path inside the file account.</param>
    /// <param name="Stream">The Stream were the file is read to.</param>
    procedure GetFile(AccountId: Guid; Path: Text; Stream: InStream)
    begin
        if GetUseGraphAPI(AccountId) then
            GraphHelper.GetFile(AccountId, Path, Stream)
        else
            RestHelper.GetFile(AccountId, Path, Stream);
    end;

    /// <summary>
    /// Create a file in the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="Path">The file path inside the file account.</param>
    /// <param name="Stream">The Stream were the file is read from.</param>
    procedure CreateFile(AccountId: Guid; Path: Text; Stream: InStream)
    begin
        if GetUseGraphAPI(AccountId) then
            GraphHelper.CreateFile(AccountId, Path, Stream)
        else
            RestHelper.CreateFile(AccountId, Path, Stream);
    end;

    /// <summary>
    /// Copies as file inside the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="SourcePath">The source file path.</param>
    /// <param name="TargetPath">The target file path.</param>
    procedure CopyFile(AccountId: Guid; SourcePath: Text; TargetPath: Text)
    begin
        if GetUseGraphAPI(AccountId) then
            GraphHelper.CopyFile(AccountId, SourcePath, TargetPath)
        else
            RestHelper.CopyFile(AccountId, SourcePath, TargetPath);
    end;

    /// <summary>
    /// Move as file inside the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="SourcePath">The source file path.</param>
    /// <param name="TargetPath">The target file path.</param>
    procedure MoveFile(AccountId: Guid; SourcePath: Text; TargetPath: Text)
    begin
        if GetUseGraphAPI(AccountId) then
            GraphHelper.MoveFile(AccountId, SourcePath, TargetPath)
        else
            RestHelper.MoveFile(AccountId, SourcePath, TargetPath);
    end;

    /// <summary>
    /// Checks if a file exists on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="Path">The file path inside the file account.</param>
    /// <returns>Returns true if the file exists</returns>
    procedure FileExists(AccountId: Guid; Path: Text): Boolean
    begin
        if GetUseGraphAPI(AccountId) then
            exit(GraphHelper.FileExists(AccountId, Path))
        else
            exit(RestHelper.FileExists(AccountId, Path));
    end;

    /// <summary>
    /// Deletes a file exists on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="Path">The file path inside the file account.</param>
    procedure DeleteFile(AccountId: Guid; Path: Text)
    begin
        if GetUseGraphAPI(AccountId) then
            GraphHelper.DeleteFile(AccountId, Path)
        else
            RestHelper.DeleteFile(AccountId, Path);
    end;

    /// <summary>
    /// Gets a List of Directories stored on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to get the file.</param>
    /// <param name="Path">The file path to list.</param>
    /// <param name="FilePaginationData">Defines the pagination data.</param>
    /// <param name="Files">A list with all directories stored in the path.</param>
    procedure ListDirectories(AccountId: Guid; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary)
    begin
        if GetUseGraphAPI(AccountId) then
            GraphHelper.ListDirectories(AccountId, Path, FilePaginationData, TempFileAccountContent)
        else
            RestHelper.ListDirectories(AccountId, Path, FilePaginationData, TempFileAccountContent);
    end;

    /// <summary>
    /// Creates a directory on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="Path">The directory path inside the file account.</param>
    procedure CreateDirectory(AccountId: Guid; Path: Text)
    begin
        if GetUseGraphAPI(AccountId) then
            GraphHelper.CreateDirectory(AccountId, Path)
        else
            RestHelper.CreateDirectory(AccountId, Path);
    end;

    /// <summary>
    /// Checks if a directory exists on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="Path">The directory path inside the file account.</param>
    /// <returns>Returns true if the directory exists</returns>
    procedure DirectoryExists(AccountId: Guid; Path: Text) Result: Boolean
    begin
        if GetUseGraphAPI(AccountId) then
            exit(GraphHelper.DirectoryExists(AccountId, Path))
        else
            exit(RestHelper.DirectoryExists(AccountId, Path));
    end;

    /// <summary>
    /// Deletes a directory exists on the provided account.
    /// </summary>
    /// <param name="AccountId">The file account ID which is used to send out the file.</param>
    /// <param name="Path">The directory path inside the file account.</param>
    procedure DeleteDirectory(AccountId: Guid; Path: Text)
    begin
        if GetUseGraphAPI(AccountId) then
            GraphHelper.DeleteDirectory(AccountId, Path)
        else
            RestHelper.DeleteDirectory(AccountId, Path);
    end;

    #endregion

    local procedure GetUseGraphAPI(AccountId: Guid): Boolean
    var
        SharePointAccount: Record "Ext. SharePoint Account";
    begin
        SharePointAccount.Get(AccountId);
        exit(SharePointAccount."Use Graph API");
    end;

    /// <summary>
    /// Gets the registered accounts for the SharePoint connector.
    /// </summary>
    /// <param name="TempAccounts">Out parameter holding all the registered accounts for the SharePoint connector.</param>
    procedure GetAccounts(var TempAccounts: Record "File Account" temporary)
    var
        Account: Record "Ext. SharePoint Account";
    begin
        if not Account.FindSet() then
            exit;

        repeat
            TempAccounts."Account Id" := Account.Id;
            TempAccounts.Name := Account.Name;
            TempAccounts.Connector := Enum::"Ext. File Storage Connector"::"SharePoint";
            TempAccounts.Insert();
        until Account.Next() = 0;
    end;

    /// <summary>
    /// Shows accounts information.
    /// </summary>
    /// <param name="AccountId">The ID of the account to show.</param>
    procedure ShowAccountInformation(AccountId: Guid)
    var
        SharePointAccountLocal: Record "Ext. SharePoint Account";
    begin
        if not SharePointAccountLocal.Get(AccountId) then
            Error(NotRegisteredAccountErr);

        SharePointAccountLocal.SetRecFilter();
        Page.Run(Page::"Ext. SharePoint Account", SharePointAccountLocal);
    end;

    /// <summary>
    /// Register an file account for the SharePoint connector.
    /// </summary>
    /// <param name="TempAccount">Out parameter holding details of the registered account.</param>
    /// <returns>True if the registration was successful; false - otherwise.</returns>
    procedure RegisterAccount(var TempAccount: Record "File Account" temporary): Boolean
    var
        SharePointAccountWizard: Page "Ext. SharePoint Account Wizard";
    begin
        SharePointAccountWizard.RunModal();

        exit(SharePointAccountWizard.GetAccount(TempAccount));
    end;

    /// <summary>
    /// Deletes an file account for the SharePoint connector.
    /// </summary>
    /// <param name="AccountId">The ID of the SharePoint account</param>
    /// <returns>True if an account was deleted.</returns>
    procedure DeleteAccount(AccountId: Guid): Boolean
    var
        SharePointAccountLocal: Record "Ext. SharePoint Account";
    begin
        if SharePointAccountLocal.Get(AccountId) then
            exit(SharePointAccountLocal.Delete());

        exit(false);
    end;

    /// <summary>
    /// Gets a description of the SharePoint connector.
    /// </summary>
    /// <returns>A short description of the SharePoint connector.</returns>
    procedure GetDescription(): Text[250]
    begin
        exit(ConnectorDescriptionTxt);
    end;

    /// <summary>
    /// Gets the SharePoint connector logo.
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

    internal procedure IsAccountValid(var TempAccount: Record "Ext. SharePoint Account" temporary): Boolean
    begin
        if TempAccount.Name = '' then
            exit(false);

        if IsNullGuid(TempAccount."Client Id") then
            exit(false);

        if IsNullGuid(TempAccount."Tenant Id") then
            exit(false);

        if TempAccount."SharePoint Url" = '' then
            exit(false);

        if TempAccount."Base Relative Folder Path" = '' then
            exit(false);

        exit(true);
    end;

    internal procedure CreateAccount(var AccountToCopy: Record "Ext. SharePoint Account"; ClientSecretOrCertificate: SecretText; CertificatePassword: SecretText; var TempFileAccount: Record "File Account" temporary)
    var
        NewExtSharePointAccount: Record "Ext. SharePoint Account";
    begin
        NewExtSharePointAccount.TransferFields(AccountToCopy);
        NewExtSharePointAccount.Id := CreateGuid();

        case NewExtSharePointAccount."Authentication Type" of
            Enum::"Ext. SharePoint Auth Type"::"Client Secret":
                NewExtSharePointAccount.SetClientSecret(ClientSecretOrCertificate);
            Enum::"Ext. SharePoint Auth Type"::Certificate:
                begin
                    NewExtSharePointAccount.SetCertificate(ClientSecretOrCertificate);
                    NewExtSharePointAccount.SetCertificatePassword(CertificatePassword);
                end;
        end;

        NewExtSharePointAccount.Insert();

        TempFileAccount."Account Id" := NewExtSharePointAccount.Id;
        TempFileAccount.Name := NewExtSharePointAccount.Name;
        TempFileAccount.Connector := Enum::"Ext. File Storage Connector"::"SharePoint";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", OnClearCompanyConfig, '', false, false)]
    local procedure EnvironmentCleanup_OnClearCompanyConfig(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    var
        ExtSharePointAccount: Record "Ext. SharePoint Account";
    begin
        ExtSharePointAccount.SetRange(Disabled, false);
        if ExtSharePointAccount.IsEmpty() then
            exit;

        ExtSharePointAccount.ModifyAll(Disabled, true);
    end;
}