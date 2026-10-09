// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50155 "Filename Proof Build Rmdr"
{
    // Constructs a level 3 issued reminder from an existing one, for the case where issuing a
    // real reminder cannot run in this company - it posts fees to the general ledger and
    // depends on a good deal of company setup.
    //
    // What the proof needs from this document is that it exists and carries reminder level 3:
    // the mechanism being proven is which pattern gets selected for a document, not how the
    // document came to be. The proof log records which of the two routes produced it, because
    // that changes what the proof is worth.

    TableNo = "Issued Reminder Header";

    trigger OnRun()
    var
        NewReminder: Record "Issued Reminder Header";
    begin
        NewReminder := Rec;
        NewReminder."No." := CopyStr(Rec."No." + Level3SuffixTok, 1, MaxStrLen(NewReminder."No."));
        NewReminder."Reminder Level" := 3;
        NewReminder.Insert(false);
    end;

    var
        Level3SuffixTok: Label '-L3', Locked = true;
}
