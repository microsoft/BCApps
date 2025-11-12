// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;

page 417 "Post Pmts and Rec. Bank Acc."
{
    PageType = StandardDialog;
    SourceTable = "Bank Acc. Reconciliation";
    Caption = 'Bank Account Reconciliation';

    layout
    {
        area(Content)
        {
            field("Balance Last Statement"; Rec."Balance Last Statement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance Last Statement';
                ToolTip = 'Specifies the ending balance shown on the last bank statement, which was used in the last posted bank reconciliation for this bank account.';
                trigger OnValidate()
                var
                    BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                begin
                    Rec.Modify();
                    BankAccReconciliationLine.LinesExist(Rec);
                    BankAccReconciliationLine.CalcSums("Statement Amount", Difference);
                    TotalBalance := Rec."Balance Last Statement" + BankAccReconciliationLine."Statement Amount";
                    CurrPage.Update();
                end;
            }
            field("Statement Ending Balance"; Rec."Statement Ending Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement Ending Balance';
                ToolTip = 'Specifies the ending balance shown on the bank''s statement that you want to reconcile with the bank account.';
                trigger OnValidate()
                begin
                    Rec.Modify();
                    CurrPage.Update();
                end;
            }
            field(TotalBalance; TotalBalance)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatExpression = GetCurrencyCode();
                AutoFormatType = 1;
                Editable = false;
                Caption = 'Total Balance';
                ToolTip = 'Specifies the accumulated balance of the bank reconciliation, which consists of the Balance Last Statement field, plus the balance in the Statement Amount field.';
            }
            field(StatementDate; Rec."Statement Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement Date';
                ToolTip = 'Specifies the date on the bank account statement.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.LinesExist(Rec);
        BankAccReconciliationLine.CalcSums("Statement Amount", Difference);
        TotalBalance := Rec."Balance Last Statement" + BankAccReconciliationLine."Statement Amount";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::LookupOK then
            exit(CheckStatementDate());
    end;

    var
        TotalBalance: Decimal;
        StatementDateEmptyMsg: Label 'The bank account reconciliation does not have a statement date. %1 is the latest date on a line. Do you want to use that date for the statement?', Comment = '%1 - statement date';

    local procedure GetCurrencyCode(): Code[10]
    var
        BankAcc: Record "Bank Account";
    begin
        if Rec."Bank Account No." = BankAcc."No." then
            exit(BankAcc."Currency Code");

        if BankAcc.Get(Rec."Bank Account No.") then
            exit(BankAcc."Currency Code");

        exit('');
    end;

    local procedure CheckStatementDate(): Boolean
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetFilter("Bank Account No.", Rec."Bank Account No.");
        BankAccReconciliationLine.SetFilter("Statement No.", Rec."Statement No.");
        BankAccReconciliationLine.SetCurrentKey("Transaction Date");
        BankAccReconciliationLine.Ascending := false;
        if BankAccReconciliationLine.FindFirst() then
            if Rec."Statement Date" = 0D then
                if Confirm(StrSubstNo(StatementDateEmptyMsg, Format(BankAccReconciliationLine."Transaction Date"))) then begin
                    Rec."Statement Date" := BankAccReconciliationLine."Transaction Date";
                    Rec.Modify();
                    exit(true);
                end else
                    exit(false);
        exit(true);
    end;
}
