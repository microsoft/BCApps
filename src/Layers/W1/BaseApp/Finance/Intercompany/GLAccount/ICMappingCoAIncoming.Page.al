// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.GLAccount;

using Microsoft.Finance.GeneralLedger.Account;

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
