#pragma warning disable AA0247
table 17310 "Tax Calc. Line"
{
    Caption = 'Tax Calc. Line';
    LookupPageID = "Tax Calc. Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            TableRelation = "Tax Calc. Header"."No.";
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
                    TaxCalcSection.Get("Section Code");
                    if "Expression Type" <> "Expression Type"::Norm then
                        "Norm Jurisdiction Code" := ''
                    else begin
                        TaxCalcSection.TestField("Norm Jurisdiction Code");
                        "Norm Jurisdiction Code" := TaxCalcSection."Norm Jurisdiction Code";
                    end;
                    TaxCalcSection.ValidateChange();
                    Expression := '';
                    Value := 0;
                    "Link Register No." := '';
                    "Sum Field No." := 0;
                    "Field Name" := '';
                    "Selection Line Code" := '';
                end;
            end;
        }
        field(4; Expression; Text[150])
        {
            Caption = 'Expression';

            trigger OnLookup()
            begin
                if "Expression Type" = "Expression Type"::Norm then begin
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
                if "Expression Type" = "Expression Type"::Term then begin
                    TaxCalcTerm.Reset();
                    TaxCalcTerm.FilterGroup(2);
                    TaxCalcTerm.SetRange("Section Code", "Section Code");
                    TaxCalcTerm.FilterGroup(0);
                    if Expression <> '' then
                        if TaxCalcTerm.Get("Section Code", Expression) then;
                    if ACTION::LookupOK = PAGE.RunModal(0, TaxCalcTerm) then begin
                        Expression := TaxCalcTerm."Term Code";
                        Description := TaxCalcTerm.Description;
                    end;
                end;
                if "Expression Type" = "Expression Type"::Link then begin
                    TestField("Link Register No.");
                    TaxCalcHeader.Get("Section Code", "Link Register No.");
                    TaxCalcLine.Reset();
                    TaxCalcLine.FilterGroup(2);
                    TaxCalcLine.SetRange("Section Code", TaxCalcHeader."Section Code");
                    TaxCalcLine.SetRange(Code, TaxCalcHeader."No.");
                    TaxCalcLine.FilterGroup(0);
                    if Expression <> '' then
                        if TaxCalcLine.Get("Section Code", Expression) then;
                    if ACTION::LookupOK = PAGE.RunModal(0, TaxCalcLine) then begin
                        TaxCalcLine.TestField("Line Code");
                        Expression := TaxCalcLine."Line Code";
                        Description := TaxCalcLine.Description;
                    end;
                end;
            end;

            trigger OnValidate()
            begin
                if Expression <> xRec.Expression then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(5; "Line Code"; Code[10])
        {
            Caption = 'Line Code';

            trigger OnValidate()
            begin
                if ("Line Code" <> xRec."Line Code") and (xRec."Line Code" <> '') then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
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
        field(9; "Link Register No."; Code[10])
        {
            Caption = 'Link Register No.';
            TableRelation = if ("Expression Type" = const(Link)) "Tax Calc. Header"."No." where("Section Code" = field("Section Code"));

            trigger OnValidate()
            begin
                if "Link Register No." <> xRec."Link Register No." then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(10; "Sum Field No."; Integer)
        {
            Caption = 'Sum Field No.';

            trigger OnValidate()
            begin
                if "Sum Field No." <> xRec."Sum Field No." then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
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
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(13; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Calc. Section";
        }
        field(14; "Dimensions Filters"; Boolean)
        {
            CalcFormula = exist("Tax Calc. Dim. Filter" where("Section Code" = field("Section Code"),
                                                               "Register No." = field(Code),
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
        field(16; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = ' ,CalcField,LineField';
            OptionMembers = " ",CalcField,LineField;

            trigger OnValidate()
            begin
                TaxCalcHeader.Get("Section Code", Code);
                TaxCalcHeader.TestField("Storing Method", TaxCalcHeader."Storing Method"::"Build Entry");
                TaxCalcSection.Get("Section Code");
                if "Line Type" <> xRec."Line Type" then
                    TaxCalcSection.ValidateChange();

                if "Line Type" = "Line Type"::CalcField then
                    "Expression Type" := "Expression Type"::Link
                else
                    Rec."Expression Type" := Rec."Expression Type"::SumField;
                Expression := '';
                Value := 0;
                "Link Register No." := '';
                "Sum Field No." := 0;
                "Field Name" := '';
                "Selection Line Code" := '';
                if "Line Type" = "Line Type"::" " then
                    GetDefaultSumField();
            end;
        }
        field(17; "Field Name"; Text[80])
        {
            Caption = 'Field Name';
            Editable = false;

            trigger OnLookup()
            begin
                if ("Expression Type" = "Expression Type"::SumField) or
                   ("Line Type" <> "Line Type"::" ")
                then begin
                    TaxCalcHeader.Get("Section Code", Code);
                    Fields.Reset();
                    if "Line Type" = "Line Type"::CalcField then
                        Fields.SetFilter("No.", MakeCalcFieldFilter(TaxCalcHeader."Table ID"))
                    else
                        Fields.SetFilter("No.", MakeFieldFilter(TaxCalcHeader."Table ID"));
                    if Fields.GetFilter("No.") <> '' then begin
                        Fields.SetRange(TableNo, TaxCalcHeader."Table ID");
                        if Fields."No." <> 0 then
                            if Fields.Get(TaxCalcHeader."Table ID", Fields."No.") then;
                        if ACTION::LookupOK = PAGE.RunModal(PAGE::"Tax Register Field Select", Fields) then begin
                            "Sum Field No." := Fields."No.";
                            "Field Name" := Fields."Field Caption";
                        end;
                    end;
                end;
            end;
        }
        field(18; "Tax Diff. Amount (Base)"; Boolean)
        {
            Caption = 'Tax Diff. Amount (Base)';

            trigger OnValidate()
            begin
                if "Tax Diff. Amount (Base)" then
                    if "Line Type" = "Line Type"::CalcField then
                        TestField("Sum Field No.", 0)
                    else
                        TestField("Line Type", "Line Type"::" ");
                if "Tax Diff. Amount (Base)" <> xRec."Tax Diff. Amount (Base)" then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
                if "Tax Diff. Amount (Base)" then begin
                    TaxCalcLine.Reset();
                    TaxCalcLine.SetRange("Section Code", "Section Code");
                    TaxCalcLine.SetRange(Code, Code);
                    TaxCalcLine.SetFilter("Line No.", '<>%1', "Line No.");
                    TaxCalcLine.ModifyAll("Tax Diff. Amount (Base)", false);
                    "Tax Diff. Amount (Tax)" := false;
                end;
            end;
        }
        field(19; "Tax Diff. Amount (Tax)"; Boolean)
        {
            Caption = 'Tax Diff. Amount (Tax)';

            trigger OnValidate()
            begin
                if "Tax Diff. Amount (Tax)" then
                    if "Line Type" = "Line Type"::CalcField then
                        TestField("Sum Field No.", 0)
                    else
                        TestField("Line Type", "Line Type"::" ");
                if "Tax Diff. Amount (Tax)" <> xRec."Tax Diff. Amount (Tax)" then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
                if "Tax Diff. Amount (Tax)" then begin
                    TaxCalcLine.Reset();
                    TaxCalcLine.SetRange("Section Code", "Section Code");
                    TaxCalcLine.SetRange(Code, Code);
                    TaxCalcLine.SetFilter("Line No.", '<>%1', "Line No.");
                    TaxCalcLine.ModifyAll("Tax Diff. Amount (Tax)", false);
                    "Tax Diff. Amount (Base)" := false;
                end;
            end;
        }
        field(20; "G/L Corr. Dimensions Filters"; Boolean)
        {
            CalcFormula = exist("Tax Diff. Corr. Dim. Filter" where("Section Code" = field("Section Code"),
                                                                     "Tax Calc. No." = field(Code),
                                                                     "Line No." = field("Line No."),
                                                                     Define = const(Template)));
            Caption = 'G/L Corr. Dimensions Filters';
            FieldClass = FlowField;
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
                        Error(Text1000, "Expression Type");
                if Period <> xRec.Period then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(42; "Selection Line Code"; Code[10])
        {
            Caption = 'Selection Line Code';

            trigger OnLookup()
            begin
                if ("Expression Type" <> "Expression Type"::SumField) or ("Sum Field No." = 0) then
                    exit;

                TaxCalcSelectionSetup.Reset();
                TaxCalcSelectionSetup.FilterGroup(2);
                TaxCalcSelectionSetup.SetRange("Section Code", "Section Code");
                TaxCalcSelectionSetup.FilterGroup(0);
                TaxCalcSelectionSetup.SetRange("Register No.", Code);
                if ACTION::LookupOK = PAGE.RunModal(0, TaxCalcSelectionSetup) then begin
                    TaxCalcSelectionSetup.TestField("Register No.", Code);
                    TaxCalcSelectionSetup.TestField("Line Code");
                    "Selection Line Code" := TaxCalcSelectionSetup."Line Code";
                end;
            end;

            trigger OnValidate()
            begin
                if "Selection Line Code" <> xRec."Selection Line Code" then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                    TaxCalcSelectionSetup.Reset();
                    TaxCalcSelectionSetup.SetRange("Section Code", "Section Code");
                    TaxCalcSelectionSetup.SetRange("Register No.", Code);
                    TaxCalcSelectionSetup.SetRange("Line Code", "Selection Line Code");
                    if not TaxCalcSelectionSetup.FindFirst() then
                        FieldError("Selection Line Code");
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
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
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
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
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
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(46; Disposed; Boolean)
        {
            Caption = 'Disposed';

            trigger OnValidate()
            begin
                if Disposed <> xRec.Disposed then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
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
        TaxCalcSection.Get("Section Code");
        TaxCalcSection.ValidateChange();

        TaxCalcDimFilter.SetRange("Section Code", "Section Code");
        TaxCalcDimFilter.SetRange("Register No.", Code);
        TaxCalcDimFilter.SetRange(Define, TaxCalcDimFilter.Define::Template);
        TaxCalcDimFilter.SetRange("Line No.", "Line No.");
        TaxCalcDimFilter.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        TaxCalcSection.Get("Section Code");
        TaxCalcSection.ValidateChange();
    end;

    var
        TaxCalcSection: Record "Tax Calc. Section";
        TaxCalcTerm: Record "Tax Calc. Term";
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup";
        TaxCalcLine: Record "Tax Calc. Line";
        "Fields": Record "Field";
        TaxCalcGLEntry: Record "Tax Calc. G/L Entry";
        TaxCalcItemEntry: Record "Tax Calc. Item Entry";
        TaxCalcFAEntry: Record "Tax Calc. FA Entry";
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
        TaxRegNormGroup: Record "Tax Register Norm Group";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1000: Label 'Period must be empty if Expression Type is %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure MakeFieldFilter(TaxCalcTableNo: Integer): Text[1024]
    begin
        case TaxCalcTableNo of
            DATABASE::"Tax Calc. G/L Entry":
                exit(TaxCalcFieldFilter(0));
            DATABASE::"Tax Calc. Item Entry":
                exit(TaxCalcItemFieldFilter(0));
            DATABASE::"Tax Calc. FA Entry":
                exit(TaxCalcFAFieldFilter(0));
        end;
    end;

    local procedure TaxCalcFieldFilter(TypeField: Option SumFields,CalcFields) FilterText: Text[1024]
    begin
        Fields.Reset();
        Fields.SetRange(TableNo, DATABASE::"Tax Calc. G/L Entry");
        Fields.SetFilter(ObsoleteState, '<>%1', Fields.ObsoleteState::Removed);
        if Fields.FindSet() then begin
            repeat
                if TaxCalcGLEntry.SetFieldFilter(Fields."No.", TypeField) then
                    FilterText := StrSubstNo('%1|%2', FilterText, Fields."No.");
            until Fields.Next() = 0;
            FilterText := DelChr(FilterText, '<>', '|');
        end;
    end;

    [Scope('OnPrem')]
    procedure MakeCalcFieldFilter(TaxCalcTableNo: Integer): Text[1024]
    begin
        case TaxCalcTableNo of
            DATABASE::"Tax Calc. G/L Entry":
                exit(TaxCalcFieldFilter(1));
            DATABASE::"Tax Calc. Item Entry":
                exit(TaxCalcItemFieldFilter(1));
            DATABASE::"Tax Calc. FA Entry":
                exit(TaxCalcFAFieldFilter(1));
        end;
    end;

    local procedure TaxCalcItemFieldFilter(TypeField: Option SumFields,CalcFields) FilterText: Text[1024]
    begin
        Fields.Reset();
        Fields.SetRange(TableNo, DATABASE::"Tax Calc. Item Entry");
        if Fields.FindSet() then begin
            repeat
                if TaxCalcItemEntry.SetFieldFilter(Fields."No.", TypeField) then
                    FilterText := StrSubstNo('%1|%2', FilterText, Fields."No.");
            until Fields.Next() = 0;
            FilterText := DelChr(FilterText, '<>', '|');
        end;
    end;

    local procedure TaxCalcFAFieldFilter(TypeField: Option SumFields,CalcFields) FilterText: Text[1024]
    begin
        Fields.Reset();
        Fields.SetRange(TableNo, DATABASE::"Tax Calc. FA Entry");
        if Fields.FindSet() then begin
            repeat
                if TaxCalcFAEntry.SetFieldFilter(Fields."No.", TypeField) then
                    FilterText := StrSubstNo('%1|%2', FilterText, Fields."No.");
            until Fields.Next() = 0;
            FilterText := DelChr(FilterText, '<>', '|');
        end;
    end;

    [Scope('OnPrem')]
    procedure GenerateProfile()
    var
        GenTemplateProfile: Record "Gen. Template Profile";
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcAccumulation: Record "Tax Calc. Accumulation";
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
    begin
        if GenTemplateProfile.Get(DATABASE::"Tax Calc. Line") then
            exit;

        GenTemplateProfile."Template Line Table No." := DATABASE::"Tax Calc. Line";
        GenTemplateProfile."Template Header Table No." := DATABASE::"Tax Calc. Header";
        GenTemplateProfile."Term Header Table No." := DATABASE::"Tax Calc. Term";
        GenTemplateProfile."Term Line Table No." := DATABASE::"Tax Calc. Term Formula";
        GenTemplateProfile."Dim. Filter Table No." := DATABASE::"Tax Calc. Dim. Filter";

        GenTemplateProfile."Section Code (Hdr)" := TaxCalcHeader.FieldNo("Section Code");
        GenTemplateProfile."Code (Hdr)" := TaxCalcHeader.FieldNo("No.");
        GenTemplateProfile."Check (Hdr)" := TaxCalcHeader.FieldNo(Check);
        GenTemplateProfile."Level (Hdr)" := TaxCalcHeader.FieldNo(Level);
        GenTemplateProfile."Storing Method (Hdr)" := TaxCalcHeader.FieldNo("Storing Method");

        GenTemplateProfile."Section Code" := FieldNo("Section Code");
        GenTemplateProfile.Code := FieldNo(Code);
        GenTemplateProfile."Line No." := FieldNo("Line No.");
        GenTemplateProfile."Expression Type" := FieldNo("Expression Type");
        GenTemplateProfile.Expression := FieldNo(Expression);
        GenTemplateProfile."Line Code (Line)" := FieldNo("Line Code");
        GenTemplateProfile."Norm Jurisd. Code (Line)" := FieldNo("Norm Jurisdiction Code");
        GenTemplateProfile."Link Code" := FieldNo("Link Register No.");
        GenTemplateProfile."Date Filter" := FieldNo("Date Filter");
        GenTemplateProfile.Period := FieldNo(Period);
        GenTemplateProfile.Description := FieldNo(Description);
        GenTemplateProfile."Rounding Precision" := FieldNo("Rounding Precision");

        GenTemplateProfile."Header Code (Link)" := TaxCalcAccumulation.FieldNo("Register No.");
        GenTemplateProfile."Line Code (Link)" := TaxCalcAccumulation.FieldNo("Template Line Code");
        GenTemplateProfile."Value (Link)" := TaxCalcAccumulation.FieldNo(Amount);

        GenTemplateProfile."Section Code (Dim)" := TaxCalcDimFilter.FieldNo("Section Code");
        GenTemplateProfile."Tax Register No. (Dim)" := TaxCalcDimFilter.FieldNo("Register No.");
        GenTemplateProfile."Define (Dim)" := TaxCalcDimFilter.FieldNo(Define);
        GenTemplateProfile."Line No. (Dim)" := TaxCalcDimFilter.FieldNo("Line No.");
        GenTemplateProfile."Dimension Code (Dim)" := TaxCalcDimFilter.FieldNo("Dimension Code");
        GenTemplateProfile."Dimension Value Filter (Dim)" := TaxCalcDimFilter.FieldNo("Dimension Value Filter");

        GenTemplateProfile.Insert();
    end;

    [Scope('OnPrem')]
    procedure GetDefaultSumField()
    begin
        if "Expression Type" = "Expression Type"::SumField then
            if TaxCalcHeader.Get("Section Code", Code) then begin
                Fields.Reset();
                Fields.SetFilter("No.", MakeFieldFilter(TaxCalcHeader."Table ID"));
                if Fields.FindFirst() then
                    if Fields.Next() = 0 then begin
                        "Sum Field No." := Fields."No.";
                        "Field Name" := Fields."Field Caption";
                    end;
            end;
    end;

    [Scope('OnPrem')]
    procedure GetGLCorrDimFilter(DimCode: Code[20]; FilterGroup: Option Debit,Credit) DimFilter: Text[250]
    var
        TaxDiffGLCorrDimFilter: Record "Tax Diff. Corr. Dim. Filter";
    begin
        if TaxDiffGLCorrDimFilter.Get("Section Code", Code, 0, "Line No.", FilterGroup, DimCode) then
            DimFilter := TaxDiffGLCorrDimFilter."Dimension Value Filter";
    end;
}

