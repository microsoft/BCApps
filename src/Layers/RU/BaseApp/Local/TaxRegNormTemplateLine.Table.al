#pragma warning disable AA0247
table 17239 "Tax Reg. Norm Template Line"
{
    Caption = 'Tax Reg. Norm Template Line';
    LookupPageID = "Tax Reg. Norm Template Lines";
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
            TableRelation = "Tax Register Norm Group".Code;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = ' ,Norm Value,Amount for Norm';
            OptionMembers = " ","Norm Value","Amount for Norm";

            trigger OnValidate()
            begin
                ValidateChange("Line Type" <> xRec."Line Type");
                if "Line Type" <> "Line Type"::" " then begin
                    TaxRegNormTemplateLine.Reset();
                    TaxRegNormTemplateLine.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
                    TaxRegNormTemplateLine.SetRange("Norm Group Code", "Norm Group Code");
                    TaxRegNormTemplateLine.SetFilter("Line No.", '<>%1', "Line No.");
                    TaxRegNormTemplateLine.SetRange("Line Type", "Line Type");
                    TaxRegNormTemplateLine.ModifyAll("Line Type", "Line Type"::" ");
                end;
                if "Line Type" = "Line Type"::"Amount for Norm" then
                    TestField("Line Code");
            end;
        }
        field(5; Description; Text[150])
        {
            Caption = 'Description';
        }
        field(6; "Line Code"; Code[10])
        {
            Caption = 'Line Code';

            trigger OnValidate()
            begin
                ValidateChange(("Line Code" <> xRec."Line Code") and (xRec."Line Code" <> ''));
                TaxRegTermMgt.ValidateLineCode("Line Code", 0);
                if "Line Code" = '' then
                    if "Line Type" = "Line Type"::"Amount for Norm" then
                        FieldError("Line Code",
                          StrSubstNo(Text2001, FieldCaption("Line Code"), FieldCaption("Line Type"), "Line Type"));
            end;
        }
        field(7; "Expression Type"; Option)
        {
            Caption = 'Expression Type';
            OptionCaption = 'Term,Link,Total,Header,,Norm';
            OptionMembers = Term,Link,Total,Header,,Norm;

            trigger OnValidate()
            begin
                if "Expression Type" <> xRec."Expression Type" then begin
                    if "Expression Type" = "Expression Type"::Norm then
                        "Jurisdiction Code" := "Norm Jurisdiction Code"
                    else
                        "Jurisdiction Code" := '';
                    ValidateChange(true);
                    Expression := '';
                    "Link Group Code" := '';
                    "Link Line Code" := '';
                end;
            end;
        }
        field(8; Expression; Text[150])
        {
            Caption = 'Expression';

            trigger OnLookup()
            var
                TaxRegNormTermName: Record "Tax Reg. Norm Term";
            begin
                if "Expression Type" = "Expression Type"::Norm then begin
                    TestField("Jurisdiction Code");
                    TaxRegNormGroup.Reset();
                    TaxRegNormGroup.FilterGroup(2);
                    TaxRegNormGroup.SetRange("Norm Jurisdiction Code", "Jurisdiction Code");
                    TaxRegNormGroup.FilterGroup(0);
                    if Expression <> '' then
                        if TaxRegNormGroup.Get("Jurisdiction Code", Expression) then;
                    if ACTION::LookupOK = PAGE.RunModal(0, TaxRegNormGroup) then begin
                        TaxRegNormGroup.CalcFields("Has Details");
                        TaxRegNormGroup.TestField("Has Details");
                        Expression := TaxRegNormGroup.Code;
                        if Description = '' then
                            Description := TaxRegNormGroup.Description;
                    end;
                end;
                if "Expression Type" = "Expression Type"::Term then begin
                    TaxRegNormTermName.Reset();
                    TaxRegNormTermName.FilterGroup(2);
                    TaxRegNormTermName.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
                    TaxRegNormTermName.FilterGroup(0);
                    if Expression <> '' then
                        if TaxRegNormTermName.Get("Norm Jurisdiction Code", Expression) then;
                    if ACTION::LookupOK = PAGE.RunModal(0, TaxRegNormTermName) then begin
                        Expression := TaxRegNormTermName."Term Code";
                        Description := TaxRegNormTermName.Description;
                    end;
                end;
                if "Expression Type" = "Expression Type"::Link then begin
                    TestField("Link Group Code");
                    TaxRegNormGroup.Get("Norm Jurisdiction Code", "Link Group Code");
                    TaxRegNormTemplateLine.FilterGroup(2);
                    TaxRegNormTemplateLine.SetRange("Norm Jurisdiction Code", TaxRegNormGroup."Norm Jurisdiction Code");
                    TaxRegNormTemplateLine.SetRange("Norm Group Code", TaxRegNormGroup.Code);
                    TaxRegNormTemplateLine.FilterGroup(0);
                    if Expression <> '' then
                        if TaxRegNormTemplateLine.Get("Norm Jurisdiction Code", Expression) then;
                    if ACTION::LookupOK = PAGE.RunModal(0, TaxRegNormTemplateLine) then begin
                        TaxRegNormTemplateLine.TestField("Line Code");
                        Expression := TaxRegNormTemplateLine."Line Code";
                        Description := TaxRegNormTemplateLine.Description;
                    end;
                end;
            end;

            trigger OnValidate()
            begin
                ValidateChange(Expression <> xRec.Expression);
            end;
        }
        field(9; "Jurisdiction Code"; Code[10])
        {
            Caption = 'Jurisdiction Code';
            TableRelation = "Tax Register Norm Jurisdiction";
        }
        field(10; "Link Group Code"; Code[10])
        {
            Caption = 'Link Group Code';
            TableRelation = if ("Expression Type" = const(Link)) "Tax Register Norm Group".Code;

            trigger OnValidate()
            begin
                ValidateChange("Link Group Code" <> xRec."Link Group Code");
            end;
        }
        field(11; "Link Line Code"; Code[10])
        {
            Caption = 'Link Line Code';

            trigger OnValidate()
            begin
                ValidateChange("Link Line Code" <> xRec."Link Line Code");
            end;
        }
        field(12; "Dimensions Filters"; Boolean)
        {
            CalcFormula = exist("Tax Reg. Norm Dim. Filter" where("Norm Jurisdiction Code" = field("Norm Jurisdiction Code"),
                                                                   "Norm Group Code" = field("Norm Group Code"),
                                                                   "Line No." = field("Line No.")));
            Caption = 'Dimensions Filters';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(14; Period; Code[30])
        {
            Caption = 'Period';

            trigger OnValidate()
            begin
                if "Expression Type" <> "Expression Type"::Term then
                    if Period <> '' then
                        Error(Text2001, FieldCaption(Period), FieldCaption("Expression Type"), "Expression Type");
                ValidateChange(Period <> xRec.Period);
            end;
        }
        field(15; "Rounding Precision"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Rounding Precision';
            DecimalPlaces = 0 :;

            trigger OnValidate()
            begin
                ValidateChange("Rounding Precision" <> xRec."Rounding Precision");
            end;
        }
        field(16; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(17; Bold; Boolean)
        {
            Caption = 'Bold';
        }
    }

    keys
    {
        key(Key1; "Norm Jurisdiction Code", "Norm Group Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        TaxRegNormDimFilter: Record "Tax Reg. Norm Dim. Filter";
    begin
        ValidateChange(true);

        TaxRegNormDimFilter.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
        TaxRegNormDimFilter.SetRange("Norm Group Code", "Norm Group Code");
        TaxRegNormDimFilter.SetRange("Line No.", "Line No.");
        TaxRegNormDimFilter.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        ValidateChange(true);
    end;

    var
        TaxRegNormGroup: Record "Tax Register Norm Group";
        TaxRegNormTemplateLine: Record "Tax Reg. Norm Template Line";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text2001: Label '%1 must be empty if %2 is %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure ValidateChange(Incident: Boolean)
    var
        TaxRegNormJurisdiction: Record "Tax Register Norm Jurisdiction";
    begin
        if not Incident then
            exit;

        TaxRegNormJurisdiction.Get("Norm Jurisdiction Code");
    end;

    [Scope('OnPrem')]
    procedure GenerateProfile()
    var
        GenTemplateProfile: Record "Gen. Template Profile";
        TaxRegNormAccumulation: Record "Tax Reg. Norm Accumulation";
        TaxRegNormDimFilter: Record "Tax Reg. Norm Dim. Filter";
    begin
        if GenTemplateProfile.Get(DATABASE::"Tax Reg. Norm Template Line") then
            exit;

        GenTemplateProfile."Template Line Table No." := DATABASE::"Tax Reg. Norm Template Line";
        GenTemplateProfile."Template Header Table No." := DATABASE::"Tax Register Norm Group";
        GenTemplateProfile."Term Header Table No." := DATABASE::"Tax Reg. Norm Term";
        GenTemplateProfile."Term Line Table No." := DATABASE::"Tax Reg. Norm Term Formula";
        GenTemplateProfile."Dim. Filter Table No." := DATABASE::"Tax Reg. Norm Dim. Filter";

        GenTemplateProfile."Section Code (Hdr)" := TaxRegNormGroup.FieldNo("Norm Jurisdiction Code");
        GenTemplateProfile."Code (Hdr)" := TaxRegNormGroup.FieldNo(Code);
        GenTemplateProfile."Check (Hdr)" := TaxRegNormGroup.FieldNo(Check);
        GenTemplateProfile."Level (Hdr)" := TaxRegNormGroup.FieldNo(Level);

        GenTemplateProfile."Section Code" := FieldNo("Norm Jurisdiction Code");
        GenTemplateProfile.Code := FieldNo("Norm Group Code");
        GenTemplateProfile."Line No." := FieldNo("Line No.");
        GenTemplateProfile."Expression Type" := FieldNo("Expression Type");
        GenTemplateProfile.Expression := FieldNo(Expression);
        GenTemplateProfile."Line Code (Line)" := FieldNo("Line Code");
        GenTemplateProfile."Norm Jurisd. Code (Line)" := FieldNo("Jurisdiction Code");
        GenTemplateProfile."Link Code" := FieldNo("Link Group Code");
        GenTemplateProfile."Date Filter" := FieldNo("Date Filter");
        GenTemplateProfile.Period := FieldNo(Period);
        GenTemplateProfile.Description := FieldNo(Description);
        GenTemplateProfile."Rounding Precision" := FieldNo("Rounding Precision");

        GenTemplateProfile."Header Code (Link)" := TaxRegNormAccumulation.FieldNo("Norm Group Code");
        GenTemplateProfile."Line Code (Link)" := TaxRegNormAccumulation.FieldNo("Template Line Code");
        GenTemplateProfile."Value (Link)" := TaxRegNormAccumulation.FieldNo(Amount);

        GenTemplateProfile."Section Code (Dim)" := TaxRegNormDimFilter.FieldNo("Norm Jurisdiction Code");
        GenTemplateProfile."Tax Register No. (Dim)" := TaxRegNormDimFilter.FieldNo("Norm Group Code");
        GenTemplateProfile."Line No. (Dim)" := TaxRegNormDimFilter.FieldNo("Line No.");
        GenTemplateProfile."Dimension Code (Dim)" := TaxRegNormDimFilter.FieldNo("Dimension Code");
        GenTemplateProfile."Dimension Value Filter (Dim)" := TaxRegNormDimFilter.FieldNo("Dimension Value Filter");

        GenTemplateProfile.Insert();
    end;
}

