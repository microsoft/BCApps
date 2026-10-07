namespace Microsoft.Purchases.Test;

table 131321 "Watch Vendor Ledger Entry"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Vendor No."; Code[20])
        {
        }
        field(3; "Line Level"; Option)
        {
            OptionMembers = "Ledger Entry","Detailed Ledger Entry";
        }
        field(4; "Line Type"; Integer)
        {
        }
        field(5; "Original Count"; Integer)
        {
        }
        field(6; "Delta Count"; Integer)
        {
        }
        field(7; "Original Sum"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(8; "Delta Sum"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(9; "Count Comparison Method"; Option)
        {
            OptionMembers = Equal,"Greater Than","Less Than";
        }
        field(10; "Sum Comparison Method"; Option)
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
