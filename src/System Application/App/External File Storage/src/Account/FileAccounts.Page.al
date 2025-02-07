// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.Telemetry;

/// <summary>
/// Lists all of the registered file accounts
/// </summary>
page 9450 "File Accounts"
{
    PageType = List;
    Caption = 'External File Accounts';
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "File Account";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    ShowFilter = false;
    LinksAllowed = false;
    RefreshOnActivate = true;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(Content)
        {
            repeater(Accounts)
            {
                FreezeColumn = NameField;
                field(LogoField; Rec.Logo)
                {
                    ShowCaption = false;
                    Caption = ' ';
                    ToolTip = 'Specifies the logo for the type of file account.';
                    Width = 1;
                }
                field(NameField; Rec.Name)
                {
                    ToolTip = 'Specifies the name of the account.';
                    Visible = not IsInLookupMode;

                    trigger OnDrillDown()
                    begin
                        ShowAccountInformation();
                    end;
                }
                field(NameFieldLookup; Rec.Name)
                {
                    ToolTip = 'Specifies the name of the account.';
                    Visible = IsInLookupMode;
                }
                field(DefaultField; DefaultTxt)
                {
                    Caption = 'Default';
                    ToolTip = 'Specifies whether the file account will be used for all scenarios for which an account is not specified. You must have a default file account, even if you have only one account.';
                    Visible = not IsInLookupMode;
                }
                field(FileConnector; Rec.Connector)
                {
                    ToolTip = 'Specifies the type of file extension that the account is added to.';
                    Visible = false;
                }
            }
        }

        area(FactBoxes)
        {
            part(Scenarios; "File Scenarios FactBox")
            {
                Caption = 'File Scenarios';
                SubPageLink = "Account Id" = field("Account Id"), Connector = field(Connector), Scenario = filter(<> Default);
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(View)
            {
                Image = View;
                ToolTip = 'View settings for the file account.';
                ShortcutKey = return;
                Visible = false;

                trigger OnAction()
                begin
                    ShowAccountInformation();
                end;
            }

            action(AddAccount)
            {
                Image = Add;
                Caption = 'Add a file account';
                ToolTip = 'Opens a File Account Wizard setup page in order to add a file account.';
                Visible = (not IsInLookupMode) and CanUserManageFileSetup;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"File Account Wizard");

                    UpdateFileAccounts();
                end;
            }
        }
        area(Processing)
        {
            action(MakeDefault)
            {
                Image = Default;
                Caption = 'Set as default';
                ToolTip = 'Mark the selected file account as the default account. This account will be used for all scenarios for which an account is not specified.';
                Visible = (not IsInLookupMode) and CanUserManageFileSetup;
                Scope = Repeater;
                Enabled = not IsDefault;

                trigger OnAction()
                begin
                    FileAccountImpl.MakeDefault(Rec);

                    UpdateAccounts := true;
                    CurrPage.Update(false);
                end;
            }
            action(StorageBrowser)
            {
                Image = BOMVersions;
                Caption = 'Storage Browser';
                ToolTip = 'Opens the Storage Browser and shows the content of the selected account.';
                Visible = (not IsInLookupMode) and CanUserManageFileSetup;
                Scope = Repeater;

                trigger OnAction()
                begin
                    FileAccountImpl.BrowseAccount(Rec);

                    UpdateAccounts := true;
                    CurrPage.Update(false);
                end;
            }

            action(Delete)
            {
                Image = Delete;
                Caption = 'Delete file account';
                ToolTip = 'Delete the file account.';
                Visible = (not IsInLookupMode) and CanUserManageFileSetup;
                Scope = Repeater;

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    FileAccountImpl.OnAfterSetSelectionFilter(Rec);

                    FileAccountImpl.DeleteAccounts(Rec);

                    UpdateFileAccounts();
                end;
            }
        }
        area(Navigation)
        {
            action(FileScenarioSetup)
            {
                Image = Answers;
                Caption = 'File Scenarios';
                ToolTip = 'Assign scenarios to the file accounts.';
                Visible = not IsInLookupMode;

                trigger OnAction()
                var
                    FileScenarioSetup: Page "File Scenario Setup";
                begin
                    FileScenarioSetup.SetFileAccountId(Rec."Account Id", Rec.Connector);
                    FileScenarioSetup.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(AddAccount_Promoted; AddAccount) { }
            }
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(MakeDefault_Promoted; MakeDefault) { }
                actionref(StorageBrowser_Promoted; StorageBrowser) { }
                actionref(Delete_Promoted; Delete) { }
            }

            group(Category_Category4)
            {
                Caption = 'Navigate';

                actionref(FileScenarioSetup_Promoted; FileScenarioSetup) { }
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000OPH', 'External File Storage', Enum::"Feature Uptake Status"::Discovered);
        CanUserManageFileSetup := FileAccountImpl.IsUserFileAdmin();
        Rec.SetCurrentKey("Account Id", Connector);
        UpdateFileAccounts();
    end;

    trigger OnAfterGetRecord()
    begin
        // Updating the accounts is done via OnAfterGetRecord in the cases when an account was changed from the corresponding connector's page
        if UpdateAccounts then begin
            UpdateAccounts := false;
            UpdateFileAccounts();
        end;

        DefaultTxt := '';

        IsDefault := TempDefaultFileAccount."Account Id" = Rec."Account Id";
        if IsDefault then
            DefaultTxt := '✓';
    end;

    local procedure UpdateFileAccounts()
    var
        FileAccount: Codeunit "File Account";
        FileScenario: Codeunit "File Scenario";
        IsSelected: Boolean;
        SelectedAccountId: Guid;
    begin
        // Maintain the same selected record after updating accounts.
        SelectedAccountId := Rec."Account Id";
        IsSelected := not IsNullGuid(SelectedAccountId);

        FileAccount.GetAllAccounts(true, Rec); // Refresh the file accounts
        FileScenario.GetDefaultFileAccount(TempDefaultFileAccount); // Refresh the default file account

        if IsSelected then begin
            Rec."Account Id" := SelectedAccountId;
            if Rec.Find() then;
        end else
            if Rec.FindFirst() then;

        CurrPage.Update(false);
    end;

    local procedure ShowAccountInformation()
    var
        Connector: Interface "External File Storage Connector";
    begin
        UpdateAccounts := true;

        if not FileAccountImpl.IsValidConnector(Rec.Connector) then
            Error(FileConnectorHasBeenUninstalledMsg);

        Connector := Rec.Connector;
        Connector.ShowAccountInformation(Rec."Account Id");
    end;

    /// <summary>
    /// Gets the selected file account.
    /// </summary>
    /// <param name="TempFileAccount">The selected file account</param>
    procedure GetAccount(var TempFileAccount: Record "File Account" temporary)
    begin
        TempFileAccount := Rec;
    end;

    /// <summary>
    /// Sets a file account to be selected.
    /// </summary>
    /// <param name="TempFileAccount">The file account to be initially selected on the page</param>
    procedure SetAccount(var TempFileAccount: Record "File Account" temporary)
    begin
        Rec := TempFileAccount;
    end;

    /// <summary>
    /// Enables the lookup mode on the page.
    /// </summary>
    procedure EnableLookupMode()
    begin
        IsInLookupMode := true;
        CurrPage.LookupMode(true);
    end;

    var
        TempDefaultFileAccount: Record "File Account" temporary;
        FileAccountImpl: Codeunit "File Account Impl.";
        CanUserManageFileSetup: Boolean;
        IsDefault: Boolean;
        IsInLookupMode: Boolean;
        UpdateAccounts: Boolean;
        FileConnectorHasBeenUninstalledMsg: Label 'The selected file extension has been uninstalled. To view information about the file account, you must reinstall the extension.';
        DefaultTxt: Text;
}