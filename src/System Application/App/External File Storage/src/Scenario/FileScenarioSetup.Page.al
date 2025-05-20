// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.Telemetry;

/// <summary>
/// Page is used to display file scenarios usage by file accounts.
/// </summary>
page 9452 "File Scenario Setup"
{
    Caption = 'File Scenario Assignment';
    PageType = List;
    UsageCategory = Administration;
    ApplicationArea = All;
    Extensible = false;
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "File Account Scenario";
    InstructionalText = 'Assign file scenarios';
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(Content)
        {
            repeater(ScenariosByFile)
            {
                IndentationColumn = Indentation;
                IndentationControls = Name;
                ShowAsTree = true;

                field(Name; Rec."Display Name")
                {
                    Caption = 'Scenarios by file accounts';
                    ToolTip = 'Specifies the scenarios that are using the file account.';
                    Editable = false;
                    StyleExpr = Style;
                }
                field(Default; DefaultTxt)
                {
                    Caption = 'Default';
                    ToolTip = 'Specifies whether this is the default account to use for scenarios when no other account is specified.';
                    StyleExpr = Style;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Account)
            {
                action(AddScenario)
                {
                    Visible = (TypeOfEntry = TypeOfEntry::Account) and CanUserManageFileSetup;
                    Caption = 'Assign scenarios';
                    ToolTip = 'Assign file scenarios for the selected file account. When assigned, everyone will use the account for the scenario. For example, if you assign the Sales Order scenario, everyone will use the account to send sales orders.';
                    Image = NewDocument;
                    Scope = Repeater;

                    trigger OnAction()
                    begin
                        TempSelectedFileAccountScenario := Rec;
                        FileScenarioImpl.AddScenarios(Rec);

                        FileScenarioImpl.GetScenariosByFileAccount(Rec);
                        SetSelectedRecord();
                    end;
                }
            }

            group(Scenario)
            {
                action(ChangeAccount)
                {
                    Visible = (TypeOfEntry = TypeOfEntry::Scenario) and CanUserManageFileSetup;
                    Caption = 'Reassign';
                    ToolTip = 'Reassign the selected scenarios to another file account.';
                    Image = Change;
                    Scope = Repeater;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(Rec);
                        TempSelectedFileAccountScenario := Rec;

                        FileScenarioImpl.ChangeAccount(Rec);
                        FileScenarioImpl.GetScenariosByFileAccount(Rec); // refresh the data on the page
                        SetSelectedRecord();
                    end;
                }
                action(Unassign)
                {
                    Visible = (TypeOfEntry = TypeOfEntry::Scenario) and CanUserManageFileSetup;
                    Caption = 'Unassign';
                    ToolTip = 'Unassign the selected scenarios. Afterward, the default file account will be used to send files for the scenarios.';
                    Image = Delete;
                    Scope = Repeater;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(Rec);
                        TempSelectedFileAccountScenario := Rec;

                        FileScenarioImpl.DeleteScenario(Rec);
                        FileScenarioImpl.GetScenariosByFileAccount(Rec); // refresh the data on the page
                        SetSelectedRecord();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(AddScenario_Promoted; AddScenario) { }
                actionref(ChangeAccount_Promoted; ChangeAccount) { }
                actionref(Unassign_Promoted; Unassign) { }
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000CTN', 'File Access', Enum::"Feature Uptake Status"::Discovered);
        CanUserManageFileSetup := FileAccountImpl.IsUserFileAdmin();
        FileScenarioImpl.GetScenariosByFileAccount(Rec);

        // Set selection
        if not Rec.Get(-1, FileAccountId, FileConnector) then
            if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        DefaultTxt := '';

        TypeOfEntry := Rec.EntryType;

        if TypeOfEntry = TypeOfEntry::Account then begin
            Indentation := 0;
            Style := 'Strong';
            if Rec.Default then
                DefaultTxt := '✓'
        end;

        if TypeOfEntry = TypeOfEntry::Scenario then begin
            Indentation := 1;
            Style := 'Standard';
        end;
    end;

    // Used to set the focus on a file account
    internal procedure SetFileAccountId(AccountId: Guid; Connector: Enum "Ext. File Storage Connector")
    begin
        FileAccountId := AccountId;
        FileConnector := Connector;
    end;

    local procedure SetSelectedRecord()
    begin
        if not Rec.Get(TempSelectedFileAccountScenario.Scenario, TempSelectedFileAccountScenario."Account Id", TempSelectedFileAccountScenario.Connector) then
            Rec.FindFirst();
    end;

    var
        TempSelectedFileAccountScenario: Record "File Account Scenario" temporary;
        FileScenarioImpl: Codeunit "File Scenario Impl.";
        FileAccountImpl: Codeunit "File Account Impl.";
        FileAccountId: Guid;
        FileConnector: Enum "Ext. File Storage Connector";
        Style, DefaultTxt : Text;
        TypeOfEntry: Enum "File Account Entry Type";
        Indentation: Integer;
        CanUserManageFileSetup: Boolean;
}