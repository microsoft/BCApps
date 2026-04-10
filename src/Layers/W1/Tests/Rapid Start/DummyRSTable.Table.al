table 136607 DummyRSTable
{
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {

        }
        field(2; "Decimal Field"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(3; "Date Field"; Date)
        {

        }
        field(4; "Code Field"; Code[20])
        {

        }
        field(5; "Text Field"; Text[50])
        {

        }
        field(6; "Long Text Field"; Text[2048])
        {

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