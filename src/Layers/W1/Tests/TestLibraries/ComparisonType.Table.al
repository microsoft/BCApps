table 132590 "Comparison Type"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Big Integer Field"; BigInteger)
        {
        }
        field(3; "Boolean Field"; Boolean)
        {
        }
        field(4; "Code Field"; Code[10])
        {
        }
        field(5; "Date Field"; Date)
        {
        }
        field(6; "Date Formula Field"; DateFormula)
        {
        }
        field(7; "Date / Time Field"; DateTime)
        {
        }
        field(8; "Decimal Field"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(9; "Duration Field"; Duration)
        {
        }
        field(10; "Integer Field"; Integer)
        {
        }
        field(11; "Option Field"; Option)
        {
            OptionMembers = First,Second,Third;
        }
        field(12; "Text Field"; Text[30])
        {
        }
        field(13; "Time Field"; Time)
        {
        }
        field(14; "Blob Field"; BLOB)
        {
        }
        field(15; "GUID Field"; Guid)
        {
        }
        field(16; "Record ID Field"; RecordID)
        {
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure Create(BigIntegerValue: BigInteger; BooleanValue: Boolean; CodeValue: Code[10]; DateValue: Date; DateFormulaValue: Text; DateTimeValue: DateTime; DecimalValue: Decimal; DurationValue: Duration; IntegerValue: Integer; OptionValue: Option; TextValue: Text[30]; TimeValue: Time; BlobValue: Text; GuidValue: Guid; RecordIdValue: RecordID)
    var
        OutStream: OutStream;
    begin
        "Big Integer Field" := BigIntegerValue;
        "Boolean Field" := BooleanValue;
        "Code Field" := CodeValue;
        "Date Field" := DateValue;
        Evaluate("Date Formula Field", DateFormulaValue);
        "Date / Time Field" := DateTimeValue;
        "Decimal Field" := DecimalValue;
        "Duration Field" := DurationValue;
        "Integer Field" := IntegerValue;
        "Option Field" := OptionValue;
        "Text Field" := TextValue;
        "Time Field" := TimeValue;
        "Blob Field".CreateOutStream(OutStream);
        OutStream.WriteText(BlobValue);
        "GUID Field" := GuidValue;
        "Record ID Field" := RecordIdValue;
        Insert();
    end;

    [Scope('OnPrem')]
    procedure Clone(ComparisonType: Record "Comparison Type")
    begin
        "Big Integer Field" := ComparisonType."Big Integer Field";
        "Boolean Field" := ComparisonType."Boolean Field";
        "Code Field" := ComparisonType."Code Field";
        "Date Field" := ComparisonType."Date Field";
        "Date Formula Field" := ComparisonType."Date Formula Field";
        "Date / Time Field" := ComparisonType."Date / Time Field";
        "Decimal Field" := ComparisonType."Decimal Field";
        "Duration Field" := ComparisonType."Duration Field";
        "Integer Field" := ComparisonType."Integer Field";
        "Option Field" := ComparisonType."Option Field";
        "Text Field" := ComparisonType."Text Field";
        "Time Field" := ComparisonType."Time Field";
        ComparisonType.CalcFields("Blob Field");
        "Blob Field" := ComparisonType."Blob Field";
        "GUID Field" := ComparisonType."GUID Field";
        "Record ID Field" := ComparisonType."Record ID Field";
        Insert();
    end;
}
