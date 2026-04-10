#pragma warning disable AA0247
table 17323 "Tax Diff. FA Posting Buffer"
{
    Caption = 'Tax Diff. FA Posting Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Acquisition Cost,Depreciation Bonus,Depreciation';
            OptionMembers = "Acquisition Cost","Depreciation Bonus",Depreciation;
        }
        field(2; "Tax Diff. Code"; Code[10])
        {
            Caption = 'Tax Diff. Code';
            DataClassification = SystemMetadata;
        }
        field(3; "Initial Amount"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            Caption = 'Initial Amount';
            DataClassification = SystemMetadata;
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Type, "Tax Diff. Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

