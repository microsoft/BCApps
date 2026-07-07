table 122002 "Quantity Allocation Buffer"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
        }
        field(2; Index; Integer)
        {
            AutoIncrement = true;
        }
        field(3; Quantity; Integer)
        {
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

