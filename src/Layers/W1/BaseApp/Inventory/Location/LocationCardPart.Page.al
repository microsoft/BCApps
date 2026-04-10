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
                }
                field("Directed Put-away and Pick"; Rec."Directed Put-away and Pick")
                {
                    ApplicationArea = All;
                    Caption = 'Directed Put-away and Pick';
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
                    }
                    field("Bin Capacity Policy"; Rec."Bin Capacity Policy")
                    {
                        ApplicationArea = All;
                        Caption = 'Capacity Policy';
                    }
                    field("Pick Bin Policy"; Rec."Pick Bin Policy")
                    {
                        ApplicationArea = All;
                        Caption = 'Pick Policy';
                    }
                }
                group(WarehouseHandling)
                {
                    Caption = 'Warehouse Handling';

                    field(RequirePicking; Rec."Require Pick")
                    {
                        ApplicationArea = All;
                        Caption = 'Require Pick';
                    }
                    field("Always Create Pick Line"; Rec."Always Create Pick Line")
                    {
                        ApplicationArea = All;
                        Caption = 'Always Create Pick Line';
                    }
                    field(RequireShipment; Rec."Require Shipment")
                    {
                        ApplicationArea = All;
                        Caption = 'Require Shipment';
                    }
                    field("Asm. Consump. Whse. Handling"; Rec."Asm. Consump. Whse. Handling")
                    {
                        ApplicationArea = All;
                        Caption = 'Assembly Consumption';
                    }
                    field("Job Consump. Whse. Handling"; Rec."Job Consump. Whse. Handling")
                    {
                        ApplicationArea = All;
                        Caption = 'Project Consumption';
                    }
                }
            }
        }
    }
}
