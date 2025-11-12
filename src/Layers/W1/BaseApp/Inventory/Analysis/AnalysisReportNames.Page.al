// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 7116 "Analysis Report Names"
{
    Caption = 'Analysis Report Names';
    PageType = List;
    SourceTable = "Analysis Report Name";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    ToolTip = 'Specifies the analysis report name.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    ToolTip = 'Specifies the analysis report description.';
                }
                field("Analysis Line Template Name"; Rec."Analysis Line Template Name")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    ToolTip = 'Specifies the analysis line template name for this analysis report.';
                }
                field("Analysis Column Template Name"; Rec."Analysis Column Template Name")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
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
    }
}

