// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Analysis;

using Microsoft.Inventory.Analysis;

page 9375 "Analysis Report Purchase"
{
    ApplicationArea = PurchaseAnalysis;
    Caption = 'Purchase Analysis Reports';
    PageType = List;
    SourceTable = "Analysis Report Name";
    SourceTableView = where("Analysis Area" = const(Purchase));
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
                    ApplicationArea = PurchaseAnalysis;
                    ToolTip = 'Specifies the analysis report name.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = PurchaseAnalysis;
                    ToolTip = 'Specifies the analysis report description.';
                }
                field("Analysis Line Template Name"; Rec."Analysis Line Template Name")
                {
                    ApplicationArea = PurchaseAnalysis;
                    ToolTip = 'Specifies the analysis line template name for this analysis report.';
                }
                field("Analysis Column Template Name"; Rec."Analysis Column Template Name")
                {
                    ApplicationArea = PurchaseAnalysis;
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
                ApplicationArea = PurchaseAnalysis;
                Caption = 'Edit Analysis Report';
                Image = Edit;
                ShortCutKey = 'Return';
                ToolTip = 'Edit the settings for the analysis report such as the name or period.';

                trigger OnAction()
                var
                    PurchaseAnalysisReport: Page "Purchase Analysis Report";
                begin
                    PurchaseAnalysisReport.SetReportName(Rec.Name);
                    PurchaseAnalysisReport.Run();
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

