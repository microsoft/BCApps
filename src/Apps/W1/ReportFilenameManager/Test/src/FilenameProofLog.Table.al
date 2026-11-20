// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

table 149503 "Filename Proof Log"
{
    Access = Internal;

    // Proof results, read back by Filename Proof Gate. Never written while a report runs (see
    // Filename Proof Log Mgt.'s Flush), so logging adds no write transaction to the flow being proven.

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
