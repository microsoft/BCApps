// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.GLAccount;

using Microsoft.Finance.GeneralLedger.Account;

page 628 "IC Mapping CoA Outgoing"
{
    PageType = ListPart;
    SourceTable = "G/L Account";
    Editable = true;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(GLNo; Rec."No.")
                {
                    Caption = 'G/L No.';
                    ToolTip = 'Specifies the G/L account number.';
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Editable = false;
                    Enabled = false;
                }
                field(GLName; Rec.Name)
                {
                    Caption = 'G/L Name';
                    ToolTip = 'Specifies the G/L account name.';
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    Editable = false;
                    Enabled = false;
                }
                field(ICNo; Rec."Default IC Partner G/L Acc. No")
                {
                    Caption = 'IC No.';
                    ToolTip = 'Specifies the intercompany account number associated with the G/L account.';
                    ApplicationArea = All;
                    TableRelation = "IC G/L Account"."No.";
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

    procedure GetSelectedLines(var GLAccounts: Record "G/L Account")
    begin
        CurrPage.SetSelectionFilter(GLAccounts);
    end;

    local procedure FormatLine()
    begin
        NameIndent := Rec.Indentation;
        Emphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;
}
