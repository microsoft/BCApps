table 160802 "Analysis Conversion"
{
    Caption = 'Analysis Conversion';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Analysis Code"; Code[10])
        {
            Caption = 'Analysis Code';
            TableRelation = "Analysis View".Code;
        }
        field(3; "GL Acc Filter (New)"; Code[250])
        {
            Caption = 'GL Acc Filter (New)';
        }
        field(4; Name; Text[50])
        {
            CalcFormula = lookup("Analysis View".Name where(Code = field("Analysis Code")));
            Caption = 'Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Analysis Code")
        {
        }
    }

    fieldgroups
    {
    }
}

