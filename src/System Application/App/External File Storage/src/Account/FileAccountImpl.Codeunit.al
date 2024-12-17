// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.FileSystem;

using System.Text;
using System.Utilities;

codeunit 9451 "File Account Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "File System Connector Logo" = rimd,
                  tabledata "File Scenario" = imd;

    procedure GetAllAccounts(LoadLogos: Boolean; var TempFileAccount: Record "File Account" temporary)
    var
        FileAccounts: Record "File Account";
        FileSystemConnector: Interface "File System Connector";
        Connector: Enum "File System Connector";
    begin
        TempFileAccount.Reset();
        TempFileAccount.DeleteAll();

        foreach Connector in Connector.Ordinals do begin
            FileSystemConnector := Connector;

            FileAccounts.DeleteAll();
            FileSystemConnector.GetAccounts(FileAccounts);

            if FileAccounts.FindSet() then
                repeat
                    TempFileAccount := FileAccounts;
                    TempFileAccount.Connector := Connector;

                    if LoadLogos then
                        ImportLogo(TempFileAccount, Connector);

                    TempFileAccount.Insert();
                until FileAccounts.Next() = 0;
        end;

        // Sort by account name
        TempFileAccount.SetCurrentKey(Name);
    end;

    procedure DeleteAccounts(var FileAccountsToDelete: Record "File Account")
    var
        CurrentDefaultFileAccount: Record "File Account";
        ConfirmManagement: Codeunit "Confirm Management";
        FileScenario: Codeunit "File Scenario";
        FileSystemConnector: Interface "File System Connector";
    begin
        CheckPermissions();

        if not ConfirmManagement.GetResponseOrDefault(ConfirmDeleteQst, true) then
            exit;

        if not FileAccountsToDelete.FindSet() then
            exit;

        // Get the current default account to track if it was deleted
        FileScenario.GetDefaultFileAccount(CurrentDefaultFileAccount);

        // Delete all selected accounts
        repeat
            // Check to validate that the connector is still installed
            // The connector could have been uninstalled by another user/session
            if IsValidConnector(FileAccountsToDelete.Connector) then begin
                FileSystemConnector := FileAccountsToDelete.Connector;
                FileSystemConnector.DeleteAccount(FileAccountsToDelete."Account Id");
            end;
        until FileAccountsToDelete.Next() = 0;

        DefaultAccountDeletion(CurrentDefaultFileAccount."Account Id", CurrentDefaultFileAccount.Connector);
    end;

    local procedure DefaultAccountDeletion(CurrentDefaultAccountId: Guid; Connector: Enum "File System Connector")
    var
        AllFileAccounts: Record "File Account";
        NewDefaultFileAccount: Record "File Account";
        FileScenario: Codeunit "File Scenario";
    begin
        GetAllAccounts(false, AllFileAccounts);

        if AllFileAccounts.IsEmpty() then
            exit; //All of the accounts were deleted, nothing to do

        if AllFileAccounts.Get(CurrentDefaultAccountId, Connector) then
            exit; // The default account was not deleted or it never existed

        // In case there's only one account, set it as default
        if AllFileAccounts.Count() = 1 then begin
            MakeDefault(AllFileAccounts);
            exit;
        end;

        Commit();  // Commit the accounts deletion in order to prompt for a new default account
        if PromptNewDefaultAccountChoice(NewDefaultFileAccount) then
            MakeDefault(NewDefaultFileAccount)
        else
            FileScenario.UnassignScenario(Enum::"File Scenario"::Default); // remove the default scenario as it is pointing to a non-existent account
    end;

    local procedure PromptNewDefaultAccountChoice(var NewDefaultFileAccount: Record "File Account"): Boolean
    var
        FileAccountsPage: Page "File Accounts";
    begin
        FileAccountsPage.LookupMode(true);
        FileAccountsPage.EnableLookupMode();
        FileAccountsPage.Caption(ChooseNewDefaultTxt);
        if FileAccountsPage.RunModal() <> Action::LookupOK then
            exit;

        FileAccountsPage.GetAccount(NewDefaultFileAccount);
        exit(true);
    end;

    local procedure ImportLogo(var FileAccount: Record "File Account"; FileSystemConnector: Interface "File System Connector")
    var
        FileSystemConnectorLogo: Record "File System Connector Logo";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        ConnectorLogoDescriptionTxt: Label '%1 Logo', Locked = true;
        OutStream: OutStream;
        ConnectorLogoBase64: Text;
    begin
        ConnectorLogoBase64 := FileSystemConnector.GetLogoAsBase64();

        if ConnectorLogoBase64 = '' then
            exit;

        if not FileSystemConnectorLogo.Get(FileAccount.Connector) then begin
            TempBlob.CreateOutStream(OutStream);
            Base64Convert.FromBase64(ConnectorLogoBase64, OutStream);
            TempBlob.CreateInStream(InStream);
            FileSystemConnectorLogo.Init();
            FileSystemConnectorLogo.Connector := FileAccount.Connector;
            FileSystemConnectorLogo.Logo.ImportStream(InStream, StrSubstNo(ConnectorLogoDescriptionTxt, FileAccount.Connector));
            if FileSystemConnectorLogo.Insert() then;
        end;
        FileAccount.Logo := FileSystemConnectorLogo.Logo;
    end;

    procedure IsAnyAccountRegistered(): Boolean
    var
        FileAccount: Record "File Account";
    begin
        GetAllAccounts(false, FileAccount);

        exit(not FileAccount.IsEmpty());
    end;

    procedure IsUserFileAdmin(): Boolean
    var
        FileScenario: Record "File Scenario";
    begin
        exit(FileScenario.WritePermission());
    end;

    procedure FindAllConnectors(var FileConnector: Record "File System Connector")
    var
        FileConnectorLogo: Record "File System Connector Logo";
        ConnectorInterface: Interface "File System Connector";
        FileSystemConnector: Enum "File System Connector";
    begin
        foreach FileSystemConnector in Enum::"File System Connector".Ordinals() do begin
            ConnectorInterface := FileSystemConnector;
            FileConnector.Connector := FileSystemConnector;
            FileConnector.Description := ConnectorInterface.GetDescription();
            if FileConnectorLogo.Get(FileConnector.Connector) then
                FileConnector.Logo := FileConnectorLogo.Logo;
            FileConnector.Insert();
        end;
    end;

    procedure IsValidConnector(Connector: Enum "File System Connector"): Boolean
    begin
        exit("File System Connector".Ordinals().Contains(Connector.AsInteger()));
    end;

    procedure MakeDefault(var FileAccount: Record "File Account")
    var
        FileScenario: Codeunit "File Scenario";
    begin
        CheckPermissions();

        if IsNullGuid(FileAccount."Account Id") then
            exit;

        FileScenario.SetDefaultFileAccount(FileAccount);
    end;

    procedure BrowseAccount(var FileAccount: Record "File Account")
    var
        StorageBrowser: Page "Storage Browser";
    begin
        CheckPermissions();

        if IsNullGuid(FileAccount."Account Id") then
            exit;

        StorageBrowser.SetFileAccount(FileAccount);
        StorageBrowser.BrowseFileAccount('');
        StorageBrowser.Run();
    end;

    procedure CheckPermissions()
    begin
        if not IsUserFileAdmin() then
            Error(CannotManageSetupErr);
    end;

    [InternalEvent(false)]
    procedure OnAfterSetSelectionFilter(var FileAccount: Record "File Account")
    begin
    end;

    var
        CannotManageSetupErr: Label 'Your user account does not give you permission to set up file accounts. Please contact your administrator.';
        ChooseNewDefaultTxt: Label 'Choose a Default Account';
        ConfirmDeleteQst: Label 'Go ahead and delete?';
}