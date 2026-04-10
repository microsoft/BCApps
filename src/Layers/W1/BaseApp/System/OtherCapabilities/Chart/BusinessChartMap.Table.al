namespace System.Visualization;

table 486 "Business Chart Map"
{
    Caption = 'Business Chart Map';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Index; Integer)
        {
            Caption = 'Index';
        }
        field(2; "Value String"; Text[30])
        {
            Caption = 'Value String';
        }
        field(3; Name; Text[249])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; Index)
        {
            Clustered = true;
        }
        key(Key2; "Value String")
        {
        }
        key(Key3; Name)
        {
        }
    }

    fieldgroups
    {
    }

    procedure Add(MapName: Text[249]; Value: Variant)
    begin
        Reset();
        if FindLast() then
            Index += 1
        else
            Index := 0;
        Name := CopyStr(MapName, 1, MaxStrLen(Name));
        "Value String" := CopyStr(Format(Value, 0, 9), 1, MaxStrLen("Value String"));
        Insert();
    end;

    procedure GetIndex(MapName: Text[249]): Integer
    begin
        Reset();
        SetRange(Name, MapName);
        if FindFirst() then
            exit(Index);
        exit(-1);
    end;

    procedure GetValueString(Idx: Integer): Text
    begin
        if Get(Idx) then
            exit("Value String");
    end;

    procedure GetValueAsDate(): Date
    var
        DateTime: DateTime;
        Date: Date;
    begin
        if Evaluate(Date, "Value String", 9) then
            exit(Date);
        if Evaluate(DateTime, "Value String", 9) then
            exit(DT2Date(DateTime));
        exit(0D);
    end;

    procedure GetName(Idx: Integer): Text
    begin
        if Get(Idx) then
            exit(Name);
    end;
}

