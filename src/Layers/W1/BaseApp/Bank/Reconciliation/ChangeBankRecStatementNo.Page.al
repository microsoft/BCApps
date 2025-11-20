// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

page 1285 "Change Bank Rec. Statement No."
{
    PageType = StandardDialog;
    Caption = 'Change Statement No.';

    layout
    {
        area(Content)
        {
            field(NewStatementNumber; NewStatementNo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New Statement No.';
                ToolTip = 'Specifies the new number of the bank account statement.';
                NotBlank = true;

                trigger OnValidate()
                var
                    BankAccReconciliation: Record "Bank Acc. Reconciliation";
                begin
                    if NewStatementNo <> GlobalBankAccReconciliation."Statement No." then
                        if BankAccReconciliation.Get(
                            GlobalBankAccReconciliation."Statement Type"::"Bank Reconciliation",
                            GlobalBankAccReconciliation."Bank Account No.",
                            NewStatementNo)
                        then
                            Error(StatementAlreadyExistsErr, NewStatementNo);
                end;
            }
        }
    }

    actions
    {
    }

    var
        GlobalBankAccReconciliation: Record "Bank Acc. Reconciliation";
        StatementAlreadyExistsErr: Label 'A bank account reconciliation with statement number %1 already exists.', Comment = '%1 - statement number';
        NewStatementNo: Code[20];

    procedure SetBankAccReconciliation(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        GlobalBankAccReconciliation := BankAccReconciliation;
        NewStatementNo := BankAccReconciliation."Statement No.";
    end;

    procedure GetNewStatementNo(): Code[20]
    begin
        exit(NewStatementNo);
    end;
}
