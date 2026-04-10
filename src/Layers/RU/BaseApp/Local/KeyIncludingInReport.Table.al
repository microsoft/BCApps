#pragma warning disable AA0247
table 17448 "Key Including In Report"
{
    Caption = 'Key Including In Report';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code Report"; Option)
        {
            Caption = 'Code Report';
            OptionCaption = 'ESN Card,ESN Rep,FSI Rep';
            OptionMembers = "ESN Card","ESN Rep","FSI Rep";
        }
        field(2; "Name Report"; Text[90])
        {
            Caption = 'Name Report';
        }
        field(3; Column1; Text[90])
        {
            Caption = 'Column1';
        }
        field(4; Column2; Text[90])
        {
            Caption = 'Column2';
        }
        field(5; Column3; Text[90])
        {
            Caption = 'Column3';
        }
        field(6; Column4; Text[90])
        {
            Caption = 'Column4';
        }
        field(7; Column5; Text[90])
        {
            Caption = 'Column5';
        }
        field(8; Column6; Text[90])
        {
            Caption = 'Column6';
        }
        field(9; Column7; Text[90])
        {
            Caption = 'Column7';
        }
        field(10; Column8; Text[90])
        {
            Caption = 'Column8';
        }
        field(11; Column9; Text[90])
        {
            Caption = 'Column9';
        }
        field(12; Column10; Text[90])
        {
            Caption = 'Column10';
        }
        field(13; Column11; Text[90])
        {
            Caption = 'Column11';
        }
        field(14; Column12; Text[90])
        {
            Caption = 'Column12';
        }
        field(15; Column13; Text[90])
        {
            Caption = 'Column13';
        }
        field(16; Column14; Text[90])
        {
            Caption = 'Column14';
        }
        field(17; Column15; Text[90])
        {
            Caption = 'Column15';
        }
        field(18; Column16; Text[90])
        {
            Caption = 'Column16';
        }
        field(19; Column17; Text[90])
        {
            Caption = 'Column17';
        }
        field(20; Column18; Text[90])
        {
            Caption = 'Column18';
        }
        field(21; Column19; Text[90])
        {
            Caption = 'Column19';
        }
        field(22; Column20; Text[90])
        {
            Caption = 'Column20';
        }
    }

    keys
    {
        key(Key1; "Code Report")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

