table 136606 DuplicatedXMLFields
{
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {

        }
        field(2; "Indirect Amount %"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(3; "Indirect (Amount) %"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(4; "Indirect Amount"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(5; "<Indirect %> Amount"; Decimal)
        {
            AutoFormatType = 0;
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