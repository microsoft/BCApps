namespace Microsoft.Test.QualityManagement;

table 139956 "Qlty. Flt B 636554D9E7F2A4C8B1"
{
    Access = Internal;
    Caption = 'Qlty. Cap B 636554D9E7F2A4C8B1', Locked = true;
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.', Locked = true;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}