table 139142 "Update Parent Line"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header Id"; Code[10])
        {
            TableRelation = "Update Parent Header";
        }
        field(2; "Line Id"; Integer)
        {
        }
        field(3; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(4; Quantity; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Header Id", "Line Id")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
