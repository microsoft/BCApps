// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Utilities;
using System.Environment;
using System.IO;
using System.Utilities;

report 29 "Export Acc. Sched. to Excel"
{
    Caption = 'Export Acc. Sched. to Excel';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                AccSchedLine: Record "Acc. Schedule Line";
                TempSheetDefLine: Record "Sheet Definition Line" temporary;
                SheetDefAccSchMgtHandler: Codeunit SheetDefAccSchMgtHandler;
                ISheetDefinition: Interface ISheetDefinition;
                ClientFileName: Text;
            begin
                if DoUseExistingTemplate then
                    UploadExistingTemplate(ClientFileName);
                if (not DoUseExistingTemplate) and DoUpdateExistingWorksheet then
                    if not UploadClientFile(ClientFileName) then
                        exit;

                Window.Open(
                  Text000 +
                  '@1@@@@@@@@@@@@@@@@@@@@@\');
                Window.Update(1, 0);
                AccSchedLineSource.SetFilter(Show, '<>%1', AccSchedLineSource.Show::No);
                OnIntegerOnAfterGetRecordOnAfterAccSchedLineSetFilter(AccSchedLineSource);

                AccSchedName.Get(AccSchedLineSource.GetRangeMin("Schedule Name"));
                AccSchedManagement.CheckAnalysisView(AccSchedName.Name, ColumnLayout.GetRangeMin("Column Layout Name"), true);
                if AccSchedName."Analysis View Name" <> '' then
                    AnalysisView.Get(AccSchedName."Analysis View Name");
                GLSetup.Get();

                PopulateExcelBuffer(AccSchedLineSource);
                if DoUpdateExistingWorksheet or DoUseExistingTemplate then begin
                    TempExcelBuffer.UpdateBookExcel(ServerFileName, SheetName, false);
                    TempExcelBuffer.WriteSheet('', CompanyDisplayName, UserId);
                end else begin
                    SheetName := AccSchedName.Name;
                    TempExcelBuffer.CreateBook(ServerFileName, AccSchedName.Name);
                    TempExcelBuffer.WriteSheet(AccSchedName.Description, CompanyDisplayName, UserId);
                end;

                if SheetDefName.Name <> '' then begin
                    AccSchedManagement.CheckSheetAnalysisView(AccSchedName.Name, SheetDefName.Name);
                    AccSchedLine.Copy(AccSchedLineSource);

                    ISheetDefinition := SheetDefName."Sheet Type";
                    ISheetDefinition.PopulateLineBufferForReporting(SheetDefName, TempSheetDefLine);
                    if TempSheetDefLine.FindSet() then begin
                        BindSubscription(SheetDefAccSchMgtHandler);
                        SheetDefAccSchMgtHandler.SetSheetDefName(SheetDefName);
                        repeat
                            SheetDefAccSchMgtHandler.SetSheetDefLine(TempSheetDefLine);
                            AccSchedManagement.ForceRecalculate(true);
                            WriteSheetPerDefinition(AccSchedLine, TempSheetDefLine."Sheet Header");
                        until TempSheetDefLine.Next() = 0;
                        UnbindSubscription(SheetDefAccSchMgtHandler);
                    end;
                end;

                Window.Close();

                if DoUpdateExistingWorksheet or DoUseExistingTemplate then begin
                    TempExcelBuffer.CloseBook();
                    if not TestMode and not SaveToStream then
                        TempExcelBuffer.OpenExcelWithName(ClientFileName);
                end else begin
                    TempExcelBuffer.CloseBook();
                    if not TestMode and not SaveToStream then
                        TempExcelBuffer.OpenExcelWithName(FileMgt.CreateFileNameWithExtension(AccSchedName.Name, ExcelFileExtensionTok));
                end;
            end;
        }
    }

    trigger OnPreReport()
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName());
        CompanyDisplayName := Company."Display Name";
        if CompanyDisplayName = '' then
            CompanyDisplayName := Company.Name;
    end;

    var
        AccSchedName: Record "Acc. Schedule Name";
        AccSchedLineSource: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        AnalysisView: Record "Analysis View";
        Currency: Record Currency;
        FinancialReport: Record "Financial Report";
        SheetDefName: Record "Sheet Definition Name";
        AccSchedManagement: Codeunit AccSchedManagement;
        MatrixMgt: Codeunit "Matrix Management";
        FileMgt: Codeunit "File Management";
        UseAmtsInAddCurr: Boolean;
        ColumnValue: Decimal;
        CompanyDisplayName: Text;
        ExistingTemplateName: Text;
        ServerFileName: Text;
        SheetName: Text[250];
        SheetNo: Integer;
        DoUpdateExistingWorksheet: Boolean;
        DoUseExistingTemplate: Boolean;
        SaveToStream: Boolean;
        TestMode: Boolean;
        Window: Dialog;

