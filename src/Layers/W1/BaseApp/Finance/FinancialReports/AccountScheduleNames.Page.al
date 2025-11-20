// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 103 "Account Schedule Names"
{
    AboutTitle = 'About (Financial Report) Row Definitions';
    AboutText = 'Row definitions in financial reports provide a place for calculations that can''t be made directly in the chart of accounts. For example, you can create subtotals for groups of accounts and then include that total in other totals. You can also calculate intermediate steps that aren''t shown in the final report.';
    AdditionalSearchTerms = 'Account Schedules';
    AnalysisModeEnabled = false;
    ApplicationArea = Basic, Suite;
    Caption = '(Financial Report) Row Definitions';
    PageType = List;
    SourceTable = "Acc. Schedule Name";
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
                    ApplicationArea = Suite;
                }
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
            action(EditAccountSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Row Definition';
                Image = Edit;
                ShortCutKey = 'Return';
                ToolTip = 'Change the row definition based on the current row definition.';

                trigger OnAction()
                var
                    AccSchedule: Page "Account Schedule";
                begin
                    AccSchedule.SetAccSchedName(Rec.Name);
                    AccSchedule.Run();
                end;
            }
            action(WhereUsed)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Where-Used';
                ToolTip = 'View or edit financial reports in which the row definition is used.';
                Image = Track;

                trigger OnAction()
                var
                    FinancialReport: Record "Financial Report";
                begin
                    FinancialReport.SetRange("Financial Report Row Group", Rec.Name);
                    Page.Run(0, FinancialReport);
                end;
            }
            action(CopyAccountSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Row Definition';
                Image = Copy;
                Scope = Repeater;
                ToolTip = 'Create a copy of the current row definition.';

                trigger OnAction()
                var
                    AccScheduleName: Record "Acc. Schedule Name";
                begin
                    CurrPage.SetSelectionFilter(AccScheduleName);
                    REPORT.RunModal(REPORT::"Copy Account Schedule", true, true, AccScheduleName);
                end;
            }
            action(ImportAccountSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Row Definition';
                Image = Import;
                Scope = Repeater;
                ToolTip = 'Import a RapidStart configuration package that contains settings for a set of row definitions. Importing row definitions lets you share them, for example, with another business unit. This requires that the row definition has been exported.';

                trigger OnAction()
                begin
                    Rec.Import();
                end;
            }
            action(ExportAccountSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Row Definition';
                Image = Export;
                Scope = Repeater;
                ToolTip = 'Export settings for the selected row definition to a RapidStart configuration package. Exporting a row definition lets you share it with another business unit.';

                trigger OnAction()
                begin
                    Rec.Export();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(EditAccountSchedule_Promoted; EditAccountSchedule) { }
                actionref(WhereUsed_Promoted; WhereUsed) { }

                group(CopyExportImport)
                {
                    Caption = 'Copy/Export/Import';

                    actionref(CopyAccountSchedule_Promoted; CopyAccountSchedule) { }
                    actionref(ExportAccountSchedule_Promoted; ExportAccountSchedule) { }
                    actionref(ImportAccountSchedule_Promoted; ImportAccountSchedule) { }
                }
            }

            group(Category_Category4)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }
}

