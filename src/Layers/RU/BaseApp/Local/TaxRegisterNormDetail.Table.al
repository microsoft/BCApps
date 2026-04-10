#pragma warning disable AA0247
table 17222 "Tax Register Norm Detail"
{
    Caption = 'Tax Register Norm Detail';
    LookupPageID = "Tax Register Norm Details";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Norm Jurisdiction Code"; Code[10])
        {
            Caption = 'Norm Jurisdiction Code';
            NotBlank = true;
            TableRelation = "Tax Register Norm Jurisdiction";
        }
        field(2; "Norm Group Code"; Code[10])
        {
            Caption = 'Norm Group Code';
            TableRelation = "Tax Register Norm Group".Code where("Norm Jurisdiction Code" = field("Norm Jurisdiction Code"));
        }
        field(3; "Norm Type"; Option)
        {
            Caption = 'Norm Type';
            NotBlank = false;
            OptionCaption = 'Amount';
            OptionMembers = Amount;
        }
        field(4; "Effective Date"; Date)
        {
            Caption = 'Effective Date';
        }
        field(5; Maximum; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Maximum';
            DecimalPlaces = 2 : 2;
            MinValue = 0;

            trigger OnValidate()
            begin
                if Maximum = 0 then
                    "Norm Above Maximum" := 0;
            end;
        }
        field(6; Norm; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Norm';
            DecimalPlaces = 2 : 5;
            MinValue = 0;
        }
        field(7; "Norm Above Maximum"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Norm Above Maximum';
            DecimalPlaces = 2 : 2;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Norm Above Maximum" <> 0 then
                    TestField(Maximum);
            end;
        }
    }

    keys
    {
        key(Key1; "Norm Jurisdiction Code", "Norm Group Code", "Norm Type", "Effective Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        TaxRegNormJurisdiction: Record "Tax Register Norm Jurisdiction";
        TaxRegNormGroup: Record "Tax Register Norm Group";

    [Scope('OnPrem')]
    procedure FormTitle() Title: Text[250]
    begin
        if TaxRegNormJurisdiction.Get("Norm Jurisdiction Code") then
            Title := TaxRegNormJurisdiction.Description;
    end;

    [Scope('OnPrem')]
    procedure LineDescription() Descr: Text[250]
    begin
        if TaxRegNormGroup.Get("Norm Jurisdiction Code", "Norm Group Code") then
            Descr := TaxRegNormGroup.Description;
    end;
}

