#pragma warning disable AS0103, PTE0004 // Accepted: this internal table is intentionally accessed only by its owning infrastructure and is not exposed through user permission sets. Tracked by AB#640773.
table 122003 "Item Sales Data"
#pragma warning restore AS0103, PTE0004
{
    Caption = 'Item Sales Data';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[10])
        {
            Caption = 'Item No.';
        }
        field(2; Period; Integer)
        {
            Caption = 'Period';
        }
        field(3; Quantity; Decimal)
        {
            Caption = 'Quantity';
            AutoFormatType = 0;
        }
        field(4; "Number of Invoices"; Integer)
        {
            Caption = 'Number of Invoices';
        }
        field(5; "Scale to Average Quantity"; Decimal)
        {
            Caption = 'Scale to Average Quantity';
            AutoFormatType = 0;
        }
    }

    keys
    {
        key(Key1; "Item No.", Period)
        {
        }
    }

    fieldgroups
    {
    }
}
