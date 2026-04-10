// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using System.IO;
using System.Utilities;

report 1142 "Export Cost Budget to Excel"
{
    Caption = 'Export Cost Budget to Excel';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Cost Budget Entry"; "Cost Budget Entry")
        {

            trigger OnAfterGetRecord()
            begin
                Clear(TempCostBudgetBuf1);
                TempCostBudgetBuf1."Cost Type No." := "Cost Type No.";
                TempCostBudgetBuf1."Budget Name" := "Budget Name";
                TempCostBudgetBuf1.Date := CalcPeriodStart(Date);
                TempCostBudgetBuf1."Cost Center Code" := "Cost Center Code";
                TempCostBudgetBuf1."Cost Object Code" := "Cost Object Code";
                TempCostBudgetBuf1.Amount := Amount;

                TempCostBudgetBuf2 := TempCostBudgetBuf1;
                if TempCostBudgetBuf2.Find() then begin
                    TempCostBudgetBuf2.Amount := TempCostBudgetBuf2.Amount + TempCostBudgetBuf1.Amount;
                    TempCostBudgetBuf2.Modify();
                end else
                    TempCostBudgetBuf2.Insert();
            end;

            trigger OnPostDataItem()
            var
                CostType: Record "Cost Type";
                Window: Dialog;
                RecNo: Integer;
                TotalRecNo: Integer;
                LastBudgetRowNo: Integer;
            begin
                Window.Open(
                  Text005 +
                  '@1@@@@@@@@@@@@@@@@@@@@@@@@@\');
                Window.Update(1, 0);
                TotalRecNo := CostType.Count();
                RecNo := 0;
                CostBudgetName.Init();

                RowNo := 1;
                EnterCell(RowNo, 1, Text006, false, true, '', TempExcelBuffer."Cell Type"::Text);
                EnterCell(RowNo, 2, '', false, true, '', TempExcelBuffer."Cell Type"::Text);
                EnterFilterInCell(GetFilter("Budget Name"), FieldCaption("Budget Name"));
                EnterFilterInCell(GetFilter("Cost Center Code"), FieldCaption("Cost Center Code"));
                EnterFilterInCell(GetFilter("Cost Object Code"), FieldCaption("Cost Object Code"));

                CostAccSetup.Get();

                RowNo := RowNo + 2;
                HeaderRowNo := RowNo;
                EnterCell(HeaderRowNo, 1, FieldCaption("Cost Type No."), false, true, '', TempExcelBuffer."Cell Type"::Text);
                EnterCell(HeaderRowNo, 2, CostType.FieldCaption(Name), false, true, '', TempExcelBuffer."Cell Type"::Text);
                EnterCell(HeaderRowNo, 3, CostType.FieldCaption("Cost Center Code"), false, true, '', TempExcelBuffer."Cell Type"::Text);
                EnterCell(HeaderRowNo, 4, CostType.FieldCaption("Cost Object Code"), false, true, '', TempExcelBuffer."Cell Type"::Text);
                i := 0;
                ColNo := 4;
                if TempPeriod.Find('-') then
                    repeat
                        ColNo := ColNo + 1;
                        EnterCell(HeaderRowNo, ColNo, Format(TempPeriod."Period Start"), false, true, '', TempExcelBuffer."Cell Type"::Date);
                    until TempPeriod.Next() = 0;

                CopyFilter("Cost Type No.", CostType."No.");
                if CostType.Find('-') then
                    repeat
                        RecNo := RecNo + 1;
                        Window.Update(1, Round(RecNo / TotalRecNo * 10000, 1));
                        RowNo := RowNo + 1;
                        EnterCostType(RowNo, CostType);
                        if (CostType.Totaling = '') or (not IncludeTotalingFormulas) then begin
                            TempCostBudgetBuf2.SetRange("Cost Type No.", CostType."No.");
                            if TempCostBudgetBuf2.Find('-') then begin
                                TempCostBudgetBuf1 := TempCostBudgetBuf2;
                                EnterCCCO(RowNo, CostType);
                                if TempPeriod.Find('-') then
                                    repeat
                                        if (TempCostBudgetBuf2."Cost Object Code" <> TempCostBudgetBuf1."Cost Object Code") or
                                           (TempCostBudgetBuf2."Cost Center Code" <> TempCostBudgetBuf1."Cost Center Code")
                                        then begin
                                            RowNo := RowNo + 1;
                                            EnterCostType(RowNo, CostType);
                                            EnterCCCO(RowNo, CostType);
                                            TempCostBudgetBuf1 := TempCostBudgetBuf2;
                                        end;
                                        TempPeriod.Get(0, TempCostBudgetBuf2.Date);
                                        EnterCell(
                                          RowNo, 4 + TempPeriod."Period No.",
                                          MatrixMgt.FormatAmount(TempCostBudgetBuf2.Amount, RoundingFactor, false),
                                          CostType.Type <> CostType.Type::"Cost Type",
                                          false, '', TempExcelBuffer."Cell Type"::Number);
                                        TempPeriod.Next();
                                    until TempCostBudgetBuf2.Next() = 0;
                            end else
                                Clear(TempCostBudgetBuf2);
                        end else
                            if TempPeriod.Find('-') then
                                repeat
                                    EnterFormula(
                                      RowNo, 4 + TempPeriod."Period No.",
                                      CostType.Totaling,
                                      CostType.Type <> CostType.Type::"Cost Type", false);
                                until TempPeriod.Next() = 0;
                    until CostType.Next() = 0;
                if IncludeTotalingFormulas then
                    HasFormulaError := TempExcelBuffer.ExportBudgetFilterToFormula(TempExcelBuffer);
                Window.Close();
                LastBudgetRowNo := RowNo;

                RowNo := RowNo + 200; // Move way below the budget

                if HasFormulaError then
                    if not Confirm(StrSubstNo(Text007, TempExcelBuffer.GetExcelReference(7))) then
                        CurrReport.Break();

                TempExcelBuffer.CreateBook(ServerFileName, TempExcelBuffer.GetExcelReference(10));
                TempExcelBuffer.SetCurrent(HeaderRowNo + 1, 1);
                TempExcelBuffer.StartRange();
                TempExcelBuffer.SetCurrent(LastBudgetRowNo, 1);
                TempExcelBuffer.EndRange();
                TempExcelBuffer.CreateRange(TempExcelBuffer.GetExcelReference(11));
                if TempPeriod.Find('-') then
                    repeat
                        TempExcelBuffer.SetCurrent(HeaderRowNo + 1, 4 + TempPeriod."Period No.");
                        TempExcelBuffer.StartRange();
                        TempExcelBuffer.SetCurrent(LastBudgetRowNo, 4 + TempPeriod."Period No.");
                        TempExcelBuffer.EndRange();
                        TempExcelBuffer.CreateRange(TempExcelBuffer.GetExcelReference(9) + '_' + Format(TempPeriod."Period No."));
                    until TempPeriod.Next() = 0;

                TempExcelBuffer.WriteSheet(PadStr(CostBudgetName.Name, 30), CompanyName, UserId);
                TempExcelBuffer.CloseBook();
                TempExcelBuffer.OpenExcel();
            end;

            trigger OnPreDataItem()
            begin
                if GetRangeMin("Budget Name") <> GetRangeMax("Budget Name") then
                    Error(Text001);

                if (StartDate = 0D) or
                   (NoOfPeriods = 0) or
                   (Format(PeriodLength) = '')
                then
                    Error(Text002);

                for i := 1 to NoOfPeriods do begin
                    if i = 1 then
                        TempPeriod."Period Start" := StartDate
                    else
                        TempPeriod."Period Start" := CalcDate(PeriodLength, TempPeriod."Period Start");
                    TempPeriod."Period End" := CalcDate(PeriodLength, TempPeriod."Period Start");
                    TempPeriod."Period End" := CalcDate('<-1D>', TempPeriod."Period End");
                    TempPeriod."Period No." := i;
                    TempPeriod.Insert();
                end;
                SetRange(Date, StartDate, TempPeriod."Period End");
                TempCostBudgetBuf2.DeleteAll();
                TempExcelBuffer.DeleteAll();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the first date to be included in the budget to be exported to Excel.';
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'No. of Periods';
                        ToolTip = 'Specifies the number of accounting periods to be exported to Excel.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the length of the accounting periods for the budget to be exported to Excel.';
                    }
                    field(IncludeTotalingFormulas; IncludeTotalingFormulas)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Include Totalling Formulas';
                        ToolTip = 'Specifies if you want sum formulas to be created in Excel based on the totaling fields used in the Chart of Cost Types window.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        TempPeriod: Record Date temporary;
        TempCostBudgetBuf1: Record "Cost Budget Buffer" temporary;
        TempCostBudgetBuf2: Record "Cost Budget Buffer" temporary;
        CostAccSetup: Record "Cost Accounting Setup";
        CostBudgetName: Record "Cost Budget Name";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        MatrixMgt: Codeunit "Matrix Management";
        PeriodLength: DateFormula;
        ServerFileName: Text;
        StartDate: Date;
        RoundingFactor: Enum "Analysis Rounding Factor";
        NoOfPeriods: Integer;
        i: Integer;
        RowNo: Integer;
        ColNo: Integer;
        HeaderRowNo: Integer;
        IncludeTotalingFormulas: Boolean;
        HasFormulaError: Boolean;

#pragma warning disable AA0074
        Text001: Label 'You can only export one budget at a time.';
        Text002: Label 'You must specify the starting date, number of periods, and period length.';
        Text005: Label 'Analyzing Data...\\';
        Text006: Label 'Export Filters';
#pragma warning disable AA0470
        Text007: Label 'Some filters cannot be converted into Excel formulas. You must verify %1 errors in the Excel worksheet. Do you want to create the Excel worksheet?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CalcPeriodStart(EntryDate: Date): Date
    begin
        TempPeriod."Period Start" := EntryDate;
        TempPeriod.Find('=<');
        exit(TempPeriod."Period Start");
    end;

    local procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValue: Text[250]; Bold: Boolean; UnderLine: Boolean; NumberFormat: Text[30]; CellType: Option)
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        TempExcelBuffer."Cell Value as Text" := CellValue;
        TempExcelBuffer.Formula := '';
        TempExcelBuffer.Bold := Bold;
        TempExcelBuffer.Underline := UnderLine;
        TempExcelBuffer.NumberFormat := NumberFormat;
        TempExcelBuffer."Cell Type" := CellType;
        TempExcelBuffer.Insert();
    end;

    local procedure EnterFilterInCell("Filter": Text[250]; FieldName: Text[100])
    begin
        if Filter <> '' then begin
            RowNo := RowNo + 1;
            EnterCell(RowNo, 1, FieldName, false, false, '', TempExcelBuffer."Cell Type"::Text);
            EnterCell(RowNo, 2, Filter, false, false, '', TempExcelBuffer."Cell Type"::Text);
        end;
    end;

    local procedure EnterFormula(RowNo: Integer; ColumnNo: Integer; CellValue: Text[250]; Bold: Boolean; UnderLine: Boolean)
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        TempExcelBuffer."Cell Value as Text" := '';
        TempExcelBuffer.Formula := CellValue; // is converted to formula later.
        TempExcelBuffer.Bold := Bold;
        TempExcelBuffer.Underline := UnderLine;
        TempExcelBuffer.Insert();
    end;

    local procedure EnterCCCO(RowNo: Integer; var CostType: Record "Cost Type")
    begin
        EnterCell(
          RowNo, 3,
          TempCostBudgetBuf2."Cost Center Code", CostType.Type <> CostType.Type::"Cost Type", false, '', TempExcelBuffer."Cell Type"::Text);
        EnterCell(
          RowNo, 4,
          TempCostBudgetBuf2."Cost Object Code", CostType.Type <> CostType.Type::"Cost Type", false, '', TempExcelBuffer."Cell Type"::Text);
    end;

    local procedure EnterCostType(RowNo: Integer; var CostType: Record "Cost Type")
    begin
        EnterCell(RowNo, 1, CostType."No.", CostType.Type <> CostType.Type::"Cost Type", false, '', TempExcelBuffer."Cell Type"::Text);
        EnterCell(
          RowNo, 2, CopyStr(CopyStr(PadStr(' ', 100), 1, 2 * CostType.Indentation + 1) + CostType.Name, 2),
          CostType.Type <> CostType.Type::"Cost Type", false, '', TempExcelBuffer."Cell Type"::Text);
    end;

    procedure SetRoundingFactor(NewRoundingFactor: Enum "Analysis Rounding Factor")
    begin
        RoundingFactor := NewRoundingFactor;
    end;

    procedure SetFileNameSilent(NewFileName: Text)
    begin
        ServerFileName := NewFileName;
    end;
}

