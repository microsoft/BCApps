// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using System.IO;
using System.Utilities;

report 7132 "Export Item Budget to Excel"
{
    Caption = 'Export Item Budget to Excel';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                Window: Dialog;
                ClientFileName: Text;
                RecNo: Integer;
                TotalRecNo: Integer;
                RowNo: Integer;
                ColumnNo: Integer;
            begin
                if DoUpdateExistingWorksheet then begin
                    if ServerFileName = '' then
                        ServerFileName := FileMgt.UploadFile(Text002, ExcelFileExtensionTok);
                    if ServerFileName = '' then
                        exit;
                    ClientFileName := FileMgt.GetFileName(ServerFileName);
                    SheetName := TempExcelBuffer.SelectSheetsName(ServerFileName);
                    if SheetName = '' then
                        exit;
                end;

                Window.Open(
                  Text000 +
                  '@1@@@@@@@@@@@@@@@@@@@@@\');

                TempExcelBuffer.DeleteAll();
                Clear(TempExcelBuffer);

                ItemBudgetName.Get(AnalysisArea, BudgetName);
                GLSetup.Get();

                if DateFilter = '' then
                    Error(Text010, Text003);

                if FindLine('-') then
                    repeat
                        TotalRecNo := TotalRecNo + 1;
                    until NextLine(1) = 0;

                RowNo := 1;
                EnterCell(RowNo, 1, Text001, false, false, true, '', TempExcelBuffer."Cell Type"::Text);
                EnterCell(RowNo, 2, '', false, false, true, '', TempExcelBuffer."Cell Type"::Text);

                RowNo := RowNo + 1;
                EnterFilterInCell(RowNo, BudgetName, ItemBudgetName.TableCaption());

                if GlobalDim1Filter <> '' then begin
                    RowNo := RowNo + 1;
                    Dim.Get(GLSetup."Global Dimension 1 Code");
                    EnterFilterInCell(RowNo, GlobalDim1Filter, Dim."Filter Caption");
                end;

                if GlobalDim2Filter <> '' then begin
                    RowNo := RowNo + 1;
                    Dim.Get(GLSetup."Global Dimension 2 Code");
                    EnterFilterInCell(RowNo, GlobalDim2Filter, Dim."Filter Caption");
                end;

                if BudgetDim1Filter <> '' then begin
                    RowNo := RowNo + 1;
                    Dim.Get(ItemBudgetName."Budget Dimension 1 Code");
                    EnterFilterInCell(RowNo, BudgetDim1Filter, Dim."Filter Caption");
                end;

                if BudgetDim2Filter <> '' then begin
                    RowNo := RowNo + 1;
                    Dim.Get(ItemBudgetName."Budget Dimension 2 Code");
                    EnterFilterInCell(RowNo, BudgetDim2Filter, Dim."Filter Caption");
                end;

                if BudgetDim3Filter <> '' then begin
                    RowNo := RowNo + 1;
                    Dim.Get(ItemBudgetName."Budget Dimension 3 Code");
                    EnterFilterInCell(RowNo, BudgetDim3Filter, Dim."Filter Caption");
                end;

                if ItemFilter <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(RowNo, ItemFilter, Text004);
                end;

                if DateFilter <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(RowNo, DateFilter, Text003);
                end;

                if SourceNoFilter <> '' then begin
                    RowNo := RowNo + 1;
                    if SourceTypeFilter = SourceTypeFilter::Customer then
                        EnterFilterInCell(RowNo, SourceNoFilter, Text005)
                    else
                        EnterFilterInCell(RowNo, SourceNoFilter, Text006);
                end;

                RowNo := RowNo + 2;
                EnterFilterInCell(RowNo, LineDimCode, Text008);

                RowNo := RowNo + 1;
                EnterFilterInCell(RowNo, ColumnDimCode, Text009);

                RowNo := RowNo + 1;
                case ValueType of
                    ValueType::"Sales Amount":
                        ShowValueAsText := Text012;
                    ValueType::"Cost Amount":
                        if AnalysisArea = AnalysisArea::Sales then
                            ShowValueAsText := Text014
                        else
                            ShowValueAsText := Text013;
                    ValueType::Quantity:
                        ShowValueAsText := Text015;
                end;
                EnterFilterInCell(RowNo, ShowValueAsText, Text011);

                RowNo := RowNo + 2;
                if FindLine('-') then begin
                    if FindColumn('-') then begin
                        ColumnNo := 1;
                        EnterCell(RowNo, ColumnNo, Text007, false, true, false, '', TempExcelBuffer."Cell Type"::Text);
                        repeat
                            ColumnNo := ColumnNo + 1;
                            EnterCell(RowNo, ColumnNo, ColumnDimCodeBuffer.Code, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                        until NextColumn(1) = 0;
                    end;
                    repeat
                        RecNo := RecNo + 1;
                        Window.Update(1, Round(RecNo / TotalRecNo * 10000, 1));
                        RowNo := RowNo + 1;
                        ColumnNo := 1;
                        EnterCell(
                          RowNo, ColumnNo, LineDimCodeBuffer.Code, LineDimCodeBuffer."Show in Bold", false, false, '', TempExcelBuffer."Cell Type"::Text);
                        if FindColumn('-') then
                            repeat
                                ColumnNo := ColumnNo + 1;
                                ColumnValue :=
                                  ItemBudgetManagement.CalculateAmount(
                                    ValueType, true,
                                    ItemStatisticsBuffer, ItemBudgetName,
                                    ItemFilter, SourceTypeFilter, SourceNoFilter, DateFilter,
                                    GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter,
                                    LineDimType, LineDimCodeBuffer, ColumnDimType, ColumnDimCodeBuffer);
                                EnterCell(
                                  RowNo,
                                  ColumnNo,
                                  MatrixMgt.FormatAmount(ColumnValue, RoundingFactor, false),
                                  LineDimCodeBuffer."Show in Bold",
                                  false,
                                  false,
                                  '',
                                  TempExcelBuffer."Cell Type"::Number)
                            until NextColumn(1) = 0;
                    until NextLine(1) = 0;
                end;
                Window.Close();

                if DoUpdateExistingWorksheet then begin
                    TempExcelBuffer.UpdateBookExcel(ServerFileName, SheetName, false);
                    TempExcelBuffer.WriteSheet('', CompanyName, UserId);
                    TempExcelBuffer.CloseBook();
                    if not TestMode then
                        TempExcelBuffer.OpenExcelWithName(ClientFileName);
                end else begin
                    TempExcelBuffer.CreateBook(ServerFileName, TempExcelBuffer.GetExcelReference(10));
                    TempExcelBuffer.WriteSheet(
                      PadStr(StrSubstNo('%1 %2', ItemBudgetName.Name, ItemBudgetName.Description), 30),
                      CompanyName, UserId);
                    TempExcelBuffer.CloseBook();
                    if not TestMode then
                        TempExcelBuffer.OpenExcel();
                end;
            end;
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

    labels
    {
    }

    var
        ItemBudgetName: Record "Item Budget Name";
        Dim: Record Dimension;
        LineDimCodeBuffer: Record "Dimension Code Buffer";
        ColumnDimCodeBuffer: Record "Dimension Code Buffer";
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        ItemBudgetManagement: Codeunit "Item Budget Management";
        MatrixMgt: Codeunit "Matrix Management";
        FileMgt: Codeunit "File Management";
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        DateFilter: Text;
        InternalDateFilter: Text;
        ShowValueAsText: Text[30];
        ServerFileName: Text;
        SheetName: Text[250];
        BudgetName: Code[10];
        GlobalDim1Filter: Text;
        GlobalDim2Filter: Text;
        BudgetDim1Filter: Text;
        BudgetDim2Filter: Text;
        BudgetDim3Filter: Text;
        SourceNoFilter: Text;
        ItemFilter: Text;
        ColumnValue: Decimal;
        AnalysisArea: Enum "Analysis Area Type";
        ValueType: Enum "Item Analysis Value Type";
        SourceTypeFilter: Enum "Analysis Source Type";
        PeriodType: Enum "Analysis Period Type";
        LineDimType: Enum "Item Budget Dimension Type";
        ColumnDimType: Enum "Item Budget Dimension Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        PeriodInitialized: Boolean;
        DoUpdateExistingWorksheet: Boolean;
        TestMode: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Analyzing Data...\\';
        Text001: Label 'Filters';
        Text002: Label 'Update Workbook';
        Text003: Label 'Date Filter';
        Text004: Label 'Item Filter';
        Text005: Label 'Customer Filter';
        Text006: Label 'Vendor Filter';
        Text007: Label 'Table Data';
        Text008: Label 'Show as Lines';
        Text009: Label 'Show as Columns';
#pragma warning disable AA0470
        Text010: Label '%1 must not be blank.';
#pragma warning restore AA0470
        Text011: Label 'Show Value as';
        Text012: Label 'Sales Amount';
        Text013: Label 'Cost Amount';
        Text014: Label 'COGS Amount';
        Text015: Label 'Quantity';
#pragma warning restore AA0074
        ExcelFileExtensionTok: Label '.xlsx', Locked = true;

    procedure SetParameters(NewAnalysisArea: Enum "Analysis Area Type"; NewBudgName: Code[10]; NewValueType: Enum "Item Analysis Value Type"; NewGlobalDim1Filter: Text; NewGlobalDim2Filter: Text; NewBudgDim1Filter: Text; NewBudgDim2Filter: Text; NewBudgDim3Filter: Text; NewDateFilter: Text; NewSourceTypeFilter: Enum "Analysis Source Type"; NewSourceNoFilter: Text; NewItemFilter: Text; NewInternalDateFilter: Text; NewPeriodInitialized: Boolean; NewPeriodType: Enum "Analysis Period Type"; NewLineDimType: Enum "Item Budget Dimension Type"; NewColumnDimType: Enum "Item Budget Dimension Type"; NewLineDimCode: Text[30]; NewColumnDimCode: Text[30]; NewRoundingFactor: Enum "Analysis Rounding Factor")
    begin
        AnalysisArea := NewAnalysisArea;
        BudgetName := NewBudgName;
        ValueType := NewValueType;
        GlobalDim1Filter := NewGlobalDim1Filter;
        GlobalDim2Filter := NewGlobalDim2Filter;
        BudgetDim1Filter := NewBudgDim1Filter;
        BudgetDim2Filter := NewBudgDim2Filter;
        BudgetDim3Filter := NewBudgDim3Filter;
        DateFilter := NewDateFilter;
        ItemFilter := NewItemFilter;
        SourceTypeFilter := NewSourceTypeFilter;
        SourceNoFilter := NewSourceNoFilter;
        InternalDateFilter := NewInternalDateFilter;
        PeriodInitialized := NewPeriodInitialized;
        PeriodType := NewPeriodType;
        LineDimType := NewLineDimType;
        ColumnDimType := NewColumnDimType;
        LineDimCode := NewLineDimCode;
        ColumnDimCode := NewColumnDimCode;
        RoundingFactor := NewRoundingFactor;
    end;

    local procedure EnterFilterInCell(RowNo: Integer; "Filter": Text; FieldName: Text[100])
    begin
        EnterCell(RowNo, 1, FieldName, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, 2, CopyStr(Filter, 1, 250), false, false, false, '', TempExcelBuffer."Cell Type"::Text);
    end;

    local procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValue: Text[250]; Bold: Boolean; Italic: Boolean; UnderLine: Boolean; NumberFormat: Text[30]; CellType: Option)
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        TempExcelBuffer."Cell Value as Text" := CellValue;
        TempExcelBuffer.Formula := '';
        TempExcelBuffer.Bold := Bold;
        TempExcelBuffer.Italic := Italic;
        TempExcelBuffer.Underline := UnderLine;
        TempExcelBuffer.NumberFormat := NumberFormat;
        TempExcelBuffer."Cell Type" := CellType;
        TempExcelBuffer.Insert();
    end;

    local procedure FindLine(Which: Text[1024]): Boolean
    begin
        exit(
          ItemBudgetManagement.FindRecord(
            ItemBudgetName, LineDimType, LineDimCodeBuffer, Which,
            ItemFilter, SourceNoFilter, PeriodType, DateFilter, PeriodInitialized, InternalDateFilter,
            GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter));
    end;

    local procedure NextLine(Steps: Integer): Integer
    begin
        exit(
          ItemBudgetManagement.NextRecord(
            ItemBudgetName, LineDimType, LineDimCodeBuffer, Steps,
            ItemFilter, SourceNoFilter, PeriodType, DateFilter,
            GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter));
    end;

    local procedure FindColumn(Which: Text[1024]): Boolean
    begin
        exit(
          ItemBudgetManagement.FindRecord(
            ItemBudgetName, ColumnDimType, ColumnDimCodeBuffer, Which,
            ItemFilter, SourceNoFilter, PeriodType, DateFilter, PeriodInitialized, InternalDateFilter,
            GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter));
    end;

    local procedure NextColumn(Steps: Integer): Integer
    begin
        exit(
          ItemBudgetManagement.NextRecord(
            ItemBudgetName, ColumnDimType, ColumnDimCodeBuffer, Steps,
            ItemFilter, SourceNoFilter, PeriodType, DateFilter,
            GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter));
    end;

    procedure SetUpdateExistingWorksheet(UpdateExistingWorksheet: Boolean)
    begin
        DoUpdateExistingWorksheet := UpdateExistingWorksheet;
    end;

    procedure SetFileNameSilent(NewFileName: Text)
    begin
        ServerFileName := NewFileName;
    end;

    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;
}

