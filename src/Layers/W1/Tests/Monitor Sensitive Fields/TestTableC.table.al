table 139063 "Test Table C"
{
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Field"; Integer)
        {
            DataClassification = SystemMetadata;

        }
        field(2; "Integer Field"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Text Field"; Text[2048])
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Code Field"; Code[50])
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Date Field"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(6; "GUID Field"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(7; "Option Field"; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = Test1,Test2,Test3;
        }
        field(10; Blob; Blob)
        {
            DataClassification = SystemMetadata;
        }
        field(11; Media; Media)
        {
            DataClassification = SystemMetadata;
        }
        field(12; MediaSet; MediaSet)
        {
            DataClassification = SystemMetadata;
        }
        field(13; FlowField; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Test Table C"."Integer Field");
        }
    }

    keys
    {
        key(PK; "Primary Field")
        {
            Clustered = true;
        }

    }
}