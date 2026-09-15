#pragma warning disable AA0247
table 17311 "Tax Calc. Term"
{
    Caption = 'Tax Calc. Term';
    LookupPageID = "Tax Calc. Terms";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Term Code"; Code[20])
        {
            Caption = 'Term Code';
            NotBlank = true;
        }
        field(3; "Expression Type"; Option)
        {
            Caption = 'Expression Type';
            OptionCaption = 'Plus/Minus,Multiply/Divide,Compare';
            OptionMembers = "Plus/Minus","Multiply/Divide",Compare;

            trigger OnValidate()
            begin
                if "Expression Type" <> xRec."Expression Type" then
                    if xRec."Expression Type" = xRec."Expression Type"::Compare then begin
                        if not Confirm(Text21000900, false, xRec."Expression Type") then
                            Error('');
                        TaxCalcSection.Get("Section Code");
                        TaxCalcSection.ValidateChange();
                        TaxCalcTermFormula.Reset();
                        TaxCalcTermFormula.SetRange("Section Code", "Section Code");
                        TaxCalcTermFormula.SetRange("Term Code", "Term Code");
                        TaxCalcTermFormula.DeleteAll();
                        Validate(Expression, '');
                    end;
            end;
        }
        field(4; Expression; Text[250])
        {
            Caption = 'Expression';
        }
        field(5; Check; Boolean)
        {
            Caption = 'Check';
        }
        field(6; "Process Sign"; Option)
        {
            Caption = 'Process Sign';
            OptionCaption = ' ,Skip Negative,Skip Positive,Always Positive,Always Negative';
            OptionMembers = " ","Skip Negative","Skip Positive","Always Positive","Always Negative";

            trigger OnValidate()
            begin
                if "Process Sign" <> xRec."Process Sign" then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(8; Description; Text[150])
        {
            Caption = 'Description';
        }
        field(9; "Rounding Precision"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Rounding Precision';
            DecimalPlaces = 0 :;

            trigger OnValidate()
            begin
                if "Rounding Precision" <> xRec."Rounding Precision" then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(12; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(13; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Calc. Section".Code;
        }
    }

    keys
    {
        key(Key1; "Section Code", "Term Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Term Code", Description)
        {
        }
    }

    trigger OnDelete()
    begin
        TaxCalcSection.Get("Section Code");
        TaxCalcSection.ValidateChange();

        TaxCalcTermFormula.Reset();
        TaxCalcTermFormula.SetRange("Section Code", "Section Code");
        TaxCalcTermFormula.SetRange("Term Code", "Term Code");
        TaxCalcTermFormula.DeleteAll();
    end;

    trigger OnInsert()
    begin
        TaxCalcSection.Get("Section Code");
        TaxCalcSection.ValidateChange();
    end;

    var
        TaxCalcTermFormula: Record "Tax Calc. Term Formula";
        TaxCalcSection: Record "Tax Calc. Section";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000900: Label 'Delete linked line %1?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure GenerateProfile()
    var
        GenTermProfile: Record "Gen. Term Profile";
    begin
        if not GenTermProfile.Get(DATABASE::"Tax Calc. Term") then begin
            GenTermProfile."Table No." := DATABASE::"Tax Calc. Term";
            GenTermProfile."Section Code (Hdr)" := FieldNo("Section Code");
            GenTermProfile."Term Code (Hdr)" := FieldNo("Term Code");
            GenTermProfile."Expression Type (Hdr)" := FieldNo("Expression Type");
            GenTermProfile."Expression (Hdr)" := FieldNo(Expression);
            GenTermProfile."Description (Hdr)" := FieldNo(Description);
            GenTermProfile."Check (Hdr)" := FieldNo(Check);
            GenTermProfile."Process Sign (Hdr)" := FieldNo("Process Sign");
            GenTermProfile."Rounding Precision (Hdr)" := FieldNo("Rounding Precision");
            GenTermProfile."Date Filter (Hdr)" := FieldNo("Date Filter");

            GenTermProfile."Section Code (Line)" := TaxCalcTermFormula.FieldNo("Section Code");
            GenTermProfile."Term Code (Line)" := TaxCalcTermFormula.FieldNo("Term Code");
            GenTermProfile."Line No. (Line)" := TaxCalcTermFormula.FieldNo("Line No.");
            GenTermProfile."Expression Type (Line)" := TaxCalcTermFormula.FieldNo("Expression Type");
            GenTermProfile."Operation (Line)" := TaxCalcTermFormula.FieldNo(Operation);
            GenTermProfile."Account Type (Line)" := TaxCalcTermFormula.FieldNo("Account Type");
            GenTermProfile."Account No. (Line)" := TaxCalcTermFormula.FieldNo("Account No.");
            GenTermProfile."Amount Type (Line)" := TaxCalcTermFormula.FieldNo("Amount Type");
            GenTermProfile."Bal. Account No. (Line)" := TaxCalcTermFormula.FieldNo("Bal. Account No.");
            GenTermProfile."Norm Jurisd. Code (Line)" := TaxCalcTermFormula.FieldNo("Norm Jurisdiction Code");
            GenTermProfile."Process Sign (Line)" := TaxCalcTermFormula.FieldNo("Process Sign");
            GenTermProfile."Process Division by Zero(Line)" := TaxCalcTermFormula.FieldNo("Process Division by Zero");

            GenTermProfile.Insert();
        end;
    end;
}

