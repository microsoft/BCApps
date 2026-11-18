// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;

codeunit 149504 "Filename Proof Issue Rmdr"
{
    // Issues a level 3 reminder for real: posts an invoice for the model reminder's customer, then
    // has Reminder-Make and Reminder-Issue make levels 1, 2 and 3 at ten-day steps (Reminder-Make
    // takes an entry's level from its last issued one). Reminder-Issue refuses a reminder with no
    // amount, so a hand-written header cannot be used.
    // A codeunit rather than a TryFunction because it writes, which on-premises a TryFunction does
    // not allow by default.

    TableNo = "Issued Reminder Header";

    trigger OnRun()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TestData: Codeunit "Filename Test Data";
        Level: Integer;
    begin
        Clear(IssuedLevel3No);
        Rec.TestField("Reminder Terms Code");

        Customer.Get(Rec."Customer No.");
        Customer.Validate("Reminder Terms Code", Rec."Reminder Terms Code");
        Customer.Modify(true);

        TestData.PostNewInvoice(Customer."No.", SalesInvoiceHeader);

        for Level := 1 to 3 do
            MakeAndIssue(Customer, Level);
    end;

    // Blank when the last run did not reach level 3.
    internal procedure IssuedReminderNo(): Code[20]
    begin
        exit(IssuedLevel3No);
    end;

    local procedure MakeAndIssue(var Customer: Record Customer; Level: Integer)
    var
        ReminderHeaderReq: Record "Reminder Header";
        ReminderHeader: Record "Reminder Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        NoLineFeeEntries: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
        ReminderIssue: Codeunit "Reminder-Issue";
        DocumentDate: Date;
    begin
        DocumentDate := CalcDate(StrSubstNo(DaysLaterTok, Level * 10), WorkDate());
        ReminderHeaderReq.Init();
        ReminderHeaderReq."Posting Date" := DocumentDate;
        ReminderHeaderReq."Document Date" := DocumentDate;

        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        ReminderMake.Set(Customer, CustLedgerEntry, ReminderHeaderReq, false, false, NoLineFeeEntries);
        if not ReminderMake.Code() then
            Error(NotMadeErr, Level, Customer."No.");

        // Issuing leaves no reminder behind, so the customer's one open reminder is the one just made.
        ReminderHeader.SetRange("Customer No.", Customer."No.");
        if not ReminderHeader.FindFirst() then
            Error(NotMadeErr, Level, Customer."No.");

        ReminderIssue.Set(ReminderHeader, false, 0D);
        ReminderIssue.Run();
        ReminderIssue.GetIssuedReminder(IssuedReminderHeader);

        if IssuedReminderHeader."Reminder Level" <> Level then
            Error(WrongLevelErr, IssuedReminderHeader."No.", IssuedReminderHeader."Reminder Level", Level);
        if Level = 3 then
            IssuedLevel3No := IssuedReminderHeader."No.";
    end;

    var
        IssuedLevel3No: Code[20];
        DaysLaterTok: Label '<+%1D>', Comment = '%1 how many days', Locked = true;
        NotMadeErr: Label 'Reminder-Make created no level %1 reminder for customer %2.', Comment = '%1 the level, %2 the customer';
        WrongLevelErr: Label 'Reminder-Issue issued reminder %1 at level %2, where level %3 was expected.', Comment = '%1 the reminder, %2 its level, %3 the level expected';
}
