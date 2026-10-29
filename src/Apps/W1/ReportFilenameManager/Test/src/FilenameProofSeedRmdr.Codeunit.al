// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Reminder;

codeunit 149523 "Filename Proof Seed Rmdr"
{
    // Makes sure the company has a level 1 issued reminder for the reminder proofs to start from.
    // It is constructed rather than issued: issuing needs overdue entries and posting setup the
    // proofs are not about.

    Access = Internal;

    trigger OnRun()
    begin
        if not EnsureLevel1() then
            Error(CouldNotSeedErr);
    end;

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
        // The level selects the pattern; the terms are read by Base Application's attachment naming.
        IssuedReminderHeader."Reminder Terms Code" := ReminderTerms.Code;
        IssuedReminderHeader."Posting Date" := WorkDate();
        IssuedReminderHeader."Document Date" := WorkDate();
        IssuedReminderHeader."Due Date" := WorkDate();
        IssuedReminderHeader."Language Code" := Customer."Language Code";
        IssuedReminderHeader."Currency Code" := Customer."Currency Code";
        CopyWhatTheReportReads(IssuedReminderHeader, Customer);
        // Without triggers, as Reminder-Issue inserts it.
        IssuedReminderHeader.Insert(false);
        exit(true);
    end;

    // What a reminder copies from its customer (Reminder Header's Customer No. validation) and the
    // Reminder report reads; without the Customer Posting Group the stand-in cannot be printed.
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

    // Completes an existing stand-in that lacks those fields, so it can be printed.
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
