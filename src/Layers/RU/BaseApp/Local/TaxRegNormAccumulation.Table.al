#pragma warning disable AA0247
table 17242 "Tax Reg. Norm Accumulation"
{
    Caption = 'Tax Reg. Norm Accumulation';
    LookupPageID = "Tax Reg. Norm Accum. Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            Editable = false;
        }
        field(3; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(4; "Norm Jurisdiction Code"; Code[10])
        {
            Caption = 'Norm Jurisdiction Code';
            NotBlank = true;
            TableRelation = "Tax Register Norm Jurisdiction";
        }
        field(5; "Norm Group Code"; Code[10])
        {
            Caption = 'Norm Group Code';
            TableRelation = "Tax Register Norm Group".Code where("Norm Jurisdiction Code" = field("Norm Jurisdiction Code"));
        }
        field(6; "Template Line No."; Integer)
        {
            Caption = 'Template Line No.';
        }
        field(7; "Template Line Code"; Code[10])
        {
            Caption = 'Template Line Code';
        }
        field(8; "Line Type"; Option)
        {
            CalcFormula = lookup("Tax Reg. Norm Template Line"."Line Type" where("Norm Jurisdiction Code" = field("Norm Jurisdiction Code"),
                                                                                  "Norm Group Code" = field("Norm Group Code"),
                                                                                  "Line No." = field("Template Line No.")));
            Caption = 'Line Type';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = ' ,Norm Value,Amount for Norm';
            OptionMembers = " ","Norm Value","Amount for Norm";
        }
        field(9; Description; Text[150])
        {
            Caption = 'Description';
        }
        field(10; Amount; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Amount';
            Editable = false;
        }
        field(11; "Amount Date Filter"; Code[30])
        {
            Caption = 'Amount Date Filter';
            Editable = false;
        }
        field(12; "Dimensions Filters"; Boolean)
        {
            CalcFormula = exist("Tax Reg. Norm Dim. Filter" where("Norm Jurisdiction Code" = field("Norm Jurisdiction Code"),
                                                                   "Norm Group Code" = field("Norm Group Code"),
                                                                   "Line No." = field("Template Line No.")));
            Caption = 'Dimensions Filters';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(14; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(15; Bold; Boolean)
        {
            Caption = 'Bold';
        }
        field(16; "Amount Period"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount Period';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Norm Jurisdiction Code", "Norm Group Code", "Template Line No.", "Starting Date", "Ending Date")
        {
            SumIndexFields = "Amount Period";
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure DrillDownAmount()
    var
        TaxRegNormTemplateLine: Record "Tax Reg. Norm Template Line";
        TaxRegNormAccumulation: Record "Tax Reg. Norm Accumulation";
        TaxRegNormCalcBuffer: Page "Tax Reg. Norm Calc. Buffer";
    begin
        if not TaxRegNormTemplateLine.Get("Norm Jurisdiction Code", "Norm Group Code", "Template Line No.") then
            exit;

        if TaxRegNormTemplateLine.Expression = '' then
            exit;

        case TaxRegNormTemplateLine."Expression Type" of
            TaxRegNormTemplateLine."Expression Type"::Link:
                begin
                    TaxRegNormAccumulation.Reset();
                    TaxRegNormAccumulation.FilterGroup(2);
                    TaxRegNormAccumulation.SetRange("Norm Jurisdiction Code", TaxRegNormTemplateLine."Norm Jurisdiction Code");
                    TaxRegNormAccumulation.FilterGroup(0);
                    TaxRegNormAccumulation.SetRange("Norm Group Code", TaxRegNormTemplateLine."Link Group Code");
                    TaxRegNormAccumulation.SetRange("Ending Date", "Ending Date");
                    TaxRegNormAccumulation.SetRange("Template Line Code", TaxRegNormTemplateLine.Expression);
                    if TaxRegNormAccumulation.FindFirst() then;
                    TaxRegNormAccumulation.SetRange("Template Line Code");
                    PAGE.Run(0, TaxRegNormAccumulation);
                end;
            TaxRegNormTemplateLine."Expression Type"::Term,
            TaxRegNormTemplateLine."Expression Type"::Total:
                begin
                    Clear(TaxRegNormCalcBuffer);
                    TaxRegNormCalcBuffer.BuildCalcBuffer(Rec);
                    TaxRegNormCalcBuffer.Run();
                end;
        end;
    end;
}

