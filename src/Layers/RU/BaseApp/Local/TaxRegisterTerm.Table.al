#pragma warning disable AA0247
table 17204 "Tax Register Term"
{
    Caption = 'Tax Register Term';
    LookupPageID = "Tax Register Term";
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
                        TaxRegSection.Get("Section Code");
                        TaxRegSection.ValidateChangeDeclaration();
                        TaxRegisterTermFormula.Reset();
                        TaxRegisterTermFormula.SetRange("Section Code", "Section Code");
                        TaxRegisterTermFormula.SetRange("Term Code", "Term Code");
                        TaxRegisterTermFormula.DeleteAll();
                        Validate(Expression, '');
                    end;
            end;
        }
        field(4; Expression; Text[250])
        {
            Caption = 'Expression';

            trigger OnLookup()
            begin
                if "Term Code" = '' then
                    exit;

                TaxRegisterTermFormula.Reset();
                TaxRegisterTermFormula.FilterGroup(2);
                TaxRegisterTermFormula.SetRange("Section Code", "Section Code");
                TaxRegisterTermFormula.FilterGroup(0);
                TaxRegisterTermFormula.SetRange("Term Code", "Term Code");
                if ("Expression Type" = "Expression Type"::Compare) and not (TaxRegisterTermFormula.Count = 3) then begin
                    if not (TaxRegisterTermFormula.Count = 0) then
                        TaxRegisterTermFormula.DeleteAll();
                    TaxRegisterTermFormula.Init();
                    TaxRegisterTermFormula."Section Code" := "Section Code";
                    TaxRegisterTermFormula."Term Code" := "Term Code";
                    TaxRegisterTermFormula."Account Type" := TaxRegisterTermFormula."Account Type"::Term;
                    TaxRegisterTermFormula.Operation := TaxRegisterTermFormula.Operation::Negative;
                    TaxRegisterTermFormula."Line No." := 10000;
                    TaxRegisterTermFormula.Insert();
                    TaxRegisterTermFormula.Operation := TaxRegisterTermFormula.Operation::Zero;
                    TaxRegisterTermFormula."Line No." := 20000;
                    TaxRegisterTermFormula.Insert();
                    TaxRegisterTermFormula.Operation := TaxRegisterTermFormula.Operation::Positive;
                    TaxRegisterTermFormula."Line No." := 30000;
                    TaxRegisterTermFormula.Insert();
                    TaxRegisterTermFormula."Line No." := 10000;
                    TaxRegisterTermFormula.Find();
                    Commit();
                end;
                PAGE.RunModal(0, TaxRegisterTermFormula);
                Expression :=
                  TaxRegTermMgt.MakeTermExpressionText("Term Code", "Section Code",
                    DATABASE::"Tax Register Term", DATABASE::"Tax Register Term Formula");
            end;
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
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
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
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
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
            TableRelation = "Tax Register Section";
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
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();

        TaxRegisterTermFormula.Reset();
        TaxRegisterTermFormula.SetRange("Section Code", "Section Code");
        TaxRegisterTermFormula.SetRange("Term Code", "Term Code");
        TaxRegisterTermFormula.DeleteAll();
    end;

    trigger OnInsert()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();
    end;

    var
        TaxRegisterTermFormula: Record "Tax Register Term Formula";
        TaxRegSection: Record "Tax Register Section";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000900: Label 'Delete linked line for expression type %1?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure GenerateProfile()
    var
        GenTermProfile: Record "Gen. Term Profile";
    begin
        if not GenTermProfile.Get(DATABASE::"Tax Register Term") then begin
            GenTermProfile."Table No." := DATABASE::"Tax Register Term";
            GenTermProfile."Section Code (Hdr)" := FieldNo("Section Code");
            GenTermProfile."Term Code (Hdr)" := FieldNo("Term Code");
            GenTermProfile."Expression Type (Hdr)" := FieldNo("Expression Type");
            GenTermProfile."Expression (Hdr)" := FieldNo(Expression);
            GenTermProfile."Description (Hdr)" := FieldNo(Description);
            GenTermProfile."Check (Hdr)" := FieldNo(Check);
            GenTermProfile."Process Sign (Hdr)" := FieldNo("Process Sign");
            GenTermProfile."Rounding Precision (Hdr)" := FieldNo("Rounding Precision");
            GenTermProfile."Date Filter (Hdr)" := FieldNo("Date Filter");

            GenTermProfile."Section Code (Line)" := TaxRegisterTermFormula.FieldNo("Section Code");
            GenTermProfile."Term Code (Line)" := TaxRegisterTermFormula.FieldNo("Term Code");
            GenTermProfile."Line No. (Line)" := TaxRegisterTermFormula.FieldNo("Line No.");
            GenTermProfile."Expression Type (Line)" := TaxRegisterTermFormula.FieldNo("Expression Type");
            GenTermProfile."Operation (Line)" := TaxRegisterTermFormula.FieldNo(Operation);
            GenTermProfile."Account Type (Line)" := TaxRegisterTermFormula.FieldNo("Account Type");
            GenTermProfile."Account No. (Line)" := TaxRegisterTermFormula.FieldNo("Account No.");
            GenTermProfile."Amount Type (Line)" := TaxRegisterTermFormula.FieldNo("Amount Type");
            GenTermProfile."Bal. Account No. (Line)" := TaxRegisterTermFormula.FieldNo("Bal. Account No.");
            GenTermProfile."Norm Jurisd. Code (Line)" := TaxRegisterTermFormula.FieldNo("Norm Jurisdiction Code");
            GenTermProfile."Process Sign (Line)" := TaxRegisterTermFormula.FieldNo("Process Sign");
            GenTermProfile."Process Division by Zero(Line)" := TaxRegisterTermFormula.FieldNo("Process Division by Zero");
            GenTermProfile.Insert();
        end;
    end;
}

