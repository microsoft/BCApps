// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

/// <summary>
/// Displays bank account statement lines in a list format for viewing transaction details.
/// Shows individual transactions from bank statements with amounts, dates, and reconciliation information.
/// </summary>
/// <remarks>
/// Source Table: Bank Account Statement Line (276). Part page for displaying statement line details.
/// Provides transaction-level view of bank statement data with balance calculations and difference tracking.
/// Integrates with bank reconciliation workflow for transaction review and validation.
/// </remarks>
page 384 "Bank Account Statement Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Bank Account Statement Line";

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
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statement Amount"; Rec."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
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

                    trigger OnDrillDown()
                    begin
                        Rec.DisplayApplication();
                    end;
                }
            }
            group(Control16)
            {
                ShowCaption = false;
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
                    ToolTip = 'Specifies the accumulated balance of the Bank Account Statement, which consists of the Balance Last Statement field, plus the balance in the Statement Amount field.';
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
    }

    trigger OnAfterGetCurrRecord()
    begin
        CalcBalance(Rec."Statement Line No.");
    end;

    trigger OnInit()
    begin
        BalanceEnable := true;
        TotalBalanceEnable := true;
        TotalDiffEnable := true;
    end;

    var
        TotalDiff: Decimal;
        TotalBalance: Decimal;
        Balance: Decimal;
        TotalDiffEnable: Boolean;
        TotalBalanceEnable: Boolean;
        BalanceEnable: Boolean;

    local procedure CalcBalance(BankAccStmtLineNo: Integer)
    var
        BankAccStmt: Record "Bank Account Statement";
        TempBankAccStmtLine: Record "Bank Account Statement Line";
    begin
        if BankAccStmt.Get(Rec."Bank Account No.", Rec."Statement No.") then;

        TempBankAccStmtLine.Copy(Rec);

        TotalDiff := -Rec.Difference;
        if TempBankAccStmtLine.CalcSums(Difference) then begin
            TotalDiff := TotalDiff + TempBankAccStmtLine.Difference;
            TotalDiffEnable := true;
        end else
            TotalDiffEnable := false;

        TotalBalance := BankAccStmt."Balance Last Statement" - Rec."Statement Amount";
        if TempBankAccStmtLine.CalcSums("Statement Amount") then begin
            TotalBalance := TotalBalance + TempBankAccStmtLine."Statement Amount";
            TotalBalanceEnable := true;
        end else
            TotalBalanceEnable := false;

        Balance := BankAccStmt."Balance Last Statement" - Rec."Statement Amount";
        TempBankAccStmtLine.SetRange("Statement Line No.", 0, BankAccStmtLineNo);
        if TempBankAccStmtLine.CalcSums("Statement Amount") then begin
            Balance := Balance + TempBankAccStmtLine."Statement Amount";
            BalanceEnable := true;
        end else
            BalanceEnable := false;
    end;
}

