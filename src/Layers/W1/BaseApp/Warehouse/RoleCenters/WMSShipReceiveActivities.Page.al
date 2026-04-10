// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Worksheet;

page 9053 "WMS Ship & Receive Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Warehouse WMS Cue";

    layout
    {
        area(content)
        {
            cuegroup("Outbound - Today")
            {
                Caption = 'Outbound - Today';
                field("Released Sales Orders - Today"; Rec."Released Sales Orders - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Sales Order List";
                }
                field("Shipments - Today"; Rec."Shipments - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Shipment List";
                }
                field("Picked Shipments - Today"; Rec."Picked Shipments - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Shipment List";
                }
                field("Posted Shipments - Today"; Rec."Posted Shipments - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Posted Whse. Shipment List";
                }

                actions
                {
                    action("New Warehouse Shipment")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'New Warehouse Shipment';
                        RunObject = Page "Warehouse Shipment";
                        RunPageMode = Create;
                        ToolTip = 'Ship items according to an advanced warehouse configuration.';
                    }
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
                field("Expected Purchase Orders"; Rec."Expected Purchase Orders")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Purchase Order List";
                }
                field(Arrivals; Rec.Arrivals)
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Receipts";
                }
                field("Posted Receipts - Today"; Rec."Posted Receipts - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Posted Whse. Receipt List";
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
                    action("New Whse. Receipt")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'New Whse. Receipt';
                        RunObject = Page "Warehouse Receipt";
                        RunPageMode = Create;
                        ToolTip = 'Receive items according to an advanced warehouse configuration. ';
                    }
                }
            }
            cuegroup(Internal)
            {
                Caption = 'Internal';
                field("Picks - All"; Rec."Picks - All")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Picks";
                }
                field("Unassigned Picks"; Rec."Unassigned Picks")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Picks";
                }
                field("Put-aways - All"; Rec."Put-aways - All")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Put-aways";
                }
                field("Unassigned Put-aways"; Rec."Unassigned Put-aways")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Put-aways";
                }
                field("Movements - All"; Rec."Movements - All")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Movements";
                }
                field("Unassigned Movements"; Rec."Unassigned Movements")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Movements";
                }
                field("Registered Picks - Today"; Rec."Registered Picks - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Registered Whse. Picks";
                }

                actions
                {
                    action("Edit Put-away Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Put-away Worksheet';
                        RunObject = Page "Put-away Worksheet";
                        ToolTip = 'Plan and organize different kinds of put-aways, including put-aways with lines from several orders. You can also assign the planned put-aways to particular warehouse employees.';
                    }
                    action("Edit Pick Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Pick Worksheet';
                        RunObject = Page "Pick Worksheet";
                        ToolTip = 'Plan and organize different kinds of picks, including picks with lines from several orders or assignment of picks to particular employees.';
                    }
                    action("Edit Movement Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Movement Worksheet';
                        RunObject = Page "Movement Worksheet";
                        ToolTip = 'Prepare to move items between bins within the warehouse.';
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

        LocationCode := Rec.GetEmployeeLocation(UserId());
        Rec.SetFilter("Location Filter", LocationCode);
    end;

    var
        LocationCode: Text[1024];
}

