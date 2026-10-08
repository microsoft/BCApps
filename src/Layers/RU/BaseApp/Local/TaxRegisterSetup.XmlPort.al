#pragma warning disable AA0247
xmlport 17200 "Tax Register Setup"
{
    Caption = 'Tax Register Setup';

    schema
    {
        textelement(TaxRegisterSetup)
        {
            tableelement("Tax Register Section"; "Tax Register Section")
            {
                XmlName = 'TaxRegisterSection';
                UseTemporary = true;
                fieldelement(Code; "Tax Register Section".Code)
                {
                }
                fieldelement(Description; "Tax Register Section".Description)
                {
                }
                fieldelement(FormID; "Tax Register Section"."Page ID")
                {
                }
                fieldelement(Type; "Tax Register Section".Type)
                {
                }
                fieldelement(NormJurisdictionCode; "Tax Register Section"."Norm Jurisdiction Code")
                {
                }
                fieldelement(Dimension1Code; "Tax Register Section"."Dimension 1 Code")
                {
                }
                fieldelement(Dimension2Code; "Tax Register Section"."Dimension 2 Code")
                {
                }
                fieldelement(Dimension3Code; "Tax Register Section"."Dimension 3 Code")
                {
                }
                fieldelement(Dimension4Code; "Tax Register Section"."Dimension 4 Code")
                {
                }
                fieldelement(FormName; "Tax Register Section"."Page Name")
                {
                }
                fieldelement(LastRegisterNo; "Tax Register Section"."Last Register No.")
                {
                }
                fieldelement(LastDateFilter; "Tax Register Section"."Last Date Filter")
                {
                }
                fieldelement(DebitBalancePoint1; "Tax Register Section"."Debit Balance Point 1")
                {
                }
                fieldelement(DebitBalancePoint2; "Tax Register Section"."Debit Balance Point 2")
                {
                }
                fieldelement(DebitBalancePoint3; "Tax Register Section"."Debit Balance Point 3")
                {
                }
                fieldelement(CreditBalancePoint1; "Tax Register Section"."Credit Balance Point 1")
                {
                }
                fieldelement(StartingDate; "Tax Register Section"."Starting Date")
                {
                }
                fieldelement(EndingDate; "Tax Register Section"."Ending Date")
                {
                }
                tableelement("Tax Register"; "Tax Register")
                {
                    LinkFields = "Section Code" = field(Code);
                    LinkTable = "Tax Register Section";
                    MinOccurs = Zero;
                    XmlName = 'TaxRegister';
                    UseTemporary = true;
                    fieldelement(SectionCode; "Tax Register"."Section Code")
                    {
                    }
                    fieldelement(No; "Tax Register"."No.")
                    {
                    }
                    fieldelement(Description; "Tax Register".Description)
                    {
                    }
                    fieldelement(TableID; "Tax Register"."Table ID")
                    {
                    }
                    fieldelement(FormID; "Tax Register"."Page ID")
                    {
                    }
                    fieldelement(Check; "Tax Register".Check)
                    {
                    }
                    fieldelement(Level; "Tax Register".Level)
                    {
                    }
                    fieldelement(RegisterID; "Tax Register"."Register ID")
                    {
                    }
                    fieldelement(StoringMethod; "Tax Register"."Storing Method")
                    {
                    }
                    fieldelement(CostingMethod; "Tax Register"."Costing Method")
                    {
                    }
                    fieldelement(GLCorrAnalysisViewCode; "Tax Register"."G/L Corr. Analysis View Code")
                    {
                    }
                    tableelement("Tax Register Line Setup"; "Tax Register Line Setup")
                    {
                        LinkFields = "Section Code" = field("Section Code"), "Tax Register No." = field("No.");
                        LinkTable = "Tax Register";
                        MinOccurs = Zero;
                        XmlName = 'TaxRegisterLineSetup';
                        UseTemporary = true;
                        fieldelement(SectionCode; "Tax Register Line Setup"."Section Code")
                        {
                        }
                        fieldelement(TaxRegisterNo; "Tax Register Line Setup"."Tax Register No.")
                        {
                        }
                        fieldelement(LineNo; "Tax Register Line Setup"."Line No.")
                        {
                        }
                        fieldelement(AccountType; "Tax Register Line Setup"."Account Type")
                        {
                        }
                        fieldelement(AccountNo; "Tax Register Line Setup"."Account No.")
                        {
                        }
                        fieldelement(AmountType; "Tax Register Line Setup"."Amount Type")
                        {
                        }
                        fieldelement(BalAccountNo; "Tax Register Line Setup"."Bal. Account No.")
                        {
                        }
                        fieldelement(CheckExistEntry; "Tax Register Line Setup"."Check Exist Entry")
                        {
                        }
                        fieldelement(LineCode; "Tax Register Line Setup"."Line Code")
                        {
                        }
                        fieldelement(EmployeeStatisticsGroupCode; "Tax Register Line Setup"."Employee Statistics Group Code")
                        {
                        }
                        fieldelement(EmployeeCategoryCode; "Tax Register Line Setup"."Employee Category Code")
                        {
                        }
                        fieldelement(PayrollPostingGroup; "Tax Register Line Setup"."Payroll Posting Group")
                        {
                        }
                    }
                    tableelement("Tax Register Template"; "Tax Register Template")
                    {
                        LinkFields = "Section Code" = field("Section Code"), Code = field("No.");
                        LinkTable = "Tax Register";
                        MinOccurs = Zero;
                        XmlName = 'TaxRegisterTemplate';
                        UseTemporary = true;
                        fieldelement(SectionCode; "Tax Register Template"."Section Code")
                        {
                        }
                        fieldelement(Code; "Tax Register Template".Code)
                        {
                        }
                        fieldelement(LineNo; "Tax Register Template"."Line No.")
                        {
                        }
                        fieldelement(ExpressionType; "Tax Register Template"."Expression Type")
                        {
                        }
                        fieldelement(Expression; "Tax Register Template".Expression)
                        {
                        }
                        fieldelement(LineCode; "Tax Register Template"."Line Code")
                        {
                        }
                        fieldelement(Description; "Tax Register Template".Description)
                        {
                        }
                        fieldelement(Value; "Tax Register Template".Value)
                        {
                        }
                        fieldelement(LinkTaxRegisterNo; "Tax Register Template"."Link Tax Register No.")
                        {
                        }
                        fieldelement(SumFieldNo; "Tax Register Template"."Sum Field No.")
                        {
                        }
                        fieldelement(LinkLineCode; "Tax Register Template"."Link Line Code")
                        {
                        }
                        fieldelement(RoundingPrecision; "Tax Register Template"."Rounding Precision")
                        {
                        }
                        fieldelement(NormJurisdictionCode; "Tax Register Template"."Norm Jurisdiction Code")
                        {
                        }
                        fieldelement(ReportLineCode; "Tax Register Template"."Report Line Code")
                        {
                        }
                        fieldelement(Indentation; "Tax Register Template".Indentation)
                        {
                        }
                        fieldelement(Bold; "Tax Register Template".Bold)
                        {
                        }
                        fieldelement(Period; "Tax Register Template".Period)
                        {
                        }
                        fieldelement(TermLineCode; "Tax Register Template"."Term Line Code")
                        {
                        }
                        fieldelement(DepreciationGroup; "Tax Register Template"."Depreciation Group")
                        {
                        }
                        fieldelement(BelongingToManufacturing; "Tax Register Template"."Belonging to Manufacturing")
                        {
                        }
                        fieldelement(FAType; "Tax Register Template"."FA Type")
                        {
                        }
                        fieldelement(DeprBonusPercentFilter; "Tax Register Template"."Depr. Bonus % Filter")
                        {
                        }
                        fieldelement(TaxDifferenceCodeFilter; "Tax Register Template"."Tax Difference Code Filter")
                        {
                        }
                        fieldelement(DeprBookFilter; "Tax Register Template"."Depr. Book Filter")
                        {
                        }
                        fieldelement(ResultOnDisposal; "Tax Register Template"."Result on Disposal")
                        {
                        }
                    }
                    tableelement("Tax Register Dim. Comb."; "Tax Register Dim. Comb.")
                    {
                        LinkFields = "Section Code" = field("Section Code"), "Tax Register No." = field("No.");
                        LinkTable = "Tax Register";
                        MinOccurs = Zero;
                        XmlName = 'TaxRegisterDimComb';
                        UseTemporary = true;
                        fieldelement(SectionCode; "Tax Register Dim. Comb."."Section Code")
                        {
                        }
                        fieldelement(TaxRegisterNo; "Tax Register Dim. Comb."."Tax Register No.")
                        {
                        }
                        fieldelement(LineNo; "Tax Register Dim. Comb."."Line No.")
                        {
                        }
                        fieldelement(Dimension1Code; "Tax Register Dim. Comb."."Dimension 1 Code")
                        {
                        }
                        fieldelement(Dimension2Code; "Tax Register Dim. Comb."."Dimension 2 Code")
                        {
                        }
                        fieldelement(CombinationRestriction; "Tax Register Dim. Comb."."Combination Restriction")
                        {
                        }
                        fieldelement(EntryNo; "Tax Register Dim. Comb."."Entry No.")
                        {
                        }
                    }
                    tableelement("Tax Register Dim. Value Comb."; "Tax Register Dim. Value Comb.")
                    {
                        LinkFields = "Section Code" = field("Section Code"), "Tax Register No." = field("No.");
                        LinkTable = "Tax Register";
                        MinOccurs = Zero;
                        XmlName = 'TaxRegisterDimValueComb';
                        UseTemporary = true;
                        fieldelement(SectionCode; "Tax Register Dim. Value Comb."."Section Code")
                        {
                        }
                        fieldelement(TaxRegisterNo; "Tax Register Dim. Value Comb."."Tax Register No.")
                        {
                        }
                        fieldelement(LineNo; "Tax Register Dim. Value Comb."."Line No.")
                        {
                        }
                        fieldelement(Dimension1Code; "Tax Register Dim. Value Comb."."Dimension 1 Code")
                        {
                        }
                        fieldelement(Dimension1ValueCode; "Tax Register Dim. Value Comb."."Dimension 1 Value Code")
                        {
                        }
                        fieldelement(Dimension2Code; "Tax Register Dim. Value Comb."."Dimension 2 Code")
                        {
                        }
                        fieldelement(Dimension2ValueCode; "Tax Register Dim. Value Comb."."Dimension 2 Value Code")
                        {
                        }
                        fieldelement(TypeLimit; "Tax Register Dim. Value Comb."."Type Limit")
                        {
                        }
                    }
                    tableelement("Tax Register Dim. Def. Value"; "Tax Register Dim. Def. Value")
                    {
                        LinkFields = "Section Code" = field("Section Code"), "Tax Register No." = field("No.");
                        LinkTable = "Tax Register";
                        MinOccurs = Zero;
                        XmlName = 'TaxRegisterDimDefValue';
                        UseTemporary = true;
                        fieldelement(SectionCode; "Tax Register Dim. Def. Value"."Section Code")
                        {
                        }
                        fieldelement(TaxRegisterNo; "Tax Register Dim. Def. Value"."Tax Register No.")
                        {
                        }
                        fieldelement(LineNo; "Tax Register Dim. Def. Value"."Line No.")
                        {
                        }
                        fieldelement(Dimension1Code; "Tax Register Dim. Def. Value"."Dimension 1 Code")
                        {
                        }
                        fieldelement(Dimension1ValueCode; "Tax Register Dim. Def. Value"."Dimension 1 Value Code")
                        {
                        }
                        fieldelement(Dimension2Code; "Tax Register Dim. Def. Value"."Dimension 2 Code")
                        {
                        }
                        fieldelement(Dimension2ValueCode; "Tax Register Dim. Def. Value"."Dimension 2 Value Code")
                        {
                        }
                        fieldelement(DimensionCode; "Tax Register Dim. Def. Value"."Dimension Code")
                        {
                        }
                        fieldelement(DimensionValue; "Tax Register Dim. Def. Value"."Dimension Value")
                        {
                        }
                    }
                    tableelement("Tax Register Dim. Filter"; "Tax Register Dim. Filter")
                    {
                        LinkFields = "Section Code" = field("Section Code"), "Tax Register No." = field("No.");
                        LinkTable = "Tax Register";
                        MinOccurs = Zero;
                        XmlName = 'TaxRegisterDimFilter';
                        UseTemporary = true;
                        fieldelement(SectionCode; "Tax Register Dim. Filter"."Section Code")
                        {
                        }
                        fieldelement(TaxRegisterNo; "Tax Register Dim. Filter"."Tax Register No.")
                        {
                        }
                        fieldelement(Define; "Tax Register Dim. Filter".Define)
                        {
                        }
                        fieldelement(LineNo; "Tax Register Dim. Filter"."Line No.")
                        {
                        }
                        fieldelement(DimensionCode; "Tax Register Dim. Filter"."Dimension Code")
                        {
                        }
                        fieldelement(DimensionValueFilter; "Tax Register Dim. Filter"."Dimension Value Filter")
                        {
                        }
                        fieldelement(EntryNo; "Tax Register Dim. Filter"."Entry No.")
                        {
                        }
                        fieldelement(IfNoValue; "Tax Register Dim. Filter"."If No Value")
                        {
                        }
                    }
                    tableelement("Tax Reg. G/L Corr. Dim. Filter"; "Tax Reg. G/L Corr. Dim. Filter")
                    {
                        LinkFields = "Section Code" = field("Section Code"), "Tax Register No." = field("No.");
                        LinkTable = "Tax Register";
                        MinOccurs = Zero;
                        XmlName = 'TaxRegisterCorrDimFilter';
                        UseTemporary = true;
                        fieldelement(SectionCode; "Tax Reg. G/L Corr. Dim. Filter"."Section Code")
                        {
                        }
                        fieldelement(TaxRegisterNo; "Tax Reg. G/L Corr. Dim. Filter"."Tax Register No.")
                        {
                        }
                        fieldelement(Define; "Tax Reg. G/L Corr. Dim. Filter".Define)
                        {
                        }
                        fieldelement(LineNo; "Tax Reg. G/L Corr. Dim. Filter"."Line No.")
                        {
                        }
                        fieldelement(FilterGroup; "Tax Reg. G/L Corr. Dim. Filter"."Filter Group")
                        {
                        }
                        fieldelement(DimensionCode; "Tax Reg. G/L Corr. Dim. Filter"."Dimension Code")
                        {
                        }
                        fieldelement(DimensionValueFilter; "Tax Reg. G/L Corr. Dim. Filter"."Dimension Value Filter")
                        {
                        }
                    }
                }
                tableelement("Tax Register Term"; "Tax Register Term")
                {
                    LinkFields = "Section Code" = field(Code);
                    LinkTable = "Tax Register Section";
                    MinOccurs = Zero;
                    XmlName = 'TaxRegisterTerm';
                    UseTemporary = true;
                    fieldelement(SectionCode; "Tax Register Term"."Section Code")
                    {
                    }
                    fieldelement(TermCode; "Tax Register Term"."Term Code")
                    {
                    }
                    fieldelement(ExpressionType; "Tax Register Term"."Expression Type")
                    {
                    }
                    fieldelement(Expression; "Tax Register Term".Expression)
                    {
                    }
                    fieldelement(Check; "Tax Register Term".Check)
                    {
                    }
                    fieldelement(ProcessSign; "Tax Register Term"."Process Sign")
                    {
                    }
                    fieldelement(Description; "Tax Register Term".Description)
                    {
                    }
                    fieldelement(RoundingPrecision; "Tax Register Term"."Rounding Precision")
                    {
                    }
                    tableelement("Tax Register Term Formula"; "Tax Register Term Formula")
                    {
                        LinkFields = "Section Code" = field("Section Code"), "Term Code" = field("Term Code");
                        LinkTable = "Tax Register Term";
                        MinOccurs = Zero;
                        XmlName = 'TaxRegisterTermFormula';
                        UseTemporary = true;
                        fieldelement(SectionCode; "Tax Register Term Formula"."Section Code")
                        {
                        }
                        fieldelement(TermCode; "Tax Register Term Formula"."Term Code")
                        {
                        }
                        fieldelement(LineNo; "Tax Register Term Formula"."Line No.")
                        {
                        }
                        fieldelement(ExpressionType; "Tax Register Term Formula"."Expression Type")
                        {
                        }
                        fieldelement(Operation; "Tax Register Term Formula".Operation)
                        {
                        }
                        fieldelement(AccountType; "Tax Register Term Formula"."Account Type")
                        {
                        }
                        fieldelement(AccountNo; "Tax Register Term Formula"."Account No.")
                        {
                        }
                        fieldelement(AmountType; "Tax Register Term Formula"."Amount Type")
                        {
                        }
                        fieldelement(BalAccountNo; "Tax Register Term Formula"."Bal. Account No.")
                        {
                        }
                        fieldelement(ProcessSign; "Tax Register Term Formula"."Process Sign")
                        {
                        }
                        fieldelement(ProcessDivisionByZero; "Tax Register Term Formula"."Process Division by Zero")
                        {
                        }
                        fieldelement(NormJurisdictionCode; "Tax Register Term Formula"."Norm Jurisdiction Code")
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
        TaxRegisterSection: Record "Tax Register Section";
        TaxRegisterName: Record "Tax Register";
        TaxRegisterLineSetup: Record "Tax Register Line Setup";
        TaxRegisterTemplate: Record "Tax Register Template";
        TaxRegDimCombination: Record "Tax Register Dim. Comb.";
        TaxRegDimValueCombination: Record "Tax Register Dim. Value Comb.";
        TaxRegDimDefaultValue: Record "Tax Register Dim. Def. Value";
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
        TaxRegGLCorrDimFilter: Record "Tax Reg. G/L Corr. Dim. Filter";
        TaxRegisterTermName: Record "Tax Register Term";
        TaxRegisterTermLine: Record "Tax Register Term Formula";

    [Scope('OnPrem')]
    procedure SetData(var TempTaxRegisterSection: Record "Tax Register Section")
    begin
        if TempTaxRegisterSection.FindSet() then
            repeat
                "Tax Register Section" := TempTaxRegisterSection;
                "Tax Register Section".Insert();

                TaxRegisterName.SetRange("Section Code", TempTaxRegisterSection.Code);
                if TaxRegisterName.FindSet() then
                    repeat
                        "Tax Register" := TaxRegisterName;
                        "Tax Register".Insert();

                        TaxRegisterLineSetup.SetRange("Section Code", TaxRegisterName."Section Code");
                        TaxRegisterLineSetup.SetRange("Tax Register No.", TaxRegisterName."No.");
                        if TaxRegisterLineSetup.FindSet() then
                            repeat
                                "Tax Register Line Setup" := TaxRegisterLineSetup;
                                "Tax Register Line Setup".Insert();
                            until TaxRegisterLineSetup.Next() = 0;

                        TaxRegisterTemplate.SetRange("Section Code", TaxRegisterName."Section Code");
                        TaxRegisterTemplate.SetRange(Code, TaxRegisterName."No.");
                        if TaxRegisterTemplate.FindSet() then
                            repeat
                                "Tax Register Template" := TaxRegisterTemplate;
                                "Tax Register Template".Insert();
                            until TaxRegisterTemplate.Next() = 0;

                        TaxRegDimCombination.SetRange("Section Code", TaxRegisterName."Section Code");
                        TaxRegDimCombination.SetRange("Tax Register No.", TaxRegisterName."No.");
                        if TaxRegDimCombination.FindSet() then
                            repeat
                                "Tax Register Dim. Comb." := TaxRegDimCombination;
                                "Tax Register Dim. Comb.".Insert();
                            until TaxRegDimCombination.Next() = 0;

                        TaxRegDimValueCombination.SetRange("Section Code", TaxRegisterName."Section Code");
                        TaxRegDimValueCombination.SetRange("Tax Register No.", TaxRegisterName."No.");
                        if TaxRegDimValueCombination.FindSet() then
                            repeat
                                "Tax Register Dim. Value Comb." := TaxRegDimValueCombination;
                                "Tax Register Dim. Value Comb.".Insert();
                            until TaxRegDimValueCombination.Next() = 0;

                        TaxRegDimDefaultValue.SetRange("Section Code", TaxRegisterName."Section Code");
                        TaxRegDimDefaultValue.SetRange("Tax Register No.", TaxRegisterName."No.");
                        if TaxRegDimDefaultValue.FindSet() then
                            repeat
                                "Tax Register Dim. Def. Value" := TaxRegDimDefaultValue;
                                "Tax Register Dim. Def. Value".Insert();
                            until TaxRegDimDefaultValue.Next() = 0;

                        TaxRegDimFilter.SetRange("Section Code", TaxRegisterName."Section Code");
                        TaxRegDimFilter.SetRange("Tax Register No.", TaxRegisterName."No.");
                        if TaxRegDimFilter.FindSet() then
                            repeat
                                "Tax Register Dim. Filter" := TaxRegDimFilter;
                                "Tax Register Dim. Filter".Insert();
                            until TaxRegDimFilter.Next() = 0;

                        TaxRegGLCorrDimFilter.SetRange("Section Code", TaxRegisterName."Section Code");
                        TaxRegGLCorrDimFilter.SetRange("Tax Register No.", TaxRegisterName."No.");
                        if TaxRegGLCorrDimFilter.FindSet() then
                            repeat
                                "Tax Reg. G/L Corr. Dim. Filter" := TaxRegGLCorrDimFilter;
                                "Tax Reg. G/L Corr. Dim. Filter".Insert();
                            until TaxRegGLCorrDimFilter.Next() = 0;
                    until TaxRegisterName.Next() = 0;

                TaxRegisterTermName.SetRange("Section Code", TempTaxRegisterSection.Code);
                if TaxRegisterTermName.FindSet() then
                    repeat
                        "Tax Register Term" := TaxRegisterTermName;
                        "Tax Register Term".Insert();

                        TaxRegisterTermLine.SetRange("Section Code", TempTaxRegisterSection.Code);
                        TaxRegisterTermLine.SetRange("Term Code", TaxRegisterTermName."Term Code");
                        if TaxRegisterTermLine.FindSet() then
                            repeat
                                "Tax Register Term Formula" := TaxRegisterTermLine;
                                "Tax Register Term Formula".Insert();
                            until TaxRegisterTermLine.Next() = 0;
                    until TaxRegisterTermName.Next() = 0;
            until TempTaxRegisterSection.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportData()
    begin
        "Tax Register Section".Reset();
        if "Tax Register Section".FindSet() then
            repeat
                TaxRegisterSection := "Tax Register Section";
                if TaxRegisterSection.Find() then begin
                    TaxRegisterSection.Delete(true);
                    TaxRegisterSection := "Tax Register Section";
                end;
                TaxRegisterSection.Insert();
            until "Tax Register Section".Next() = 0;

        "Tax Register".Reset();
        if "Tax Register".FindSet() then
            repeat
                TaxRegisterName := "Tax Register";
                if TaxRegisterName.Find() then begin
                    TaxRegisterName.Delete(true);
                    TaxRegisterName := "Tax Register";
                end;
                TaxRegisterName.Insert();
            until "Tax Register".Next() = 0;

        "Tax Register Line Setup".Reset();
        if "Tax Register Line Setup".FindSet() then
            repeat
                TaxRegisterLineSetup := "Tax Register Line Setup";
                if TaxRegisterLineSetup.Find() then begin
                    TaxRegisterLineSetup.Delete(true);
                    TaxRegisterLineSetup := "Tax Register Line Setup";
                end;
                TaxRegisterLineSetup.Insert();
            until "Tax Register Line Setup".Next() = 0;

        "Tax Register Template".Reset();
        if "Tax Register Template".FindSet() then
            repeat
                TaxRegisterTemplate := "Tax Register Template";
                if TaxRegisterTemplate.Find() then begin
                    TaxRegisterTemplate.Delete(true);
                    TaxRegisterTemplate := "Tax Register Template";
                end;
                TaxRegisterTemplate.Insert();
            until "Tax Register Template".Next() = 0;

        "Tax Register Dim. Comb.".Reset();
        if "Tax Register Dim. Comb.".FindSet() then
            repeat
                TaxRegDimCombination := "Tax Register Dim. Comb.";
                if TaxRegDimCombination.Find() then begin
                    TaxRegDimCombination.Delete(true);
                    TaxRegDimCombination := "Tax Register Dim. Comb.";
                end;
                TaxRegDimCombination.Insert();
            until "Tax Register Dim. Comb.".Next() = 0;

        "Tax Register Dim. Value Comb.".Reset();
        if "Tax Register Dim. Value Comb.".FindSet() then
            repeat
                TaxRegDimValueCombination := "Tax Register Dim. Value Comb.";
                if TaxRegDimValueCombination.Find() then begin
                    TaxRegDimValueCombination.Delete(true);
                    TaxRegDimValueCombination := "Tax Register Dim. Value Comb.";
                end;
                TaxRegDimValueCombination.Insert();
            until "Tax Register Dim. Value Comb.".Next() = 0;

        "Tax Register Dim. Def. Value".Reset();
        if "Tax Register Dim. Def. Value".FindSet() then
            repeat
                TaxRegDimDefaultValue := "Tax Register Dim. Def. Value";
                if TaxRegDimDefaultValue.Find() then begin
                    TaxRegDimDefaultValue.Delete(true);
                    TaxRegDimDefaultValue := "Tax Register Dim. Def. Value";
                end;
                TaxRegDimDefaultValue.Insert();
            until "Tax Register Dim. Def. Value".Next() = 0;

        "Tax Register Dim. Filter".Reset();
        if "Tax Register Dim. Filter".FindSet() then
            repeat
                TaxRegDimFilter := "Tax Register Dim. Filter";
                if TaxRegDimFilter.Find() then begin
                    TaxRegDimFilter.Delete(true);
                    TaxRegDimFilter := "Tax Register Dim. Filter";
                end;
                TaxRegDimFilter.Insert();
            until "Tax Register Dim. Filter".Next() = 0;

        "Tax Reg. G/L Corr. Dim. Filter".Reset();
        if "Tax Reg. G/L Corr. Dim. Filter".FindSet() then
            repeat
                TaxRegGLCorrDimFilter := "Tax Reg. G/L Corr. Dim. Filter";
                if TaxRegGLCorrDimFilter.Find() then begin
                    TaxRegGLCorrDimFilter.Delete(true);
                    TaxRegGLCorrDimFilter := "Tax Reg. G/L Corr. Dim. Filter";
                end;
                TaxRegGLCorrDimFilter.Insert();
            until "Tax Reg. G/L Corr. Dim. Filter".Next() = 0;

        "Tax Register Term".Reset();
        if "Tax Register Term".FindSet() then
            repeat
                TaxRegisterTermName := "Tax Register Term";
                if TaxRegisterTermName.Find() then begin
                    TaxRegisterTermName.Delete(true);
                    TaxRegisterTermName := "Tax Register Term";
                end;
                TaxRegisterTermName.Insert();
            until "Tax Register Term".Next() = 0;

        "Tax Register Term Formula".Reset();
        if "Tax Register Term Formula".FindSet() then
            repeat
                TaxRegisterTermLine := "Tax Register Term Formula";
                if TaxRegisterTermLine.Find() then begin
                    TaxRegisterTermLine.Delete(true);
                    TaxRegisterTermLine := "Tax Register Term Formula";
                end;
                TaxRegisterTermLine.Insert();
            until "Tax Register Term Formula".Next() = 0;
    end;
}