#pragma warning disable AA0074
        Text000: Label 'Analyzing Data...\\';
        Text001: Label 'Filters';
        Text002: Label 'Update Workbook';
#pragma warning restore AA0074
        ExcelFileExtensionTok: Label '.xlsx', Locked = true;
        GenericSheetNameLbl: Label 'Sheet %1', Comment = '%1 = Sheet number';

    procedure SetOptions(var AccSchedLine2: Record "Acc. Schedule Line"; ColumnLayoutName2: Code[10]; UseAmtsInAddCurr2: Boolean)
    begin
        SetOptions(AccSchedLine2, ColumnLayoutName2, UseAmtsInAddCurr2, '');
    end;

    procedure SetOptions(var AccSchedLine2: Record "Acc. Schedule Line"; ColumnLayoutName2: Code[10]; UseAmtsInAddCurr2: Boolean; FinancialReportName: Code[10])
    begin
        SetOptions(AccSchedLine2, ColumnLayoutName2, UseAmtsInAddCurr2, FinancialReportName, '');
    end;

    procedure SetOptions(var AccSchedLine2: Record "Acc. Schedule Line"; ColumnLayoutName2: Code[10]; UseAmtsInAddCurr2: Boolean; FinancialReportName: Code[10]; SheetDefNameText: Code[10])
    begin
        AccSchedLineSource.CopyFilters(AccSchedLine2);
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName2);
        UseAmtsInAddCurr := UseAmtsInAddCurr2;
        if FinancialReportName <> '' then
            FinancialReport.Get(FinancialReportName);
        if SheetDefNameText <> '' then
            SheetDefName.Get(SheetDefNameText);
    end;

    local procedure WriteSheetPerDefinition(var AccSchedLine: Record "Acc. Schedule Line"; PerDefSheetName: Text)
    begin
        PopulateExcelBuffer(AccSchedLine);
        SheetNo += 1;
        if PerDefSheetName = '' then
            PerDefSheetName := StrSubstNo(GenericSheetNameLbl, SheetNo);
        TempExcelBuffer.SelectOrAddSheet(PerDefSheetName);
        TempExcelBuffer.WriteSheet(PerDefSheetName, CompanyDisplayName, UserId);
    end;

    local procedure PopulateExcelBuffer(var AccSchedLine: Record "Acc. Schedule Line")
    var
        RecNo, TotalRecNo : Integer;
        ColumnNo, RowNo : Integer;
        IntroductionParagraph, ClosingParagraph : Text;
    begin
        RecNo := 0;
        TotalRecNo := AccSchedLine.Count();

        TempExcelBuffer.DeleteAll();

        RowNo := 1;
        EnterCell(RowNo, 1, Text001, false, false, true, false, '', TempExcelBuffer."Cell Type"::Text);
        EnterFilterInCell(
          RowNo, AccSchedLine.GetFilter("Date Filter"), AccSchedLine.FieldCaption("Date Filter"),
          '', TempExcelBuffer."Cell Type"::Text);
        EnterFilterInCell(
          RowNo, AccSchedLine.GetFilter("G/L Budget Filter"), AccSchedLine.FieldCaption("G/L Budget Filter"),
          '', TempExcelBuffer."Cell Type"::Text);
        EnterFilterInCell(
          RowNo, AccSchedLine.GetFilter("Cost Budget Filter"), AccSchedLine.FieldCaption("Cost Budget Filter"),
          '', TempExcelBuffer."Cell Type"::Text);
        EnterFilterInCell(
          RowNo, AccSchedLine.GetFilter("Cost Center Filter"), AccSchedLine.FieldCaption("Cost Center Filter"),
          '', TempExcelBuffer."Cell Type"::Text);
        EnterFilterInCell(
          RowNo, AccSchedLine.GetFilter("Cost Object Filter"), AccSchedLine.FieldCaption("Cost Object Filter"),
          '', TempExcelBuffer."Cell Type"::Text);
        EnterFilterInCell(
          RowNo, AccSchedLine.GetFilter("Cash Flow Forecast Filter"), AccSchedLine.FieldCaption("Cash Flow Forecast Filter"),
          '', TempExcelBuffer."Cell Type"::Text);

        IntroductionParagraph := FinancialReport.GetIntroductoryParagraph();
        if IntroductionParagraph <> '' then begin
            RowNo += 1;
            EnterCellBlobValue(RowNo, 1, IntroductionParagraph, TempExcelBuffer."Cell Type"::Text);
        end;

        if ((AccSchedName."Analysis View Name" = '') and (GLSetup."Global Dimension 1 Code" <> '')) or
           ((AccSchedName."Analysis View Name" <> '') and (AnalysisView."Dimension 1 Code" <> ''))
        then
            EnterFilterInCell(
              RowNo, AccSchedLine.GetFilter("Dimension 1 Filter"), GetDimFilterCaption(1), '', TempExcelBuffer."Cell Type"::Text);
        if ((AccSchedName."Analysis View Name" = '') and (GLSetup."Global Dimension 2 Code" <> '')) or
           ((AccSchedName."Analysis View Name" <> '') and (AnalysisView."Dimension 2 Code" <> ''))
        then
            EnterFilterInCell(
              RowNo, AccSchedLine.GetFilter("Dimension 2 Filter"), GetDimFilterCaption(2), '', TempExcelBuffer."Cell Type"::Text);
        if (AccSchedName."Analysis View Name" = '') or
           ((AccSchedName."Analysis View Name" <> '') and (AnalysisView."Dimension 3 Code" <> ''))
        then
            EnterFilterInCell(
              RowNo, AccSchedLine.GetFilter("Dimension 3 Filter"), GetDimFilterCaption(3), '', TempExcelBuffer."Cell Type"::Text);
        if (AccSchedName."Analysis View Name" = '') or
           ((AccSchedName."Analysis View Name" <> '') and (AnalysisView."Dimension 4 Code" <> ''))
        then
            EnterFilterInCell(
              RowNo, AccSchedLine.GetFilter("Dimension 4 Filter"), GetDimFilterCaption(4), '', TempExcelBuffer."Cell Type"::Text);

        RowNo := RowNo + 1;
        if UseAmtsInAddCurr then
            EnterFilterInCell(
              RowNo, GLSetup."Additional Reporting Currency", Currency.TableCaption(), '', TempExcelBuffer."Cell Type"::Text)
        else
            EnterFilterInCell(
              RowNo, GLSetup."LCY Code", Currency.TableCaption(), '', TempExcelBuffer."Cell Type"::Text);

        RowNo := RowNo + 1;
        if AccSchedLine.Find('-') then begin
            if ColumnLayout.Find('-') then begin
                RowNo := RowNo + 1;
                ColumnNo := 2; // Skip the "Row No." column.
                repeat
                    ColumnNo := ColumnNo + 1;
                    EnterCell(
                      RowNo, ColumnNo, AccSchedManagement.CalcColumnHeader(AccSchedLine, ColumnLayout), false, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                until ColumnLayout.Next() = 0;
            end;
            repeat
                RecNo := RecNo + 1;
                Window.Update(1, Round(RecNo / TotalRecNo * 10000, 1));
                if ShouldIncludeRow(AccSchedLine) then begin
                    RowNo := RowNo + 1;
                    ColumnNo := 1;
                    EnterCell(
                    RowNo, ColumnNo, AccSchedLine."Row No.",
                    AccSchedLine.Bold, AccSchedLine.Italic, AccSchedLine.Underline, AccSchedLine."Double Underline",
                    '0', TempExcelBuffer."Cell Type"::Text);
                    ColumnNo := 2;
                    EnterCell(
                    RowNo, ColumnNo, AccSchedLine.Description,
                    AccSchedLine.Bold, AccSchedLine.Italic, AccSchedLine.Underline, AccSchedLine."Double Underline",
                    '', TempExcelBuffer."Cell Type"::Text);
                    if ColumnLayout.Find('-') then
                        repeat
                            CalcColumnValue(AccSchedLine);
                            ColumnNo := ColumnNo + 1;
                            EnterCell(
                            RowNo, ColumnNo, MatrixMgt.FormatAmount(ColumnValue, ColumnLayout."Rounding Factor", UseAmtsInAddCurr),
                            AccSchedLine.Bold, AccSchedLine.Italic, AccSchedLine.Underline, AccSchedLine."Double Underline",
                            '', TempExcelBuffer."Cell Type"::Number)
                        until ColumnLayout.Next() = 0;
                end;
            until AccSchedLine.Next() = 0;
        end;

        ClosingParagraph := FinancialReport.GetClosingParagraph();
        if ClosingParagraph <> '' then begin
            RowNo += 1;
            EnterCellBlobValue(RowNo, 1, ClosingParagraph, TempExcelBuffer."Cell Type"::Text);
        end;
    end;

    local procedure CalcColumnValue(var AccSchedLine: Record "Acc. Schedule Line")
    begin
        OnBeforeCalcColumnValue(UseAmtsInAddCurr, ColumnLayout);
        if AccSchedLine.Totaling = '' then
            ColumnValue := 0
        else begin
            ColumnValue := AccSchedManagement.CalcCell(AccSchedLine, ColumnLayout, UseAmtsInAddCurr);
            if AccSchedManagement.GetDivisionError() then
                ColumnValue := 0
        end;
        OnAferCalcColumnValue(UseAmtsInAddCurr, ColumnLayout);
    end;

    local procedure EnterFilterInCell(var RowNo: Integer; "Filter": Text[250]; FieldName: Text[100]; Format: Text[30]; CellType: Option)
    begin
        if Filter <> '' then begin
            RowNo := RowNo + 1;
            EnterCell(RowNo, 1, FieldName, false, false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            EnterCell(RowNo, 2, Filter, false, false, false, false, Format, CellType);
        end;
    end;

    local procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValue: Text; Bold: Boolean; Italic: Boolean; UnderLine: Boolean; DoubleUnderLine: Boolean; Format: Text[30]; CellType: Option)
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        TempExcelBuffer."Cell Value as Text" := CopyStr(CellValue, 1, MaxStrLen(TempExcelBuffer."Cell Value as Text"));
        TempExcelBuffer.Formula := '';
        TempExcelBuffer.Bold := Bold;
        TempExcelBuffer.Italic := Italic;
        if DoubleUnderLine = true then begin
            TempExcelBuffer."Double Underline" := true;
            TempExcelBuffer.Underline := false;
        end else begin
            TempExcelBuffer."Double Underline" := false;
            TempExcelBuffer.Underline := UnderLine;
        end;
        TempExcelBuffer.NumberFormat := Format;
        TempExcelBuffer."Cell Type" := CellType;
        TempExcelBuffer.Insert();
    end;

    local procedure EnterCellBlobValue(RowNo: Integer; ColumnNo: Integer; CellValue: Text; CellType: Option)
    var
        OutStream: OutStream;
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        TempExcelBuffer."Cell Value as Blob".CreateOutStream(OutStream);
        OutStream.WriteText(CellValue);
        TempExcelBuffer."Cell Type" := CellType;
        TempExcelBuffer.Insert();
    end;

    local procedure GetDimFilterCaption(DimFilterNo: Integer): Text[80]
    var
        Dimension: Record Dimension;
    begin
        if AccSchedName."Analysis View Name" = '' then
            case DimFilterNo of
                1:
                    Dimension.Get(GLSetup."Global Dimension 1 Code");
                2:
                    Dimension.Get(GLSetup."Global Dimension 2 Code");
            end
        else
            case DimFilterNo of
                1:
                    Dimension.Get(AnalysisView."Dimension 1 Code");
                2:
                    Dimension.Get(AnalysisView."Dimension 2 Code");
                3:
                    Dimension.Get(AnalysisView."Dimension 3 Code");
                4:
                    Dimension.Get(AnalysisView."Dimension 4 Code");
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

    procedure SetUseExistingTemplate(var FinReportExcelTemplate: Record "Fin. Report Excel Template")
    var
        InStream: InStream;
    begin
        FinReportExcelTemplate.CalcFields(Template);
        if not FinReportExcelTemplate.Template.HasValue() then
            exit;

        FinReportExcelTemplate.Template.CreateInStream(InStream);
        ServerFileName := FileMgt.InStreamExportToServerFile(InStream, ExcelFileExtensionTok);
        DoUseExistingTemplate := ServerFileName <> '';
        if FinReportExcelTemplate."File Name" <> '' then
            ExistingTemplateName := FinReportExcelTemplate."File Name"
        else
            ExistingTemplateName := FinancialReport.Description;
        ExistingTemplateName := FileMgt.CreateFileNameWithExtension(ExistingTemplateName, ExcelFileExtensionTok);
    end;

    procedure SetSaveToStream(NewSaveToStream: Boolean)
    begin
        SaveToStream := NewSaveToStream;
    end;

    procedure GetSavedStream(var OutStream: OutStream)
    begin
        TempExcelBuffer.SaveToStream(OutStream, true);
    end;

    local procedure UploadExistingTemplate(var ClientFileName: Text)
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        ClientFileName := ExistingTemplateName;

        FileMgt.IsAllowedPath(ServerFileName, false);
        FileMgt.BLOBImportFromServerFile(TempBlob, ServerFileName);
        TempBlob.CreateInStream(InStream);
        TempExcelBuffer.GetSheetsNameListFromStream(InStream, TempNameValueBuffer);

        DoUseExistingTemplate := false;
        TempNameValueBuffer.SetRange(Value, FinancialReport."Financial Report Row Group");
        if not TempNameValueBuffer.FindFirst() then
            exit;

        SheetName := TempNameValueBuffer.Value;
        DoUseExistingTemplate := SheetName <> '';
    end;

    local procedure UploadClientFile(var ClientFileName: Text): Boolean
    begin
        ServerFileName := FileMgt.UploadFile(Text002, ExcelFileExtensionTok);
        ClientFileName := FileMgt.GetFileName(ServerFileName);
        if ServerFileName = '' then
            exit(false);

        SheetName := TempExcelBuffer.SelectSheetsName(ServerFileName);
        if SheetName = '' then
            exit(false);

        exit(true);
    end;

    local procedure ShouldIncludeRow(var AccSchedLine: Record "Acc. Schedule Line"): Boolean
    var
        HasNonZeroColumn: Boolean;
    begin
        if AccSchedLine.Show = AccSchedLine.Show::"If Any Column Not Zero" then begin
            HasNonZeroColumn := false;
            if ColumnLayout.Find('-') then
                repeat
                    CalcColumnValue(AccSchedLine);
                    if ColumnValue <> 0 then
                        exit(true);
                until ColumnLayout.Next() = 0;
            exit(HasNonZeroColumn);
        end;
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcColumnValue(var UseAmtsInAddCurr: Boolean; var ColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAferCalcColumnValue(var UseAmtsInAddCurr: Boolean; var ColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIntegerOnAfterGetRecordOnAfterAccSchedLineSetFilter(var AccScheduleLine: Record "Acc. Schedule Line")
    begin
    end;
}

