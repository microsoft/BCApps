// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Utilities;

page 7151 "Item Analysis View List"
{
    Caption = 'Analysis View List';
    DataCaptionFields = "Analysis Area";
    Editable = false;
    PageType = List;
    SourceTable = "Item Analysis View";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                }
                field("Include Budgets"; Rec."Include Budgets")
                {
                    ApplicationArea = ItemBudget;
                }
                field("Last Date Updated"; Rec."Last Date Updated")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    Editable = false;
                }
                field("Dimension 1 Code"; Rec."Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 2 Code"; Rec."Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 3 Code"; Rec."Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
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
        area(navigation)
        {
            group("&Analysis")
            {
                Caption = '&Analysis';
                Image = AnalysisView;
                action(Card)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    var
                        PageManagement: Codeunit "Page Management";
                    begin
                        PageManagement.PageRun(Rec);
                    end;
                }
                action(PageItemAnalysisViewFilter)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    Caption = 'Filter';
                    Image = "Filter";
                    RunObject = Page "Item Analysis View Filter";
                    RunPageLink = "Analysis Area" = field("Analysis Area"),
                                  "Analysis View Code" = field(Code);
                    ToolTip = 'Apply the filter.';
                }
            }
        }
        area(processing)
        {
            action("&Update")
            {
                ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                Caption = '&Update';
                Image = Refresh;
                RunObject = Codeunit "Update Item Analysis View";
                ToolTip = 'Get the latest entries into the analysis view.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Update_Promoted"; "&Update")
                {
                }
            }
        }
    }
}

