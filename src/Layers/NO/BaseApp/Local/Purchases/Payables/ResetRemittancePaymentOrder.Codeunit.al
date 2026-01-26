// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.GeneralLedger.Journal;

codeunit 15000000 "Reset Remittance Payment Order"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;

    trigger OnRun()
    var
        WaitingJournal: Record "Waiting Journal";
    begin
        // Only the PaymOrders with PaymOrder type=Export can be reseted.
        if CurrentRemPaymOrder.Type <> CurrentRemPaymOrder.Type::Export then
            CurrentRemPaymOrder.FieldError(Type);

        // Ask the user if he wan'ts to reset:
        if not HideDialog then
            if not Confirm(Text000 + Text001 + Text002 + Text003 + Text004 + Text005, false, CurrentRemPaymOrder.ID) then
                Error('');

        // PaymOrder is marked as reseted:
        CurrentRemPaymOrder.Canceled := true;
        CurrentRemPaymOrder.Modify();

        // Delete marks for vendor entries and check if the status is Sent for Waiting journal lines:
        // Go through all Waiting journal lines:
        WaitingJournal.Init();
        WaitingJournal.SetRange("Payment Order ID - Sent", CurrentRemPaymOrder.ID);
        WaitingJournal.FindSet();
        repeat
            ResetWaitingJournalLine(WaitingJournal);
        until WaitingJournal.Next() = 0;
    end;

    var
        Text000: Label 'Warning: Cancelling a remittance payment order could cause problems.\';
        Text001: Label 'Note following:\';
        Text002: Label '- Payments from the payment order must be remitted or posted again.\';
        Text003: Label '- If data received in return from the bank contain links to payments in the payment order, an error will occur.\';
        Text004: Label '- Sequence no./daily sequence no. may have to be adjusted to the correct value.\\';
        Text005: Label 'Cancel remittance payment order %1?';
        Text006: Label 'Warning: Cancelling a payment can cause problems.\';
        Text007: Label 'Cancel waiting journal reference %1?';
        CurrentRemPaymOrder: Record "Remittance Payment Order";
        RemTools: Codeunit "Remittance Tools";
        HideDialog: Boolean;

    procedure ResetWaitingJournalLine(WaitingJournal: Record "Waiting Journal")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // Reset Waiting journal line and corresponding entries.
        // This function should be used as external, not only as local.

        // Status must be Sent:
        if WaitingJournal."Remittance Status" = WaitingJournal."Remittance Status"::Settled then
            WaitingJournal.FieldError("Remittance Status");

        // For each Waiting journal line: delete marks on corresponding entries:
        GenJnlLine.Init();
        GenJnlLine.TransferFields(WaitingJournal); // Create parameter.
        RemTools.MarkEntry(GenJnlLine, '', 0); // Delete marks on entries.

        // Reset Waiting journal:
        WaitingJournal.Validate("Remittance Status", WaitingJournal."Remittance Status"::Reseted);

        WaitingJournal.Modify();
    end;

    [Scope('OnPrem')]
    procedure ResetWaitingJournalJN(WaitingJournal: Record "Waiting Journal")
    begin
        // Ask the user if he wants to reset:
        if not Confirm(Text006 + Text001 + Text002 + Text003 + Text004 + Text007, false, WaitingJournal.Reference) then
            Error('');

        ResetWaitingJournalLine(WaitingJournal);
    end;

    [Scope('OnPrem')]
    procedure SetPaymOrder(RemPaymOrder: Record "Remittance Payment Order")
    begin
        //Specify current PaymOrder:
        CurrentRemPaymOrder := RemPaymOrder;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;
}

