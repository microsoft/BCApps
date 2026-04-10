// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Warehouse.Ledger;

page 9323 "Simulated Production Orders"
{
    AdditionalSearchTerms = 'order prototype';
    ApplicationArea = Manufacturing;
    Caption = 'Simulated Production Orders';
    CardPageID = "Simulated Production Order";
    Editable = false;
    PageType = List;
    SourceTable = "Production Order";
    SourceTableView = where(Status = const(Simulated));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    Lookup = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Finished Date"; Rec."Finished Date")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Pro&d. Order")
            {
                Caption = 'Pro&d. Order';
                Image = "Order";
                group("E&ntries")
                {
                    Caption = 'E&ntries';
                    Image = Entries;
                    action("Item Ledger E&ntries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Item Ledger E&ntries';
                        Image = ItemLedger;
                        RunObject = Page "Item Ledger Entries";
                        RunPageLink = "Order Type" = const(Production),
                                      "Order No." = field("No.");
                        RunPageView = sorting("Order Type", "Order No.");
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the item ledger entries of the item on the document or journal line.';
                    }
                    action("Capacity Ledger Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Capacity Ledger Entries';
                        Image = CapacityLedger;
                        RunObject = Page "Capacity Ledger Entries";
                        RunPageLink = "Order Type" = const(Production),
                                      "Order No." = field("No.");
                        RunPageView = sorting("Order Type", "Order No.");
                        ToolTip = 'View the capacity ledger entries of the involved production order. Capacity is recorded either as time (run time, stop time, or setup time) or as quantity (scrap quantity or output quantity).';
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Value Entries';
                        Image = ValueLedger;
                        RunObject = Page "Value Entries";
                        RunPageLink = "Order Type" = const(Production),
                                      "Order No." = field("No.");
                        RunPageView = sorting("Order Type", "Order No.");
                        ToolTip = 'View the value entries of the item on the document or journal line.';
                    }
                    action("&Warehouse Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Warehouse Entries';
                        Image = BinLedger;
                        RunObject = Page "Warehouse Entries";
                        RunPageLink = "Source Type" = filter(83 | 5407),
                                      "Source Subtype" = filter("3" | "4" | "5"),
                                      "Source No." = field("No.");
                        RunPageView = sorting("Source Type", "Source Subtype", "Source No.");
                        ToolTip = 'View the history of quantities that are registered for the item in warehouse activities. ';
                    }
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Prod. Order Comment Sheet";
                    RunPageLink = Status = field(Status),
                                  "Prod. Order No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
                action(Statistics)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Production Order Statistics";
                    RunPageLink = Status = field(Status),
                                  "No." = field("No."),
                                  "Date Filter" = field("Date Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Change &Status")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Change &Status';
                    Image = ChangeStatus;
                    ToolTip = 'Change the status of the selected production order(s) to a new one.';

                    trigger OnAction()
                    var
                        ProductionOrder: record "Production Order";
                        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
                    begin
                        CurrPage.SetSelectionFilter(ProductionOrder);
                        ProdOrderStatusMgt.ChangeStatusWithSelectionFilter(ProductionOrder);
                    end;
                }
                action("&Update Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Update Unit Cost';
                    Ellipsis = true;
                    Image = UpdateUnitCost;
                    ToolTip = 'Update the cost of the parent item per changes to the production BOM or routing.';

                    trigger OnAction()
                    var
                        ProdOrder: Record "Production Order";
                    begin
                        ProdOrder.SetRange(Status, Rec.Status);
                        ProdOrder.SetRange("No.", Rec."No.");

                        REPORT.RunModal(REPORT::"Update Unit Cost", true, true, ProdOrder);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Change &Status_Promoted"; "Change &Status")
                {
                }
                actionref("&Update Unit Cost_Promoted"; "&Update Unit Cost")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }
}

