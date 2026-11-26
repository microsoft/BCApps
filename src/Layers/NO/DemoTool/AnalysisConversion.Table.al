#pragma warning disable AS0103, PTE0004 // Accepted: this internal table is intentionally accessed only by its owning infrastructure and is not exposed through user permission sets. Tracked by AB#640773.
table 160802 "Analysis Conversion"
#pragma warning restore AS0103, PTE0004
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

