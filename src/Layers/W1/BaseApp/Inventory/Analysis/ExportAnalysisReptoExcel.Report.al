// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;
using System.Utilities;

report 7113 "Export Analysis Rep. to Excel"
{
    Caption = 'Export Analysis Rep. to Excel';
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
                Window.Update(1, 0);
                TotalRecNo := AnalysisLine.Count();
                RecNo := 0;

                TempExcelBuffer.DeleteAll();
                Clear(TempExcelBuffer);

                AnalysisLineTemplate.Get(AnalysisLine."Analysis Area", AnalysisLine."Analysis Line Template Name");
                if AnalysisLineTemplate."Item Analysis View Code" <> '' then
                    ItemAnalysisView.Get(AnalysisLineTemplate."Analysis Area", AnalysisLineTemplate."Item Analysis View Code");
                GLSetup.Get();

                RowNo := 1;
                EnterCell(RowNo, 1, Text001, false, false, true, '', TempExcelBuffer."Cell Type"::Text);
                if AnalysisLine.GetFilter("Date Filter") <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(
                      RowNo,
                      AnalysisLine.GetFilter("Date Filter"),
                      AnalysisLine.FieldCaption("Date Filter"),
                      '',
                      TempExcelBuffer."Cell Type"::Text);
                end;
                if AnalysisLine.GetFilter("Item Budget Filter") <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(
                      RowNo,
                      AnalysisLine.GetFilter("Item Budget Filter"),
                      AnalysisLine.FieldCaption("Item Budget Filter"),
                      '',
                      TempExcelBuffer."Cell Type"::Text);
                end;
                if AnalysisLine.GetFilter("Dimension 1 Filter") <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(
                      RowNo,
                      AnalysisLine.GetFilter("Dimension 1 Filter"),
                      GetDimFilterCaption(1),
                      '',
                      TempExcelBuffer."Cell Type"::Text);
                end;
                if AnalysisLine.GetFilter("Dimension 2 Filter") <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(
                      RowNo,
                      AnalysisLine.GetFilter("Dimension 2 Filter"),
                      GetDimFilterCaption(2),
                      '',
                      TempExcelBuffer."Cell Type"::Text);
                end;
                if AnalysisLine.GetFilter("Dimension 3 Filter") <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(
                      RowNo,
                      AnalysisLine.GetFilter("Dimension 3 Filter"),
                      GetDimFilterCaption(3),
                      '',
                      TempExcelBuffer."Cell Type"::Text);
                end;

                RowNo := RowNo + 1;
                if GLSetup."LCY Code" <> '' then begin
                    RowNo := RowNo + 1;
                    EnterFilterInCell(
                      RowNo,
                      GLSetup."LCY Code",
                      Currency.TableCaption(),
                      '',
                      TempExcelBuffer."Cell Type"::Text);
                end;

                RowNo := RowNo + 1;
                AnalysisLine.SetFilter(Show, '<>%1', AnalysisLine.Show::No);
                if AnalysisLine.Find('-') then begin
                    if ColumnLayout.Find('-') then begin
                        RowNo := RowNo + 1;
                        ColumnNo := 1;
                        repeat
                            ColumnNo := ColumnNo + 1;
                            EnterCell(
                              RowNo,
                              ColumnNo,
                              ColumnLayout."Column Header",
                              false,
                              false,
                              false,
                              '',
                              TempExcelBuffer."Cell Type"::Text);
                        until ColumnLayout.Next() = 0;
                    end;
                    repeat
                        RecNo := RecNo + 1;
                        Window.Update(1, Round(RecNo / TotalRecNo * 10000, 1));
                        RowNo := RowNo + 1;
                        ColumnNo := 1;
                        EnterCell(
                          RowNo,
                          ColumnNo,
                          AnalysisLine.Description,
                          AnalysisLine.Bold,
                          AnalysisLine.Italic,
                          AnalysisLine.Underline,
                          '',
                          TempExcelBuffer."Cell Type"::Text);
                        if ColumnLayout.Find('-') then
                            repeat
                                ColumnValue := AnalysisReportManagement.CalcCell(AnalysisLine, ColumnLayout, false);
                                if AnalysisReportManagement.GetDivisionError() then
                                    ColumnValue := 0;
                                ColumnNo := ColumnNo + 1;
                                EnterCell(
                                  RowNo,
                                  ColumnNo,
                                  MatrixMgt.FormatAmount(ColumnValue, ColumnLayout."Rounding Factor", false),
                                  AnalysisLine.Bold,
                                  AnalysisLine.Italic,
                                  AnalysisLine.Underline,
                                  '',
                                  TempExcelBuffer."Cell Type"::Number)
                            until ColumnLayout.Next() = 0;
                    until AnalysisLine.Next() = 0;
                end;

                Window.Close();

                if DoUpdateExistingWorksheet then begin
                    TempExcelBuffer.UpdateBook(ServerFileName, SheetName);
                    TempExcelBuffer.WriteSheet('', CompanyName, UserId);
                    TempExcelBuffer.CloseBook();
                    if not TestMode then
                        TempExcelBuffer.OpenExcelWithName(ClientFileName);
                end else begin
                    TempExcelBuffer.CreateBook(ServerFileName, AnalysisTemplateName);
                    TempExcelBuffer.WriteSheet(AnalysisLine.Description, CompanyName, UserId);
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
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisLine: Record "Analysis Line";
        ColumnLayout: Record "Analysis Column";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        ItemAnalysisView: Record "Item Analysis View";
        Currency: Record Currency;
        AnalysisReportManagement: Codeunit "Analysis Report Management";
        MatrixMgt: Codeunit "Matrix Management";
        FileMgt: Codeunit "File Management";
        ColumnValue: Decimal;
        ServerFileName: Text;
        SheetName: Text[250];
        AnalysisTemplateName: Code[10];
        DoUpdateExistingWorksheet: Boolean;
        TestMode: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Analyzing Data...\\';
        Text001: Label 'Filters';
        Text002: Label 'Update Workbook';
#pragma warning restore AA0074
        ExcelFileExtensionTok: Label '.xlsx', Locked = true;

    procedure SetOptions(var AnalysisLine2: Record "Analysis Line"; ColumnLayoutName2: Code[10]; NewAnalysisTemplateName: Code[10])
    begin
        AnalysisTemplateName := NewAnalysisTemplateName;
        AnalysisLine.CopyFilters(AnalysisLine2);
        AnalysisLine := AnalysisLine2;
        AnalysisLine.SetFilter("Analysis Line Template Name", NewAnalysisTemplateName);
        ColumnLayout.SetRange("Analysis Area", AnalysisLine2."Analysis Area");
        ColumnLayout.SetRange("Analysis Column Template", ColumnLayoutName2);
        ColumnLayout.SetFilter(Show, '<>%1', ColumnLayout.Show::Never);
    end;

    local procedure EnterFilterInCell(RowNo: Integer; "Filter": Text[250]; FieldName: Text[100]; Format: Text[30]; CellType: Option)
    begin
        if Filter <> '' then begin
            EnterCell(RowNo, 1, FieldName, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            EnterCell(RowNo, 2, Filter, false, false, false, Format, CellType);
        end;
    end;

    local procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValue: Text[250]; Bold: Boolean; Italic: Boolean; UnderLine: Boolean; Format: Text[30]; CellType: Option)
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        TempExcelBuffer."Cell Value as Text" := CellValue;
        TempExcelBuffer.Formula := '';
        TempExcelBuffer.Bold := Bold;
        TempExcelBuffer.Italic := Italic;
        TempExcelBuffer.Underline := UnderLine;
        TempExcelBuffer.NumberFormat := Format;
        TempExcelBuffer."Cell Type" := CellType;
        TempExcelBuffer.Insert();
    end;

    local procedure GetDimFilterCaption(DimFilterNo: Integer): Text[80]
    var
        Dimension: Record Dimension;
    begin
        if AnalysisLineTemplate."Item Analysis View Code" = '' then
            case DimFilterNo of
                1:
                    Dimension.Get(GLSetup."Global Dimension 1 Code");
                2:
                    Dimension.Get(GLSetup."Global Dimension 2 Code");
            end
        else
            case DimFilterNo of
                1:
                    Dimension.Get(ItemAnalysisView."Dimension 1 Code");
                2:
                    Dimension.Get(ItemAnalysisView."Dimension 2 Code");
                3:
                    Dimension.Get(ItemAnalysisView."Dimension 3 Code");
            end;
        exit(CopyStr(Dimension.GetMLFilterCaption(GlobalLanguage), 1, 80));
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

