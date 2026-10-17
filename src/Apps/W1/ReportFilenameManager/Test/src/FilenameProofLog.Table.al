// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
table 50153 "Filename Proof Log"
{
    Access = Internal;

    // Where the proofs write what they found, one row per line, and where Filename Proof Gate reads
    // their verdicts back. Owned by the test app, so the tests depend on nothing that does not ship
    // with them.
    //
    // Rows are never written while a report is running. Filename Proof Log Mgt. buffers them in a
    // temporary record and copies them here at a point where a write transaction is safe - see its
    // Flush. Writing during the run would open a transaction, and Base Application's print flow
    // calls Report.RunModal with a request page, which Business Central forbids once locks are held.

    Caption = 'Filename Proof Log';
    DataClassification = SystemMetadata;
    TableType = Normal;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Run ID"; Integer)
        {
            Caption = 'Run ID';
            Editable = false;
        }
        field(3; "Logged At"; DateTime)
        {
            Caption = 'Logged At';
            Editable = false;
        }
        field(4; "Event Name"; Text[60])
        {
            Caption = 'Event';
            Editable = false;
        }
        field(5; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            Editable = false;
        }
        field(6; Item; Text[100])
        {
            Caption = 'Item';
            Editable = false;
        }
        field(7; Value; Text[250])
        {
            Caption = 'Value';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Run; "Run ID", "Entry No.")
        {
        }
    }

    /// <summary>
    /// Returns the next unused run number, so each proof's lines are separable.
    /// </summary>
    procedure NextRunId(): Integer
    var
        FilenameProofLog: Record "Filename Proof Log";
    begin
        FilenameProofLog.SetCurrentKey("Run ID", "Entry No.");
        if FilenameProofLog.FindLast() then
            exit(FilenameProofLog."Run ID" + 1);
        exit(1);
    end;
}
