table 132803 "UPG-Integration Table Mapping"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[20])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(14; "Table Filter"; BLOB)
        {
            Caption = 'Table Filter';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetTableFilter("Filter": Text)
    var
        OutStream: OutStream;
    begin
        "Table Filter".CreateOutStream(OutStream);
        OutStream.Write(Filter);
    end;

    procedure GetTableFilter() Value: Text
    var
        InStream: InStream;
    begin
        CalcFields("Table Filter");
        "Table Filter".CreateInStream(InStream);
        InStream.Read(Value);
    end;
}