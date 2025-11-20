// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Ledger;

page 412 "Bank Rec. Line Match Details"
{
    Caption = 'Match Details';
    DataCaptionExpression = ' ';
    LinksAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Bank Acc. Reconciliation Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control7)
            {
                Caption = ' ';
                ShowCaption = false;
                field(MatchDetails; MatchDetails)
                {
                    Caption = ' ';
                    ShowCaption = false;
                    Editable = false;
                    Enabled = false;
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Control8)
            {
                Caption = ' ';
                ShowCaption = false;
                part(ApplyBankLedgerEntries; "Applied Bank Acc. Ledger Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Ledger Entry';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
    begin
        PaymentMatchingDetails.SetRange("Statement Type", Rec."Statement Type");
        PaymentMatchingDetails.SetRange("Statement No.", Rec."Statement No.");
        PaymentMatchingDetails.SetRange("Statement Line No.", Rec."Statement Line No.");
        PaymentMatchingDetails.SetRange("Bank Account No.", Rec."Bank Account No.");
        PaymentMatchingDetails.SetFilter(Message, '<>''''');
        if PaymentMatchingDetails.FindLast() then
            MatchDetails := PaymentMatchingDetails.Message;

        PopulateLedgerEntrySubpage();
    end;

    var
        MatchDetails: Text;

    local procedure PopulateLedgerEntrySubpage()
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        Rec.FilterManyToOneMatches(BankAccRecMatchBuffer);
        if BankAccRecMatchBuffer.FindFirst() then
            BankAccountLedgerEntry.SetRange("Entry No.", BankAccRecMatchBuffer."Ledger Entry No.")
        else begin
            BankAccountLedgerEntry.SetRange("Statement No.", Rec."Statement No.");
            BankAccountLedgerEntry.SetRange("Statement Line No.", Rec."Statement Line No.");
            BankAccountLedgerEntry.SetRange("Bank Account No.", Rec."Bank Account No.");
        end;

        CurrPage.ApplyBankLedgerEntries.Page.SetTableView(BankAccountLedgerEntry);
        CurrPage.ApplyBankLedgerEntries.Page.Update();
    end;
}
