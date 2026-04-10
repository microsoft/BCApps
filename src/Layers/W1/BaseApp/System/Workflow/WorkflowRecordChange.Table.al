namespace System.Automation;

using System.Reflection;

table 1525 "Workflow - Record Change"
{
    Caption = 'Workflow - Record Change';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(4; "Old Value"; Text[250])
        {
            Caption = 'Old Value';
        }
        field(5; "New Value"; Text[250])
        {
            Caption = 'New Value';
        }
        field(6; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(7; "Workflow Step Instance ID"; Guid)
        {
            Caption = 'Workflow Step Instance ID';
        }
        field(8; "Field Caption"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."),
                                                              "No." = field("Field No.")));
            Caption = 'Field Caption';
            FieldClass = FlowField;
        }
        field(9; Inactive; Boolean)
        {
            Caption = 'Inactive';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Workflow Step Instance ID", "Record ID")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetFormattedNewValue(FormatOptionString: Boolean): Text
    begin
        exit(FormatValue("New Value", FormatOptionString));
    end;

    procedure GetFormattedOldValue(FormatOptionString: Boolean): Text
    begin
        exit(FormatValue("Old Value", FormatOptionString));
    end;

    procedure FormatValue(Value: Text; FormatOptionString: Boolean): Text
    var
        DateFormula: DateFormula;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        Bool: Boolean;
        Date: Date;
        DateTime: DateTime;
        Decimal: Decimal;
        Duration: Duration;
        "Integer": Integer;
        Option: Option;
        Time: Time;
        BigInteger: BigInteger;
    begin
        RecRef.Get("Record ID");
        FieldRef := RecRef.Field("Field No.");
        case FieldRef.Type of
            FieldType::Date:
                begin
                    Evaluate(Date, Value, 9);
                    exit(Format(Date));
                end;
            FieldType::Boolean:
                begin
                    Evaluate(Bool, Value, 9);
                    exit(Format(Bool));
                end;
            FieldType::DateFormula:
                begin
                    Evaluate(DateFormula, Value, 9);
                    exit(Format(DateFormula));
                end;
            FieldType::DateTime:
                begin
                    Evaluate(DateTime, Value, 9);
                    exit(Format(DateTime));
                end;
            FieldType::BigInteger:
                begin
                    Evaluate(BigInteger, Value, 9);
                    exit(Format(BigInteger));
                end;
            FieldType::Time:
                begin
                    Evaluate(Time, Value, 9);
                    exit(Format(Time));
                end;
            FieldType::Option:
                begin
                    Evaluate(Option, Value, 9);
                    if FormatOptionString then begin
                        FieldRef.Value := Option;
                        exit(Format(FieldRef.Value));
                    end;
                    exit(Format(Option));
                end;
            FieldType::Integer:
                begin
                    Evaluate(Integer, Value, 9);
                    exit(Format(Integer));
                end;
            FieldType::Duration:
                begin
                    Evaluate(Duration, Value, 9);
                    exit(Format(Duration));
                end;
            FieldType::Decimal:
                begin
                    Evaluate(Decimal, Value, 9);
                    exit(Format(Decimal));
                end;
            FieldType::Code, FieldType::Text:
                exit(Format(Value));
            else
                exit(Format(Value));
        end;
    end;
}

