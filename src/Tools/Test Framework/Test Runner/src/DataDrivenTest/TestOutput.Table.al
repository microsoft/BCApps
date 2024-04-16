table 130453 "Test Output"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Test Suite"; Code[10])
        {
            TableRelation = "AL Test Suite".Name;
        }
        field(2; "Method Name"; Code[250])
        {
        }
        field(3; "Line No."; Integer)
        {
        }
        field(4; "Test Description"; Text[250])
        {
        }
        field(10; "Test Output"; Blob)
        {
        }
    }

    keys
    {
        key(Key1; "Test Suite", "Method Name", "Line No.")
        {
            Clustered = true;
        }
    }
}