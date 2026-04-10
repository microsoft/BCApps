#pragma warning disable AA0247
table 17449 "Including In Report"
{
    Caption = 'Including In Report';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
        }
        field(2; "Report Code"; Option)
        {
            Caption = 'Report Code';
            OptionCaption = 'ESN Card,ESN Rep,FSI Rep';
            OptionMembers = "ESN Card","ESN Rep","FSI Rep";
        }
        field(3; Column1; Boolean)
        {
            Caption = 'Column1';
        }
        field(4; Column2; Boolean)
        {
            Caption = 'Column2';
        }
        field(5; Column3; Boolean)
        {
            Caption = 'Column3';
        }
        field(6; Column4; Boolean)
        {
            Caption = 'Column4';
        }
        field(7; Column5; Boolean)
        {
            Caption = 'Column5';
        }
        field(8; Column6; Boolean)
        {
            Caption = 'Column6';
        }
        field(9; Column7; Boolean)
        {
            Caption = 'Column7';
        }
        field(10; Column8; Boolean)
        {
            Caption = 'Column8';
        }
        field(11; Column9; Boolean)
        {
            Caption = 'Column9';
        }
        field(12; Column10; Boolean)
        {
            Caption = 'Column10';
        }
        field(13; Column11; Boolean)
        {
            Caption = 'Column11';
        }
        field(14; Column12; Boolean)
        {
            Caption = 'Column12';
        }
        field(15; Column13; Boolean)
        {
            Caption = 'Column13';
        }
        field(16; Column14; Boolean)
        {
            Caption = 'Column14';
        }
        field(17; Column15; Boolean)
        {
            Caption = 'Column15';
        }
        field(18; Column16; Boolean)
        {
            Caption = 'Column16';
        }
        field(19; Column17; Boolean)
        {
            Caption = 'Column17';
        }
        field(20; Column18; Boolean)
        {
            Caption = 'Column18';
        }
        field(21; Column19; Boolean)
        {
            Caption = 'Column19';
        }
        field(22; Column20; Boolean)
        {
            Caption = 'Column20';
        }
    }

    keys
    {
        key(Key1; "Element Code", "Report Code")
        {
            Clustered = true;
        }
        key(Key2; "Report Code", Column1, Column2, Column3, Column4, Column5, Column6, Column7, Column8, Column9, Column10)
        {
        }
    }

    fieldgroups
    {
    }
}

