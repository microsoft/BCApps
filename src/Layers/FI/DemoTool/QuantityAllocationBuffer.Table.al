table 122002 "Quantity Allocation Buffer"
{
    Caption = 'Quantity Allocation Buffer';
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
            AutoIncrement = true;
            Caption = 'Index';
        }
        field(3; Quantity; Integer)
        {
            Caption = 'Quantity';
        }
    }

    keys
    {
        key(Key1; "Item No.", Index)
        {
        }
    }

    fieldgroups
    {
    }

    procedure MaxIndex(ItemNo: Code[20]): Integer
    begin
        Reset();
        SetRange("Item No.", ItemNo);
        if FindLast() then
            exit(Index);
        exit(0);
    end;
}

