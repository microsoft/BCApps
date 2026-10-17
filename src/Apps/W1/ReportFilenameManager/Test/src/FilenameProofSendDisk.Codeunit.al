// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50171 "Filename Proof Send Disk"
{
    // Calls the real Send to Disk route, isolated so its failure cannot end the proof.
    //
    // The route renders the report and then hands the file to a client download. A test session
    // has no client to receive it, so the call fails - after the name has already been decided.
    // That is the same shape as Filename Proof Show Inbox, and the same reason: what is being
    // proven happens before the part that cannot work here.
    //
    // Report Selections.SendToDiskForCust is Scope = 'OnPrem', which is why this app targets
    // OnPrem. The app under test does not: it subscribes to an event, which carries no scope, so
    // the deliverable stays Cloud-targeted. See docs/TODO.md.

    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        ReportSelections: Record "Report Selections";
        RecordVariant: Variant;
    begin
        // Narrowed to this one document first, for the reason Filename Proof Attach PDF records: a
        // Variant carries the record's filters, and without this the route renders every posted
        // invoice the caller's filter lets through.
        Rec.SetRecFilter();
        RecordVariant := Rec;
        ReportSelections.SendToDiskForCust(
            Enum::"Report Selection Usage"::"S.Invoice", RecordVariant, Rec."No.", DocumentNameTok, Rec."Bill-to Customer No.");
    end;

    var
        // What Base Application would call the document. It is passed through to the route and is
        // deliberately not what the proof checks: the point is that the pattern replaces it.
        DocumentNameTok: Label 'Invoice', Locked = true;
}
