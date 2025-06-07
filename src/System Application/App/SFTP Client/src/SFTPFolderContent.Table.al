table 50100 "SFTP Folder Content"
{
    DataClassification = SystemMetadata;
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;
    Extensible = false;
    Caption = 'SFTP Folder Content', Locked = true;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.', Locked = true;
            DataClassification = SystemMetadata;
            Access = Internal;
        }
        field(2; Name; Text[2048])
        {
            Caption = 'Name', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(3; "Full Name"; Text[2048])
        {
            Caption = 'Full Name', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(4; "Is Directory"; Boolean)
        {
            Caption = 'Is Directory', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(5; Length; BigInteger)
        {
            Caption = 'Length', Locked = true;
            DataClassification = SystemMetadata;
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