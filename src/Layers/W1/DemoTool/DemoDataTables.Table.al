table 101906 "Demo Data Tables"
{
    Caption = 'Demo Data Tables';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(2; "Field ID"; Integer)
        {
            Caption = 'Field ID';
        }
        field(3; "Order"; Integer)
        {
            Caption = 'Order';
        }
        field(4; "Need Translation"; Boolean)
        {
            Caption = 'Need Translation';
        }
    }

    keys
    {
        key(Key1; "Table ID", "Field ID")
        {
        }
    }

    fieldgroups
    {
    }
}

