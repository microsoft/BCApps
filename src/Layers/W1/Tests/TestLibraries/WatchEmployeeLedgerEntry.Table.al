namespace Microsoft.HumanResources.Test;

#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 131323 "Watch Employee Ledger Entry"
#pragma warning restore AS0103, PTE0004
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Employee No."; Code[20])
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
