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

/// <summary>
/// Exports account schedule data and column layouts to Excel format with comprehensive formatting and template support.
/// Provides flexible Excel export functionality including existing template updates, custom formatting, and filter information.
/// </summary>
/// <remarks>
/// Supports both new Excel file creation and existing template updates. Includes advanced Excel formatting,
/// formula preservation, and integration with financial report Excel templates for standardized output formatting.
/// Extensible through multiple integration events for custom column calculations and filter processing.
/// </remarks>
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
                TempDimPerspectiveLine: Record "Dimension Perspective Line" temporary;
                DimPerspectiveAccSchMgtHandler: Codeunit DimPerspectiveAccSchMgtHandler;
                IDimPerspective: Interface IDimensionPerspective;
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

                if DimPerspectiveName.Name <> '' then begin
                    AccSchedManagement.CheckPerspectiveAnalysisView(AccSchedName.Name, DimPerspectiveName.Name);
                    AccSchedLine.Copy(AccSchedLineSource);

                    IDimPerspective := DimPerspectiveName."Perspective Type";
                    IDimPerspective.PopulateLineBufferForReporting(DimPerspectiveName, TempDimPerspectiveLine);
                    if TempDimPerspectiveLine.FindSet() then begin
                        BindSubscription(DimPerspectiveAccSchMgtHandler);
                        DimPerspectiveAccSchMgtHandler.SetDimPerspectiveName(DimPerspectiveName);
                        repeat
                            DimPerspectiveAccSchMgtHandler.SetDimPerspectiveLine(TempDimPerspectiveLine);
                            AccSchedManagement.ForceRecalculate(true);
                            WriteSheetPerDefinition(AccSchedLine, TempDimPerspectiveLine."Perspective Header");
                        until TempDimPerspectiveLine.Next() = 0;
                        UnbindSubscription(DimPerspectiveAccSchMgtHandler);
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
        FinancialReportAuditing: Codeunit "Financial Report Auditing";
    begin
        Company.Get(CompanyName());
        CompanyDisplayName := Company."Display Name";
        if CompanyDisplayName = '' then
            CompanyDisplayName := Company.Name;

        FinancialReportAuditing.LogReportUsage(FinancialReport.Name, Enum::"Financial Report Format"::Excel, RunForExport);
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
        DimPerspectiveName: Record "Dimension Perspective Name";
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
        RunForExport: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Analyzing Data...\\';
        Text001: Label 'Filters';
        Text002: Label 'Update Workbook';
