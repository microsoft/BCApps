namespace Microsoft.Sales.Test;

table 131310 "Watch Customer"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Customer No."; Code[20])
        {
        }
        field(3; "Original LE Count"; Integer)
        {
        }
        field(4; "Original Dtld. LE Count"; Integer)
        {
        }
        field(5; "Watch LE"; Boolean)
        {
        }
        field(6; "Watch Dtld. LE"; Boolean)
        {
        }
        field(7; "LE Comparison Method"; Option)
        {
            OptionMembers = Equal,"Greater Than","Less Than";
        }
        field(8; "Dtld. LE Comparison Method"; Option)
        {
            OptionMembers = Equal,"Greater Than","Less Than";
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

