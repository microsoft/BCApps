// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.VAT.Reporting;
using System.IO;

report 11605 "Export BAS Setup to Excel"
{
    Caption = 'Export BAS Setup to Excel';
    ProcessingOnly = true;

    dataset
    {
        dataitem("BAS Setup"; "BAS Setup")
        {
            CalcFields = "Field Label No.", "Field Description";

            trigger OnAfterGetRecord()
            begin
                RowNo := RowNo + 1;
                EnterCell(RowNo, 1, "Row No.", false, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(RowNo, 2, "Field Label No.", false, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(RowNo, 3, "Field Description", false, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(RowNo, 4, Format(Type), false, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(RowNo, 5, Format("Amount Type"), false, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(RowNo, 6, "GST Bus. Posting Group", false, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(RowNo, 7, "GST Prod. Posting Group", false, false, '', ExcelBuf."Cell Type"::Text);
                BASUpdate.InitializeRequest(BASCalcSheet, false, Selection, PeriodSelection, ExcludeClosingEntries);
                if not BASCalcSheet.Exported then
                    BASUpdate.CalcLineTotal("BAS Setup", ColumnValue, 0)
                else
                    BASUpdate.CalcExportLineTotal("BAS Setup", ColumnValue, 0, DocumentNo, VersionNo);
                if "Print with" = "Print with"::"Opposite Sign" then
                    ColumnValue := -ColumnValue;
                if ColumnValue = 0 then
                    EnterCell(RowNo, 8, '', false, false, '', ExcelBuf."Cell Type"::Text)
                else
                    EnterCell(RowNo, 8, Format(ColumnValue), false, false, '', ExcelBuf."Cell Type"::Number);
            end;

            trigger OnPostDataItem()
            begin
                ExcelBuf.CreateBook('', ExcelBuf.GetExcelReference(11600));
                ExcelBuf.CreateRangeName(ExcelBuf.GetExcelReference(8), 1, HeaderRowNo + 1);
                ExcelBuf.WriteSheet(PadStr(StrSubstNo('%1', "Setup Name"), 30), CompanyName, UserId);
                ExcelBuf.CloseBook();
                ExcelBuf.OpenExcel();
            end;

            trigger OnPreDataItem()
            begin
                ExcelBuf.DeleteAll();
                RowNo := 1;
                EnterCell(RowNo, 1, Text006, true, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(RowNo, 2, '', false, false, '', ExcelBuf."Cell Type"::Text);
                RowNo := RowNo + 1;
                EnterFilterInCell(GetFilter("Setup Name"), FieldCaption("Setup Name"));
                EnterFilterInCell(Format(Selection), 'Include GST Entries');
                EnterFilterInCell(Format(PeriodSelection), 'Include GST Entries');
                EnterFilterInCell(Format(ExcludeClosingEntries), 'ExcludeClosingEntries');

                RowNo := RowNo + 2;
                HeaderRowNo := RowNo;
                EnterCell(HeaderRowNo, 1, FieldCaption("Row No."), true, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(HeaderRowNo, 2, FieldCaption("Field Label No."), true, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(HeaderRowNo, 3, FieldCaption("Field Description"), true, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(HeaderRowNo, 4, FieldCaption(Type), true, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(HeaderRowNo, 5, FieldCaption("Amount Type"), true, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(HeaderRowNo, 6, FieldCaption("GST Bus. Posting Group"), true, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(HeaderRowNo, 7, FieldCaption("GST Prod. Posting Group"), true, false, '', ExcelBuf."Cell Type"::Text);
                EnterCell(HeaderRowNo, 8, 'Column Amount', true, false, '', ExcelBuf."Cell Type"::Text);

                SetFilter(
                  "Date Filter",
                  BASUpdate.GetPeriodFilter(PeriodSelection, BASCalcSheet.A3, BASCalcSheet.A4));
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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

    trigger OnPreReport()
    begin
        ExcelBuf.LockTable();
    end;

    var
        ExcelBuf: Record "Excel Buffer" temporary;
        BASUpdate: Report "BAS-Update";
        BASCalcSheet: Record "BAS Calculation Sheet";
        RowNo: Integer;
        HeaderRowNo: Integer;
        ExcludeClosingEntries: Boolean;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        ColumnValue: Decimal;
        Text006: Label 'Export Filters';
        DocumentNo: Code[11];
        VersionNo: Integer;

    local procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValue: Text[250]; Bold: Boolean; UnderLine: Boolean; NumberFormat: Text[30]; CellType: Option)
    begin
        ExcelBuf.Init();
        ExcelBuf.Validate("Row No.", RowNo);
        ExcelBuf.Validate("Column No.", ColumnNo);
        ExcelBuf."Cell Value as Text" := CellValue;
        ExcelBuf.Formula := '';
        ExcelBuf.Bold := Bold;
        ExcelBuf.Underline := UnderLine;
        ExcelBuf.NumberFormat := NumberFormat;
        ExcelBuf."Cell Type" := CellType;
        ExcelBuf.Insert();
    end;

    [Scope('OnPrem')]
    procedure SetValues(var NewBASCalcSheet: Record "BAS Calculation Sheet"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewExcludeClosingEntries: Boolean; NewDocumentNo: Code[11]; NewVersionNo: Integer)
    begin
        BASCalcSheet.Copy(NewBASCalcSheet);
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        ExcludeClosingEntries := NewExcludeClosingEntries;
        DocumentNo := NewDocumentNo;
        VersionNo := NewVersionNo;
    end;

    local procedure EnterFilterInCell("Filter": Text[250]; FieldName: Text[100])
    begin
        if Filter <> '' then begin
            RowNo := RowNo + 1;
            EnterCell(RowNo, 2, FieldName, true, false, '', ExcelBuf."Cell Type"::Text);
            EnterCell(RowNo, 3, Filter, false, false, '', ExcelBuf."Cell Type"::Text);
        end;
    end;
}

