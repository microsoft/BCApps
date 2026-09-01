table 135300 "Prediction Data"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Not included"; Code[50])
        {
        }
        field(2; "Feature A"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(3; "Feature B"; Option)
        {
            OptionMembers = Option1,Option2,Option3;
        }
        field(4; Label; Boolean)
        {
        }
        field(6; "Feature D"; Text[30])
        {
        }
        field(15; "Feature C"; Integer)
        {
        }
        field(16; "Feature E"; Decimal)
        {
            CalcFormula = sum("Sales Invoice Line".Quantity);
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(17; "Feature F"; Decimal)
        {
            CalcFormula = sum("Sales Invoice Line"."Unit Price");
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(18; "Feature G"; Boolean)
        {
        }
        field(19; "Feature H"; Boolean)
        {
        }
        field(20; "Feature I"; Boolean)
        {
        }
        field(21; "Feature J"; Boolean)
        {
        }
        field(22; "Feature K"; Boolean)
        {
        }
        field(23; "Feature L"; Boolean)
        {
        }
        field(24; "Feature M"; Boolean)
        {
        }
        field(25; "Feature N"; Boolean)
        {
        }
        field(26; "Feature O"; Boolean)
        {
        }
        field(27; "Feature P"; Boolean)
        {
        }
        field(28; "Feature Q"; Boolean)
        {
        }
        field(29; "Feature R"; Boolean)
        {
        }
        field(30; "Feature S"; Boolean)
        {
        }
        field(31; "Feature T"; Text[30])
        {
        }
        field(32; "Feature U"; Code[10])
        {
        }
        field(33; "Feature V"; Integer)
        {
        }
        field(34; "Feature W"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(35; "Feature X"; Boolean)
        {
        }
    }

    keys
    {
        key(Key1; "Not included")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
