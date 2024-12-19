// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.Text;
using System.Utilities;

codeunit 9451 "File Account Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "File Storage Connector Logo" = rimd,
                  tabledata "File Scenario" = imd;

    procedure GetAllAccounts(LoadLogos: Boolean; var TempFileAccount: Record "File Account" temporary)
    var
        TempFileFileAccounts: Record "File Account" temporary;
        FileSystemConnector: Interface "External File Storage Connector";
        Connector: Enum "Ext. File Storage Connector";
    begin
        TempFileAccount.Reset();
        TempFileAccount.DeleteAll();

        foreach Connector in Connector.Ordinals do begin
            FileSystemConnector := Connector;

            TempFileFileAccounts.DeleteAll();
            FileSystemConnector.GetAccounts(TempFileFileAccounts);

            if TempFileFileAccounts.FindSet() then
                repeat
                    TempFileAccount := TempFileFileAccounts;
                    TempFileAccount.Connector := Connector;

                    if LoadLogos then
                        ImportLogo(TempFileAccount, Connector);

                    TempFileAccount.Insert();
                until TempFileFileAccounts.Next() = 0;
        end;

        // Sort by account name
        TempFileAccount.SetCurrentKey(Name);
    end;

    procedure DeleteAccounts(var TempFileAccountsToDelete: Record "File Account" temporary)
    var
        TempCurrentDefaultFileAccount: Record "File Account" temporary;
        ConfirmManagement: Codeunit "Confirm Management";
        FileScenario: Codeunit "File Scenario";
        FileSystemConnector: Interface "External File Storage Connector";
    begin
        CheckPermissions();

        if not ConfirmManagement.GetResponseOrDefault(ConfirmDeleteQst, true) then
            exit;

        if not TempFileAccountsToDelete.FindSet() then
            exit;

        // Get the current default account to track if it was deleted
        FileScenario.GetDefaultFileAccount(TempCurrentDefaultFileAccount);

        // Delete all selected accounts
        repeat
            // Check to validate that the connector is still installed
            // The connector could have been uninstalled by another user/session
            if IsValidConnector(TempFileAccountsToDelete.Connector) then begin
                FileSystemConnector := TempFileAccountsToDelete.Connector;
                FileSystemConnector.DeleteAccount(TempFileAccountsToDelete."Account Id");
            end;
        until TempFileAccountsToDelete.Next() = 0;

        DefaultAccountDeletion(TempCurrentDefaultFileAccount."Account Id", TempCurrentDefaultFileAccount.Connector);
    end;

    local procedure DefaultAccountDeletion(CurrentDefaultAccountId: Guid; Connector: Enum "Ext. File Storage Connector")
    var
        TempAllFileAccounts: Record "File Account" temporary;
        TempNewDefaultFileAccount: Record "File Account" temporary;
        FileScenario: Codeunit "File Scenario";
    begin
        GetAllAccounts(false, TempAllFileAccounts);

        if TempAllFileAccounts.IsEmpty() then
            exit; //All of the accounts were deleted, nothing to do

        if TempAllFileAccounts.Get(CurrentDefaultAccountId, Connector) then
            exit; // The default account was not deleted or it never existed

        // In case there's only one account, set it as default
        if TempAllFileAccounts.Count() = 1 then begin
            MakeDefault(TempAllFileAccounts);
            exit;
        end;

        Commit();  // Commit the accounts deletion in order to prompt for a new default account
        if PromptNewDefaultAccountChoice(TempNewDefaultFileAccount) then
            MakeDefault(TempNewDefaultFileAccount)
        else
            FileScenario.UnassignScenario(Enum::"File Scenario"::Default); // remove the default scenario as it is pointing to a non-existent account
    end;

    local procedure PromptNewDefaultAccountChoice(var TempNewDefaultFileAccount: Record "File Account" temporary): Boolean
    var
        FileAccountsPage: Page "File Accounts";
    begin
        FileAccountsPage.LookupMode(true);
        FileAccountsPage.EnableLookupMode();
        FileAccountsPage.Caption(ChooseNewDefaultTxt);
        if FileAccountsPage.RunModal() <> Action::LookupOK then
            exit;

        FileAccountsPage.GetAccount(TempNewDefaultFileAccount);
        exit(true);
    end;

    local procedure ImportLogo(var TempFileAccount: Record "File Account" temporary; FileSystemConnector: Interface "External File Storage Connector")
    var
        FileSystemConnectorLogo: Record "File Storage Connector Logo";
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

        if not FileSystemConnectorLogo.Get(TempFileAccount.Connector) then begin
            TempBlob.CreateOutStream(OutStream);
            Base64Convert.FromBase64(ConnectorLogoBase64, OutStream);
            TempBlob.CreateInStream(InStream);
            FileSystemConnectorLogo.Init();
            FileSystemConnectorLogo.Connector := TempFileAccount.Connector;
            FileSystemConnectorLogo.Logo.ImportStream(InStream, StrSubstNo(ConnectorLogoDescriptionTxt, TempFileAccount.Connector));
            if FileSystemConnectorLogo.Insert() then;
        end;
        TempFileAccount.Logo := FileSystemConnectorLogo.Logo;
    end;

    procedure IsAnyAccountRegistered(): Boolean
    var
        TempFileAccount: Record "File Account" temporary;
    begin
        GetAllAccounts(false, TempFileAccount);

        exit(not TempFileAccount.IsEmpty());
    end;

    procedure IsUserFileAdmin(): Boolean
    var
        FileScenario: Record "File Scenario";
    begin
        exit(FileScenario.WritePermission());
    end;

    procedure FindAllConnectors(var TempFileConnector: Record "Ext. File Storage Connector" temporary)
    var
        FileConnectorLogo: Record "File Storage Connector Logo";
        ConnectorInterface: Interface "External File Storage Connector";
        FileSystemConnector: Enum "Ext. File Storage Connector";
    begin
        foreach FileSystemConnector in Enum::"Ext. File Storage Connector".Ordinals() do begin
            ConnectorInterface := FileSystemConnector;
            TempFileConnector.Connector := FileSystemConnector;
            TempFileConnector.Description := ConnectorInterface.GetDescription();
            if FileConnectorLogo.Get(TempFileConnector.Connector) then
                TempFileConnector.Logo := FileConnectorLogo.Logo;
            TempFileConnector.Insert();
        end;
    end;

    procedure IsValidConnector(Connector: Enum "Ext. File Storage Connector"): Boolean
    begin
        exit("Ext. File Storage Connector".Ordinals().Contains(Connector.AsInteger()));
    end;

    procedure MakeDefault(var TempFileAccount: Record "File Account" temporary)
    var
        FileScenario: Codeunit "File Scenario";
    begin
        CheckPermissions();

        if IsNullGuid(TempFileAccount."Account Id") then
            exit;

        FileScenario.SetDefaultFileAccount(TempFileAccount);
    end;

    procedure BrowseAccount(var TempFileAccount: Record "File Account" temporary)
    var
        StorageBrowser: Page "Storage Browser";
    begin
        CheckPermissions();

        if IsNullGuid(TempFileAccount."Account Id") then
            exit;

        StorageBrowser.SetFileAccount(TempFileAccount);
        StorageBrowser.BrowseFileAccount('');
        StorageBrowser.Run();
    end;

    procedure CheckPermissions()
    begin
        if not IsUserFileAdmin() then
            Error(CannotManageSetupErr);
    end;

    [InternalEvent(false)]
    procedure OnAfterSetSelectionFilter(var TempFileAccount: Record "File Account" temporary)
    begin
    end;

    var
        CannotManageSetupErr: Label 'Your user account does not give you permission to set up file accounts. Please contact your administrator.';
        ChooseNewDefaultTxt: Label 'Choose a Default Account';
        ConfirmDeleteQst: Label 'Go ahead and delete?';
}