// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Statement;

/// <summary>
/// Displays list of bank reconciliation lines for manual entry and editing.
/// Provides interface for adding, modifying, and managing reconciliation line items.
/// </summary>
page 380 "Bank Acc. Reconciliation Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Bank Acc. Reconciliation Line";
    SourceTableView = where("Statement Type" = const("Bank Reconciliation"));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Transaction Date"; Rec."Transaction Date")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                }
                field("Value Date"; Rec."Value Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Check No."; Rec."Check No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                }
                field("Statement Amount"; Rec."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the amount of the transaction on the bank''s statement shown on this reconciliation line.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Applied Amount"; Rec."Applied Amount")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        Rec.DisplayApplication();
                    end;
                }
                field(Difference; Rec.Difference)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Applied Entries"; Rec."Applied Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Related-Party Name"; Rec."Related-Party Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Additional Transaction Info"; Rec."Additional Transaction Info")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
            group(Control16)
            {
                ShowCaption = false;
                label(Control13)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    Caption = ' ';
                }
                field(Balance; Balance + Rec."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec.GetCurrencyCode();
                    AutoFormatType = 1;
                    Caption = 'Balance';
                    Editable = false;
                    Enabled = BalanceEnable;
                    ToolTip = 'Specifies a balance, consisting of the Balance Last Statement field, plus the balance that has accumulated in the Statement Amount field.';
                }
                field(TotalBalance; TotalBalance + Rec."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec.GetCurrencyCode();
                    AutoFormatType = 1;
                    Caption = 'Total Balance';
                    Editable = false;
                    Enabled = TotalBalanceEnable;
                    ToolTip = 'Specifies the accumulated balance of the bank reconciliation, which consists of the Balance Last Statement field, plus the balance in the Statement Amount field.';
                }
                field(TotalDiff; TotalDiff + Rec.Difference)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec.GetCurrencyCode();
                    AutoFormatType = 1;
                    Caption = 'Total Difference';
                    Editable = false;
                    Enabled = TotalDiffEnable;
                    ToolTip = 'Specifies the total amount of the Difference field for all the lines on the bank reconciliation.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowStatementLineDetails)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Details';
                RunObject = Page "Bank Statement Line Details";
                RunPageLink = "Data Exch. No." = field("Data Exch. Entry No."),
                              "Line No." = field("Data Exch. Line No.");
                ToolTip = 'View additional information about the document on the selected line and link to the related card.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."Statement Line No." <> 0 then
            CalcBalance(Rec."Statement Line No.");
        SetUserInteractions();
    end;

    trigger OnAfterGetRecord()
    begin
        SetUserInteractions();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        SetUserInteractions();
    end;

    trigger OnInit()
    begin
        BalanceEnable := true;
        TotalBalanceEnable := true;
        TotalDiffEnable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if BelowxRec then
            CalcBalance(xRec."Statement Line No.")
        else
            CalcBalance(xRec."Statement Line No." - 1);
    end;

    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        StyleTxt: Text;
        TotalDiffEnable: Boolean;
        TotalBalanceEnable: Boolean;
        BalanceEnable: Boolean;

    protected var
        TotalDiff: Decimal;
        Balance: Decimal;
        TotalBalance: Decimal;

    local procedure CalcBalance(BankAccReconLineNo: Integer)
    var
        CopyBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        if BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.") then;

        CopyBankAccReconciliationLine.Copy(Rec);

        TotalDiff := -Rec.Difference;
        if CopyBankAccReconciliationLine.CalcSums(Difference) then begin
            TotalDiff := TotalDiff + CopyBankAccReconciliationLine.Difference;
            TotalDiffEnable := true;
        end;

        TotalBalance := BankAccReconciliation."Balance Last Statement" - Rec."Statement Amount";
        if CopyBankAccReconciliationLine.CalcSums("Statement Amount") then begin
            TotalBalance := TotalBalance + CopyBankAccReconciliationLine."Statement Amount";
            TotalBalanceEnable := true;
        end;

        Balance := BankAccReconciliation."Balance Last Statement" - Rec."Statement Amount";
        CopyBankAccReconciliationLine.SetRange("Statement Line No.", 0, BankAccReconLineNo);
        if CopyBankAccReconciliationLine.CalcSums("Statement Amount") then begin
            Balance := Balance + CopyBankAccReconciliationLine."Statement Amount";
            BalanceEnable := true;
        end;
    end;

    procedure GetSelectedRecords(var TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        CurrPage.SetSelectionFilter(BankAccReconciliationLine);
        if BankAccReconciliationLine.FindSet() then
            repeat
                TempBankAccReconciliationLine := BankAccReconciliationLine;
                TempBankAccReconciliationLine.Insert();
            until BankAccReconciliationLine.Next() = 0;
    end;

    local procedure SetUserInteractions()
    begin
        StyleTxt := Rec.GetStyle();
    end;

    procedure ToggleMatchedFilter(SetFilterOn: Boolean)
    begin
        if SetFilterOn then
            Rec.SetFilter(Difference, '<>%1', 0)
        else
            Rec.SetRange(Difference);
        CurrPage.Update();
    end;
}

