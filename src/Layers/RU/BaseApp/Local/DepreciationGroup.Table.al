#pragma warning disable AA0247
table 12476 "Depreciation Group"
{
    Caption = 'Depreciation Group';
    DrillDownPageID = "Depreciation Group";
    LookupPageID = "Depreciation Group";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; "Tax Depreciation Rate"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Tax Depreciation Rate';
        }
        field(4; "Depreciation Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Depreciation Factor';
            InitValue = 1;
        }
        field(5; "Depr. Bonus %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Depr. Bonus %';
            MaxValue = 100;
            MinValue = 0;
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
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }
}

