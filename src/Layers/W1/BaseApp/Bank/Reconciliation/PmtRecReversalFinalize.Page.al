// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

page 531 "Pmt. Rec. Reversal Finalize"
{
    PageType = NavigatePage;
    Caption = 'Reverse Payment Reconciliation Journal';
    layout
    {
        area(Content)
        {
            label(FinalizeLabel)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = FinalizeTxt;
            }
            field(CreatePaymentRecJournal; CreatePaymentRecJournal)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create new Payment Reconciliation Journal';
                ToolTip = 'Specifies if a Payment Reconciliation Journal will be created with the same entries as the reversed one.';
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Back';
                Image = PreviousRecord;

                trigger OnAction()
                begin
                    ActionSelected := ActionSelected::Back;
                    CurrPage.Close();
                end;
            }
            action(ActionFinalize)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Finalize';
                Image = NextRecord;

                trigger OnAction()
                begin
                    ActionSelected := ActionSelected::Finalize;
                    CurrPage.Close();
                end;
            }
        }
    }


    var
        CreatePaymentRecJournal: Boolean;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        ActionSelected: Option Nothing,Back,Finalize;
        FinalizeMsg: Label 'After finalizing, the bank statement will be undone, %1 entries will be unapplied and %2 entries will be reversed. You can only unapply and revert the entries manually after this.', Comment = '%1 - Number of entries to unapply, %2 - Number of entries to reverse';
        FinalizeNoStatementMsg: Label 'After finalizing, %1 entries will be unapplied and %2 entries will be reversed. You can only unapply and revert the entries manually after this.', Comment = '%1 - Number of entries to unapply, %2 - Number of entries to reverse';
        FinalizeTxt: Text;
        ShowingNoStatementMsg: Boolean;

    trigger OnOpenPage()
    var
        PaymentRecRelatedEntry: Record "Payment Rec. Related Entry";
        ToUnapply: Integer;
        ToReverse: Integer;
    begin
        CreatePaymentRecJournal := true;
        ActionSelected := ActionSelected::Nothing;
        PaymentRecRelatedEntry.SetRange("Bank Account No.", BankAccountNo);
        PaymentRecRelatedEntry.SetRange("Statement No.", StatementNo);
        PaymentRecRelatedEntry.SetFilter("Entry Type", '<> %1', PaymentRecRelatedEntry."Entry Type"::"Bank Account");
        PaymentRecRelatedEntry.SetRange(ToUnapply, true);
        ToUnapply := PaymentRecRelatedEntry.Count();
        PaymentRecRelatedEntry.SetRange(ToUnapply);
        PaymentRecRelatedEntry.SetRange(ToReverse, true);
        ToReverse := PaymentRecRelatedEntry.Count();
        if not ShowingNoStatementMsg then
            FinalizeTxt := Text.StrSubstNo(FinalizeMsg, ToUnapply, ToReverse)
        else
            FinalizeTxt := Text.StrSubstNo(FinalizeNoStatementMsg, ToUnapply, ToReverse);
    end;

    procedure SetNoStatementMsg()
    begin
        ShowingNoStatementMsg := true;
    end;

    procedure BackSelected(): Boolean
    begin
        exit(ActionSelected = ActionSelected::Back);
    end;

    procedure FinalizeSelected(): Boolean
    begin
        exit(ActionSelected = ActionSelected::Finalize);
    end;

    procedure CreatePaymentRecJournalSelected(): Boolean
    begin
        exit(CreatePaymentRecJournal);
    end;

    procedure SetPaymentRecRelatedEntries(NewBankAccountNo: Code[20]; NewStatementNo: Code[20])
    begin
        BankAccountNo := NewBankAccountNo;
        StatementNo := NewStatementNo;
    end;

}
