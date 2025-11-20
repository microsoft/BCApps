// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;

page 908 "Assembly Availability"
{
    Caption = 'Assembly Availability';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    InstructionalText = 'The quantity on inventory is not sufficient to cover the net change in inventory. Are you sure that you want to record the quantity?';
    ModifyAllowed = false;
    PageType = ConfirmationDialog;
    SourceTable = "Assembly Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Details)
            {
                Caption = 'Details';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number assigned to the assembly order from the number series that you set up in the Assembly Setup window.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item that is being assembled with the assembly order.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the description of the assembly item.';
                }
                field("Current Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Current Quantity';
                    ToolTip = 'Specifies how many units of the assembly item remain to be posted as assembled output.';
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of the assembly item are reserved for this assembly order header.';
                }
                field(AbleToAssemble; QtyAvailToMake)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Able to Assemble';
                    DecimalPlaces = 0 : 5;
                    Style = Unfavorable;
                    StyleExpr = QtyAvailTooLow;
                    ToolTip = 'Specifies how many units of the assembly item can be assembled, based on the availability of components on the assembly order lines.';
                }
                field(EarliestAvailableDate; EarliestAvailableDate)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Earliest Available Date';
                    ToolTip = 'Specifies the late arrival date of an inbound supply order that can cover the needed quantity of the assembly item.';
                }
                field(Inventory; Inventory)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the assembly item are in inventory.';

                    trigger OnDrillDown()
                    var
                        Item: Record Item;
                        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
                    begin
                        Item.Get(Rec."Item No.");
                        Rec.SetItemFilter(Item);
                        ItemAvailFormsMgt.ShowItemLedgerEntries(Item, false);
                    end;
                }
                field(GrossRequirement; GrossRequirement)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Gross Requirement';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total demand for the assembly item.';
                }
                field(ReservedRequirement; ReservedRequirement)
                {
                    ApplicationArea = Planning;
                    Caption = 'Reserved Requirement';
                }
                field(ScheduledReceipts; ScheduledReceipts)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Scheduled Receipts';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the assembly item are inbound on orders.';
                }
                field(ReservedReceipts; ReservedReceipts)
                {
                    ApplicationArea = Planning;
                    Caption = 'Reserved Receipts';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the code of the item variant of the item that is being assembled.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location to which you want to post output of the assembly item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the unit of measure code of the assembly item.';
                }
                part(AssemblyLineAvail; "Assembly Line Avail.")
                {
                    ApplicationArea = Assembly;
                    SubPageLink = "Document Type" = field("Document Type"),
                                  "Document No." = field("No.");
                }
            }
        }
    }

    actions
    {
    }

    var
        Inventory: Decimal;
        GrossRequirement: Decimal;
        ReservedRequirement: Decimal;
        ScheduledReceipts: Decimal;
        ReservedReceipts: Decimal;
        EarliestAvailableDate: Date;
        QtyAvailToMake: Decimal;
        QtyAvailTooLow: Boolean;

    [Scope('OnPrem')]
    procedure SetData(var TempAssemblyHeader2: Record "Assembly Header" temporary; var TempAssemblyLine2: Record "Assembly Line" temporary)
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        Rec.Copy(TempAssemblyHeader2, true);
        TempAssemblyLine.Copy(TempAssemblyLine2, true);
        CurrPage.AssemblyLineAvail.PAGE.SetHeader(TempAssemblyHeader2);
        CurrPage.AssemblyLineAvail.PAGE.SetLinesRecord(TempAssemblyLine);
    end;

    procedure SetHeaderInventoryData(Inventory2: Decimal; GrossRequirement2: Decimal; ReservedRequirement2: Decimal; ScheduledReceipts2: Decimal; ReservedReceipts2: Decimal; EarliestAvailableDate2: Date; QtyAvailToMake2: Decimal; QtyAvailTooLow2: Boolean)
    begin
        Inventory := Inventory2;
        GrossRequirement := GrossRequirement2;
        ReservedRequirement := ReservedRequirement2;
        ScheduledReceipts := ScheduledReceipts2;
        ReservedReceipts := ReservedReceipts2;
        EarliestAvailableDate := EarliestAvailableDate2;
        QtyAvailToMake := QtyAvailToMake2;
        QtyAvailTooLow := QtyAvailTooLow2;
    end;
}

