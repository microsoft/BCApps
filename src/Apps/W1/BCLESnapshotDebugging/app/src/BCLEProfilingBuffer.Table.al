namespace Microsoft.Samples.BCLESnapshotDebugging;

table 70950 "BCLE Profiling Buffer"
{
    Caption = 'BCLE Profiling Buffer';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Category Code"; Code[20])
        {
            Caption = 'Category Code';
            DataClassification = SystemMetadata;
        }
        field(3; Bucket; Integer)
        {
            Caption = 'Bucket';
            DataClassification = SystemMetadata;
        }
        field(4; Payload; Blob)
        {
            Caption = 'Payload';
            DataClassification = SystemMetadata;
        }
        field(5; "Payload Size"; Integer)
        {
            Caption = 'Payload Size';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(WrongIndex; Bucket)
        {
        }
    }
}
