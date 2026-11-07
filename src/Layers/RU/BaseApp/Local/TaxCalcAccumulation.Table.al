#pragma warning disable AA0247
table 17314 "Tax Calc. Accumulation"
{
    Caption = 'Tax Calc. Accumulation';
    LookupPageID = "Tax Calc. Accumulat. Lines";
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
            TableRelation = "Tax Calc. Section";
        }
        field(3; "Template Line No."; Integer)
        {
            Caption = 'Template Line No.';
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
        field(15; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Amount';
            DecimalPlaces = 2 : 2;
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
            DecimalPlaces = 2 : 2;
        }
        field(36; "Amount Date Filter"; Code[30])
        {
            Caption = 'Amount Date Filter';
            Editable = false;
        }
        field(38; "Register No."; Code[10])
        {
            Caption = 'Register No.';
            TableRelation = "Tax Calc. Header"."No." where("Section Code" = field("Section Code"));
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
            CalcFormula = exist("Tax Calc. Dim. Filter" where("Section Code" = field("Section Code"),
                                                               "Register No." = field("Register No."),
                                                               Define = const(Template),
                                                               "Line No." = field("Template Line No.")));
            Caption = 'Dimensions Filters';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Tax Diff. Amount (Base)"; Boolean)
        {
            Caption = 'Tax Diff. Amount (Base)';
        }
        field(53; "Tax Diff. Amount (Tax)"; Boolean)
        {
            Caption = 'Tax Diff. Amount (Tax)';
        }
        field(54; Disposed; Boolean)
        {
            Caption = 'Disposed';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Section Code", "Register No.", "Template Line No.", "Starting Date", "Ending Date")
        {
            SumIndexFields = "Amount Period";
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Formula: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure DrillDownAmount()
    var
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcAccumulation: Record "Tax Calc. Accumulation";
        TaxCalcCalcBuffer: Page "Tax Calc. Calc. Buffer";
    begin
        if not TaxCalcLine.Get("Section Code", "Register No.", "Template Line No.") then
            exit;
        case TaxCalcLine."Expression Type" of
            TaxCalcLine."Expression Type"::Link:
                begin
                    if TaxCalcLine.Expression = '' then
                        exit;
                    TaxCalcAccumulation.Reset();
                    TaxCalcAccumulation.FilterGroup(2);
                    TaxCalcAccumulation.SetRange("Section Code", TaxCalcLine."Section Code");
                    TaxCalcAccumulation.FilterGroup(0);
                    TaxCalcAccumulation.SetRange("Register No.", TaxCalcLine."Link Register No.");
                    TaxCalcAccumulation.SetRange("Ending Date", "Ending Date");
                    TaxCalcAccumulation.SetRange("Template Line Code", TaxCalcLine.Expression);
                    if TaxCalcAccumulation.FindFirst() then;
                    TaxCalcAccumulation.SetRange("Template Line Code");
                    PAGE.RunModal(0, TaxCalcAccumulation);
                end;
            TaxCalcLine."Expression Type"::Total:
                Message(Text001, TaxCalcLine.Expression);
            TaxCalcLine."Expression Type"::Term:
                begin
                    if TaxCalcLine.Expression = '' then
                        exit;
                    Clear(TaxCalcCalcBuffer);
                    TaxCalcCalcBuffer.BuildTmpCalcBuffer(Rec);
                    TaxCalcCalcBuffer.RunModal();
                end;
            TaxCalcLine."Expression Type"::SumField:
                begin
                    if TaxCalcLine."Sum Field No." = 0 then
                        exit;
                    TaxCalcHeader.Get("Section Code", "Register No.");
                    TaxCalcHeader.SetFilter("Date Filter", "Amount Date Filter");
                    TaxCalcHeader.ShowDetails("Template Line No.");
                end;
        end;
    end;
}

