// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

page 9203 "Budget Matrix"
{
    Caption = 'Budget Matrix';
    DataCaptionExpression = BudgetName;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "Dimension Code Buffer";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the code of the record.';

                    trigger OnAssistEdit()
                    begin
                        LookUpCode(LineDimType, LineDimCode, Rec.Code);
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the record.';
                }
                field(TotalBudgetedAmount; Rec.Amount)
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    Caption = 'Budgeted Amount';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the G/L account''s total budget.';

                    trigger OnDrillDown()
                    begin
                        SetCommonFilters(GLAccBudgetBuf);
                        SetDimFilters(GLAccBudgetBuf, 0);
                        BudgetDrillDown();
                    end;
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(12);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Balance")
            {
                Caption = '&Balance';
                Image = Balance;
                action(GLAccBalanceBudget)
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Account Balance/Bud&get';
                    Image = Period;
                    ToolTip = 'Open a summary of the debit and credit balances for the current budget.';

                    trigger OnAction()
                    begin
                        GLAccountBalanceBudget();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        NameIndent := 0;
        for MATRIX_CurrentColumnOrdinal := 1 to MATRIX_CurrentNoOfMatrixColumn do
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        Rec.Amount := MatrixMgt.RoundAmount(CalcAmount(false), RoundingFactor);
        FormatLine();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(FindRec(LineDimType, Rec, Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(NextRec(LineDimType, Rec, Steps));
    end;

    trigger OnOpenPage()
    begin
        if GLAccBudgetBuf.GetFilter("Global Dimension 1 Filter") <> '' then
            GlobalDim1Filter := GLAccBudgetBuf.GetFilter("Global Dimension 1 Filter");
        if GLAccBudgetBuf.GetFilter("Global Dimension 2 Filter") <> '' then
            GlobalDim2Filter := GLAccBudgetBuf.GetFilter("Global Dimension 2 Filter");

        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GLAccBudgetBuf: Record "G/L Acc. Budget Buffer";
        GLBudgetName: Record "G/L Budget Name";
        MatrixRecords: array[12] of Record "Dimension Code Buffer";
        MATRIX_MatrixRecord: Record "Dimension Code Buffer";
        MatrixMgt: Codeunit "Matrix Management";
        BudgetName: Code[10];
        LineDimType: Enum "G/L Budget Matrix Dimensions";
        ColumnDimType: Enum "G/L Budget Matrix Dimensions";
        LineDimCode: Text[30];
        PeriodType: Enum "Analysis Period Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        DateFilter: Text[30];
        InternalDateFilter: Text[30];
        BusUnitFilter: Code[250];
        GLAccFilter: Text;
        IncomeBalanceGLAccFilter: Enum "G/L Account Income/Balance";
        GLAccCategoryFilter: Enum "G/L Account Category";
        GlobalDim1Filter: Code[250];
        GlobalDim2Filter: Code[250];
        BudgetDim1Filter: Code[250];
        BudgetDim2Filter: Code[250];
        BudgetDim3Filter: Code[250];
        BudgetDim4Filter: Code[250];
        PeriodInitialized: Boolean;
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[12] of Decimal;
        MATRIX_CaptionSet: array[12] of Text[80];
        RoundingFactorFormatString: Text;
        Emphasize: Boolean;
        NameIndent: Integer;

#pragma warning disable AA0074
        Text001: Label 'Period';
#pragma warning disable AA0470
        Text002: Label 'You may only edit column 1 to %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure DimCodeToOption(DimCode: Text[30]): Integer
    var
        BusUnit: Record "Business Unit";
        GLAcc: Record "G/L Account";
    begin
        case DimCode of
            '':
                exit(-1);
            GLAcc.TableCaption:
                exit(0);
            Text001:
                exit(1);
            BusUnit.TableCaption:
                exit(2);
            GLSetup."Global Dimension 1 Code":
                exit(3);
            GLSetup."Global Dimension 2 Code":
                exit(4);
            GLBudgetName."Budget Dimension 1 Code":
                exit(5);
            GLBudgetName."Budget Dimension 2 Code":
                exit(6);
            GLBudgetName."Budget Dimension 3 Code":
                exit(7);
            GLBudgetName."Budget Dimension 4 Code":
                exit(8);
            else
                exit(-1);
        end;
    end;

    local procedure FindRec(DimType: Enum "G/L Budget Matrix Dimensions"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]) Found: Boolean
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        case DimType of
            DimType::"G/L Account":
                begin
                    GLAcc."No." := DimCodeBuf.Code;
                    if GLAccFilter <> '' then
                        GLAcc.SetFilter("No.", GLAccFilter);
                    SetIncomeBalanceGLAccFilterOnGLAcc(GLAcc);
                    if GLAccCategoryFilter <> GLAccCategoryFilter::" " then
                        GLAcc.SetRange("Account Category", GLAccCategoryFilter);
                    Found := GLAcc.Find(Which);
                    if Found then
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                end;
            DimType::Period:
                begin
                    if not PeriodInitialized then
                        DateFilter := '';
                    PeriodInitialized := true;
                    Period."Period Start" := DimCodeBuf."Period Start";
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter)
                    else
                        if not PeriodInitialized and (InternalDateFilter <> '') then
                            Period.SetFilter("Period Start", InternalDateFilter);
                    Found := PeriodPageMgt.FindDate(Which, Period, PeriodType);
                    if Found then
                        CopyPeriodToBuf(Period, DimCodeBuf);
                end;
            DimType::"Business Unit":
                begin
                    BusUnit.Code := DimCodeBuf.Code;
                    if BusUnitFilter <> '' then
                        BusUnit.SetFilter(Code, BusUnitFilter);
                    Found := BusUnit.Find(Which);
                    if Found then
                        CopyBusUnitToBuf(BusUnit, DimCodeBuf);
                end;
            DimType::"Global Dimension 1":
                begin
                    SetDimensionValueFilters(DimVal, GlobalDim1Filter, GLSetup."Global Dimension 1 Code", DimCodeBuf);
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Global Dimension 2":
                begin
                    SetDimensionValueFilters(DimVal, GlobalDim2Filter, GLSetup."Global Dimension 2 Code", DimCodeBuf);
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Budget Dimension 1":
                begin
                    SetDimensionValueFilters(DimVal, BudgetDim1Filter, GLBudgetName."Budget Dimension 1 Code", DimCodeBuf);
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Budget Dimension 2":
                begin
                    SetDimensionValueFilters(DimVal, BudgetDim2Filter, GLBudgetName."Budget Dimension 2 Code", DimCodeBuf);
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Budget Dimension 3":
                begin
                    SetDimensionValueFilters(DimVal, BudgetDim3Filter, GLBudgetName."Budget Dimension 3 Code", DimCodeBuf);
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Budget Dimension 4":
                begin
                    SetDimensionValueFilters(DimVal, BudgetDim4Filter, GLBudgetName."Budget Dimension 4 Code", DimCodeBuf);
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValToBuf(DimVal, DimCodeBuf);
                end;
        end;
        OnAfterFindRec(DimType, Which, DimCodeBuf, Found);
    end;

    local procedure NextRec(DimType: Enum "G/L Budget Matrix Dimensions"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer) ResultSteps: Integer
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        case DimType of
            DimType::"G/L Account":
                begin
                    GLAcc."No." := DimCodeBuf.Code;
                    if GLAccFilter <> '' then
                        GLAcc.SetFilter("No.", GLAccFilter);
                    SetIncomeBalanceGLAccFilterOnGLAcc(GLAcc);
                    if GLAccCategoryFilter <> GLAccCategoryFilter::" " then
                        GLAcc.SetRange("Account Category", GLAccCategoryFilter);
                    ResultSteps := GLAcc.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                end;
            DimType::Period:
                begin
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter);
                    Period."Period Start" := DimCodeBuf."Period Start";
                    ResultSteps := PeriodPageMgt.NextDate(Steps, Period, PeriodType);
                    if ResultSteps <> 0 then
                        CopyPeriodToBuf(Period, DimCodeBuf);
                end;
            DimType::"Business Unit":
                begin
                    BusUnit.Code := DimCodeBuf.Code;
                    if BusUnitFilter <> '' then
                        BusUnit.SetFilter(Code, BusUnitFilter);
                    ResultSteps := BusUnit.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyBusUnitToBuf(BusUnit, DimCodeBuf);
                end;
            DimType::"Global Dimension 1":
                begin
                    SetDimensionValueFilters(DimVal, GlobalDim1Filter, GLSetup."Global Dimension 1 Code", DimCodeBuf);
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Global Dimension 2":
                begin
                    SetDimensionValueFilters(DimVal, GlobalDim2Filter, GLSetup."Global Dimension 2 Code", DimCodeBuf);
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Budget Dimension 1":
                begin
                    SetDimensionValueFilters(DimVal, BudgetDim1Filter, GLBudgetName."Budget Dimension 1 Code", DimCodeBuf);
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Budget Dimension 2":
                begin
                    SetDimensionValueFilters(DimVal, BudgetDim2Filter, GLBudgetName."Budget Dimension 2 Code", DimCodeBuf);
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Budget Dimension 3":
                begin
                    SetDimensionValueFilters(DimVal, BudgetDim3Filter, GLBudgetName."Budget Dimension 3 Code", DimCodeBuf);
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Budget Dimension 4":
                begin
                    SetDimensionValueFilters(DimVal, BudgetDim4Filter, GLBudgetName."Budget Dimension 4 Code", DimCodeBuf);
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValToBuf(DimVal, DimCodeBuf);
                end;
        end;
        OnAfterNextRec(DimType, Steps, DimCodeBuf, ResultSteps);
    end;

    local procedure SetDimensionValueFilters(var DimensionValue: Record "Dimension Value"; CodeFilter: Code[250]; SetupDimensionCode: Code[20]; DimensionCodeBuffer: Record "Dimension Code Buffer")
    begin
        if CodeFilter <> '' then
            DimensionValue.SetFilter(Code, CodeFilter);
        DimensionValue."Dimension Code" := SetupDimensionCode;
        DimensionValue.SetRange("Dimension Code", DimensionValue."Dimension Code");
        DimensionValue.Code := DimensionCodeBuffer.Code;

        OnAfterSetDimensionValueFilters(DimensionValue);
    end;

    local procedure CopyGLAccToBuf(var TheGLAcc: Record "G/L Account"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := TheGLAcc."No.";
        TheDimCodeBuf.Name := TheGLAcc.Name;
        TheDimCodeBuf.Totaling := TheGLAcc.Totaling;
        TheDimCodeBuf.Indentation := TheGLAcc.Indentation;
        TheDimCodeBuf."Show in Bold" := TheGLAcc."Account Type" <> TheGLAcc."Account Type"::Posting;
        OnAfterCopyGLAccToBuf(TheGLAcc, TheDimCodeBuf);
    end;

    local procedure CopyPeriodToBuf(var ThePeriod: Record Date; var TheDimCodeBuf: Record "Dimension Code Buffer")
    var
        Period2: Record Date;
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := Format(ThePeriod."Period Start");
        TheDimCodeBuf."Period Start" := ThePeriod."Period Start";
        TheDimCodeBuf."Period End" := ThePeriod."Period End";
        if DateFilter <> '' then begin
            Period2.SetFilter("Period End", DateFilter);
            if Period2.GetRangeMax("Period End") < TheDimCodeBuf."Period End" then
                TheDimCodeBuf."Period End" := Period2.GetRangeMax("Period End");
        end;
        TheDimCodeBuf.Name := ThePeriod."Period Name";
    end;

    local procedure CopyBusUnitToBuf(var TheBusUnit: Record "Business Unit"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := TheBusUnit.Code;
        if TheBusUnit.Name <> '' then
            TheDimCodeBuf.Name := TheBusUnit.Name
        else
            TheDimCodeBuf.Name := TheBusUnit."Company Name";
    end;

    local procedure CopyDimValToBuf(var TheDimVal: Record "Dimension Value"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := TheDimVal.Code;
        TheDimCodeBuf.Name := TheDimVal.Name;
        TheDimCodeBuf.Totaling := TheDimVal.Totaling;
        TheDimCodeBuf.Indentation := TheDimVal.Indentation;
        TheDimCodeBuf."Show in Bold" :=
          TheDimVal."Dimension Value Type" <> TheDimVal."Dimension Value Type"::Standard;
        OnAfterCopyDimValueToBuf(TheDimVal, TheDimCodeBuf);
    end;

    local procedure LookUpCode(DimType: Enum "G/L Budget Matrix Dimensions"; DimCode: Text[30]; "Code": Text[30])
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        DimVal: Record "Dimension Value";
    begin
        case DimType of
            DimType::"G/L Account":
                begin
                    GLAcc.Get(Code);
                    PAGE.RunModal(PAGE::"G/L Account List", GLAcc);
                end;
            DimType::Period:
                ;
            DimType::"Business Unit":
                begin
                    BusUnit.Get(Code);
                    PAGE.RunModal(PAGE::"Business Unit List", BusUnit);
                end;
            DimType::"Global Dimension 1", DimType::"Global Dimension 2",
            DimType::"Budget Dimension 1", DimType::"Budget Dimension 2",
            DimType::"Budget Dimension 3", DimType::"Budget Dimension 4":
                begin
                    DimVal.SetRange("Dimension Code", DimCode);
                    DimVal.Get(DimCode, Code);

                    PAGE.RunModal(PAGE::"Dimension Value List", DimVal);
                end;
        end;
        OnAfterLookUpCode(DimType, DimCode, Code);
    end;

    local procedure SetCommonFilters(var TheGLAccBudgetBuf: Record "G/L Acc. Budget Buffer")
    begin
        TheGLAccBudgetBuf.Reset();
        TheGLAccBudgetBuf.SetRange("Budget Filter", GLBudgetName.Name);
        if BusUnitFilter <> '' then
            TheGLAccBudgetBuf.SetFilter("Business Unit Filter", BusUnitFilter);
        if GLAccFilter <> '' then
            TheGLAccBudgetBuf.SetFilter("G/L Account Filter", GLAccFilter);
        if IncomeBalanceGLAccFilter <> IncomeBalanceGLAccFilter::" " then
            TheGLAccBudgetBuf.SetRange("Income/Balance", IncomeBalanceGLAccFilter);
        if DateFilter <> '' then
            TheGLAccBudgetBuf.SetFilter("Date Filter", DateFilter);
        if GlobalDim1Filter <> '' then
            TheGLAccBudgetBuf.SetFilter("Global Dimension 1 Filter", GlobalDim1Filter);
        if GlobalDim2Filter <> '' then
            TheGLAccBudgetBuf.SetFilter("Global Dimension 2 Filter", GlobalDim2Filter);
        if BudgetDim1Filter <> '' then
            TheGLAccBudgetBuf.SetFilter("Budget Dimension 1 Filter", BudgetDim1Filter);
        if BudgetDim2Filter <> '' then
            TheGLAccBudgetBuf.SetFilter("Budget Dimension 2 Filter", BudgetDim2Filter);
        if BudgetDim3Filter <> '' then
            TheGLAccBudgetBuf.SetFilter("Budget Dimension 3 Filter", BudgetDim3Filter);
        if BudgetDim4Filter <> '' then
            TheGLAccBudgetBuf.SetFilter("Budget Dimension 4 Filter", BudgetDim4Filter);
        OnAfterSetCommonFilters(GLAccBudgetBuf);
    end;

    local procedure SetDimFilters(var TheGLAccBudgetBuf: Record "G/L Acc. Budget Buffer"; LineOrColumn: Option Line,Column)
    var
        DimCodeBuf: Record "Dimension Code Buffer";
        DimType: Enum "G/L Budget Matrix Dimensions";
    begin
        if LineOrColumn = LineOrColumn::Line then begin
            DimCodeBuf := Rec;
            DimType := LineDimType;
        end else begin
            DimCodeBuf := MATRIX_MatrixRecord;
            DimType := ColumnDimType;
        end;

        case DimType of
            DimType::"G/L Account":
                if DimCodeBuf.Totaling <> '' then
                    GLAccBudgetBuf.SetFilter("G/L Account Filter", DimCodeBuf.Totaling)
                else
                    GLAccBudgetBuf.SetRange("G/L Account Filter", DimCodeBuf.Code);
            DimType::Period:
                TheGLAccBudgetBuf.SetRange("Date Filter", DimCodeBuf."Period Start", DimCodeBuf."Period End");
            DimType::"Business Unit":
                TheGLAccBudgetBuf.SetRange("Business Unit Filter", DimCodeBuf.Code);
            DimType::"Global Dimension 1":
                if DimCodeBuf.Totaling <> '' then
                    TheGLAccBudgetBuf.SetFilter("Global Dimension 1 Filter", DimCodeBuf.Totaling)
                else
                    TheGLAccBudgetBuf.SetRange("Global Dimension 1 Filter", DimCodeBuf.Code);
            DimType::"Global Dimension 2":
                if DimCodeBuf.Totaling <> '' then
                    TheGLAccBudgetBuf.SetFilter("Global Dimension 2 Filter", DimCodeBuf.Totaling)
                else
                    TheGLAccBudgetBuf.SetRange("Global Dimension 2 Filter", DimCodeBuf.Code);
            DimType::"Budget Dimension 1":
                if DimCodeBuf.Totaling <> '' then
                    TheGLAccBudgetBuf.SetFilter("Budget Dimension 1 Filter", DimCodeBuf.Totaling)
                else
                    TheGLAccBudgetBuf.SetRange("Budget Dimension 1 Filter", DimCodeBuf.Code);
            DimType::"Budget Dimension 2":
                if DimCodeBuf.Totaling <> '' then
                    TheGLAccBudgetBuf.SetFilter("Budget Dimension 2 Filter", DimCodeBuf.Totaling)
                else
                    TheGLAccBudgetBuf.SetRange("Budget Dimension 2 Filter", DimCodeBuf.Code);
            DimType::"Budget Dimension 3":
                if DimCodeBuf.Totaling <> '' then
                    TheGLAccBudgetBuf.SetFilter("Budget Dimension 3 Filter", DimCodeBuf.Totaling)
                else
                    TheGLAccBudgetBuf.SetRange("Budget Dimension 3 Filter", DimCodeBuf.Code);
            DimType::"Budget Dimension 4":
                if DimCodeBuf.Totaling <> '' then
                    TheGLAccBudgetBuf.SetFilter("Budget Dimension 4 Filter", DimCodeBuf.Totaling)
                else
                    TheGLAccBudgetBuf.SetRange("Budget Dimension 4 Filter", DimCodeBuf.Code);
        end;
        OnAfterSetDimFilters(TheGLAccBudgetBuf, DimType, DimCodeBuf);
    end;

    local procedure BudgetDrillDown()
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        IsHandled: Boolean;
    begin
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        if GLAccBudgetBuf.GetFilter("G/L Account Filter") <> '' then
            GLAccBudgetBuf.CopyFilter("G/L Account Filter", GLBudgetEntry."G/L Account No.");
        if GLAccBudgetBuf.GetFilter("Business Unit Filter") <> '' then
            GLAccBudgetBuf.CopyFilter("Business Unit Filter", GLBudgetEntry."Business Unit Code");
        if GLAccBudgetBuf.GetFilter("Global Dimension 1 Filter") <> '' then
            GLAccBudgetBuf.CopyFilter("Global Dimension 1 Filter", GLBudgetEntry."Global Dimension 1 Code");
        if GLAccBudgetBuf.GetFilter("Global Dimension 2 Filter") <> '' then
            GLAccBudgetBuf.CopyFilter("Global Dimension 2 Filter", GLBudgetEntry."Global Dimension 2 Code");
        if GLAccBudgetBuf.GetFilter("Budget Dimension 1 Filter") <> '' then
            GLAccBudgetBuf.CopyFilter("Budget Dimension 1 Filter", GLBudgetEntry."Budget Dimension 1 Code");
        if GLAccBudgetBuf.GetFilter("Budget Dimension 2 Filter") <> '' then
            GLAccBudgetBuf.CopyFilter("Budget Dimension 2 Filter", GLBudgetEntry."Budget Dimension 2 Code");
        if GLAccBudgetBuf.GetFilter("Budget Dimension 3 Filter") <> '' then
            GLAccBudgetBuf.CopyFilter("Budget Dimension 3 Filter", GLBudgetEntry."Budget Dimension 3 Code");
        if GLAccBudgetBuf.GetFilter("Budget Dimension 4 Filter") <> '' then
            GLAccBudgetBuf.CopyFilter("Budget Dimension 4 Filter", GLBudgetEntry."Budget Dimension 4 Code");
        if GLAccBudgetBuf.GetFilter("Date Filter") <> '' then
            GLAccBudgetBuf.CopyFilter("Date Filter", GLBudgetEntry.Date)
        else
            GLBudgetEntry.SetRange(Date, 0D, DMY2Date(31, 12, 9999));
        if (GLBudgetEntry.GetFilter("Global Dimension 1 Code") <> '') or (GLBudgetEntry.GetFilter("Global Dimension 2 Code") <> '') or
               (GLBudgetEntry.GetFilter("Business Unit Code") <> '')
            then
            GLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.", "Business Unit Code", "Global Dimension 1 Code")
        else
            GLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.", Date);
        IsHandled := false;
        OnBudgetDrillDownOnBeforePageRun(GLAccBudgetBuf, GLBudgetEntry, IsHandled);
        if IsHandled then
            exit;
        PAGE.Run(0, GLBudgetEntry);
    end;

    local procedure CalcAmount(SetColumnFilter: Boolean): Decimal
    begin
        SetCommonFilters(GLAccBudgetBuf);
        SetDimFilters(GLAccBudgetBuf, 0);
        if SetColumnFilter then
            SetDimFilters(GLAccBudgetBuf, 1);
        exit(CalcFieldsAndGetBudgetedAmount(GLAccBudgetBuf));
    end;

    local procedure CalcFieldsAndGetBudgetedAmount(var GLAccBudgetBuf: Record "G/L Acc. Budget Buffer") Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcFieldsAndGetBudgetedAmount(GLAccBudgetBuf, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GLAccBudgetBuf.CalcFields("Budgeted Amount");
        exit(GLAccBudgetBuf."Budgeted Amount");
    end;

    local procedure FromRoundedValue(OrgAmount: Decimal): Decimal
    var
        NewAmount: Decimal;
    begin
        NewAmount := OrgAmount;
        case RoundingFactor of
            RoundingFactor::"1000":
                NewAmount := OrgAmount * 1000;
            RoundingFactor::"1000000":
                NewAmount := OrgAmount * 1000000;
        end;
        exit(NewAmount);
    end;

    procedure LoadMatrix(NewMatrixColumns: array[32] of Text[80]; var NewMatrixRecords: array[12] of Record "Dimension Code Buffer"; CurrentNoOfMatrixColumns: Integer; NewLineDimCode: Text[30]; NewLineDimType: Enum "G/L Budget Matrix Dimensions"; NewColumnDimType: Enum "G/L Budget Matrix Dimensions"; NewGlobalDim1Filter: Code[250]; NewGlobalDim2Filter: Code[250]; NewBudgetDim1Filter: Code[250]; NewBudgetDim2Filter: Code[250]; NewBudgetDim3Filter: Code[250]; NewBudgetDim4Filter: Code[250]; var NewGLBudgetName: Record "G/L Budget Name"; NewDateFilter: Text[30]; NewGLAccFilter: Text; NewIncomeBalanceGLAccFilter: Enum "G/L Account Income/Balance"; NewGLAccCategoryFilter: Enum "G/L Account Category"; NewRoundingFactor: Enum "Analysis Rounding Factor"; NewPeriodType: Enum "Analysis Period Type")
    var
        i: Integer;
    begin
        for i := 1 to 12 do
            MATRIX_CellData[i] := 0;

        for i := 1 to 12 do begin
            if NewMatrixColumns[i] = '' then
                MATRIX_CaptionSet[i] := ' '
            else
                MATRIX_CaptionSet[i] := NewMatrixColumns[i];
            MatrixRecords[i] := NewMatrixRecords[i];
        end;
        if CurrentNoOfMatrixColumns > ArrayLen(MATRIX_CellData) then
            MATRIX_CurrentNoOfMatrixColumn := ArrayLen(MATRIX_CellData)
        else
            MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        LineDimCode := NewLineDimCode;
        LineDimType := NewLineDimType;
        ColumnDimType := NewColumnDimType;
        GlobalDim1Filter := NewGlobalDim1Filter;
        GlobalDim2Filter := NewGlobalDim2Filter;
        BudgetDim1Filter := NewBudgetDim1Filter;
        BudgetDim2Filter := NewBudgetDim2Filter;
        BudgetDim3Filter := NewBudgetDim3Filter;
        BudgetDim4Filter := NewBudgetDim4Filter;
        GLBudgetName := NewGLBudgetName;
        DateFilter := NewDateFilter;
        GLAccFilter := NewGLAccFilter;
        IncomeBalanceGLAccFilter := NewIncomeBalanceGLAccFilter;
        GLAccCategoryFilter := NewGLAccCategoryFilter;
        RoundingFactor := NewRoundingFactor;
        PeriodType := NewPeriodType;
        RoundingFactorFormatString := MatrixMgt.FormatRoundingFactor(RoundingFactor, false);
        InternalDateFilter := '';
    end;

#if not CLEAN26
    [Obsolete('Replaced by LoadMatrix with NewGLAccFilter: Text instead of Code[250]', '26.0')]
    procedure LoadMatrix(NewMatrixColumns: array[32] of Text[80]; var NewMatrixRecords: array[12] of Record "Dimension Code Buffer"; CurrentNoOfMatrixColumns: Integer; NewLineDimCode: Text[30]; NewLineDimType: Enum "G/L Budget Matrix Dimensions"; NewColumnDimType: Enum "G/L Budget Matrix Dimensions"; NewGlobalDim1Filter: Code[250]; NewGlobalDim2Filter: Code[250]; NewBudgetDim1Filter: Code[250]; NewBudgetDim2Filter: Code[250]; NewBudgetDim3Filter: Code[250]; NewBudgetDim4Filter: Code[250]; var NewGLBudgetName: Record "G/L Budget Name"; NewDateFilter: Text[30]; NewGLAccFilter: Code[250]; NewIncomeBalanceGLAccFilter: Enum "G/L Account Income/Balance"; NewGLAccCategoryFilter: Enum "G/L Account Category"; NewRoundingFactor: Enum "Analysis Rounding Factor"; NewPeriodType: Enum "Analysis Period Type")
    var
        i: Integer;
    begin
        for i := 1 to 12 do
            MATRIX_CellData[i] := 0;

        for i := 1 to 12 do begin
            if NewMatrixColumns[i] = '' then
                MATRIX_CaptionSet[i] := ' '
            else
                MATRIX_CaptionSet[i] := NewMatrixColumns[i];
            MatrixRecords[i] := NewMatrixRecords[i];
        end;
        if CurrentNoOfMatrixColumns > ArrayLen(MATRIX_CellData) then
            MATRIX_CurrentNoOfMatrixColumn := ArrayLen(MATRIX_CellData)
        else
            MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        LineDimCode := NewLineDimCode;
        LineDimType := NewLineDimType;
        ColumnDimType := NewColumnDimType;
        GlobalDim1Filter := NewGlobalDim1Filter;
        GlobalDim2Filter := NewGlobalDim2Filter;
        BudgetDim1Filter := NewBudgetDim1Filter;
        BudgetDim2Filter := NewBudgetDim2Filter;
        BudgetDim3Filter := NewBudgetDim3Filter;
        BudgetDim4Filter := NewBudgetDim4Filter;
        GLBudgetName := NewGLBudgetName;
        DateFilter := NewDateFilter;
        GLAccFilter := NewGLAccFilter;
        IncomeBalanceGLAccFilter := NewIncomeBalanceGLAccFilter;
        GLAccCategoryFilter := NewGLAccCategoryFilter;
        RoundingFactor := NewRoundingFactor;
        PeriodType := NewPeriodType;
        RoundingFactorFormatString := MatrixMgt.FormatRoundingFactor(RoundingFactor, false);
        InternalDateFilter := '';
    end;
#endif

    local procedure MATRIX_OnDrillDown(MATRIX_ColumnOrdinal: Integer)
    begin
        MATRIX_MatrixRecord := MatrixRecords[MATRIX_ColumnOrdinal];
        SetCommonFilters(GLAccBudgetBuf);
        SetDimFilters(GLAccBudgetBuf, 0);
        SetDimFilters(GLAccBudgetBuf, 1);
        BudgetDrillDown();
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    begin
        MATRIX_MatrixRecord := MatrixRecords[MATRIX_ColumnOrdinal];
        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundAmount(CalcAmount(true), RoundingFactor);
    end;

    local procedure UpdateAmount(MATRIX_ColumnOrdinal: Integer)
    var
        NewAmount: Decimal;
    begin
        OnBeforeUpdateAmount(MATRIX_ColumnOrdinal);
        if MATRIX_ColumnOrdinal > MATRIX_CurrentNoOfMatrixColumn then
            Error(Text002, MATRIX_CurrentNoOfMatrixColumn);
        MATRIX_MatrixRecord := MatrixRecords[MATRIX_ColumnOrdinal];
        NewAmount := FromRoundedValue(MATRIX_CellData[MATRIX_ColumnOrdinal]);
        if CalcAmount(true) = 0 then; // To set filters correctly
        CalcFieldsAndSetNewBudgetedAmount(GLAccBudgetBuf, NewAmount);
        Rec.Amount := MatrixMgt.RoundAmount(CalcAmount(false), RoundingFactor);
        CurrPage.Update();
        OnAfterUpdateAmount();
    end;

    local procedure CalcFieldsAndSetNewBudgetedAmount(var GLAccBudgetBuf: Record "G/L Acc. Budget Buffer"; NewAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcFieldsAndSetNewBudgetedAmount(GLAccBudgetBuf, NewAmount, IsHandled);
        if IsHandled then
            exit;

        GLAccBudgetBuf.CalcFields("Budgeted Amount");
        GLAccBudgetBuf.Validate("Budgeted Amount", NewAmount);
    end;

    local procedure GLAccountBalanceBudget()
    var
        GLAcc: Record "G/L Account";
    begin
        if DimCodeToOption(LineDimCode) = 0 then
            GLAcc.Get(Rec.Code)
        else begin
            if GLAccFilter <> '' then
                GLAcc.SetFilter("No.", GLAccFilter);
            SetIncomeBalanceGLAccFilterOnGLAcc(GLAcc);
            if GLAccCategoryFilter <> GLAccCategoryFilter::" " then
                GLAcc.SetRange("Account Category", GLAccCategoryFilter);
            GLAcc.FindFirst();
            GLAcc.Reset();
        end;
        GLAcc.SetRange("Budget Filter", GLBudgetName.Name);
        if DateFilter <> '' then
            GLAcc.SetFilter("Date Filter", DateFilter);
        if BusUnitFilter <> '' then
            GLAcc.SetFilter("Business Unit Filter", BusUnitFilter);
        if GLAccFilter <> '' then
            GLAcc.SetFilter("No.", GLAccFilter);
        SetIncomeBalanceGLAccFilterOnGLAcc(GLAcc);
        if GLAccCategoryFilter <> GLAccCategoryFilter::" " then
            GLAcc.SetRange("Account Category", GLAccCategoryFilter);
        if GlobalDim1Filter <> '' then
            GLAcc.SetFilter("Global Dimension 1 Filter", GlobalDim1Filter);
        if GlobalDim2Filter <> '' then
            GLAcc.SetFilter("Global Dimension 2 Filter", GlobalDim2Filter);
        PAGE.Run(PAGE::"G/L Account Balance/Budget", GLAcc);
    end;

    local procedure FormatLine()
    begin
        Emphasize := Rec."Show in Bold";
        NameIndent := Rec.Indentation;
    end;

    local procedure FormatStr(): Text
    begin
        exit(RoundingFactorFormatString);
    end;

    local procedure SetIncomeBalanceGLAccFilterOnGLAcc(var GLAccount: Record "G/L Account")
    begin
        case IncomeBalanceGLAccFilter of
            IncomeBalanceGLAccFilter::"Balance Sheet":
                GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
            IncomeBalanceGLAccFilter::"Income Statement":
                GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        end;

        OnAfterSetIncomeBalanceGLAccFilterOnGLAcc(GLAccount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindRec(DimType: Enum "G/L Budget Matrix Dimensions"; Which: Text[250]; var DimensionCodeBuffer: Record "Dimension Code Buffer"; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookUpCode(DimType: Enum "G/L Budget Matrix Dimensions"; DimCode: Text[30]; FieldCode: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNextRec(DimType: Enum "G/L Budget Matrix Dimensions"; Steps: Integer; var DimensionCodeBuffer: Record "Dimension Code Buffer"; var ResultSteps: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCommonFilters(var TheGLAccBudgetBuffer: Record "G/L Acc. Budget Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDimFilters(var TheGLAccBudgetBuffer: Record "G/L Acc. Budget Buffer"; DimType: Enum "G/L Budget Matrix Dimensions"; DimCodeBuf: Record "Dimension Code Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetIncomeBalanceGLAccFilterOnGLAcc(var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDimensionValueFilters(var DimensionValue: Record "Dimension Value")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateAmount()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateAmount(MATRIX_ColumnOrdinal: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcFieldsAndGetBudgetedAmount(var GLAccBudgetBuffer: Record "G/L Acc. Budget Buffer"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcFieldsAndSetNewBudgetedAmount(var GLAccBudgetBuf: Record "G/L Acc. Budget Buffer"; NewAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBudgetDrillDownOnBeforePageRun(var GLAccBudgetBuffer: Record "G/L Acc. Budget Buffer"; var GLBudgetEntry: Record "G/L Budget Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGLAccToBuf(GLAcc: Record "G/L Account"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyDimValueToBuf(DimVal: Record "Dimension Value"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
    end;
}

