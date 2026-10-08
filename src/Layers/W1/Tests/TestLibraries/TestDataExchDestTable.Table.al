table 132460 "Test Data Exch. Dest Table"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Integer)
        {
        }
        field(2; Text; Text[30])
        {
        }
        field(3; Date; Date)
        {
        }
        field(4; Decimal; Decimal)
        {
            AutoFormatType = 0;
        }
        field(5; KeyH1; Integer)
        {
        }
        field(6; KeyH2; Code[10])
        {
        }
        field(7; NonKey; Code[10])
        {
        }
        field(8; ExchNo; Integer)
        {
        }
        field(9; LineNo; Integer)
        {
        }
        field(10; Boolean; Boolean)
        {
        }
    }

    keys
    {
        key(Key1; KeyH1, KeyH2, "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure InsertRec(KeyValue: Integer; TextValue: Text[30]; DateValue: Date; DecimalValue: Decimal; KeyH1Value: Integer; KeyH2Value: Code[10]; NonKeyValue: Code[10]; ExchNoValue: Integer; LineNoValue: Integer)
    begin
        Init();
        Validate(Key, KeyValue);
        Validate(Text, TextValue);
        Validate(Date, DateValue);
        Validate(Decimal, DecimalValue);
        Validate(KeyH1, KeyH1Value);
        Validate(KeyH2, KeyH2Value);
        Validate(NonKey, NonKeyValue);
        Validate(ExchNo, ExchNoValue);
        Validate(LineNo, LineNoValue);
        Insert(true);
    end;
}
