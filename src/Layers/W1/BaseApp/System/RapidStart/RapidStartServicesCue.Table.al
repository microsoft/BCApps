namespace System.IO;

table 9061 "RapidStart Services Cue"
{
    Caption = 'RapidStart Services Cue';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(10; "Not Started"; Integer)
        {
            CalcFormula = count("Config. Line" where("Line Type" = const(Table),
                                                      Status = const(" ")));
            Caption = 'Not Started';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "In Progress"; Integer)
        {
            CalcFormula = count("Config. Line" where("Line Type" = const(Table),
                                                      Status = const("In Progress")));
            Caption = 'In Progress';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; Completed; Integer)
        {
            CalcFormula = count("Config. Line" where("Line Type" = const(Table),
                                                      Status = const(Completed)));
            Caption = 'Completed';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Ignored; Integer)
        {
            CalcFormula = count("Config. Line" where("Line Type" = const(Table),
                                                      Status = const(Ignored)));
            Caption = 'Ignored';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; Promoted; Integer)
        {
            CalcFormula = count("Config. Line" where("Line Type" = const(Table),
                                                      "Promoted Table" = const(true)));
            Caption = 'Promoted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; Blocked; Integer)
        {
            CalcFormula = count("Config. Line" where("Line Type" = const(Table),
                                                      Status = const(Blocked)));
            Caption = 'Blocked';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

