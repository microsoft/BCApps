// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Provides a comprehensive overview of the chart of accounts in a tree structure.
/// Displays G/L accounts with their hierarchical relationships, balances, and key properties in a read-only format.
/// </summary>
page 634 "Chart of Accounts Overview"
{
    Caption = 'Chart of Accounts Overview';
    ApplicationArea = Basic, Suite;
    PageType = List;
    UsageCategory = Lists;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "G/L Account";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowAsTree = true;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field("Net Change"; Rec."Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    BlankZero = true;
                }
                field(Balance; Rec.Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    BlankZero = true;
                }
                field("Account Category"; Rec."Account Category")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Income/Balance"; Rec."Income/Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Account Subcategory Descript."; Rec."Account Subcategory Descript.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Caption = 'Account Subcategory';
                    DrillDown = false;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Direct Posting"; Rec."Direct Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether you will be able to post directly or only indirectly to this general ledger account.';
                    Visible = false;
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        GLaccList: Page "G/L Account List";
                    begin
                        GLaccList.LookupMode(true);
                        GLaccList.RunModal();
                    end;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Balance at Date"; Rec."Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    Visible = false;
                }
                field("Additional-Currency Net Change"; Rec."Additional-Currency Net Change")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Visible = false;
                }
                field("Add.-Currency Balance at Date"; Rec."Add.-Currency Balance at Date")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Visible = false;
                }
                field("Additional-Currency Balance"; Rec."Additional-Currency Balance")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Visible = false;
                }
                field("Budgeted Amount"; Rec."Budgeted Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    Visible = false;
                }
                field("Consol. Debit Acc."; Rec."Consol. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Consol. Credit Acc."; Rec."Consol. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Cost Type No."; Rec."Cost Type No.")
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    Visible = false;
                }
                field("Consol. Translation Method"; Rec."Consol. Translation Method")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Default IC Partner G/L Acc. No"; Rec."Default IC Partner G/L Acc. No")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    Visible = false;
                }
                field("Default Deferral Template Code"; Rec."Default Deferral Template Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Deferral Template';
                    Editable = false;
                    Visible = false;
                }
                field("No. 2"; Rec."No. 2")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        FormatLine();
    end;

    trigger OnOpenPage()
    begin
        ExpandAll();
    end;

    var
        Emphasize: Boolean;
        NameIndent: Integer;

    local procedure ExpandAll()
    begin
        CopyGLAccToTemp(false);
    end;

    local procedure CopyGLAccToTemp(OnlyRoot: Boolean)
    var
        GLAcc: Record "G/L Account";
    begin
        Rec.Reset();
        Rec.DeleteAll();
        Rec.SetCurrentKey("No.");

        if OnlyRoot then
            GLAcc.SetRange(Indentation, 0);
        GLAcc.SetFilter("Account Type", '<>%1', GLAcc."Account Type"::"End-Total");
        if GLAcc.Find('-') then
            repeat
                Rec := GLAcc;
                if GLAcc."Account Type" = GLAcc."Account Type"::"Begin-Total" then
                    Rec.Totaling := GetEndTotal(GLAcc);
                Rec.Insert();
            until GLAcc.Next() = 0;

        if Rec.FindFirst() then;
    end;

    local procedure GetEndTotal(var GLAcc: Record "G/L Account"): Text[250]
    var
        GLAcc2: Record "G/L Account";
    begin
        GLAcc2.SetFilter("No.", '>%1', GLAcc."No.");
        GLAcc2.SetRange(Indentation, GLAcc.Indentation);
        GLAcc2.SetRange("Account Type", GLAcc2."Account Type"::"End-Total");
        if GLAcc2.FindFirst() then
            exit(GLAcc2.Totaling);

        exit('');
    end;

    local procedure FormatLine()
    begin
        NameIndent := Rec.Indentation;
        Emphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;
}
