// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Provides management interface for financial report column definitions used in financial reporting.
/// Enables creation, editing, copying, import/export, and where-used analysis of column layout templates.
/// </summary>
/// <remarks>
/// Primary functionality: Column definition management, copy operations, RapidStart import/export integration.
/// Navigation: Links to Column Layout page for detailed column editing and Financial Report usage tracking.
/// Extensibility: Standard page extension patterns for additional fields and actions.
/// </remarks>
page 488 "Column Layout Names"
{
    AboutTitle = 'About (Financial Report) Column Definitions';
    AboutText = 'Use column definitions to specify the columns to include in a report. For example, you can design a report layout to compare net change and balance for the same period this year and last year.';
    AnalysisModeEnabled = false;
    ApplicationArea = All;
    Caption = '(Financial Report) Column Definitions';
    PageType = List;
    SourceTable = "Column Layout Name";
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Analysis View Name"; Rec."Analysis View Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Status; Rec.Status) { }
                field("Internal Description"; Rec."Internal Description")
                {
                    ApplicationArea = Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
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
            action(EditColumnLayoutSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Column Definition';
                Ellipsis = true;
                Image = SetupColumns;
                ToolTip = 'Create or change the column definition for the current financial report name.';

                trigger OnAction()
                var
                    ColumnLayout: Page "Column Layout";
                begin
                    ColumnLayout.SetColumnLayoutName(Rec.Name);
                    ColumnLayout.Run();
                end;
            }
            action(WhereUsed)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Where-Used';
                ToolTip = 'View or edit financial reports in which the column definition is used.';
                Image = Track;

                trigger OnAction()
                var
                    FinancialReport: Record "Financial Report";
                begin
                    FinancialReport.SetRange("Financial Report Column Group", Rec.Name);
                    Page.Run(0, FinancialReport);
                end;
            }
            action(CopyColumnLayout)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Column Definition';
                Image = Copy;
                Scope = Repeater;
                ToolTip = 'Create a copy of the current column definition.';

                trigger OnAction()
                var
                    ColumnLayoutName: Record "Column Layout Name";
                begin
                    CurrPage.SetSelectionFilter(ColumnLayoutName);
                    Report.RunModal(Report::"Copy Column Layout", true, true, ColumnLayoutName);
                end;
            }
            action(ImportColumnDefinition)
            {
                ApplicationArea = All;
                Caption = 'Import Column Definition';
                Image = Import;
                Scope = Repeater;
                ToolTip = 'Import a RapidStart configuration package that contains settings for a set of column definitions. Importing column definitions lets you share them, for example, with another business unit. This requires that the column definition has been exported.';

                trigger OnAction()
                begin
                    Rec.XMLExchangeImport();
                end;

            }
            action(ExportColumnDefinition)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Column Definition';
                Image = Export;
                Scope = Repeater;
                ToolTip = 'Export settings for the selected column definition to a RapidStart configuration package. Exporting a column definition lets you share it with another business unit.';

                trigger OnAction()
                begin
                    Rec.XmlExchangeExport();
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(EditColumnLayoutSetup_Promoted; EditColumnLayoutSetup) { }
                actionref(WhereUsed_Promoted; WhereUsed) { }

                group(CopyExportImport)
                {
                    Caption = 'Copy/Export/Import';

                    actionref(CopyColumnLayout_Promoted; CopyColumnLayout) { }
                    actionref(ImportColumnDefinition_Promoted; ImportColumnDefinition) { }
                    actionref(ExportColumnDefinition_Promoted; ExportColumnDefinition) { }
                }
            }
        }
    }

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
        Rec.Status := FinancialReportMgt.GetDefaultStatus();
    end;
}

