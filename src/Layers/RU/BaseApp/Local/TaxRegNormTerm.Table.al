#pragma warning disable AA0247
table 17240 "Tax Reg. Norm Term"
{
    Caption = 'Tax Reg. Norm Term';
    LookupPageID = "Tax Reg. Norm Terms";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Norm Jurisdiction Code"; Code[10])
        {
            Caption = 'Norm Jurisdiction Code';
            NotBlank = true;
            TableRelation = "Tax Register Norm Jurisdiction";
        }
        field(2; "Term Code"; Code[20])
        {
            Caption = 'Term Code';
            NotBlank = true;
        }
        field(3; Description; Text[150])
        {
            Caption = 'Description';
        }
        field(4; "Expression Type"; Option)
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
                        ValidateChangeDeclaration(true);
                        TaxRegNormTermFormula.Reset();
                        TaxRegNormTermFormula.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
                        TaxRegNormTermFormula.SetRange("Term Code", "Term Code");
                        TaxRegNormTermFormula.DeleteAll();
                        Validate(Expression, '');
                    end else
                        ValidateChangeDeclaration(true);
            end;
        }
        field(5; Expression; Text[250])
        {
            Caption = 'Expression';

            trigger OnLookup()
            begin
                if "Term Code" = '' then
                    exit;
                TaxRegNormTermFormula.Reset();
                TaxRegNormTermFormula.FilterGroup(2);
                TaxRegNormTermFormula.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
                TaxRegNormTermFormula.FilterGroup(0);
                TaxRegNormTermFormula.SetRange("Term Code", "Term Code");
                if ("Expression Type" = "Expression Type"::Compare) and not (TaxRegNormTermFormula.Count = 3) then begin
                    if not (TaxRegNormTermFormula.Count = 0) then
                        TaxRegNormTermFormula.DeleteAll();
                    TaxRegNormTermFormula.Init();
                    TaxRegNormTermFormula."Norm Jurisdiction Code" := "Norm Jurisdiction Code";
                    TaxRegNormTermFormula."Term Code" := "Term Code";
                    TaxRegNormTermFormula."Account Type" := TaxRegNormTermFormula."Account Type"::Termin;
                    TaxRegNormTermFormula.Operation := TaxRegNormTermFormula.Operation::Negative;
                    TaxRegNormTermFormula."Line No." := 10000;
                    TaxRegNormTermFormula.Insert();
                    TaxRegNormTermFormula.Operation := TaxRegNormTermFormula.Operation::Zero;
                    TaxRegNormTermFormula."Line No." := 20000;
                    TaxRegNormTermFormula.Insert();
                    TaxRegNormTermFormula.Operation := TaxRegNormTermFormula.Operation::Positive;
                    TaxRegNormTermFormula."Line No." := 30000;
                    TaxRegNormTermFormula.Insert();
                    TaxRegNormTermFormula."Line No." := 10000;
                    TaxRegNormTermFormula.Find();
                    Commit();
                end;
                PAGE.RunModal(0, TaxRegNormTermFormula);
                Expression :=
                  TaxRegTermMgt.MakeTermExpressionText("Term Code", "Norm Jurisdiction Code",
                    DATABASE::"Tax Reg. Norm Term", DATABASE::"Tax Reg. Norm Term Formula");
            end;
        }
        field(6; "Rounding Precision"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Rounding Precision';
            DecimalPlaces = 0 :;

            trigger OnValidate()
            begin
                ValidateChangeDeclaration("Rounding Precision" <> xRec."Rounding Precision");
            end;
        }
        field(7; "Process Sign"; Option)
        {
            Caption = 'Process Sign';
            OptionCaption = ' ,Skip Negative,Skip Positive,Always Positive,Always Negative';
            OptionMembers = " ","Skip Negative","Skip Positive","Always Positive","Always Negative";

            trigger OnValidate()
            begin
                ValidateChangeDeclaration("Process Sign" <> xRec."Process Sign");
            end;
        }
        field(8; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(9; Check; Boolean)
        {
            Caption = 'Check';
        }
    }

    keys
    {
        key(Key1; "Norm Jurisdiction Code", "Term Code")
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
        ValidateChangeDeclaration(true);

        TaxRegNormTermFormula.Reset();
        TaxRegNormTermFormula.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
        TaxRegNormTermFormula.SetRange("Term Code", "Term Code");
        TaxRegNormTermFormula.DeleteAll();
    end;

    trigger OnInsert()
    begin
        ValidateChangeDeclaration(true);
    end;

    var
        TaxRegNormTermFormula: Record "Tax Reg. Norm Term Formula";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000900: Label 'Delete linked line %1?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure ValidateChangeDeclaration(Incident: Boolean)
    var
        TaxRegNormJurisdiction: Record "Tax Register Norm Jurisdiction";
    begin
        if not Incident then
            exit;

        TaxRegNormJurisdiction.Get("Norm Jurisdiction Code");
        // NormJurisdiction.ValidateChangeDeclaration();
    end;

    [Scope('OnPrem')]
    procedure GenerateProfile()
    var
        GenTermProfile: Record "Gen. Term Profile";
    begin
        if not GenTermProfile.Get(DATABASE::"Tax Reg. Norm Term") then begin
            GenTermProfile."Table No." := DATABASE::"Tax Reg. Norm Term";
            GenTermProfile."Section Code (Hdr)" := FieldNo("Norm Jurisdiction Code");
            GenTermProfile."Term Code (Hdr)" := FieldNo("Term Code");
            GenTermProfile."Expression Type (Hdr)" := FieldNo("Expression Type");
            GenTermProfile."Expression (Hdr)" := FieldNo(Expression);
            GenTermProfile."Description (Hdr)" := FieldNo(Description);
            GenTermProfile."Check (Hdr)" := FieldNo(Check);
            GenTermProfile."Process Sign (Hdr)" := FieldNo("Process Sign");
            GenTermProfile."Rounding Precision (Hdr)" := FieldNo("Rounding Precision");
            GenTermProfile."Date Filter (Hdr)" := FieldNo("Date Filter");

            GenTermProfile."Section Code (Line)" := TaxRegNormTermFormula.FieldNo("Norm Jurisdiction Code");
            GenTermProfile."Term Code (Line)" := TaxRegNormTermFormula.FieldNo("Term Code");
            GenTermProfile."Line No. (Line)" := TaxRegNormTermFormula.FieldNo("Line No.");
            GenTermProfile."Expression Type (Line)" := TaxRegNormTermFormula.FieldNo("Expression Type");
            GenTermProfile."Operation (Line)" := TaxRegNormTermFormula.FieldNo(Operation);
            GenTermProfile."Account Type (Line)" := TaxRegNormTermFormula.FieldNo("Account Type");
            GenTermProfile."Account No. (Line)" := TaxRegNormTermFormula.FieldNo("Account No.");
            GenTermProfile."Amount Type (Line)" := TaxRegNormTermFormula.FieldNo("Amount Type");
            GenTermProfile."Bal. Account No. (Line)" := TaxRegNormTermFormula.FieldNo("Bal. Account No.");
            GenTermProfile."Norm Jurisd. Code (Line)" := TaxRegNormTermFormula.FieldNo("Jurisdiction Code");
            GenTermProfile."Process Sign (Line)" := TaxRegNormTermFormula.FieldNo("Process Sign");
            GenTermProfile."Process Division by Zero(Line)" := TaxRegNormTermFormula.FieldNo("Process Division by Zero");

            GenTermProfile.Insert();
        end;
    end;
}

