// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using System.IO;
using System.Reflection;
using System.Utilities;

report 82 "Export Budget to Excel"
{
    Caption = 'Export Budget to Excel';
    ProcessingOnly = true;

    dataset
    {
        dataitem("G/L Budget Entry"; "G/L Budget Entry")
        {
            DataItemTableView = sorting("Budget Name", "G/L Account No.", "Business Unit Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Budget Dimension 1 Code", "Budget Dimension 2 Code", "Budget Dimension 3 Code", "Budget Dimension 4 Code", Date);
            RequestFilterFields = "Budget Name", "Business Unit Code", "G/L Account No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Budget Dimension 1 Code", "Budget Dimension 2 Code", "Budget Dimension 3 Code", "Budget Dimension 4 Code";

            trigger OnAfterGetRecord()
            begin
                Clear(TempBudgetBuf1);
                TempBudgetBuf1."G/L Account No." := "G/L Account No.";
                TempBudgetBuf1."Dimension Value Code 1" := GetDimValueCode(ColumnDimCode[1]);
                TempBudgetBuf1."Dimension Value Code 2" := GetDimValueCode(ColumnDimCode[2]);
                TempBudgetBuf1."Dimension Value Code 3" := GetDimValueCode(ColumnDimCode[3]);
                TempBudgetBuf1."Dimension Value Code 4" := GetDimValueCode(ColumnDimCode[4]);
                TempBudgetBuf1."Dimension Value Code 5" := GetDimValueCode(ColumnDimCode[5]);
                TempBudgetBuf1."Dimension Value Code 6" := GetDimValueCode(ColumnDimCode[6]);
                TempBudgetBuf1."Dimension Value Code 7" := GetDimValueCode(ColumnDimCode[7]);
                TempBudgetBuf1."Dimension Value Code 8" := GetDimValueCode(ColumnDimCode[8]);
                TempBudgetBuf1.Date := CalcPeriodStart(Date);
                TempBudgetBuf1.Amount := Amount;

                TempBudgetBuf2 := TempBudgetBuf1;
                if TempBudgetBuf2.Find() then begin
                    TempBudgetBuf2.Amount :=
                      TempBudgetBuf2.Amount + TempBudgetBuf1.Amount;
                    TempBudgetBuf2.Modify();
                end else
                    TempBudgetBuf2.Insert();
            end;

            trigger OnPostDataItem()
            var
                DimValue: Record "Dimension Value";
                BusUnit: Record "Business Unit";
                ConfirmManagement: Codeunit "Confirm Management";
                TypeHelper: Codeunit "Type Helper";
                Window: Dialog;
                RecNo: Integer;
                TotalRecNo: Integer;
                Continue: Boolean;
                IsHandled: Boolean;
                LastBudgetRowNo: Integer;
                DimensionRange: array[2, 8] of Integer;
            begin
                Window.Open(
                  Text005 +
                  '@1@@@@@@@@@@@@@@@@@@@@@@@@@\');
                Window.Update(1, 0);
                TotalRecNo := GLAcc.Count();
                RecNo := 0;

                RowNo := 1;
                EnterCell(RowNo, 1, Text006, false, true, '', TempExcelBuf."Cell Type"::Text);
                EnterCell(RowNo, 2, '', false, true, '', TempExcelBuf."Cell Type"::Text);
                EnterFilterInCell(GetFilter("Budget Name"), FieldCaption("Budget Name"));

                GLSetup.Get();
                EnterFilterInCell(GetFilter("Business Unit Code"), FieldCaption("Business Unit Code"));
                EnterDimFilter(GLSetup."Global Dimension 1 Code", GetFilter("Global Dimension 1 Code"));
                EnterDimFilter(GLSetup."Global Dimension 2 Code", GetFilter("Global Dimension 2 Code"));
                GLBudgetName.Get(GetFilter("Budget Name"));
                EnterDimFilter(GLBudgetName."Budget Dimension 1 Code", GetFilter("Budget Dimension 1 Code"));
                EnterDimFilter(GLBudgetName."Budget Dimension 2 Code", GetFilter("Budget Dimension 2 Code"));
                EnterDimFilter(GLBudgetName."Budget Dimension 3 Code", GetFilter("Budget Dimension 3 Code"));
                EnterDimFilter(GLBudgetName."Budget Dimension 4 Code", GetFilter("Budget Dimension 4 Code"));
                OnAfterEnterDimFilter("G/L Budget Entry", TempExcelBuf, RowNo);

                RowNo := RowNo + 2;
                HeaderRowNo := RowNo;
                EnterCell(HeaderRowNo, 1, FieldCaption("G/L Account No."), false, true, '', TempExcelBuf."Cell Type"::Text);
                EnterCell(HeaderRowNo, 2, GLAcc.FieldCaption(Name), false, true, '', TempExcelBuf."Cell Type"::Text);
                i := 0;
                ColNo := 2;
                Continue := true;
                while Continue do begin
                    i := i + 1;
                    if i > 8 then
                        Continue := false
                    else
                        if ColumnDimCode[i] = '' then
                            Continue := false;
                    if Continue then begin
                        ColNo := ColNo + 1;
                        IsHandled := false;
                        OnGLBudgetEntryOnPostDataItemOnBeforeSetHeaderDim(HeaderRowNo, ColNo, i, TempExcelBuf, IsHandled);
                        if not IsHandled then
                            if i = BusUnitDimIndex then
                                EnterCell(HeaderRowNo, ColNo, BusUnit.TableCaption(), false, true, '', TempExcelBuf."Cell Type"::Text)
                            else begin
                                Dim.Get(ColumnDimCode[i]);
                                EnterCell(HeaderRowNo, ColNo, Dim."Code Caption", false, true, '', TempExcelBuf."Cell Type"::Text);
                            end;
                    end;
                end;
                if TempPeriod.Find('-') then
                    repeat
                        ColNo := ColNo + 1;
                        EnterCell(
                          HeaderRowNo, ColNo, CopyStr(TypeHelper.FormatDateWithCurrentCulture(TempPeriod."Period Start"), 1, 250),
                          false, true, '', TempExcelBuf."Cell Type"::Date);
                    until TempPeriod.Next() = 0;

                CopyFilter("G/L Account No.", GLAcc."No.");
                OnAfterCopyFilterGLAccount(GLAcc);
                if GLAcc.Find('-') then
                    repeat
                        RecNo := RecNo + 1;
                        Window.Update(1, Round(RecNo / TotalRecNo * 10000, 1));
                        RowNo := RowNo + 1;
                        EnterCell(
                          RowNo, 2, CopyStr(CopyStr(PadStr(' ', 100), 1, 2 * GLAcc.Indentation + 1) + GLAcc.Name, 2),
                          GLAcc."Account Type" <> GLAcc."Account Type"::Posting, false, '', TempExcelBuf."Cell Type"::Text);
                        EnterCell(
                          RowNo, 1, GLAcc."No.", GLAcc."Account Type" <> GLAcc."Account Type"::Posting, false, '', TempExcelBuf."Cell Type"::Text);
                        if (GLAcc.Totaling = '') or (not IncludeTotalingFormulas) then begin
                            TempBudgetBuf2.SetRange("G/L Account No.", GLAcc."No.");
                            if TempBudgetBuf2.Find('-') then begin
                                TempBudgetBuf1 := TempBudgetBuf2;
                                EnterDimValues();
                                if TempPeriod.Find('-') then;
                                repeat
                                    if IsDimDifferent(TempBudgetBuf1, TempBudgetBuf2) then begin
                                        RowNo := RowNo + 1;
                                        EnterCell(
                                          RowNo, 1, GLAcc."No.", GLAcc."Account Type" <> GLAcc."Account Type"::Posting, false, '', TempExcelBuf."Cell Type"::Text);
                                        EnterDimValues();
                                        TempBudgetBuf1 := TempBudgetBuf2;
                                    end;
                                    TempPeriod.Get(0, TempBudgetBuf2.Date);
                                    EnterCell(
                                      RowNo, NoOfDimensions + 2 + TempPeriod."Period No.",
                                      MatrixMgt.FormatAmount(TempBudgetBuf2.Amount, RoundingFactor, false),
                                      GLAcc."Account Type" <> GLAcc."Account Type"::Posting,
                                      false, '', TempExcelBuf."Cell Type"::Number);
                                    TempPeriod.Next();
                                until TempBudgetBuf2.Next() = 0;
                            end else begin
                                Clear(TempBudgetBuf2);
                                EnterDimValues();
                            end;
                        end else
                            if TempPeriod.Find('-') then
                                repeat
                                    EnterFormula(
                                      RowNo,
                                      NoOfDimensions + 2 + TempPeriod."Period No.",
                                      GLAcc.Totaling,
                                      GLAcc."Account Type" <> GLAcc."Account Type"::Posting,
                                      false,
                                      '#,##0.00');
                                until TempPeriod.Next() = 0;
                    until GLAcc.Next() = 0;
                if IncludeTotalingFormulas then
                    HasFormulaError := TempExcelBuf.ExportBudgetFilterToFormula(TempExcelBuf);
                Window.Close();
                LastBudgetRowNo := RowNo;

                EnterRangeOfValues(DimensionRange, BusUnit, DimValue);
                if HasFormulaError then
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text007, TempExcelBuf.GetExcelReference(7)), true) then
                        CurrReport.Break();

                TempExcelBuf.CreateBook(ServerFileName, TempExcelBuf.GetExcelReference(10));
                TempExcelBuf.SetCurrent(HeaderRowNo + 1, 1);
                TempExcelBuf.StartRange();
                TempExcelBuf.SetCurrent(LastBudgetRowNo, 1);
                TempExcelBuf.EndRange();
                TempExcelBuf.CreateRange(TempExcelBuf.GetExcelReference(8));
                if TempPeriod.Find('-') then
                    repeat
                        TempExcelBuf.SetCurrent(HeaderRowNo + 1, NoOfDimensions + 2 + TempPeriod."Period No.");
                        TempExcelBuf.StartRange();
                        TempExcelBuf.SetCurrent(LastBudgetRowNo, NoOfDimensions + 2 + TempPeriod."Period No.");
                        TempExcelBuf.EndRange();
                        TempExcelBuf.CreateRange(TempExcelBuf.GetExcelReference(9) + '_' + Format(TempPeriod."Period No."));
                    until TempPeriod.Next() = 0;

                for i := 1 to NoOfDimensions do begin
                    TempExcelBuf.SetCurrent(HeaderRowNo + 1, i + 2);
                    TempExcelBuf.StartRange();
                    TempExcelBuf.SetCurrent(LastBudgetRowNo, i + 2);
                    TempExcelBuf.EndRange();
                    TempExcelBuf.CreateRange('NAV_DIM' + Format(i));
                    TempExcelBuf.SetCurrent(DimensionRange[1, i], 1);
                    TempExcelBuf.StartRange();
                    TempExcelBuf.SetCurrent(DimensionRange[2, i], 1);
                    TempExcelBuf.EndRange();
                    TempExcelBuf.CreateValidationRule('NAV_DIM' + Format(i));
                end;

                TempExcelBuf.WriteSheet(
                  PadStr(StrSubstNo('%1 %2', GLBudgetName.Name, GLBudgetName.Description), 30),
                  CompanyName,
                  UserId);

                TempExcelBuf.CloseBook();
                if not TestMode then begin
                    TempExcelBuf.SetFriendlyFilename(StrSubstNo('%1-%2', GLBudgetName.Name, GLBudgetName.Description));
                    TempExcelBuf.OpenExcel();
                end;
            end;

            trigger OnPreDataItem()
            var
                BusUnit: Record "Business Unit";
                DimensionValue: Record "Dimension Value";
            begin
                if GetRangeMin("Budget Name") <> GetRangeMax("Budget Name") then
                    Error(Text001);

                if (StartDateReq = 0D) or
                   (NoOfPeriodsReq = 0) or
                   (Format(PeriodLengthReq) = '')
                then
                    Error(Text002);

                SelectedDim.Reset();
                SelectedDim.SetRange("User ID", UserId);
                SelectedDim.SetRange("Object Type", 3);
                SelectedDim.SetRange("Object ID", REPORT::"Export Budget to Excel");
                i := 0;
                OnGLBudgetEntryPreDataItemOnAfterSelectedDimSetFilters(ColumnDimCode, i);
                if BusUnit.FindFirst() then begin
                    i := i + 1;
                    BusUnitDimIndex := i;
                    BusUnitDimCode := CopyStr(UpperCase(BusUnit.TableCaption()), 1, MaxStrLen(ColumnDimCode[1]));
                    ColumnDimCode[BusUnitDimIndex] := BusUnitDimCode;
                end;
                if SelectedDim.Find('-') then
                    repeat
                        DimensionValue.SetRange("Dimension Code", SelectedDim."Dimension Code");
                        if not DimensionValue.IsEmpty() then begin
                            i := i + 1;
                            if i > ArrayLen(ColumnDimCode) then
                                Error(Text003, ArrayLen(ColumnDimCode));
                            ColumnDimCode[i] := SelectedDim."Dimension Code";
                        end;
                    until (SelectedDim.Next() = 0) or (i = 8);
                NoOfDimensions := i;

                InsertTempPeriods();

                SetRange(Date, StartDateReq, TempPeriod."Period End");
                TempBudgetBuf2.DeleteAll();
                TempExcelBuf.DeleteAll();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartDate; StartDateReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(NoOfPeriods; NoOfPeriodsReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'No. of Periods';
                        ToolTip = 'Specifies how many accounting periods to include.';
                    }
                    field(PeriodLength; PeriodLengthReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(ColumnDimensions; ColumnDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Column Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies dimensions that apply to the columns.';

                        trigger OnAssistEdit()
                        begin
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Export Budget to Excel", ColumnDim);
                        end;
                    }
                    field(IncludeTotalingFormulas; IncludeTotalingFormulas)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Include Totaling Formulas';
                        ToolTip = 'Specifies if you want sum formulas to be created in Excel based on the totaling fields used in the Chart of Accounts window and for dimension values.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            ColumnDim := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Export Budget to Excel", '');
            if StartDateReq = 0D then
                StartDateReq := CalcDate('<-CY>', WorkDate());
            if (Format(PeriodLengthReq) = '') or (Format(PeriodLengthReq) = '0D') then
                Evaluate(PeriodLengthReq, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        DimSelectionBuf.CompareDimText(
          3, REPORT::"Export Budget to Excel", '', ColumnDim, Text000);
    end;

    var
        SelectedDim: Record "Selected Dimension";
        TempBudgetBuf1: Record "Budget Buffer" temporary;
        TempBudgetBuf2: Record "Budget Buffer" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        GLSetup: Record "General Ledger Setup";
        Dim: Record Dimension;
        GLBudgetName: Record "G/L Budget Name";
        TempExcelBuf: Record "Excel Buffer" temporary;
        GLAcc: Record "G/L Account";
        MatrixMgt: Codeunit "Matrix Management";
        i: Integer;
        RowNo: Integer;
        ColNo: Integer;
        ServerFileName: Text;
        ColumnDim: Text[250];
        ColumnDimCode: array[8] of Code[20];
        HasFormulaError: Boolean;
        IncludeTotalingFormulas: Boolean;
        RoundingFactor: Enum "Analysis Rounding Factor";
        HeaderRowNo: Integer;
        BusUnitDimIndex: Integer;
        BusUnitDimCode: Code[20];
        TestMode: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Column Dimensions';
        Text001: Label 'You can only export one budget at a time.';
        Text002: Label 'You must specify a Start Date, No. of Periods, and a Period Length.';
#pragma warning disable AA0470
        Text003: Label 'You can only select a maximum of %1 column dimensions.';
#pragma warning restore AA0470
        Text005: Label 'Analyzing Data...\\';
        Text006: Label 'Export Filters';
#pragma warning disable AA0470
        Text007: Label 'Some filters cannot be converted into Excel formulas. You will have to check %1 errors in the Excel worksheet. Do you want to create the Excel worksheet?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        DimSelectionBuf: Record "Dimension Selection Buffer";
        TempPeriod: Record Date temporary;
        PeriodLengthReq: DateFormula;
        StartDateReq: Date;
        NoOfPeriodsReq: Integer;
        NoOfDimensions: Integer;

    local procedure CalcPeriodStart(EntryDate: Date): Date
    begin
        TempPeriod."Period Start" := EntryDate;
        TempPeriod.Find('=<');
        exit(TempPeriod."Period Start");
    end;

    local procedure InsertTempPeriods()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertTempPeriods(TempPeriod, StartDateReq, NoOfPeriodsReq, PeriodLengthReq, IsHandled);
        if IsHandled then
            exit;

        for i := 1 to NoOfPeriodsReq do begin
            if i = 1 then
                TempPeriod."Period Start" := StartDateReq
            else
                TempPeriod."Period Start" := CalcDate(PeriodLengthReq, TempPeriod."Period Start");
            TempPeriod."Period End" := CalcDate(PeriodLengthReq, TempPeriod."Period Start");
            TempPeriod."Period End" := CalcDate('<-1D>', TempPeriod."Period End");
            TempPeriod."Period No." := i;
            TempPeriod.Insert();
        end;
    end;

    local procedure GetDimValueCode(DimCode: Code[20]) Result: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDimValueCode(DimCode, Result, IsHandled, "G/L Budget Entry");
        if IsHandled then
            exit(Result);

        if DimCode = '' then
            exit('');
        if DimCode = BusUnitDimCode then
            exit("G/L Budget Entry"."Business Unit Code");
        DimSetEntry.SetRange("Dimension Set ID", "G/L Budget Entry"."Dimension Set ID");
        DimSetEntry.SetRange("Dimension Code", DimCode);
        if DimSetEntry.FindFirst() then
            exit(DimSetEntry."Dimension Value Code");
        exit('');
    end;

    local procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValue: Text[250]; Bold: Boolean; UnderLine: Boolean; NumberFormat: Text[30]; CellType: Option)
    begin
        TempExcelBuf.Init();
        TempExcelBuf.Validate("Row No.", RowNo);
        TempExcelBuf.Validate("Column No.", ColumnNo);
        TempExcelBuf."Cell Value as Text" := CellValue;
        TempExcelBuf.Formula := '';
        TempExcelBuf.Bold := Bold;
        TempExcelBuf.Underline := UnderLine;
        TempExcelBuf.NumberFormat := NumberFormat;
        TempExcelBuf."Cell Type" := CellType;
        TempExcelBuf.Insert();
    end;

    local procedure EnterFilterInCell("Filter": Text; FieldName: Text[100])
    begin
        if Filter <> '' then begin
            RowNo := RowNo + 1;
            EnterCell(RowNo, 1, FieldName, false, false, '', TempExcelBuf."Cell Type"::Text);
            EnterCell(RowNo, 2, CopyStr(Filter, 1, 250), false, false, '', TempExcelBuf."Cell Type"::Text);
        end;
    end;

    local procedure EnterDimValue(ColDimIndex: Integer; DimValueCode: Code[20])
    var
        DimFilter: Text;
        ShouldGetDimValueCode: Boolean;
    begin
        if ColumnDimCode[ColDimIndex] <> '' then begin
            ColNo := ColNo + 1;
            ShouldGetDimValueCode := (DimValueCode = '') and (ColDimIndex > BusUnitDimIndex);
            OnEnterDimValueOnAfterCalcShouldGetDimValueCode(DimValueCode, ColDimIndex, BusUnitDimIndex, ShouldGetDimValueCode);
            if ShouldGetDimValueCode then begin
                DimFilter := GetGLBudgetEntryDimFilter(ColumnDimCode[ColDimIndex]);
                if GetDimValueCount(ColumnDimCode[ColDimIndex], DimFilter) = 1 then
                    DimValueCode := CopyStr(DimFilter, 1, MaxStrLen(DimValueCode));
            end;
            EnterCell(RowNo, ColNo, DimValueCode, false, false, '', TempExcelBuf."Cell Type"::Text);
        end;
    end;

    local procedure EnterDimValues()
    begin
        ColNo := 2;
        EnterDimValue(1, TempBudgetBuf2."Dimension Value Code 1");
        EnterDimValue(2, TempBudgetBuf2."Dimension Value Code 2");
        EnterDimValue(3, TempBudgetBuf2."Dimension Value Code 3");
        EnterDimValue(4, TempBudgetBuf2."Dimension Value Code 4");
        EnterDimValue(5, TempBudgetBuf2."Dimension Value Code 5");
        EnterDimValue(6, TempBudgetBuf2."Dimension Value Code 6");
        EnterDimValue(7, TempBudgetBuf2."Dimension Value Code 7");
        EnterDimValue(8, TempBudgetBuf2."Dimension Value Code 8");
    end;

    local procedure EnterFormula(RowNo: Integer; ColumnNo: Integer; CellValue: Text[250]; Bold: Boolean; UnderLine: Boolean; NumberFormat: Text[30])
    begin
        TempExcelBuf.Init();
        TempExcelBuf.Validate("Row No.", RowNo);
        TempExcelBuf.Validate("Column No.", ColumnNo);
        TempExcelBuf."Cell Value as Text" := '';
        TempExcelBuf.Formula := CellValue; // is converted to formula later.
        TempExcelBuf.Bold := Bold;
        TempExcelBuf.Underline := UnderLine;
        TempExcelBuf.NumberFormat := NumberFormat;
        TempExcelBuf.Insert();
    end;

    local procedure EnterDimFilter(DimCode: Code[20]; DimFilter: Text)
    begin
        if DimCode <> '' then begin
            Dim.Get(DimCode);
            EnterFilterInCell(DimFilter, Dim."Code Caption");
        end;
    end;

    procedure SetParameters(NewStartDate: Date; NewNoOfPeriods: Integer; NewPeriodLength: DateFormula; NewRoundingFactor: Option "None","1","1000","1000000")
    begin
        StartDateReq := NewStartDate;
        NoOfPeriodsReq := NewNoOfPeriods;
        PeriodLengthReq := NewPeriodLength;
        RoundingFactor := Enum::"Analysis Rounding Factor".FromInteger(NewRoundingFactor);
    end;

    procedure SetFileNameSilent(NewFileName: Text)
    begin
        ServerFileName := NewFileName;
    end;

    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;

    local procedure IsDimDifferent(BudgetBuf1: Record "Budget Buffer"; BudgetBuf2: Record "Budget Buffer"): Boolean
    begin
        exit(
          (BudgetBuf1."Dimension Value Code 1" <> BudgetBuf2."Dimension Value Code 1") or
          (BudgetBuf1."Dimension Value Code 2" <> BudgetBuf2."Dimension Value Code 2") or
          (BudgetBuf1."Dimension Value Code 3" <> BudgetBuf2."Dimension Value Code 3") or
          (BudgetBuf1."Dimension Value Code 4" <> BudgetBuf2."Dimension Value Code 4") or
          (BudgetBuf1."Dimension Value Code 5" <> BudgetBuf2."Dimension Value Code 5") or
          (BudgetBuf1."Dimension Value Code 6" <> BudgetBuf2."Dimension Value Code 6") or
          (BudgetBuf1."Dimension Value Code 7" <> BudgetBuf2."Dimension Value Code 7") or
          (BudgetBuf1."Dimension Value Code 8" <> BudgetBuf2."Dimension Value Code 8"));
    end;

    local procedure GetGLBudgetEntryDimFilter(DimensionCode: Code[20]): Text
    begin
        if DimensionCode = '' then
            exit;

        case DimensionCode of
            GLSetup."Global Dimension 1 Code":
                exit("G/L Budget Entry".GetFilter("Global Dimension 1 Code"));
            GLSetup."Global Dimension 2 Code":
                exit("G/L Budget Entry".GetFilter("Global Dimension 2 Code"));
            GLBudgetName."Budget Dimension 1 Code":
                exit("G/L Budget Entry".GetFilter("Budget Dimension 1 Code"));
            GLBudgetName."Budget Dimension 2 Code":
                exit("G/L Budget Entry".GetFilter("Budget Dimension 2 Code"));
            GLBudgetName."Budget Dimension 3 Code":
                exit("G/L Budget Entry".GetFilter("Budget Dimension 3 Code"));
            GLBudgetName."Budget Dimension 4 Code":
                exit("G/L Budget Entry".GetFilter("Budget Dimension 4 Code"));
        end;
    end;

    local procedure GetDimValueCount(DimCode: Code[20]; DimFilter: Text): Integer
    var
        DimValue: Record "Dimension Value";
    begin
        DimValue.SetRange("Dimension Code", DimCode);
        DimValue.SetFilter("Dimension Value Type", '%1|%2',
          DimValue."Dimension Value Type"::Standard, DimValue."Dimension Value Type"::"Begin-Total");
        DimValue.SetFilter(Code, DimFilter);
        exit(DimValue.Count);
    end;

    local procedure EnterRangeOfValues(var DimensionRange: array[2, 8] of Integer; var BusUnit: Record "Business Unit"; var DimValue: Record "Dimension Value")
    begin
        RowNo := RowNo + 200; // Move way below the budget
        for i := 1 to NoOfDimensions do
            EnterRangeForDimension(DimensionRange, BusUnit, DimValue);
    end;

    local procedure EnterRangeForDimension(var DimensionRange: array[2, 8] of Integer; var BusUnit: Record "Business Unit"; var DimValue: Record "Dimension Value")
    var
        RecRef: RecordRef;
        DimFilter: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnterRangeForDimension(DimensionRange, BusUnit, DimValue, RowNo, IsHandled, i, "G/L Budget Entry", TempExcelBuf);
        if IsHandled then
            exit;

        if i = BusUnitDimIndex then begin
            RecRef.GetTable(BusUnit);
            EnterRange(BusUnit, DimensionRange, BusUnit.FieldNo(Code));
        end else begin
            DimValue.SetRange("Dimension Code", ColumnDimCode[i]);
            DimValue.SetFilter("Dimension Value Type", '%1|%2',
              DimValue."Dimension Value Type"::Standard, DimValue."Dimension Value Type"::"Begin-Total");
            DimFilter := GetGLBudgetEntryDimFilter(ColumnDimCode[i]);
            DimValue.SetRange(Code);
            if DimFilter <> '' then
                DimValue.SetFilter(Code, DimFilter);
            EnterRange(DimValue, DimensionRange, DimValue.FieldNo(Code));
        end;
    end;

    local procedure EnterRange(RecVariant: Variant; var DimensionRange: array[2, 8] of Integer; FieldID: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(RecVariant);
        if RecRef.FindSet() then begin
            DimensionRange[1, i] := RowNo;
            repeat
                FieldRef := RecRef.Field(FieldID);
                EnterCell(RowNo, 1, Format(FieldRef.Value), false, false, '', TempExcelBuf."Cell Type"::Text);
                RowNo := RowNo + 1;
            until RecRef.Next() = 0;
            DimensionRange[2, i] := RowNo - 1;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEnterDimFilter(var GLBudgetEntry: Record "G/L Budget Entry"; var ExcelBuffer: Record "Excel Buffer"; var RowNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFilterGLAccount(var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnterRangeForDimension(var DimensionRange: array[2, 8] of Integer; var BusUnit: Record "Business Unit"; var DimValue: Record "Dimension Value"; var RowNo: Integer; var IsHandled: Boolean; i: Integer; var GLBudgetEntry: Record "G/L Budget Entry"; var ExcelBuffer: Record "Excel Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempPeriods(var TempPeriod: Record Date temporary; StartDate: Date; NoOfPeriods: Integer; PeriodLength: DateFormula; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDimValueCode(DimCode: Code[20]; var Result: Code[20]; var IsHandled: Boolean; var GLBudgetEntry: Record "G/L Budget Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnterDimValueOnAfterCalcShouldGetDimValueCode(DimValueCode: Code[20]; ColDimIndex: Integer; BusUnitDimIndex: Integer; var ShouldGetDimValueCode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGLBudgetEntryPreDataItemOnAfterSelectedDimSetFilters(var ColumnDimCode: array[8] of Code[20]; var i: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGLBudgetEntryOnPostDataItemOnBeforeSetHeaderDim(HeaderRowNo: Integer; ColNo: Integer; i: Integer; var ExcelBuffer: Record "Excel Buffer" temporary; var IsHandled: Boolean)
    begin
    end;
}

