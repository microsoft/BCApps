// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;

page 108 "Financial Reports"
{
    AboutText = 'With the Financial Reports feature, you can get insights into the financial data shown on your chart of accounts (COA). Using row and column definitions, you can set up financial reports to analyse figures in general ledger (G/L) accounts, and compare general ledger entries with budget entries.';
    AboutTitle = 'About Financial Reports';
    AdditionalSearchTerms = 'account schedule,finance reports,financial reporting';
    AnalysisModeEnabled = false;
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Reports';
    PageType = List;
    SourceTable = "Financial Report";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    trigger OnAssistEdit()
                    var
                        AccScheduleOverview: Page "Acc. Schedule Overview";
                    begin
                        AccScheduleOverview.SetFinancialReportName(Rec.Name);
                        AccScheduleOverview.SetViewOnlyMode(true);
                        AccScheduleOverview.Run();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Financial Report Row Group"; Rec."Financial Report Row Group")
                {
                    Caption = 'Row Definition';
                    ApplicationArea = Basic, Suite;
                }
                field(AnalysisViewRow; AnalysisViewRow)
                {
                    Caption = 'Row Analysis View Name';
                    ApplicationArea = Basic, Suite;
                    Tooltip = 'Specifies the name of the analysis view you want the row definitions to be based on. Using an analysis view is optional.';
                    TableRelation = "Analysis View".Code;

                    trigger OnValidate()
                    var
                        AccScheduleName: Record "Acc. Schedule Name";
                        AnalysisView: Record "Analysis View";
                    begin
                        AccScheduleName.Get(Rec."Financial Report Row Group");
                        if AnalysisViewRow <> '' then begin
                            AnalysisView.Get(AnalysisViewRow);
                            AccScheduleName."Analysis View Name" := AnalysisView.Code;
                        end else
                            Clear(AccScheduleName."Analysis View Name");

                        AccScheduleName.Modify();
                    end;
                }
                field("Financial Report Column Group"; Rec."Financial Report Column Group")
                {
                    Caption = 'Column Definition';
                    ApplicationArea = Basic, Suite;
                }
                field(AnalysisViewColumn; AnalysisViewColumn)
                {
                    Caption = 'Column Analysis View Name';
                    ApplicationArea = Basic, Suite;
                    Tooltip = 'Specifies the name of the analysis view you want the column layout to be based on. Using an analysis view is optional.';
                    TableRelation = "Analysis View".Code;

                    trigger OnValidate()
                    var
                        ColumnLayoutName: Record "Column Layout Name";
                        AnalysisView: Record "Analysis View";
                    begin
                        ColumnLayoutName.Get(Rec."Financial Report Column Group");
                        if AnalysisViewRow <> '' then begin
                            AnalysisView.Get(AnalysisViewRow);
                            ColumnLayoutName."Analysis View Name" := AnalysisView.Code;
                        end else
                            Clear(ColumnLayoutName."Analysis View Name");

                        ColumnLayoutName.Modify();
                    end;
                }
                field(SheetDefinition; Rec.SheetDefinition)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sheet definition to be used for the financial report.';

                    trigger OnValidate()
                    begin
                        GetSheetAnalysisView();
                    end;
                }
                field(SheetAnalysisView; SheetAnalysisView)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sheet Analysis View Name';
                    TableRelation = "Analysis View";
                    ToolTip = 'Specifies the name of the analysis view you want the sheet definitions to be based on. Using an analysis view is optional.';

                    trigger OnValidate()
                    var
                        AnalysisView: Record "Analysis View";
                        SheetDefName: Record "Sheet Definition Name";
                    begin
                        SheetDefName.Get(Rec.SheetDefinition);
                        if SheetAnalysisView <> '' then begin
                            AnalysisView.Get(SheetAnalysisView);
                            SheetDefName."Analysis View Name" := AnalysisView.Code;
                        end else
                            Clear(SheetDefName."Analysis View Name");
                        SheetDefName.Modify();
                    end;
                }
                field("Internal Description"; Rec."Internal Description")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }

        area(factboxes)
        {
            systempart(ControlLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(ControlNotes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ViewFinancialReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Financial Report';
                Image = View;
                ToolTip = 'View the selected financial report with data.';
                AboutTitle = 'View Financial Report';
                AboutText = 'This action will open the financial report in a sandbox like environment, where all changes are saved to the user and not the report';
                trigger OnAction()
                var
                    AccScheduleOverview: Page "Acc. Schedule Overview";
                begin
                    AccScheduleOverview.SetFinancialReportName(Rec.Name);
                    AccScheduleOverview.SetViewOnlyMode(true);
                    AccScheduleOverview.Run();
                end;
            }
            action(EditRowGroup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Row Definition';
                Image = Edit;
                ShortCutKey = 'Return';
                ToolTip = 'Edit the row definition of the selected financial report.';

                trigger OnAction()
                var
                    AccSchedule: Page "Account Schedule";
                begin
                    AccSchedule.SetAccSchedName(Rec."Financial Report Row Group");
                    AccSchedule.Run();
                end;
            }
            action(EditColumnGroup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Column Definition';
                Ellipsis = false;
                Image = Edit;
                ToolTip = 'Edit the column definition of the selected financial report.';

                trigger OnAction()
                var
                    ColumnLayout: Page "Column Layout";
                begin
                    ColumnLayout.SetColumnLayoutName(Rec."Financial Report Column Group");
                    ColumnLayout.Run();
                end;
            }
            action(EditSheetDefinition)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Sheet Definition';
                Image = Edit;
                ToolTip = 'Edit the selected sheet definition.';

                trigger OnAction()
                var
                    SheetDefLine: Record "Sheet Definition Line";
                begin
                    Rec.TestField(SheetDefinition);
                    SheetDefLine.SetRange(Name, Rec.SheetDefinition);
                    Page.Run(0, SheetDefLine);
                end;
            }
            action(ShowAllRowDefinitions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show All Row Definitions';
                Image = List;
                ToolTip = 'Open the Row Definitions list page.';
                RunObject = page "Account Schedule Names";
            }
            action(ShowAllColumnDefinitions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show All Column Definitions';
                Image = List;
                ToolTip = 'Open the Column Definitions list page.';
                RunObject = page "Column Layout Names";
            }
            action(CopyFinancialReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Report Definition';
                Image = Copy;
                Scope = Repeater;
                ToolTip = 'Create a copy of the selected financial report definition.';

                trigger OnAction()
                var
                    FinancialReport: Record "Financial Report";
                begin
                    CurrPage.SetSelectionFilter(FinancialReport);
                    REPORT.RunModal(REPORT::"Copy Financial Report", true, true, FinancialReport);
                end;
            }
            action(ImportFinancialReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Report Definition';
                Image = Import;
                Scope = Repeater;
                ToolTip = 'Import a RapidStart configuration package that contains the definition for a financial report. Importing a financial report definition lets you share it, for example, with another business unit. This requires that the financial report definition has been exported.';

                trigger OnAction()
                var
                    FinancialReportMgt: Codeunit "Financial Report Mgt.";
                begin
                    FinancialReportMgt.XMLExchangeImport(Rec);
                end;
            }
            action(ExportFinancialReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Report Definition';
                Image = Export;
                Scope = Repeater;
                ToolTip = 'Export the definition for the selected financial report to a RapidStart configuration package. Exporting a financial report definition lets you share it with another business unit.';

                trigger OnAction()
                var
                    FinancialReportMgt: Codeunit "Financial Report Mgt.";
                begin
                    FinancialReportMgt.XMLExchangeExport(Rec);
                end;
            }
        }
        area(navigation)
        {
            action(Overview)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Report Definition';
                Ellipsis = false;
                Image = Edit;
                AboutTitle = 'Edit Financial Report';
                AboutText = 'This action will open the financial report in edit mode, where all changes are visible to other users';
                ToolTip = 'Edit the default settings (such as row/column definitions to be used) on the selected financial report.';
                trigger OnAction()
                var
                    AccSchedOverview: Page "Acc. Schedule Overview";
                begin
                    AccSchedOverview.SetViewOnlyMode(false);
                    AccSchedOverview.SetFinancialReportName(Rec.Name);
                    AccSchedOverview.Run();
                end;
            }
            action(Schedules)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Schedules';
                ToolTip = 'View or edit when the financial report is scheduled to be exported or emailed.';
                Image = CheckList;

                trigger OnAction()
                var
                    FinancialReportSchedule: Record "Financial Report Schedule";
                begin
                    FinancialReportSchedule.SetRange("Financial Report Name", Rec.Name);
                    Page.Run(0, FinancialReportSchedule);
                end;
            }
        }
        area(reporting)
        {
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print/PDF';
                Ellipsis = false;
                Image = Print;
                Scope = Repeater;
                ToolTip = 'Prepare to print or get a PDF of the selected report. A report request window opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    FinancialReportMgt: Codeunit "Financial Report Mgt.";
                begin
                    FinancialReportMgt.Print(Rec);
                end;
            }
        }
        area(Promoted)
        {
            actionref(ViewFinancialReport_Promoted; ViewFinancialReport) { }
            actionref(Print_Promoted; Print) { }

            group(Category_Edit)
            {
                Caption = 'Edit definitions';
                actionref(Overview_Promoted; Overview) { }
                actionref(EditRowGroup_Promoted; EditRowGroup) { }
                actionref(EditColumnGroup_Promoted; EditColumnGroup) { }
                actionref(EditSheetDefinition_Promoted; EditSheetDefinition) { }
                actionref(ShowAllRowDefinitions_Promoted; ShowAllRowDefinitions) { }
                actionref(ShowAllColumnDefinitions_Promoted; ShowAllColumnDefinitions) { }
                actionref(Schedules_Promoted; Schedules) { }
            }
            group(CopyExportImport)
            {
                Caption = 'Copy/Export/Import';
                actionref(CopyFinancialReport_Promoted; CopyFinancialReport) { }
                actionref(ExportFinancialReport_Promoted; ExportFinancialReport) { }
                actionref(ImportFinancialReport_Promoted; ImportFinancialReport) { }
            }
        }
    }

    trigger OnInit()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        FinancialReportMgt.Initialize();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(SheetAnalysisView);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateCalculatedFields();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateCalculatedFields();
    end;

    local procedure UpdateCalculatedFields()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
    begin
        Clear(AnalysisViewColumn);
        Clear(AnalysisViewRow);
        if Rec."Financial Report Row Group" <> '' then
            if AccScheduleName.Get(Rec."Financial Report Row Group") then
                AnalysisViewRow := AccScheduleName."Analysis View Name";

        if Rec."Financial Report Column Group" <> '' then
            if ColumnLayoutName.Get(Rec."Financial Report Column Group") then
                AnalysisViewColumn := ColumnLayoutName."Analysis View Name";

        GetSheetAnalysisView();
    end;

    local procedure GetSheetAnalysisView()
    var
        SheetDefName: Record "Sheet Definition Name";
    begin
        Clear(SheetAnalysisView);
        if Rec.SheetDefinition <> '' then
            if SheetDefName.Get(Rec.SheetDefinition) then
                SheetAnalysisView := SheetDefName."Analysis View Name";
    end;

    var
        AnalysisViewRow: Text;
        AnalysisViewColumn: Text;
        SheetAnalysisView: Text;
}
