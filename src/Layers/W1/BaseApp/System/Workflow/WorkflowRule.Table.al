namespace System.Automation;

using System.Reflection;

table 1524 "Workflow Rule"
{
    Caption = 'Workflow Rule';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = filter(Table));
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
            TableRelation = Field."No." where(TableNo = field("Table ID"));
        }
        field(4; Operator; Option)
        {
            Caption = 'Operator';
            InitValue = Changed;
            OptionCaption = 'Increased,Decreased,Changed';
            OptionMembers = Increased,Decreased,Changed;
        }
        field(8; "Workflow Code"; Code[20])
        {
            Caption = 'Workflow Code';
            TableRelation = Workflow.Code;
        }
        field(9; "Workflow Step ID"; Integer)
        {
            Caption = 'Workflow Step ID';
            TableRelation = "Workflow Step".ID where("Workflow Code" = field("Workflow Code"));
        }
        field(10; "Field Caption"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Field No.")));
            Caption = 'Field Caption';
            FieldClass = FlowField;
        }
        field(11; "Workflow Step Instance ID"; Guid)
        {
            Caption = 'Workflow Step Instance ID';
        }
    }

    keys
    {
        key(Key1; "Workflow Code", "Workflow Step ID", ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        RuleDisplayTxt: Label '%1 is %2', Comment = '%1 = The field; %2 = type of operation; (Amount is Increased)';

    procedure EvaluateRule(RecRef: RecordRef; xRecRef: RecordRef): Boolean
    var
        FieldRef: FieldRef;
        xFieldRef: FieldRef;
        Value: Variant;
        xValue: Variant;
    begin
        if not RecRef.FieldExist("Field No.") then
            exit(false);

        FieldRef := RecRef.Field("Field No.");
        xFieldRef := xRecRef.Field("Field No.");

        Value := FieldRef.Value();
        xValue := xFieldRef.Value();

        exit(CompareValues(xValue, Value));
    end;

    procedure CompareValues(xValue: Variant; Value: Variant): Boolean
    begin
        if Value.IsInteger or Value.IsBigInteger or Value.IsDecimal or Value.IsDuration then
            exit(CompareNumbers(xValue, Value));

        if Value.IsDate then
            exit(CompareDates(xValue, Value));

        if Value.IsTime then
            exit(CompareTimes(xValue, Value));

        if Value.IsDateTime then
            exit(CompareDateTimes(xValue, Value));

        exit(CompareText(Format(xValue, 0, 2), Format(Value, 0, 2)));
    end;

    local procedure CompareNumbers(xValue: Decimal; Value: Decimal): Boolean
    begin
        case Operator of
            Operator::Increased:
                exit(xValue < Value);
            Operator::Decreased:
                exit(xValue > Value);
            Operator::Changed:
                exit(xValue <> Value);
            else
                exit(false);
        end;
    end;

    local procedure CompareDates(xValue: Date; Value: Date): Boolean
    begin
        exit(CompareDateTimes(CreateDateTime(xValue, 0T), CreateDateTime(Value, 0T)));
    end;

    local procedure CompareTimes(xValue: Time; Value: Time): Boolean
    var
        ReferenceDate: Date;
    begin
        ReferenceDate := Today;
        exit(CompareDateTimes(CreateDateTime(ReferenceDate, xValue), CreateDateTime(ReferenceDate, Value)));
    end;

    local procedure CompareDateTimes(xValue: DateTime; Value: DateTime): Boolean
    begin
        case Operator of
            Operator::Increased:
                exit(xValue - Value < 0);
            Operator::Decreased:
                exit(xValue - Value > 0);
            Operator::Changed:
                exit(xValue <> Value);
            else
                exit(false);
        end;
    end;

    local procedure CompareText(xValue: Text; Value: Text): Boolean
    begin
        case Operator of
            Operator::Increased:
                exit(xValue < Value);
            Operator::Decreased:
                exit(xValue > Value);
            Operator::Changed:
                exit(xValue <> Value);
            else
                exit(false);
        end;
    end;

    procedure GetDisplayText(): Text
    begin
        CalcFields("Field Caption");
        exit(StrSubstNo(RuleDisplayTxt, "Field Caption", Operator));
    end;
}

