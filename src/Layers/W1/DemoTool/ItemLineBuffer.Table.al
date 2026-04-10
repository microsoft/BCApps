table 122001 "Item Line Buffer"
{
    Caption = 'Item Line Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(2; Index; Integer)
        {
            Caption = 'Index';
        }
        field(3; Quantity; Decimal)
        {
            Caption = 'Quantity';
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                Positive := Quantity > 0;
            end;
        }
        field(4; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(5; "Customer/Vendor No."; Code[20])
        {
            Caption = 'Customer/Vendor No.';
        }
        field(6; "Date Delta"; Integer)
        {
            Caption = 'Date Delta';
        }
        field(7; "Document Date Delta"; Integer)
        {
            Caption = 'Document Date Delta';
        }
        field(8; "Document Index"; Integer)
        {
            Caption = 'Document Index';
        }
    }

    keys
    {
        key(Key1; "Item No.", Index)
        {
        }
        key(Key2; "Document Date Delta", "Document Index")
        {
        }
    }

    fieldgroups
    {
    }

    procedure Sign(): Integer
    begin
        if Quantity = 0 then
            exit(1);
        exit(Quantity / Abs(Quantity));
    end;
}
