namespace Microsoft.Test.Utilities;

table 135002 "Comma Caption Test Buffer"
{
    DataClassification = SystemMetadata;
    ReplicateData = false;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Status; Enum "Comma Caption Test")
        {
            Caption = 'Status';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}
