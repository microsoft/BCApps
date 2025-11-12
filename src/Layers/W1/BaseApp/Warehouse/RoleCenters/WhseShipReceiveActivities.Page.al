// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Activity;

page 9050 "Whse Ship & Receive Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Warehouse Basic Cue";

    layout
    {
        area(content)
        {
            cuegroup("Outbound - Today")
            {
                Caption = 'Outbound - Today';
                field("Rlsd. Sales Orders Until Today"; Rec."Rlsd. Sales Orders Until Today")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Released Sales Orders Until Today';
                    DrillDown = true;
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of released sales orders that are displayed in the Warehouse Basic Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Posted Sales Shipments - Today"; Rec."Posted Sales Shipments - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Posted Sales Shipments";
                    ToolTip = 'Specifies the number of posted sales shipments that are displayed in the Basic Warehouse Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Transfer Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Transfer Order';
                        RunObject = Page "Transfer Order";
                        RunPageMode = Create;
                        ToolTip = 'Move items from one warehouse location to another.';
                    }
                }
            }
            cuegroup("Inbound - Today")
            {
                Caption = 'Inbound - Today';
                field("Exp. Purch. Orders Until Today"; Rec."Exp. Purch. Orders Until Today")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Expected Purch. Orders Until Today';
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of expected purchase orders that are displayed in the Basic Warehouse Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Posted Purch. Receipts - Today"; Rec."Posted Purch. Receipts - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Posted Purchase Receipts";
                    ToolTip = 'Specifies the number of posted purchase receipts that are displayed in the Warehouse Basic Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Purchase Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Purchase Order';
                        RunObject = Page "Purchase Order";
                        RunPageMode = Create;
                        ToolTip = 'Purchase goods or services from a vendor.';
                    }
                }
            }
            cuegroup(Internal)
            {
                Caption = 'Internal';
                field("Invt. Picks Until Today"; Rec."Invt. Picks Until Today")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Inventory Picks Until Today';
                    DrillDownPageID = "Inventory Picks";
                    ToolTip = 'Specifies the number of inventory picks that are displayed in the Warehouse Basic Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Invt. Put-aways Until Today"; Rec."Invt. Put-aways Until Today")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Inventory Put-aways Until Today';
                    DrillDownPageID = "Inventory Put-aways";
                    ToolTip = 'Specifies the number of inventory put-always that are displayed in the Warehouse Basic Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Open Phys. Invt. Orders"; Rec."Open Phys. Invt. Orders")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Open Phys. Invt. Orders';
                    DrillDownPageID = "Physical Inventory Orders";
                    ToolTip = 'Specifies the number of open physical inventory orders.';
                }

                actions
                {
                    action("New Inventory Pick")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Inventory Pick';
                        RunObject = Page "Inventory Pick";
                        RunPageMode = Create;
                        ToolTip = 'Prepare to pick items in a basic warehouse configuration.';
                    }
                    action("New Inventory Put-away")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Inventory Put-away';
                        RunObject = Page "Inventory Put-away";
                        RunPageMode = Create;
                        ToolTip = 'Prepare to put items away in a basic warehouse configuration.';
                    }
                    action("Edit Item Reclassification Journal")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Item Reclassification Journal';
                        RunObject = Page "Item Reclass. Journal";
                        ToolTip = 'Change data for an item, such as its location, dimension, or lot number.';
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetRange("Date Filter", 0D, WorkDate());
        Rec.SetRange("Date Filter2", WorkDate(), WorkDate());
        Rec.SetRange("User ID Filter", UserId());

        LocationCode := WhseWMSCue.GetEmployeeLocation(UserId());
        Rec.SetFilter("Location Filter", LocationCode);
    end;

    var
        WhseWMSCue: Record "Warehouse WMS Cue";
        LocationCode: Text[1024];
}

