// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 9377 "Analysis Report Inventory"
{
    ApplicationArea = InventoryAnalysis;
    Caption = 'Inventory Analysis Reports';
    PageType = List;
    SourceTable = "Analysis Report Name";
    SourceTableView = where("Analysis Area" = const(Inventory));
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
                    ApplicationArea = InventoryAnalysis;
                    ToolTip = 'Specifies the analysis report name.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = InventoryAnalysis;
                    ToolTip = 'Specifies the analysis report description.';
                }
                field("Analysis Line Template Name"; Rec."Analysis Line Template Name")
                {
                    ApplicationArea = InventoryAnalysis;
                    ToolTip = 'Specifies the analysis line template name for this analysis report.';
                }
                field("Analysis Column Template Name"; Rec."Analysis Column Template Name")
                {
                    ApplicationArea = InventoryAnalysis;
                    ToolTip = 'Specifies the column template name for this analysis report.';
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
            action(EditAnalysisReport)
            {
                ApplicationArea = InventoryAnalysis;
                Caption = 'Edit Analysis Report';
                Image = Edit;
                ShortCutKey = 'Return';
                ToolTip = 'Edit the settings for the analysis report such as the name or period.';

                trigger OnAction()
                var
                    InventoryAnalysisReport: Page "Inventory Analysis Report";
                begin
                    InventoryAnalysisReport.SetReportName(Rec.Name);
                    InventoryAnalysisReport.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(EditAnalysisReport_Promoted; EditAnalysisReport)
                {
                }
            }
        }
    }
}

