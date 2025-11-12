// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Statement;

page 1300 "Pmt. Rec. Undo Statement"
{
    Caption = 'Reverse Payment Reconciliation Journal';
    PageType = NavigatePage;
    SourceTable = "Bank Account Statement";
    Editable = false;

    layout
    {
        area(Content)
        {
            label(UndoBankStatementLabel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'To reverse the Payment Reconciliation Journal, the following bank statement will be undone:';
            }
            field(BankAccountNo; Rec."Bank Account No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account No.';
                ToolTip = 'Specifies the number of the bank account that has been reconciled with this Bank Account Statement.';
            }
            field(BankAccountName; Rec."Bank Account Name")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account Name';
                ToolTip = 'Specifies the name of the bank account that has been reconciled.';
            }
            field(StatementNo; Rec."Statement No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement No.';
                ToolTip = 'Specifies the number of the bank''s statement that has been reconciled with the bank account.';
                trigger OnDrillDown()
                begin
                    Page.Run(Page::"Bank Account Statement", Rec);
                end;
            }
            field(StatementDate; Rec."Statement Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement Date';
                ToolTip = 'Specifies the date on the bank''s statement that has been reconciled with the bank account.';
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Next';
                Image = Approve;

                trigger OnAction()
                begin
                    IsNextSelected := true;
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        IsNextSelected: Boolean;
        StatementSet: Boolean;

    trigger OnOpenPage()
    begin
        if StatementSet then
            exit;
        IsNextSelected := true;
        Error('');
    end;

    procedure SetBankAccountStatement(BankAccountNoToOpen: Code[20]; StatementNoToOpen: Code[20])
    begin
        if not Rec.Get(BankAccountNoToOpen, StatementNoToOpen) then
            exit;
        StatementSet := true;
    end;

    procedure NextSelected(): Boolean
    begin
        exit(IsNextSelected);
    end;
}
