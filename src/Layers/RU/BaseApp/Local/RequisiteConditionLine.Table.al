#pragma warning disable AA0247
#if not CLEANSCHEMA28 
table 26561 "Requisite Condition Line"
{
    Caption = 'Requisite Condition Line';
    ObsoleteReason = 'Obsolete functionality';
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(3; "Base Requisites Group Name"; Text[30])
        {
            Caption = 'Base Requisites Group Name';
        }
        field(5; "Base Requisite Name"; Text[30])
        {
            Caption = 'Base Requisite Name';
            NotBlank = true;
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(7; "Condition Sign"; Option)
        {
            Caption = 'Condition Sign';
            OptionCaption = '=,<>';
            OptionMembers = "=","<>";
        }
        field(8; Value; Text[250])
        {
            Caption = 'Value';
        }
        field(9; "Requisite Name"; Text[30])
        {
            Caption = 'Requisite Name';
            NotBlank = true;
        }
        field(10; "Requisites Group Name"; Text[30])
        {
            Caption = 'Requisites Group Name';
        }
    }

    keys
    {
        key(Key1; "Report Code", "Base Requisites Group Name", "Base Requisite Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

 
#endif