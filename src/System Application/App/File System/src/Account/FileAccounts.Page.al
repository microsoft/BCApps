// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.FileSystem;

using System.Telemetry;

/// <summary>
/// Lists all of the registered file accounts
/// </summary>
page 9450 "File Accounts"
{
    PageType = List;
    Caption = 'File Accounts';
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
                Visible = ShowLogo;
                FreezeColumn = NameField;
                field(LogoField; Rec.LogoBlob)
                {
                    ShowCaption = false;
                    Caption = ' ';
                    Visible = ShowLogo;
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

        area(factboxes)
        {
            part(Scenarios; "File Scenarios FactBox")
            {
                Caption = 'File Scenarios';
                SubPageLink = "Account Id" = field("Account Id"), Connector = field(Connector), Scenario = filter(<> 0); // Do not show Default scenario
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
                Caption = 'Add an file account';
                ToolTip = 'Opens a File Account Wizard setup page in order to add an File Account.';
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
            action(BrowseAccount)
            {
                Image = SelectField;
                Caption = 'Browse Account';
                ToolTip = 'Opens a File Browser and shows the content of the selected account.';
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

                actionref(AddAccount_Promoted; AddAccount)
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(MakeDefault_Promoted; MakeDefault)
                {
                }
                actionref(BrowseAccount_Promoted; BrowseAccount)
                {
                }
                actionref(Delete_Promoted; Delete)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report';
            }
            group(Category_Category4)
            {
                Caption = 'Navigate';

                actionref(FileScenarioSetup_Promoted; FileScenarioSetup)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000CTA', 'Fileing', Enum::"Feature Uptake Status"::Discovered);
        CanUserManageFileSetup := FileAccountImpl.IsUserFileAdmin();
        Rec.SetCurrentKey("Account Id", Connector);
        UpdateFileAccounts();
        ShowLogo := true;
    end;

    trigger OnAfterGetRecord()
    begin
        // Updating the accounts is done via OnAfterGetRecord in the cases when an account was changed from the corresponding connector's page
        if UpdateAccounts then begin
            UpdateAccounts := false;
            UpdateFileAccounts();
        end;

        DefaultTxt := '';

        IsDefault := DefaultFileAccount."Account Id" = Rec."Account Id";
        if IsDefault then
            DefaultTxt := '✓';
    end;

    local procedure UpdateFileAccounts()
    var
        FileAccount: Codeunit "File Account";
        FileScenario: Codeunit "File Scenario";
        SelectedAccountId: Guid;
        IsSelected: Boolean;
    begin
        // We need this code block to maintain the same selected record.
        SelectedAccountId := Rec."Account Id";
        IsSelected := not IsNullGuid(SelectedAccountId);

        FileAccount.GetAllAccounts(true, Rec); // Refresh the file accounts
        FileScenario.GetDefaultFileAccount(DefaultFileAccount); // Refresh the default file account

        if IsSelected then begin
            Rec."Account Id" := SelectedAccountId;
            if Rec.Find() then;
        end else
            if Rec.FindFirst() then;

        HasFileAccount := not Rec.IsEmpty();

        CurrPage.Update(false);
    end;

    local procedure ShowAccountInformation()
    var
        FileAccountImpl: Codeunit "File Account Impl.";
        Connector: Interface "File System Connector";
    begin
        UpdateAccounts := true;

#pragma warning disable AL0603
        if not FileAccountImpl.IsValidConnector(Rec.Connector.AsInteger()) then
#pragma warning restore AL0603
            Error(FileConnectorHasBeenUninstalledMsg);

        Connector := Rec.Connector;
        Connector.ShowAccountInformation(Rec."Account Id");
    end;

    /// <summary>
    /// Gets the selected file account.
    /// </summary>
    /// <param name="FileAccount">The selected file account</param>
    procedure GetAccount(var FileAccount: Record "File Account")
    begin
        FileAccount := Rec;
    end;

    /// <summary>
    /// Sets an file account to be selected.
    /// </summary>
    /// <param name="FileAccount">The file account to be initially selected on the page</param>
    procedure SetAccount(var FileAccount: Record "File Account")
    begin
        Rec := FileAccount;
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
        DefaultFileAccount: Record "File Account";
        FileAccountImpl: Codeunit "File Account Impl.";
        CanUserManageFileSetup: Boolean;
        HasFileAccount: Boolean;
        IsDefault: Boolean;
        IsInLookupMode: Boolean;
        ShowLogo: Boolean;
        UpdateAccounts: Boolean;
        DefaultTxt: Text;
        FileConnectorHasBeenUninstalledMsg: Label 'The selected file extension has been uninstalled. To view information about the file account, you must reinstall the extension.';
}