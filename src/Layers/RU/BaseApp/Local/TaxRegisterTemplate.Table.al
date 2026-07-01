#pragma warning disable AA0247
table 17202 "Tax Register Template"
{
    Caption = 'Tax Register Template';
    LookupPageID = "Tax Register Templates";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            TableRelation = "Tax Register"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Expression Type"; Option)
        {
            Caption = 'Expression Type';
            OptionCaption = 'Term,Link,Total,Header,SumField,Norm';
            OptionMembers = Term,Link,Total,Header,SumField,Norm;

            trigger OnValidate()
            begin
                if "Expression Type" <> xRec."Expression Type" then begin
                    TaxRegSection.Get("Section Code");
                    if "Expression Type" <> "Expression Type"::Norm then
                        "Norm Jurisdiction Code" := ''
                    else begin
                        TaxRegSection.TestField("Norm Jurisdiction Code");
                        "Norm Jurisdiction Code" := TaxRegSection."Norm Jurisdiction Code";
                    end;
                    TaxRegSection.ValidateChangeDeclaration();
                    Expression := '';
                    Value := 0;
                    "Link Tax Register No." := '';
                    "Sum Field No." := 0;
                    "Link Line Code" := '';
                    "Term Line Code" := '';
                end;
            end;
        }
        field(4; Expression; Text[150])
        {
            Caption = 'Expression';

            trigger OnLookup()
            begin
                case "Expression Type" of
                    "Expression Type"::Norm:
                        begin
                            TestField("Norm Jurisdiction Code");
                            TaxRegNormGroup.Reset();
                            TaxRegNormGroup.FilterGroup(2);
                            TaxRegNormGroup.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
                            TaxRegNormGroup.FilterGroup(0);
                            if Expression <> '' then
                                if TaxRegNormGroup.Get("Norm Jurisdiction Code", Expression) then;
                            if ACTION::LookupOK = PAGE.RunModal(0, TaxRegNormGroup) then begin
                                Expression := TaxRegNormGroup.Code;
                                if Description = '' then
                                    Description := TaxRegNormGroup.Description;
                            end;
                        end;
                    "Expression Type"::Term:
                        begin
                            TaxRegTerm.Reset();
                            TaxRegTerm.FilterGroup(2);
                            TaxRegTerm.SetRange("Section Code", "Section Code");
                            TaxRegTerm.FilterGroup(0);
                            if Expression <> '' then
                                if TaxRegTerm.Get("Section Code", Expression) then;
                            if ACTION::LookupOK = PAGE.RunModal(0, TaxRegTerm) then begin
                                Expression := TaxRegTerm."Term Code";
                                if Description = '' then
                                    Description := TaxRegTerm.Description;
                            end;
                        end;
                    "Expression Type"::SumField:
                        begin
                            "Link Tax Register No." := Code;
                            TaxReg.Get("Section Code", "Link Tax Register No.");
                            Field.Reset();
                            Field.SetFilter("No.", MakeFieldFilter(TaxReg."Table ID"));
                            if Field.GetFilter("No.") <> '' then begin
                                Field.SetRange(TableNo, TaxReg."Table ID");
                                if Field."No." <> 0 then
                                    if Field.Get(TaxReg."Table ID", Field."No.") then;
                                if ACTION::LookupOK = PAGE.RunModal(PAGE::"Tax Register Field Select", Field) then begin
                                    if TaxReg."Table ID" = DATABASE::"Tax Register FA Entry" then begin
                                        if Field."No." <> TaxRegFAEntry.FieldNo("Depreciation Amount") then
                                            TestField(Period, '');
                                        if Field."No." <> TaxRegFAEntry.FieldNo("Depreciation Bonus Amount") then
                                            TestField("Depr. Bonus % Filter", '');
                                        if not (Field."No." in [TaxRegFAEntry.FieldNo("Acquisition Cost"),
                                                                TaxRegFAEntry.FieldNo("Valuation Changes")])
                                        then
                                            TestField("Tax Difference Code Filter", '');

                                        if Field."No." = TaxRegFAEntry.FieldNo("Acquis. Cost for Released FA") then begin
                                            FASetup.Get();
                                            FASetup.TestField("Release Depr. Book");
                                            TaxRegSetup.Get();
                                            TaxRegSetup.TestField("Tax Depreciation Book");
                                            if not ("Depr. Book Filter" in
                                                    [FASetup."Release Depr. Book", TaxRegSetup."Tax Depreciation Book"])
                                            then
                                                FieldError("Depr. Book Filter");
                                        end;
                                    end;
                                    "Sum Field No." := Field."No.";
                                    Expression := Field."Field Caption";
                                end;
                            end;
                        end;
                    "Expression Type"::Link:
                        begin
                            TestField("Link Tax Register No.");
                            TaxReg.Get("Section Code", "Link Tax Register No.");
                            TaxRegTemplate.FilterGroup(2);
                            TaxRegTemplate.SetRange("Section Code", TaxReg."Section Code");
                            TaxRegTemplate.SetRange(Code, TaxReg."No.");
                            TaxRegTemplate.FilterGroup(0);
                            if Expression <> '' then
                                if TaxRegTemplate.Get("Section Code", Expression) then;
                            if ACTION::LookupOK = PAGE.RunModal(0, TaxRegTemplate) then begin
                                TaxRegTemplate.TestField("Line Code");
                                Expression := TaxRegTemplate."Line Code";
                                if Description = '' then
                                    Description := TaxRegTemplate.Description;
                            end;
                        end;
                end;
            end;

            trigger OnValidate()
            begin
                if Expression <> xRec.Expression then
                    if ("Expression Type" in ["Expression Type"::Link, "Expression Type"::SumField]) and (Expression <> '') then
                        Expression := xRec.Expression
                    else begin
                        TaxRegSection.Get("Section Code");
                        TaxRegSection.ValidateChangeDeclaration();
                    end;
            end;
        }
        field(5; "Line Code"; Code[10])
        {
            Caption = 'Line Code';

            trigger OnValidate()
            begin
                if ("Line Code" <> xRec."Line Code") and (xRec."Line Code" <> '') then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(6; Description; Text[150])
        {
            Caption = 'Description';
        }
        field(7; Value; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value';
        }
        field(8; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(9; "Link Tax Register No."; Code[10])
        {
            Caption = 'Link Tax Register No.';
            TableRelation = if ("Expression Type" = const(Link)) "Tax Register"."No." where("Section Code" = field("Section Code"));

            trigger OnValidate()
            begin
                if "Link Tax Register No." <> xRec."Link Tax Register No." then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();

                    if "Link Tax Register No." = '' then
                        Expression := '';
                end;
            end;
        }
        field(10; "Sum Field No."; Integer)
        {
            Caption = 'Sum Field No.';

            trigger OnValidate()
            begin
                if "Sum Field No." <> xRec."Sum Field No." then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(11; "Link Line Code"; Code[10])
        {
            Caption = 'Link Line Code';

            trigger OnValidate()
            begin
                if "Link Line Code" <> xRec."Link Line Code" then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(12; "Rounding Precision"; Decimal)
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
        field(13; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Register Section";
        }
        field(14; "Dimensions Filters"; Boolean)
        {
            CalcFormula = exist("Tax Register Dim. Filter" where("Section Code" = field("Section Code"),
                                                                  "Tax Register No." = field(Code),
                                                                  Define = const(Template),
                                                                  "Line No." = field("Line No.")));
            Caption = 'Dimensions Filters';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Norm Jurisdiction Code"; Code[10])
        {
            Caption = 'Norm Jurisdiction Code';
            TableRelation = "Tax Register Norm Jurisdiction";
        }
        field(16; "G/L Corr. Dimensions Filters"; Boolean)
        {
            CalcFormula = exist("Tax Reg. G/L Corr. Dim. Filter" where("Section Code" = field("Section Code"),
                                                                        "Tax Register No." = field(Code),
                                                                        "Line No." = field("Line No."),
                                                                        Define = const(Template)));
            Caption = 'G/L Corr. Dimensions Filters';
            FieldClass = FlowField;
        }
        field(37; "Report Line Code"; Text[10])
        {
            Caption = 'Report Line Code';
        }
        field(39; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(40; Bold; Boolean)
        {
            Caption = 'Bold';
        }
        field(41; Period; Code[30])
        {
            Caption = 'Period';

            trigger OnValidate()
            begin
                if not ("Expression Type" in ["Expression Type"::Term, "Expression Type"::SumField]) then
                    if Period <> '' then
                        Error(Text2001, "Expression Type");
                if Period <> xRec.Period then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(42; "Term Line Code"; Code[10])
        {
            Caption = 'Term Line Code';

            trigger OnLookup()
            begin
                if ("Expression Type" <> "Expression Type"::SumField) or
                   ("Sum Field No." = 0) or
                   ("Link Tax Register No." = '')
                then
                    exit;

                TaxRegLineSetup.Reset();
                TaxRegLineSetup.FilterGroup(2);
                TaxRegLineSetup.SetRange("Section Code", "Section Code");
                TaxRegLineSetup.FilterGroup(0);
                TaxRegLineSetup.SetRange("Tax Register No.", "Link Tax Register No.");
                if ACTION::LookupOK = PAGE.RunModal(0, TaxRegLineSetup) then begin
                    TaxRegLineSetup.TestField("Tax Register No.", "Link Tax Register No.");
                    TaxRegLineSetup.TestField("Line Code");
                    "Term Line Code" := TaxRegLineSetup."Line Code";
                end;
            end;

            trigger OnValidate()
            begin
                if "Term Line Code" <> xRec."Term Line Code" then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                    TaxRegLineSetup.Reset();
                    TaxRegLineSetup.SetRange("Section Code", "Section Code");
                    TaxRegLineSetup.SetRange("Tax Register No.", "Link Tax Register No.");
                    TaxRegLineSetup.SetRange("Line Code", "Term Line Code");
                    if not TaxRegLineSetup.FindFirst() then
                        FieldError("Term Line Code");
                end;
            end;
        }
        field(43; "Depreciation Group"; Code[10])
        {
            Caption = 'Depreciation Group';
            TableRelation = if ("Expression Type" = const(SumField)) "Depreciation Group".Code;

            trigger OnValidate()
            begin
                if "Depreciation Group" <> xRec."Depreciation Group" then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(44; "Belonging to Manufacturing"; Option)
        {
            Caption = 'Belonging to Manufacturing';
            OptionCaption = ' ,Production,Nonproduction';
            OptionMembers = " ",Production,Nonproduction;

            trigger OnValidate()
            begin
                if "Belonging to Manufacturing" <> xRec."Belonging to Manufacturing" then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(45; "FA Type"; Option)
        {
            Caption = 'FA Type';
            OptionCaption = ' ,Fixed Assets,Intangible Assets';
            OptionMembers = " ","Fixed Assets","Intangible Assets";

            trigger OnValidate()
            begin
                if "FA Type" <> xRec."FA Type" then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(56; "Depr. Bonus % Filter"; Code[20])
        {
            Caption = 'Depr. Bonus % Filter';

            trigger OnValidate()
            begin
                if "Depr. Bonus % Filter" <> xRec."Depr. Bonus % Filter" then begin
                    TestField("Expression Type", "Expression Type"::SumField);
                    if "Sum Field No." <> TaxRegFAEntry.FieldNo("Depreciation Bonus Amount") then
                        Error(Text2003, FieldCaption(Expression), TaxRegFAEntry.FieldCaption("Depreciation Bonus Amount"));
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(57; "Tax Difference Code Filter"; Code[80])
        {
            Caption = 'Tax Difference Code Filter';
            TableRelation = "Tax Difference";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Tax Difference Code Filter" <> xRec."Tax Difference Code Filter" then begin
                    TestField("Expression Type", "Expression Type"::SumField);
                    if not ("Sum Field No." in [TaxRegFAEntry.FieldNo("Acquisition Cost"),
                                                TaxRegFAEntry.FieldNo("Valuation Changes")])
                    then
                        Error(
                          Text2004,
                          FieldCaption(Expression),
                          TaxRegFAEntry.FieldCaption("Acquisition Cost"),
                          TaxRegFAEntry.FieldCaption("Valuation Changes"));

                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(58; "Depr. Book Filter"; Code[80])
        {
            Caption = 'Depr. Book Filter';
            TableRelation = "Depreciation Book";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Depr. Book Filter" <> xRec."Depr. Book Filter" then begin
                    FASetup.Get();
                    FASetup.TestField("Release Depr. Book");
                    TaxRegSetup.Get();
                    TaxRegSetup.TestField("Tax Depreciation Book");
                    TestField("Expression Type", "Expression Type"::SumField);
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();

                    if ("Sum Field No." = TaxRegFAEntry.FieldNo("Acquis. Cost for Released FA")) and
                       not ("Depr. Book Filter" in [FASetup."Release Depr. Book", TaxRegSetup."Tax Depreciation Book"])
                    then
                        FieldError(Expression);
                end;
            end;
        }
        field(59; "Result on Disposal"; Option)
        {
            Caption = 'Result on Disposal';
            OptionCaption = ' ,Gain,Loss';
            OptionMembers = " ",Gain,Loss;

            trigger OnValidate()
            begin
                if "Result on Disposal" <> xRec."Result on Disposal" then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                    if "Result on Disposal" <> "Result on Disposal"::" " then begin
                        TaxReg.Get("Section Code", Code);
                        TaxReg.TestField("Table ID", DATABASE::"Tax Register FA Entry");

                        if not ("Sum Field No." in
                                [TaxRegFAEntry.FieldNo("Sales Gain/Loss"), TaxRegFAEntry.FieldNo("Sold FA Qty")])
                        then
                            FieldError(Expression);
                    end;
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Section Code", "Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();

        TaxRegDimFilter.SetRange("Section Code", "Section Code");
        TaxRegDimFilter.SetRange("Tax Register No.", Code);
        TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::Template);
        TaxRegDimFilter.SetRange("Line No.", "Line No.");
        TaxRegDimFilter.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();
    end;

    var
        FASetup: Record "FA Setup";
        TaxRegSetup: Record "Tax Register Setup";
        TaxRegSection: Record "Tax Register Section";
        TaxRegTerm: Record "Tax Register Term";
        TaxReg: Record "Tax Register";
        TaxRegLineSetup: Record "Tax Register Line Setup";
        TaxRegTemplate: Record "Tax Register Template";
        "Field": Record "Field";
        TaxRegGLEntry: Record "Tax Register G/L Entry";
        TaxRegFAEntry: Record "Tax Register FA Entry";
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
        TaxRegNormGroup: Record "Tax Register Norm Group";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text2001: Label 'Period must be empty if Expression Type is %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text2003: Label '%1 must be %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text2004: Label '%1 must be %2 or %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure MakeFieldFilter(TaxRegTableNo: Integer) FilterText: Text[1024]
    begin
        Field.Reset();
        Field.SetRange(TableNo, TaxRegTableNo);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        if Field.FindSet() then begin
            repeat
                if TaxRegGLEntry.SetFieldFilter(Field."No.") then
                    FilterText := StrSubstNo('%1|%2', FilterText, Field."No.");
            until Field.Next() = 0;
            FilterText := DelChr(FilterText, '<>', '|');
        end;
    end;

    [Scope('OnPrem')]
    procedure GenerateProfile()
    var
        GenTemplateProfile: Record "Gen. Template Profile";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
    begin
        if GenTemplateProfile.Get(DATABASE::"Tax Register Template") then
            exit;

        GenTemplateProfile."Template Line Table No." := DATABASE::"Tax Register Template";
        GenTemplateProfile."Template Header Table No." := DATABASE::"Tax Register";
        GenTemplateProfile."Term Header Table No." := DATABASE::"Tax Register Term";
        GenTemplateProfile."Term Line Table No." := DATABASE::"Tax Register Term Formula";
        GenTemplateProfile."Dim. Filter Table No." := DATABASE::"Tax Register Dim. Filter";

        GenTemplateProfile."Section Code (Hdr)" := TaxReg.FieldNo("Section Code");
        GenTemplateProfile."Code (Hdr)" := TaxReg.FieldNo("No.");
        GenTemplateProfile."Check (Hdr)" := TaxReg.FieldNo(Check);
        GenTemplateProfile."Level (Hdr)" := TaxReg.FieldNo(Level);

        GenTemplateProfile."Section Code" := FieldNo("Section Code");
        GenTemplateProfile.Code := FieldNo(Code);
        GenTemplateProfile."Line No." := FieldNo("Line No.");
        GenTemplateProfile."Expression Type" := FieldNo("Expression Type");
        GenTemplateProfile.Expression := FieldNo(Expression);
        GenTemplateProfile."Line Code (Line)" := FieldNo("Line Code");
        GenTemplateProfile."Norm Jurisd. Code (Line)" := FieldNo("Norm Jurisdiction Code");
        GenTemplateProfile."Link Code" := FieldNo("Link Tax Register No.");
        GenTemplateProfile."Date Filter" := FieldNo("Date Filter");
        GenTemplateProfile.Period := FieldNo(Period);
        GenTemplateProfile.Description := FieldNo(Description);
        GenTemplateProfile."Rounding Precision" := FieldNo("Rounding Precision");

        GenTemplateProfile."Header Code (Link)" := TaxRegAccumulation.FieldNo("Tax Register No.");
        GenTemplateProfile."Line Code (Link)" := TaxRegAccumulation.FieldNo("Template Line Code");
        GenTemplateProfile."Value (Link)" := TaxRegAccumulation.FieldNo(Amount);

        GenTemplateProfile."Section Code (Dim)" := TaxRegDimFilter.FieldNo("Section Code");
        GenTemplateProfile."Tax Register No. (Dim)" := TaxRegDimFilter.FieldNo("Tax Register No.");
        GenTemplateProfile."Define (Dim)" := TaxRegDimFilter.FieldNo(Define);
        GenTemplateProfile."Line No. (Dim)" := TaxRegDimFilter.FieldNo("Line No.");
        GenTemplateProfile."Dimension Code (Dim)" := TaxRegDimFilter.FieldNo("Dimension Code");
        GenTemplateProfile."Dimension Value Filter (Dim)" := TaxRegDimFilter.FieldNo("Dimension Value Filter");

        GenTemplateProfile.Insert();
    end;

    [Scope('OnPrem')]
    procedure GetGLCorrDimFilter(DimCode: Code[20]; FilterGroup: Option Debit,Credit) DimFilter: Text[250]
    var
        TaxRegGLCorrDimFilter: Record "Tax Reg. G/L Corr. Dim. Filter";
    begin
        if TaxRegGLCorrDimFilter.Get("Section Code", Code, 0, "Line No.", FilterGroup, DimCode) then
            DimFilter := TaxRegGLCorrDimFilter."Dimension Value Filter";
    end;

    [Scope('OnPrem')]
    procedure InitFADeprBookFilter()
    var
        TaxRegisterName: Record "Tax Register";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        TaxRegisterName.Get("Section Code", Code);
        if TaxRegisterName."Table ID" = DATABASE::"Tax Register FA Entry" then begin
            TaxRegisterSetup.Get();
            "Depr. Book Filter" := TaxRegisterSetup."Tax Depreciation Book";
        end;
    end;
}

