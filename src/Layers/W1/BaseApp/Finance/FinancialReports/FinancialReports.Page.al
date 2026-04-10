// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;

/// <summary>
/// Financial reports list page providing management interface for configuring and running financial reports.
/// Combines account schedule row definitions with column layouts to create comprehensive financial statements.
/// </summary>
/// <remarks>
/// Supports drill-down to account schedule overview, analysis view integration for enhanced reporting,
/// and template-based financial statement generation including balance sheets and income statements.
/// </remarks>
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
                field(CategoryCode; Rec.CategoryCode)
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
                field(DimPerspective; Rec.DimPerspective)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        GetPerspectiveAnalysisView();
                    end;
                }
                field(PerspectiveAnalysisView; PerspectiveAnalysisView)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Perspective Analysis View Name';
                    TableRelation = "Analysis View";
                    ToolTip = 'Specifies the name of the analysis view you want the dimension perspectives to be based on. Using an analysis view is optional.';

                    trigger OnValidate()
                    var
                        AnalysisView: Record "Analysis View";
                        DimPerspectiveName: Record "Dimension Perspective Name";
                    begin
                        DimPerspectiveName.Get(Rec.DimPerspective);
                        if PerspectiveAnalysisView <> '' then begin
                            AnalysisView.Get(PerspectiveAnalysisView);
                            DimPerspectiveName."Analysis View Name" := AnalysisView.Code;
                        end else
                            Clear(DimPerspectiveName."Analysis View Name");
                        DimPerspectiveName.Modify();
                    end;
                }
                field(Status; Rec.Status) { }
                field("Internal Description"; Rec."Internal Description")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Last Run by User"; Rec."Last Run by User")
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
                ShortCutKey = 'Return';

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
            action(EditDimPerspective)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Dimension Perspective';
                Image = Edit;
                ToolTip = 'Edit the selected dimension perspective.';

                trigger OnAction()
                var
                    DimPerspectiveLine: Record "Dimension Perspective Line";
                begin
                    Rec.TestField(DimPerspective);
                    DimPerspectiveLine.SetRange(Name, Rec.DimPerspective);
                    Page.Run(0, DimPerspectiveLine);
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
            action(ShowAllCategories)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show All Categories';
                Image = List;
                RunObject = page "Financial Report Categories";
                ToolTip = 'View or edit financial report categories.';
            }
            action(EditCategory)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Category';
                Image = Edit;
                ToolTip = 'Edit the category of the selected financial report.';
                trigger OnAction()
                var
                    FinancialReportCategory: Record "Financial Report Category";
                begin
                    if FinancialReportCategory.Get(Rec.CategoryCode) then
                        Page.Run(Page::"Financial Report Category", FinancialReportCategory);
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
            action("Audit Logs")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Audit Logs';
                Image = Log;
                ToolTip = 'Opens the Financial Report Audit Logs for the selected report.';
                RunObject = Page "Financial Report Audit Logs";
                RunPageLink = "Report Name" = field(Name);
            }
            action("All Audit Logs")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'All Audit Logs';
                Image = Log;
                ToolTip = 'Opens the Financial Report Audit Logs showing all entries.';
                RunObject = Page "Financial Report Audit Logs";
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
                Caption = 'Definitions';
                actionref(Overview_Promoted; Overview) { }
                actionref(EditRowGroup_Promoted; EditRowGroup) { }
                actionref(EditColumnGroup_Promoted; EditColumnGroup) { }
                actionref(EditDimPerspective_Promoted; EditDimPerspective) { }
                actionref(EditCategory_Promoted; EditCategory) { }
                actionref(ShowAllRowDefinitions_Promoted; ShowAllRowDefinitions) { }
                actionref(ShowAllColumnDefinitions_Promoted; ShowAllColumnDefinitions) { }
                actionref(ShowAllCategories_Promoted; ShowAllCategories) { }
                actionref(Schedules_Promoted; Schedules) { }
            }
            group(CopyExportImport)
            {
                Caption = 'Copy/Export/Import';
                actionref(CopyFinancialReport_Promoted; CopyFinancialReport) { }
                actionref(ExportFinancialReport_Promoted; ExportFinancialReport) { }
                actionref(ImportFinancialReport_Promoted; ImportFinancialReport) { }
            }
            group(Audit)
            {
                Caption = 'Audit';
                ShowAs = SplitButton;
                actionref("Audit Logs_Promoted"; "Audit Logs") { }
                actionref("All Audit Logs_Promoted"; "All Audit Logs") { }
            }
        }
    }

    trigger OnInit()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        FinancialReportMgt.Initialize();
    end;

    trigger OnOpenPage()
    var
        FinancialReportStatus: Record "Financial Report Status";
        LastFilterGroup: Integer;
    begin
        if not FinancialReportStatus.WritePermission() then begin
            LastFilterGroup := Rec.FilterGroup();
            Rec.FilterGroup(4);
            Rec.SetRange("Status Blocked", false);
            Rec.FilterGroup(LastFilterGroup);
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        Clear(PerspectiveAnalysisView);
        Rec.Status := FinancialReportMgt.GetDefaultStatus();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateCalculatedFields();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateCalculatedFields();
    end;

    /// <summary>
    /// Updates calculated fields for analysis view names from row and column definitions.
    /// Retrieves analysis view assignments from account schedule and column layout records.
    /// </summary>
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

        GetPerspectiveAnalysisView();
    end;

    local procedure GetPerspectiveAnalysisView()
    var
        DimPerspectiveName: Record "Dimension Perspective Name";
    begin
        Clear(PerspectiveAnalysisView);
        if Rec.DimPerspective <> '' then
            if DimPerspectiveName.Get(Rec.DimPerspective) then
                PerspectiveAnalysisView := DimPerspectiveName."Analysis View Name";
    end;

    var
        AnalysisViewRow: Text;
        AnalysisViewColumn: Text;
        PerspectiveAnalysisView: Text;
}
