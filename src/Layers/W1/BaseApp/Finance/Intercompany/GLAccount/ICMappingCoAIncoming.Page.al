// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.GLAccount;

using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// List interface for mapping incoming intercompany G/L accounts to local G/L accounts.
/// Provides selection and mapping capabilities for IC account synchronization from partners.
/// </summary>
page 627 "IC Mapping CoA Incoming"
{
    PageType = ListPart;
    SourceTable = "IC G/L Account";
    Editable = true;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(ICNo; Rec."No.")
                {
                    Caption = 'IC No.';
                    ToolTip = 'Specifies the intercompany account number.';
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Editable = false;
                    Enabled = false;
                }
                field(ICName; Rec.Name)
                {
                    Caption = 'IC Name';
                    ToolTip = 'Specifies the intercompany account name.';
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Editable = false;
                    Enabled = false;
                }
                field(GLNo; Rec."Map-to G/L Acc. No.")
                {
                    Caption = 'G/L No.';
                    ToolTip = 'Specifies the G/L account number associated with the corresponding intercompany account.';
                    ApplicationArea = All;
                    TableRelation = "G/L Account"."No.";
                    Editable = true;
                    Enabled = true;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        FormatLine();
    end;

    var
        Emphasize: Boolean;
        NameIndent: Integer;

    /// <summary>
    /// Returns the currently selected intercompany G/L accounts from the page.
    /// Used for batch operations on multiple selected accounts.
    /// </summary>
    /// <param name="ICAccounts">Record set to be populated with selected IC accounts</param>
    procedure GetSelectedLines(var ICAccounts: Record "IC G/L Account")
    begin
        CurrPage.SetSelectionFilter(ICAccounts);
    end;

    local procedure FormatLine()
    begin
        NameIndent := Rec.Indentation;
        Emphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;
}