#pragma warning restore AA0074
        ExcelFileExtensionTok: Label '.xlsx', Locked = true;
        GenericSheetNameLbl: Label 'Sheet %1', Comment = '%1 = Sheet number';

    /// <summary>
    /// Sets account schedule export options including account schedule lines, column layout, and currency settings.
    /// Configures the basic export parameters for Excel generation without financial report context.
    /// </summary>
    /// <param name="AccSchedLine2">Account schedule line record to export</param>
    /// <param name="ColumnLayoutName2">Column layout name for formatting</param>
    /// <param name="UseAmtsInAddCurr2">Whether to use amounts in additional currency</param>
    procedure SetOptions(var AccSchedLine2: Record "Acc. Schedule Line"; ColumnLayoutName2: Code[10]; UseAmtsInAddCurr2: Boolean)
    begin
        SetOptions(AccSchedLine2, ColumnLayoutName2, UseAmtsInAddCurr2, '');
    end;

    /// <summary>
    /// Sets comprehensive account schedule export options including financial report context.
    /// Configures all export parameters for Excel generation with financial report integration.
    /// </summary>
    /// <param name="AccSchedLine2">Account schedule line record to export</param>
    /// <param name="ColumnLayoutName2">Column layout name for formatting</param>
    /// <param name="UseAmtsInAddCurr2">Whether to use amounts in additional currency</param>
    /// <param name="FinancialReportName">Financial report name for context and template selection</param>
    procedure SetOptions(var AccSchedLine2: Record "Acc. Schedule Line"; ColumnLayoutName2: Code[10]; UseAmtsInAddCurr2: Boolean; FinancialReportName: Code[10])
    begin
        SetOptions(AccSchedLine2, ColumnLayoutName2, UseAmtsInAddCurr2, FinancialReportName, '');
    end;

    procedure SetOptions(var AccSchedLine2: Record "Acc. Schedule Line"; ColumnLayoutName2: Code[10]; UseAmtsInAddCurr2: Boolean; FinancialReportName: Code[10]; DimPerspectiveNameText: Code[10])
    begin
        AccSchedLineSource.CopyFilters(AccSchedLine2);
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName2);
        UseAmtsInAddCurr := UseAmtsInAddCurr2;
        if FinancialReportName <> '' then
            FinancialReport.Get(FinancialReportName);
        if DimPerspectiveNameText <> '' then
            DimPerspectiveName.Get(DimPerspectiveNameText);
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

    /// <summary>
    /// Controls whether to update an existing Excel worksheet or create a new one.
    /// Enables modification of existing workbooks while preserving non-data content.
    /// </summary>
    /// <param name="UpdateExistingWorksheet">True to update existing worksheet, false to create new</param>
    procedure SetUpdateExistingWorksheet(UpdateExistingWorksheet: Boolean)
    begin
        DoUpdateExistingWorksheet := UpdateExistingWorksheet;
    end;

    /// <summary>
    /// Sets the output file path for silent Excel export without user interaction.
    /// Enables automated export scenarios where file path is predetermined.
    /// </summary>
    /// <param name="NewFileName">Full file path for Excel output file</param>
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        ServerFileName := NewFileName;
    end;

    /// <summary>
    /// Enables or disables test mode for Excel export operations.
    /// Test mode allows validation and debugging without full file generation.
    /// </summary>
    /// <param name="NewTestMode">True to enable test mode, false for normal operation</param>
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;

    /// <summary>
    /// Configures the export to use an existing Excel template for formatting and layout.
    /// Enables template-based Excel generation with predefined formatting and structure.
    /// </summary>
    /// <param name="FinReportExcelTemplate">Financial report Excel template record containing template data</param>
    /// <remarks>
    /// Extracts template from BLOB field, creates server file, and configures export parameters
    /// for template-based Excel generation with preserved formatting and structure.
    /// </remarks>
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

    /// <summary>
    /// Configures the export to save Excel data to a stream instead of a file.
    /// Enables in-memory Excel processing and custom output handling.
    /// </summary>
    /// <param name="NewSaveToStream">True to save to stream, false to save to file</param>
    procedure SetSaveToStream(NewSaveToStream: Boolean)
    begin
        SaveToStream := NewSaveToStream;
    end;

    /// <summary>
    /// Retrieves the saved Excel data as an output stream for custom processing.
    /// Provides access to generated Excel content for further manipulation or transmission.
    /// </summary>
    /// <param name="OutStream">Output stream containing the Excel data</param>
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

    procedure SetRunForExport()
    begin
        RunForExport := true;
    end;

    /// <summary>
    /// Integration event raised before calculating column values during Excel export.
    /// Enables custom modification of currency settings and column layout parameters.
    /// </summary>
    /// <param name="UseAmtsInAddCurr">Whether to use amounts in additional currency</param>
    /// <param name="ColumnLayout">Column layout record being processed</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcColumnValue(var UseAmtsInAddCurr: Boolean; var ColumnLayout: Record "Column Layout")
    begin
    end;

    /// <summary>
    /// Integration event raised after calculating column values during Excel export.
    /// Enables custom post-processing of currency settings and calculated column data.
    /// </summary>
    /// <param name="UseAmtsInAddCurr">Whether amounts in additional currency were used</param>
    /// <param name="ColumnLayout">Column layout record that was processed</param>
    [IntegrationEvent(false, false)]
    local procedure OnAferCalcColumnValue(var UseAmtsInAddCurr: Boolean; var ColumnLayout: Record "Column Layout")
    begin
    end;

    /// <summary>
    /// Integration event raised after applying filters to account schedule lines during data processing.
    /// Enables custom filter modification and additional filter criteria application.
    /// </summary>
    /// <param name="AccScheduleLine">Account schedule line record with applied filters</param>
    [IntegrationEvent(false, false)]
    local procedure OnIntegerOnAfterGetRecordOnAfterAccSchedLineSetFilter(var AccScheduleLine: Record "Acc. Schedule Line")
    begin
    end;
}

