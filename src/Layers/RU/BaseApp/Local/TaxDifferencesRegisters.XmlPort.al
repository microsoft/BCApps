#pragma warning disable AA0247
xmlport 17300 "Tax Differences Registers"
{
    Caption = 'Tax Differences Registers';

    schema
    {
        textelement(TaxDifferencesRegisters)
        {
            tableelement("Tax Calc. Section"; "Tax Calc. Section")
            {
                XmlName = 'TaxCalcSection';
                UseTemporary = true;
                fieldelement(Code; "Tax Calc. Section".Code)
                {
                }
                fieldelement(Description; "Tax Calc. Section".Description)
                {
                }
                fieldelement(FormID; "Tax Calc. Section"."Page ID")
                {
                }
                fieldelement(Type; "Tax Calc. Section".Type)
                {
                }
                fieldelement(NormJurisdictionCode; "Tax Calc. Section"."Norm Jurisdiction Code")
                {
                }
                fieldelement(Dimension1Code; "Tax Calc. Section"."Dimension 1 Code")
                {
                }
                fieldelement(Dimension2Code; "Tax Calc. Section"."Dimension 2 Code")
                {
                }
                fieldelement(Dimension3Code; "Tax Calc. Section"."Dimension 3 Code")
                {
                }
                fieldelement(Dimension4Code; "Tax Calc. Section"."Dimension 4 Code")
                {
                }
                fieldelement(StartingDate; "Tax Calc. Section"."Starting Date")
                {
                }
                fieldelement(EndingDate; "Tax Calc. Section"."Ending Date")
                {
                }
                tableelement("Tax Calc. Header"; "Tax Calc. Header")
                {
                    LinkFields = "Section Code" = field(Code);
                    LinkTable = "Tax Calc. Section";
                    MinOccurs = Zero;
                    XmlName = 'TaxCalcHeader';
                    UseTemporary = true;
                    fieldelement(SectionCode; "Tax Calc. Header"."Section Code")
                    {
                    }
                    fieldelement(No; "Tax Calc. Header"."No.")
                    {
                    }
                    fieldelement(Description; "Tax Calc. Header".Description)
                    {
                    }
                    fieldelement(TableID; "Tax Calc. Header"."Table ID")
                    {
                    }
                    fieldelement(FormID; "Tax Calc. Header"."Page ID")
                    {
                    }
                    fieldelement(Check; "Tax Calc. Header".Check)
                    {
                    }
                    fieldelement(Level; "Tax Calc. Header".Level)
                    {
                    }
                    fieldelement(RegisterID; "Tax Calc. Header"."Register ID")
                    {
                    }
                    fieldelement(StoringMethod; "Tax Calc. Header"."Storing Method")
                    {
                    }
                    fieldelement(TaxDiffCode; "Tax Calc. Header"."Tax Diff. Code")
                    {
                    }
                    fieldelement(GLCorrAnalysisViewCode; "Tax Calc. Header"."G/L Corr. Analysis View Code")
                    {
                    }
                    tableelement("Tax Calc. Selection Setup"; "Tax Calc. Selection Setup")
                    {
                        LinkFields = "Section Code" = field("Section Code"), "Register No." = field("No.");
                        LinkTable = "Tax Calc. Header";
                        MinOccurs = Zero;
                        XmlName = 'TaxCalcSelectionSetup';
                        UseTemporary = true;
                        fieldelement(SectionCode; "Tax Calc. Selection Setup"."Section Code")
                        {
                        }
                        fieldelement(RegisterNo; "Tax Calc. Selection Setup"."Register No.")
                        {
                        }
                        fieldelement(LineNo; "Tax Calc. Selection Setup"."Line No.")
                        {
                        }
                        fieldelement(AccountNo; "Tax Calc. Selection Setup"."Account No.")
                        {
                        }
                        fieldelement(BalAccountNo; "Tax Calc. Selection Setup"."Bal. Account No.")
                        {
                        }
                        fieldelement(RegisterType; "Tax Calc. Selection Setup"."Register Type")
                        {
                        }
                        fieldelement(LineCode; "Tax Calc. Selection Setup"."Line Code")
                        {
                        }
                    }
                    tableelement("Tax Calc. Line"; "Tax Calc. Line")
                    {
                        LinkFields = "Section Code" = field("Section Code"), Code = field("No.");
                        LinkTable = "Tax Calc. Header";
                        MinOccurs = Zero;
                        XmlName = 'TaxCalcLine';
                        UseTemporary = true;
                        fieldelement(SectionCode; "Tax Calc. Line"."Section Code")
                        {
                        }
                        fieldelement(Code; "Tax Calc. Line".Code)
                        {
                        }
                        fieldelement(LineNo; "Tax Calc. Line"."Line No.")
                        {
                        }
                        fieldelement(ExpressionType; "Tax Calc. Line"."Expression Type")
                        {
                        }
                        fieldelement(Expression; "Tax Calc. Line".Expression)
                        {
                        }
                        fieldelement(LineCode; "Tax Calc. Line"."Line Code")
                        {
                        }
                        fieldelement(Description; "Tax Calc. Line".Description)
                        {
                        }
                        fieldelement(Value; "Tax Calc. Line".Value)
                        {
                        }
                        fieldelement(LinkRegisterNo; "Tax Calc. Line"."Link Register No.")
                        {
                        }
                        fieldelement(SumFieldNo; "Tax Calc. Line"."Sum Field No.")
                        {
                        }
                        fieldelement(RoundingPrecision; "Tax Calc. Line"."Rounding Precision")
                        {
                        }
                        fieldelement(NormJurisdictionCode; "Tax Calc. Line"."Norm Jurisdiction Code")
                        {
                        }
                        fieldelement(LineType; "Tax Calc. Line"."Line Type")
                        {
                        }
                        fieldelement(TaxDiffAmountBase; "Tax Calc. Line"."Tax Diff. Amount (Base)")
                        {
                        }
                        fieldelement(TaxDiffAmountTax; "Tax Calc. Line"."Tax Diff. Amount (Tax)")
                        {
                        }
                        fieldelement(Indentation; "Tax Calc. Line".Indentation)
                        {
                        }
                        fieldelement(Bold; "Tax Calc. Line".Bold)
                        {
                        }
                        fieldelement(Period; "Tax Calc. Line".Period)
                        {
                        }
                        fieldelement(SelectionLineCode; "Tax Calc. Line"."Selection Line Code")
                        {
                        }
                        fieldelement(DepreciationGroup; "Tax Calc. Line"."Depreciation Group")
                        {
                        }
                        fieldelement(BelongingToManufacturing; "Tax Calc. Line"."Belonging to Manufacturing")
                        {
                        }
                        fieldelement(FAType; "Tax Calc. Line"."FA Type")
                        {
                        }
                        fieldelement(Disposed; "Tax Calc. Line".Disposed)
                        {
                        }
                    }
                    tableelement("Tax Calc. Dim. Filter"; "Tax Calc. Dim. Filter")
                    {
                        LinkFields = "Section Code" = field("Section Code"), "Register No." = field("No.");
                        LinkTable = "Tax Calc. Header";
                        MinOccurs = Zero;
                        XmlName = 'TaxCalcDimFilter';
                        UseTemporary = true;
                        fieldelement(SectionCode; "Tax Calc. Dim. Filter"."Section Code")
                        {
                        }
                        fieldelement(RegisterNo; "Tax Calc. Dim. Filter"."Register No.")
                        {
                        }
                        fieldelement(Define; "Tax Calc. Dim. Filter".Define)
                        {
                        }
                        fieldelement(LineNo; "Tax Calc. Dim. Filter"."Line No.")
                        {
                        }
                        fieldelement(DimensionCode; "Tax Calc. Dim. Filter"."Dimension Code")
                        {
                        }
                        fieldelement(DimensionValueFilter; "Tax Calc. Dim. Filter"."Dimension Value Filter")
                        {
                        }
                        fieldelement(EntryNo; "Tax Calc. Dim. Filter"."Entry No.")
                        {
                        }
                        fieldelement(IfNoValue; "Tax Calc. Dim. Filter"."If No Value")
                        {
                        }
                    }
                }
                tableelement("Tax Calc. Term"; "Tax Calc. Term")
                {
                    LinkFields = "Section Code" = field(Code);
                    LinkTable = "Tax Calc. Section";
                    MinOccurs = Zero;
                    XmlName = 'TaxCalcTermName';
                    UseTemporary = true;
                    fieldelement(SectionCode; "Tax Calc. Term"."Section Code")
                    {
                    }
                    fieldelement(TermCode; "Tax Calc. Term"."Term Code")
                    {
                    }
                    fieldelement(ExpressionType; "Tax Calc. Term"."Expression Type")
                    {
                    }
                    fieldelement(Expression; "Tax Calc. Term".Expression)
                    {
                    }
                    fieldelement(Check; "Tax Calc. Term".Check)
                    {
                    }
                    fieldelement(ProcessSign; "Tax Calc. Term"."Process Sign")
                    {
                    }
                    fieldelement(Description; "Tax Calc. Term".Description)
                    {
                    }
                    fieldelement(RoundingPrecision; "Tax Calc. Term"."Rounding Precision")
                    {
                    }
                    tableelement("Tax Calc. Term Formula"; "Tax Calc. Term Formula")
                    {
                        LinkFields = "Section Code" = field("Section Code"), "Term Code" = field("Term Code");
                        LinkTable = "Tax Calc. Term";
                        MinOccurs = Zero;
                        XmlName = 'TaxCalcTermLine';
                        UseTemporary = true;
                        fieldelement(SectionCode; "Tax Calc. Term Formula"."Section Code")
                        {
                        }
                        fieldelement(TermCode; "Tax Calc. Term Formula"."Term Code")
                        {
                        }
                        fieldelement(LineNo; "Tax Calc. Term Formula"."Line No.")
                        {
                        }
                        fieldelement(ExpressionType; "Tax Calc. Term Formula"."Expression Type")
                        {
                        }
                        fieldelement(Operation; "Tax Calc. Term Formula".Operation)
                        {
                        }
                        fieldelement(AccountType; "Tax Calc. Term Formula"."Account Type")
                        {
                        }
                        fieldelement(AccountNo; "Tax Calc. Term Formula"."Account No.")
                        {
                        }
                        fieldelement(AmountType; "Tax Calc. Term Formula"."Amount Type")
                        {
                        }
                        fieldelement(BalAccountNo; "Tax Calc. Term Formula"."Bal. Account No.")
                        {
                        }
                        fieldelement(ProcessSign; "Tax Calc. Term Formula"."Process Sign")
                        {
                        }
                        fieldelement(ProcessDivisionByZero; "Tax Calc. Term Formula"."Process Division by Zero")
                        {
                        }
                        fieldelement(NormJurisdictionCode; "Tax Calc. Term Formula"."Norm Jurisdiction Code")
                        {
                        }
                    }
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    var
        TaxCalcSection: Record "Tax Calc. Section";
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcTerm: Record "Tax Calc. Term";
        TaxCalcTermFormula: Record "Tax Calc. Term Formula";
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";

    [Scope('OnPrem')]
    procedure SetData(var TempTaxCalcSection: Record "Tax Calc. Section")
    begin
        if TempTaxCalcSection.FindSet() then
            repeat
                "Tax Calc. Section" := TempTaxCalcSection;
                "Tax Calc. Section".Insert();

                TaxCalcHeader.SetRange("Section Code", TempTaxCalcSection.Code);
                if TaxCalcHeader.FindSet() then
                    repeat
                        "Tax Calc. Header" := TaxCalcHeader;
                        "Tax Calc. Header".Insert();

                        TaxCalcSelectionSetup.SetRange("Section Code", TaxCalcHeader."Section Code");
                        TaxCalcSelectionSetup.SetRange("Register No.", TaxCalcHeader."No.");
                        if TaxCalcSelectionSetup.FindSet() then
                            repeat
                                "Tax Calc. Selection Setup" := TaxCalcSelectionSetup;
                                "Tax Calc. Selection Setup".Insert();
                            until TaxCalcSelectionSetup.Next() = 0;

                        TaxCalcLine.SetRange("Section Code", TaxCalcHeader."Section Code");
                        TaxCalcLine.SetRange(Code, TaxCalcHeader."No.");
                        if TaxCalcLine.FindSet() then
                            repeat
                                "Tax Calc. Line" := TaxCalcLine;
                                "Tax Calc. Line".Insert();
                            until TaxCalcLine.Next() = 0;

                        TaxCalcDimFilter.SetRange("Section Code", TaxCalcHeader."Section Code");
                        TaxCalcDimFilter.SetRange("Register No.", TaxCalcHeader."No.");
                        if TaxCalcDimFilter.FindSet() then
                            repeat
                                "Tax Calc. Dim. Filter" := TaxCalcDimFilter;
                                "Tax Calc. Dim. Filter".Insert();
                            until TaxCalcDimFilter.Next() = 0;
                    until TaxCalcHeader.Next() = 0;

                TaxCalcTerm.SetRange("Section Code", TempTaxCalcSection.Code);
                if TaxCalcTerm.FindSet() then
                    repeat
                        "Tax Calc. Term" := TaxCalcTerm;
                        "Tax Calc. Term".Insert();

                        TaxCalcTermFormula.SetRange("Section Code", TaxCalcTerm."Section Code");
                        TaxCalcTermFormula.SetRange("Term Code", TaxCalcTerm."Term Code");
                        if TaxCalcTermFormula.FindSet() then
                            repeat
                                "Tax Calc. Term Formula" := TaxCalcTermFormula;
                                "Tax Calc. Term Formula".Insert();
                            until TaxCalcTermFormula.Next() = 0;
                    until TaxCalcTerm.Next() = 0;
            until TempTaxCalcSection.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportData()
    begin
        "Tax Calc. Section".Reset();
        if "Tax Calc. Section".FindSet() then
            repeat
                TaxCalcSection := "Tax Calc. Section";
                if TaxCalcSection.Find() then begin
                    TaxCalcSection.Delete(true);
                    TaxCalcSection := "Tax Calc. Section";
                end;
                TaxCalcSection.Insert();
            until "Tax Calc. Section".Next() = 0;

        "Tax Calc. Header".Reset();
        if "Tax Calc. Header".FindSet() then
            repeat
                TaxCalcHeader := "Tax Calc. Header";
                if TaxCalcHeader.Find() then begin
                    TaxCalcHeader.Delete(true);
                    TaxCalcHeader := "Tax Calc. Header";
                end;
                TaxCalcHeader.Insert();
            until "Tax Calc. Header".Next() = 0;

        "Tax Calc. Selection Setup".Reset();
        if "Tax Calc. Selection Setup".FindSet() then
            repeat
                TaxCalcSelectionSetup := "Tax Calc. Selection Setup";
                if TaxCalcSelectionSetup.Find() then begin
                    TaxCalcSelectionSetup.Delete(true);
                    TaxCalcSelectionSetup := "Tax Calc. Selection Setup";
                end;
                TaxCalcSelectionSetup.Insert();
            until "Tax Calc. Selection Setup".Next() = 0;

        "Tax Calc. Line".Reset();
        if "Tax Calc. Line".FindSet() then
            repeat
                TaxCalcLine := "Tax Calc. Line";
                if TaxCalcLine.Find() then begin
                    TaxCalcLine.Delete(true);
                    TaxCalcLine := "Tax Calc. Line";
                end;
                TaxCalcLine.Insert();
            until "Tax Calc. Line".Next() = 0;

        "Tax Calc. Dim. Filter".Reset();
        if "Tax Calc. Dim. Filter".FindSet() then
            repeat
                TaxCalcDimFilter := "Tax Calc. Dim. Filter";
                if TaxCalcDimFilter.Find() then begin
                    TaxCalcDimFilter.Delete(true);
                    TaxCalcDimFilter := "Tax Calc. Dim. Filter";
                end;
                TaxCalcDimFilter.Insert();
            until "Tax Calc. Dim. Filter".Next() = 0;

        "Tax Calc. Term".Reset();
        if "Tax Calc. Term".FindSet() then
            repeat
                TaxCalcTerm := "Tax Calc. Term";
                if TaxCalcTerm.Find() then begin
                    TaxCalcTerm.Delete(true);
                    TaxCalcTerm := "Tax Calc. Term";
                end;
                TaxCalcTerm.Insert();
            until "Tax Calc. Term".Next() = 0;

        "Tax Calc. Term Formula".Reset();
        if "Tax Calc. Term Formula".FindSet() then
            repeat
                TaxCalcTermFormula := "Tax Calc. Term Formula";
                if TaxCalcTermFormula.Find() then begin
                    TaxCalcTermFormula.Delete(true);
                    TaxCalcTermFormula := "Tax Calc. Term Formula";
                end;
                TaxCalcTermFormula.Insert();
            until "Tax Calc. Term Formula".Next() = 0;
    end;
}

