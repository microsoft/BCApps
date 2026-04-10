#pragma warning disable AA0247
table 14921 "Assessed Tax Code"
{
    Caption = 'Assessed Tax Code';
    DrillDownPageID = "Assessed Tax Code List";
    LookupPageID = "Assessed Tax Code List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(4; "Region Code"; Code[2])
        {
            Caption = 'Region Code';
            Numeric = true;

            trigger OnValidate()
            begin
                if "Region Code" <> xRec."Region Code" then
                    CheckExistenceInFA();
            end;
        }
        field(5; "Rate %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Rate %';
            DecimalPlaces = 2 : 2;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Rate %" <> xRec."Rate %" then
                    CheckExistenceInFA();
            end;
        }
        field(6; "Dec. Rate Tax Allowance Code"; Code[7])
        {
            Caption = 'Dec. Rate Tax Allowance Code';
            TableRelation = "Assessed Tax Allowance";

            trigger OnValidate()
            begin
                if "Dec. Rate Tax Allowance Code" <> xRec."Dec. Rate Tax Allowance Code" then
                    CheckExistenceInFA();
            end;
        }
        field(7; "Dec. Amount Tax Allowance Code"; Code[7])
        {
            Caption = 'Dec. Amount Tax Allowance Code';
            TableRelation = "Assessed Tax Allowance";

            trigger OnValidate()
            begin
                if "Dec. Amount Tax Allowance Code" <> xRec."Dec. Amount Tax Allowance Code" then
                    CheckExistenceInFA();
            end;
        }
        field(8; "Decreasing Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Decreasing Amount';
            DecimalPlaces = 2 : 2;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Decreasing Amount" <> xRec."Decreasing Amount" then
                    CheckExistenceInFA();
            end;
        }
        field(9; "Exemption Tax Allowance Code"; Code[7])
        {
            Caption = 'Exemption Tax Allowance Code';
            TableRelation = "Assessed Tax Allowance";

            trigger OnValidate()
            begin
                if "Exemption Tax Allowance Code" <> xRec."Exemption Tax Allowance Code" then
                    CheckExistenceInFA();
            end;
        }
        field(10; "Decreasing Amount Type"; Option)
        {
            Caption = 'Decreasing Amount Type';
            OptionCaption = 'Percent,Amount';
            OptionMembers = Percent,Amount;

            trigger OnValidate()
            begin
                if "Decreasing Amount Type" <> xRec."Decreasing Amount Type" then
                    CheckExistenceInFA();
            end;
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
        fieldgroup(DropDown; "Code", Description, "Region Code", "Rate %")
        {
        }
    }

    trigger OnDelete()
    begin
        FixedAsset.Reset();
        FixedAsset.SetRange("Assessed Tax Code", Code);
        if FixedAsset.FindFirst() then
            Error(Text002, Code, FixedAsset."No.");
    end;

    var
        FixedAsset: Record "Fixed Asset";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You can''t modify Assessed Tax Code=%1 until you remove it from Fixed Asset=%2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'You can''t delete Assessed Tax Code=%1 until you remove it from Fixed Asset=%2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure CheckExistenceInFA()
    begin
        FixedAsset.Reset();
        FixedAsset.SetRange("Assessed Tax Code", Code);
        if FixedAsset.FindFirst() then
            Error(Text001, Code, FixedAsset."No.");
    end;
}

