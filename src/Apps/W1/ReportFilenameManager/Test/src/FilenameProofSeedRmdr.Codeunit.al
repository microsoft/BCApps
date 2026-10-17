// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50173 "Filename Proof Seed Rmdr"
{
    // Makes sure the company has a level 1 issued reminder for the reminder proofs to work from.
    //
    // Those proofs build a level 3 reminder from an existing level 1, by issuing one for real
    // where the company allows it and constructing one where it does not. Neither route helps
    // when there is no level 1 to start from, and a freshly restored CRONUS has none - so on
    // 24 September 2026, in a container hours old, two proofs reported "no verdict at all" and
    // "this company has no issued reminder carrying both a level and reminder terms".
    //
    // Those two had been passing for weeks on a container where earlier runs had left reminders
    // behind. That is the part worth naming: they were never self-sufficient, and their green
    // was reporting on the environment rather than on the feature.
    //
    // Issuing a reminder for real needs overdue entries, reminder terms with levels, and posting
    // setup that reaches the general ledger. None of that is what these proofs are about - they
    // are about which pattern is selected for a document - so the document is constructed, and
    // the proof log says which route produced it, because that changes what the proof is worth.

    Access = Internal;

    trigger OnRun()
    begin
        if not EnsureLevel1() then
            Error(CouldNotSeedErr);
    end;

    /// <summary>
    /// A level 1 issued reminder carrying reminder terms, created only when the company has none.
    /// </summary>
    /// <returns>True when one exists afterwards.</returns>
    internal procedure EnsureLevel1(): Boolean
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
    begin
        IssuedReminderHeader.SetRange("Reminder Level", 1);
        IssuedReminderHeader.SetFilter("Reminder Terms Code", '<>%1', '');
        if not IssuedReminderHeader.IsEmpty() then
            exit(true);

        if not Customer.FindFirst() then
            exit(false);
        if not ReminderTerms.FindFirst() then
            exit(false);

        IssuedReminderHeader.Reset();
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." := SeedNoTok;
        if IssuedReminderHeader.Get(IssuedReminderHeader."No.") then
            exit(true);

        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." := SeedNoTok;
        IssuedReminderHeader."Customer No." := Customer."No.";
        IssuedReminderHeader.Name := Customer.Name;
        IssuedReminderHeader."Reminder Level" := 1;
        // Both are needed, and by different proofs: the level decides which pattern is selected,
        // and the terms are what Base Application's own attachment-naming subscriber reads.
        IssuedReminderHeader."Reminder Terms Code" := ReminderTerms.Code;
        IssuedReminderHeader."Posting Date" := WorkDate();
        IssuedReminderHeader."Document Date" := WorkDate();
        IssuedReminderHeader."Due Date" := WorkDate();
        IssuedReminderHeader."Language Code" := Customer."Language Code";
        IssuedReminderHeader."Currency Code" := Customer."Currency Code";
        CopyWhatTheReportReads(IssuedReminderHeader, Customer);
        // Insert without triggers, as the level 3 construction beside it does: this is a stand-in
        // document, and running the table's own logic would demand the very setup being avoided.
        IssuedReminderHeader.Insert(false);
        exit(true);
    end;

    /// <summary>
    /// What Reminder-Make copies from the customer and Base Application's Reminder report reads -
    /// as Filename Reminder Tests.BuildReminder sets it. Without the Customer Posting Group the
    /// stand-in could not be printed: "The Customer Posting Group does not exist" (container
    /// client, 8 October, client-pass row R.1).
    /// </summary>
    internal procedure CopyWhatTheReportReads(var IssuedReminderHeader: Record "Issued Reminder Header"; var Customer: Record Customer)
    begin
        IssuedReminderHeader."Customer Posting Group" := Customer."Customer Posting Group";
        IssuedReminderHeader."Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
        IssuedReminderHeader."VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
        IssuedReminderHeader.Address := Customer.Address;
        IssuedReminderHeader.City := Customer.City;
        IssuedReminderHeader."Post Code" := Customer."Post Code";
        IssuedReminderHeader."Country/Region Code" := Customer."Country/Region Code";
    end;

    /// <summary>
    /// Completes a stand-in made before CopyWhatTheReportReads existed, so it can be printed.
    /// </summary>
    internal procedure CompleteExistingStandIn()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        Customer: Record Customer;
    begin
        if not IssuedReminderHeader.Get(SeedNoTok) then
            exit;
        if not Customer.Get(IssuedReminderHeader."Customer No.") then
            exit;
        CopyWhatTheReportReads(IssuedReminderHeader, Customer);
        IssuedReminderHeader.Modify(false);
    end;

    var
        SeedNoTok: Label 'PROOF-RMDR-1', Locked = true;
        CouldNotSeedErr: Label 'No customer or no reminder terms in this company, so a level 1 reminder could not be constructed.';
}
