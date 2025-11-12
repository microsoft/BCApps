// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

page 7155 "Sales Analysis View Card"
{
    Caption = 'Sales Analysis View Card';
    PageType = Card;
    SourceTable = "Item Analysis View";
    SourceTableView = where("Analysis Area" = const(Sales));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies a code for the analysis view.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the name of the analysis view.';
                }
                field("Item Filter"; Rec."Item Filter")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies a filter to specify the items that will be included in an analysis view.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemList: Page "Item List";
                    begin
                        ItemList.LookupMode(true);
                        if ItemList.RunModal() = ACTION::LookupOK then begin
                            Text := ItemList.GetSelectionFilter();
                            exit(true);
                        end;
                    end;
                }
                field("Location Filter"; Rec."Location Filter")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a location filter to specify that only entries posted to a particular location are to be included in an analysis view.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LocList: Page "Location List";
                    begin
                        LocList.LookupMode(true);
                        if LocList.RunModal() = ACTION::LookupOK then begin
                            Text := LocList.GetSelectionFilter();
                            exit(true);
                        end;
                    end;
                }
                field("Date Compression"; Rec."Date Compression")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the period that the program will combine entries for, in order to create a single entry for that time period.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the date from which item ledger entries will be included in an analysis view.';
                }
                field("Last Date Updated"; Rec."Last Date Updated")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the date on which the analysis view was last updated.';
                }
                field("Last Entry No."; Rec."Last Entry No.")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the number of the last item ledger entry you posted, prior to updating the analysis view.';
                }
                field("Last Budget Entry No."; Rec."Last Budget Entry No.")
                {
                    ApplicationArea = SalesBudget;
                    ToolTip = 'Specifies the number of the last item budget entry you entered prior to updating the analysis view.';
                }
                field("Update on Posting"; Rec."Update on Posting")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies if the analysis view is updated every time that you post an item ledger entry, for example from a sales invoice.';
                }
                field("Include Budgets"; Rec."Include Budgets")
                {
                    ApplicationArea = SalesBudget;
                    ToolTip = 'Specifies whether to include an update of analysis view budget entries, when updating an analysis view.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions';
                field("Dimension 1 Code"; Rec."Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 2 Code"; Rec."Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 3 Code"; Rec."Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
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
                action("Filter")
                {
                    ApplicationArea = SalesAnalysis;
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
                ApplicationArea = SalesAnalysis;
                Caption = '&Update';
                Image = Refresh;
                RunObject = Codeunit "Update Item Analysis View";
                ToolTip = 'Get the latest entries into the analysis view.';
            }
            action("Enable Update on Posting")
            {
                ApplicationArea = SalesAnalysis;
                Caption = 'Enable Update on Posting';
                Image = Apply;
                ToolTip = 'Ensure that the analysis view is updated when new ledger entries are posted.';

                trigger OnAction()
                begin
                    Rec.SetUpdateOnPosting(true);
                end;
            }
            action("Disable Update on Posting")
            {
                ApplicationArea = SalesAnalysis;
                Caption = 'Disable Update on Posting';
                Image = UnApply;
                ToolTip = 'Ensure that the analysis view is not updated when new ledger entries are posted.';

                trigger OnAction()
                begin
                    Rec.SetUpdateOnPosting(false);
                end;
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
                actionref(Filter_Promoted; Filter)
                {
                }
                actionref("Enable Update on Posting_Promoted"; "Enable Update on Posting")
                {
                }
                actionref("Disable Update on Posting_Promoted"; "Disable Update on Posting")
                {
                }
            }
        }
    }
}

