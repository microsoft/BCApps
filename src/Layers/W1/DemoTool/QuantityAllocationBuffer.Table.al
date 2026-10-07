#pragma warning disable AS0103, PTE0004 // Accepted: this internal table is intentionally accessed only by its owning infrastructure and is not exposed through user permission sets. Tracked by AB#640773.
table 122002 "Quantity Allocation Buffer"
#pragma warning restore AS0103, PTE0004
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

