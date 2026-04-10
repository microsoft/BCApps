namespace System.IO;

table 1213 "Data Exchange Type"
{
    Caption = 'Data Exchange Type';
    DrillDownPageID = "Data Exchange Types";
    LookupPageID = "Data Exchange Types";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "Data Exch. Def. Code"; Code[20])
        {
            Caption = 'Data Exch. Def. Code';
            TableRelation = "Data Exch. Def".Code;
        }
        field(4; "Entity Type"; Option)
        {
            Caption = 'Entity Type';
            OptionCaption = 'Invoice,Credit Memo';
            OptionMembers = Invoice,"Credit Memo";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure FindEntry(Type: Option): Code[20]
    begin
        Reset();
        SetRange("Entity Type", Type);
        if not FindFirst() then
            exit('');

        exit(Code);
    end;
}

