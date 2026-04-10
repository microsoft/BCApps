namespace System.IO;

table 8621 "Config. Selection"
{
    Caption = 'Config. Selection';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            Editable = false;
        }
        field(3; Name; Text[250])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(4; "Line Type"; Option)
        {
            Caption = 'Line Type';
            Editable = false;
            OptionCaption = 'Area,Group,Table';
            OptionMembers = "Area",Group,"Table";
        }
        field(5; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
            Editable = false;
        }
        field(6; Selected; Boolean)
        {
            Caption = 'Selected';

            trigger OnValidate()
            begin
                case "Line Type" of
                    "Line Type"::Group:
                        begin
                            ConfigSelection.SetRange("Parent Line No.", "Line No.");
                            ConfigSelection.SetRange("Line Type", "Line Type"::Table);
                            ConfigSelection.ModifyAll(Selected, Selected);
                        end;
                    "Line Type"::Area:
                        begin
                            ConfigSelection.SetRange("Parent Line No.", "Line No.");
                            ConfigSelection.SetRange("Line Type", "Line Type"::Table);
                            ConfigSelection.ModifyAll(Selected, Selected);
                            ConfigSelection.SetRange("Line Type", "Line Type"::Group);
                            if ConfigSelection.FindSet() then
                                repeat
                                    ConfigSelection2.SetRange("Parent Line No.", ConfigSelection."Line No.");
                                    ConfigSelection2.SetRange("Line Type", "Line Type"::Table);
                                    ConfigSelection2.ModifyAll(Selected, Selected);
                                until ConfigSelection.Next() = 0;
                        end;
                end;
            end;
        }
        field(25; "Vertical Sorting"; Integer)
        {
            Caption = 'Vertical Sorting';
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Vertical Sorting")
        {
        }
    }

    fieldgroups
    {
    }

    var
        ConfigSelection: Record "Config. Selection";
        ConfigSelection2: Record "Config. Selection";
}

