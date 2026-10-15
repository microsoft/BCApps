// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50154 "Filename Proof Issue Rmdr"
{
    // Issues a level 3 reminder for real, the way a company does: an invoice is left unpaid past
    // its due date, and Base Application's own Reminder-Make creates a reminder for it and
    // Reminder-Issue issues it - three times, because a reminder reaches level 3 only by levels 1
    // and 2 having been issued for the same entry before it.
    //
    // Everything it uses is the proof's own: the customer and the reminder terms of the model
    // reminder it is run on (Filename Test Data made both; the terms have levels 1 to 3 with no
    // grace period, no due date calculation, no fees and no attachment texts), and an invoice it
    // posts for that customer at the work date, which is therefore due at the work date. The three
    // reminders are dated ten, twenty and thirty days after it, so each finds the entry overdue
    // and the previous reminder's due date passed - which is what Reminder-Make asks of the next
    // level. Nothing is posted to the general ledger: there is no fee and no interest.
    //
    // The first version of this codeunit wrote a reminder header at level 3 with one line of text
    // and issued that. Reminder-Issue refuses a reminder with no amount on it - "There is nothing
    // to issue" - so the real route never once ran, and the proof always fell back to a
    // constructed document. A reminder Reminder-Make builds carries the open invoice, so it does.
    //
    // A separate codeunit rather than a TryFunction because it writes, and AL forbids writes
    // inside a TryFunction. Run through Codeunit.Run, the caller gets the same isolation: if
    // issuing will not work in this company, everything this does is rolled back and the caller
    // carries on - except what Reminder-Issue itself commits, which is the proof's own data.

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

        // The entry the reminders are about.
        TestData.PostNewInvoice(Customer."No.", SalesInvoiceHeader);

        for Level := 1 to 3 do
            MakeAndIssue(Customer, Level);
    end;

    /// <summary>
    /// The number of the level 3 reminder the last run issued; blank when it did not get that far.
    /// </summary>
    internal procedure IssuedReminderNo(): Code[20]
    begin
        exit(IssuedLevel3No);
    end;

    /// <summary>
    /// Has Reminder-Make create the customer's next reminder, dated ten days on per level, issues it
    /// through Reminder-Issue, and insists it came out at the level expected.
    /// </summary>
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

        // The customer is the proof's own, and an issued reminder leaves no reminder behind, so the
        // one open reminder for that customer is the one just made.
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
