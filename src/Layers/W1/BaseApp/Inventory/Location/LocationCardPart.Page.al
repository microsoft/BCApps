// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

page 5705 "Location Card Part"
{
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "Location";
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Location Code';
                    ToolTip = 'Specifies a location code for the warehouse or distribution center where your items are handled and stored before being sold.';

                    trigger OnDrillDown()
                    begin
                        if Rec.Code <> '' then
                            Page.Run(Page::"Location Card", Rec);
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Location Name';
                    ToolTip = 'Specifies the name or address of the location.';
                }
                field("Directed Put-away and Pick"; Rec."Directed Put-away and Pick")
                {
                    ApplicationArea = All;
                    Caption = 'Directed Put-away and Pick';
                    ToolTip = 'Specifies if the location requires advanced warehouse functionality, such as calculated bin suggestion.';
                }
                field("Allow Breakbulk"; Rec."Allow Breakbulk")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Breakbulk';
                }
                group(Bin)
                {
                    field(BinMandatory; Rec."Bin Mandatory")
                    {
                        ApplicationArea = All;
                        Caption = 'Bin Mandatory';
                        ToolTip = 'Specifies if the location requires that a bin code is specified on all item transactions.';
                    }
                    field("Bin Capacity Policy"; Rec."Bin Capacity Policy")
                    {
                        ApplicationArea = All;
                        Caption = 'Capacity Policy';
                        ToolTip = 'Specifies how bins are automatically filled, according to their capacity.';
                    }
                    field("Pick Bin Policy"; Rec."Pick Bin Policy")
                    {
                        ApplicationArea = All;
                        Caption = 'Pick Policy';
                        ToolTip = 'Specifies how bins are automatically selected for inventory picks.';
                    }
                }
                group(WarehouseHandling)
                {
                    Caption = 'Warehouse Handling';

                    field(RequirePicking; Rec."Require Pick")
                    {
                        ApplicationArea = All;
                        Caption = 'Require Pick';
                        ToolTip = 'Specifies if the location requires a dedicated warehouse activity when picking items.';
                    }
                    field("Always Create Pick Line"; Rec."Always Create Pick Line")
                    {
                        ApplicationArea = All;
                        Caption = 'Always Create Pick Line';
                        ToolTip = 'Specifies that a pick line is created, even if an appropriate zone and bin from which to pick the item cannot be found.';
                    }
                    field(RequireShipment; Rec."Require Shipment")
                    {
                        ApplicationArea = All;
                        Caption = 'Require Shipment';
                        ToolTip = 'Specifies if the location requires a shipment document when shipping items.';
                    }
                    field("Asm. Consump. Whse. Handling"; Rec."Asm. Consump. Whse. Handling")
                    {
                        ApplicationArea = All;
                        Caption = 'Assembly Consumption';
                        ToolTip = 'Specifies the warehouse handling for consumption in assembly scenarios.';
                    }
                    field("Job Consump. Whse. Handling"; Rec."Job Consump. Whse. Handling")
                    {
                        ApplicationArea = All;
                        Caption = 'Project Consumption';
                        ToolTip = 'Specifies the warehouse handling for consumption in project scenarios.';
                    }
                }
            }
        }
    }
}
