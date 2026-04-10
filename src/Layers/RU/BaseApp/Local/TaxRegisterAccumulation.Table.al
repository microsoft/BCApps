#pragma warning disable AA0247
table 17208 "Tax Register Accumulation"
{
    Caption = 'Tax Register Accumulation';
    LookupPageID = "Tax Register Accumulat. Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Register Section";
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            Editable = false;
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(6; Description; Text[150])
        {
            Caption = 'Description';
        }
        field(8; "Template Line No."; Integer)
        {
            Caption = 'Template Line No.';
        }
        field(15; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Amount';
            Editable = false;
        }
        field(18; "Template Line Code"; Code[10])
        {
            Caption = 'Template Line Code';
        }
        field(35; "Amount Period"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount Period';
        }
        field(36; "Amount Date Filter"; Code[30])
        {
            Caption = 'Amount Date Filter';
            Editable = false;
        }
        field(37; "Report Line Code"; Text[10])
        {
            Caption = 'Report Line Code';
        }
        field(38; "Tax Register No."; Code[10])
        {
            Caption = 'Tax Register No.';
            TableRelation = "Tax Register"."No." where("Section Code" = field("Section Code"));
        }
        field(39; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(40; Bold; Boolean)
        {
            Caption = 'Bold';
        }
        field(50; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(51; "Dimensions Filters"; Boolean)
        {
            CalcFormula = exist("Tax Register Dim. Filter" where("Section Code" = field("Section Code"),
                                                                  "Tax Register No." = field("Tax Register No."),
                                                                  Define = const(Template),
                                                                  "Line No." = field("Template Line No.")));
            Caption = 'Dimensions Filters';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Section Code", "Tax Register No.", "Template Line No.", "Starting Date", "Ending Date")
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
        TaxRegName: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TaxRegCalcBufferForm: Page "Tax Register Calc. Buffer";
    begin
        if not TaxRegTemplate.Get("Section Code", "Tax Register No.", "Template Line No.") then
            exit;
        if TaxRegTemplate.Expression = '' then
            exit;
        case TaxRegTemplate."Expression Type" of
            TaxRegTemplate."Expression Type"::Link:
                begin
                    TaxRegAccumulation.Reset();
                    TaxRegAccumulation.FilterGroup(2);
                    TaxRegAccumulation.SetRange("Section Code", TaxRegTemplate."Section Code");
                    TaxRegAccumulation.FilterGroup(0);
                    TaxRegAccumulation.SetRange("Tax Register No.", TaxRegTemplate."Link Tax Register No.");
                    TaxRegAccumulation.SetRange("Ending Date", "Ending Date");
                    TaxRegAccumulation.SetRange("Template Line Code", TaxRegTemplate.Expression);
                    if TaxRegAccumulation.FindFirst() then;
                    TaxRegAccumulation.SetRange("Template Line Code");
                    PAGE.RunModal(0, TaxRegAccumulation);
                end;
            TaxRegTemplate."Expression Type"::Term,
            TaxRegTemplate."Expression Type"::Total:
                begin
                    Clear(TaxRegCalcBufferForm);
                    TaxRegCalcBufferForm.BuildTaxRegCalcBuffer(Rec);
                    TaxRegCalcBufferForm.RunModal();
                end;
            TaxRegTemplate."Expression Type"::SumField:
                begin
                    TaxRegName.Get("Section Code", "Tax Register No.");
                    TaxRegName.SetFilter("Date Filter", "Amount Date Filter");
                    TaxRegName.ShowDetails("Template Line No.");
                end;
        end;
    end;
}

