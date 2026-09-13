// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

table 134083 "Concurrent Seq. Test Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Run ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Session No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Allocation Index"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(4; Ready; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Run ID", "Session No.", "Allocation Index")
        {
            Clustered = true;
        }
        key(EntryNo; "Run ID", "Entry No.")
        {
        }
    }

    procedure GetNoOfAllocationsPerSession(): Integer
    begin
        exit(10);
    end;
}