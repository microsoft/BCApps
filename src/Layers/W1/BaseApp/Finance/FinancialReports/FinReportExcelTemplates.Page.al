// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;
using System.IO;

page 773 "Fin. Report Excel Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Excel Layouts';
    PageType = List;
    SourceTable = "Fin. Report Excel Template";
    DataCaptionExpression = GetCaption();
    AnalysisModeEnabled = false;
    AboutTitle = 'About financial report Excel layouts';
    AboutText = 'On this page, you can create and import Excel workbooks to be used as layouts for the Excel version of the financial report. This allows you to format and visualize the financial report data directly in Excel without the need of a developer.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Financial Report Name"; Rec."Financial Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(Copy)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy';
                ToolTip = 'Make a copy of the selected layout.';
                Image = CopyDocument;
                Scope = Repeater;
                Enabled = Rec.Code <> '';

                trigger OnAction()
                var
                    FinReportExcelTemplate: Record "Fin. Report Excel Template";
                    NewFinReportExcelTempl: Page "New Fin. Report Excel Templ.";
                    InStream: InStream;
                    OutStream: OutStream;
                begin
                    NewFinReportExcelTempl.SetSource(Rec);
                    if NewFinReportExcelTempl.RunModal() = Action::Ok then begin
                        NewFinReportExcelTempl.GetRecord(FinReportExcelTemplate);
                        Rec.CalcFields(Template);
                        Rec.Template.CreateInStream(InStream);
                        FinReportExcelTemplate.Template.CreateOutStream(OutStream);
                        CopyStream(OutStream, InStream);
                        FinReportExcelTemplate.Insert();
                    end;
                end;
            }
        }
        area(Processing)
        {
            action(Export)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export/Run';
                ToolTip = 'Export the selected layout with the latest data from the financial report.';
                AboutTitle = 'About exporting layouts';
                AboutText = 'Use this action to export the selected layout, which will create an Excel workbook on your device with the latest data from the financial report. You can then create a new sheet and apply your own formatting and visualization with the data.';
                Image = Export;
                Scope = Repeater;
                Enabled = Rec.Code <> '';

                trigger OnAction()
                var
                    ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
                begin
                    ExportAccSchedToExcel.SetOptions(
                        this.AccScheduleLine, this.TempFinancialReport."Financial Report Column Group", this.TempFinancialReport.UseAmountsInAddCurrency,
                        this.TempFinancialReport.Name, this.TempFinancialReport.SheetDefinition);
                    ExportAccSchedToExcel.SetUseExistingTemplate(Rec);
                    ExportAccSchedToExcel.Run();
                end;
            }
            fileuploadaction(Import)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import';
                ToolTip = 'Import and replace the Excel workbook for the selected layout.';
                AboutTitle = 'About importing layouts';
                AboutText = 'Use this action to import the customized Excel workbook. You can then specify this layout code on the financial report, and it will be used in future exports of the report.';
                Image = Import;
                Scope = Repeater;
                Enabled = Rec.Code <> '';
                AllowMultipleFiles = false;
                AllowedFileExtensions = '.xlsx';

                trigger OnAction(Files: List of [FileUpload])
                var
                    FileMgt: Codeunit "File Management";
                    InStream: InStream;
                    OutStream: OutStream;
                begin
                    Files.Get(1).CreateInStream(InStream);
                    Rec.Template.CreateOutStream(OutStream);
                    CopyStream(OutStream, InStream);
                    Rec."File Name" := CopyStr(FileMgt.GetFileNameWithoutExtension(Files.Get(1).FileName), 1, MaxStrLen(Rec."File Name"));
                    Rec.Modify();
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Copy_Promoted; Copy) { }
                actionref(Export_Promoted; Export) { }
                actionref(Import_Promoted; Import) { }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
        OutStream: OutStream;
    begin
        ExportAccSchedToExcel.SetOptions(
            this.AccScheduleLine, this.TempFinancialReport."Financial Report Column Group", this.TempFinancialReport.UseAmountsInAddCurrency,
            this.TempFinancialReport.Name, this.TempFinancialReport.SheetDefinition);
        ExportAccSchedToExcel.SetSaveToStream(true);
        ExportAccSchedToExcel.RunModal();
        Rec.Template.CreateOutStream(OutStream);
        ExportAccSchedToExcel.GetSavedStream(OutStream);
    end;

    var
        TempFinancialReport: Record "Financial Report" temporary;
        AccScheduleLine: Record "Acc. Schedule Line";

    internal procedure SetSource(var NewTempFinancialReport: Record "Financial Report"; var NewAccScheduleLine: Record "Acc. Schedule Line")
    begin
        this.TempFinancialReport.Copy(NewTempFinancialReport);
        this.AccScheduleLine.Copy(NewAccScheduleLine);

        Rec.FilterGroup(2);
        Rec.SetRange("Financial Report Name", NewTempFinancialReport.Name);
        Rec.FilterGroup(0);
    end;

    internal procedure GetCaption(): Text
    begin
        exit(TempFinancialReport.Name);
    end;
}