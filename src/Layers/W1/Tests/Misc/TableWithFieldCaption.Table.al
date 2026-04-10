table 135001 TableWithFieldCaption
{
    DataClassification = SystemMetadata;
    ReplicateData = false;
    
    fields
    {
        field(1; "Entry No."; Integer)
        {

        }
        field(2; MyField; Integer)
        {
            Caption = 'MyCaption';
        }
        field(3; MyCaption; Integer)
        {
            Caption = 'MyField';
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