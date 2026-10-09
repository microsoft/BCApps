// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50154 "Filename Proof Issue Rmdr"
{
    // Builds a reminder for the same customer as an existing one, at reminder level 3, and puts
    // it through the real Reminder-Issue routine.
    //
    // A separate codeunit rather than a TryFunction because it writes, and AL forbids writes
    // inside a TryFunction. Run through Codeunit.Run, the caller gets the same isolation: if
    // issuing will not work in this company, everything this does is rolled back and the caller
    // carries on.

    TableNo = "Issued Reminder Header";

    trigger OnRun()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ReminderIssue: Codeunit "Reminder-Issue";
    begin
        ReminderHeader.Init();
        ReminderHeader.Insert(true);
        ReminderHeader.Validate("Customer No.", Rec."Customer No.");
        ReminderHeader.Validate("Posting Date", WorkDate());
        ReminderHeader.Validate("Document Date", WorkDate());
        ReminderHeader.Validate("Due Date", WorkDate());
        if Rec."Reminder Terms Code" <> '' then
            ReminderHeader.Validate("Reminder Terms Code", Rec."Reminder Terms Code");
        ReminderHeader."Reminder Level" := 3;
        ReminderHeader.Modify(true);

        ReminderLine.Init();
        ReminderLine."Reminder No." := ReminderHeader."No.";
        ReminderLine."Line No." := 10000;
        ReminderLine.Description := ProofLineTok;
        ReminderLine.Insert(true);

        ReminderIssue.Set(ReminderHeader, false, 0D);
        ReminderIssue.Run();
    end;

    var
        ProofLineTok: Label 'Filename proof line', Locked = true;
}
