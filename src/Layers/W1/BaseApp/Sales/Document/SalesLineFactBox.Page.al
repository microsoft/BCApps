// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Availability;

page 9087 "Sales Line FactBox"
{
    Caption = 'Sales Line Details';
    PageType = CardPart;
    SourceTable = "Sales Line";

    layout
    {
        area(content)
        {
            field(ItemNo; ShowNo())
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item No.';
                Lookup = false;
                ToolTip = 'Specifies the item that is handled on the sales line.';

                trigger OnDrillDown()
                begin
                    SalesInfoPaneMgt.LookupItem(Rec);
                end;
            }
            field("Required Quantity"; Rec."Outstanding Quantity" - Rec."Reserved Quantity")
            {
                ApplicationArea = Reservation;
                Caption = 'Required Quantity';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies how many units of the item are required on the sales line.';
            }
            group(Attachments)
            {
                Caption = 'Attachments';
                field("Attached Doc Count"; Rec."Attached Doc Count")
                {
                    ApplicationArea = All;
                    Caption = 'Documents';
                    ToolTip = 'Specifies the number of attachments.';

                    trigger OnDrillDown()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
            }
            group(Availability)
            {
                Caption = 'Availability';
                field("Shipment Date"; SalesInfoPaneMgt.CalcAvailabilityDate(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Shipment Date';
                    ToolTip = 'Specifies when the items on the sales line must be shipped.';
                }
                field("Item Availability"; SalesInfoPaneMgt.CalcAvailability(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Availability';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies how may units of the item on the sales line are available, in inventory or incoming before the shipment date.';

                    trigger OnDrillDown()
                    begin
#if not CLEAN25
                        ItemAvailFormsMgt.ShowItemAvailFromSalesLine(Rec, "Item Availability Type"::"Event".AsInteger());
#else
                        SalesAvailabilityMgt.ShowItemAvailabilityFromSalesLine(Rec, "Item Availability Type"::"Event");
#endif
                        CurrPage.Update(true);
                    end;
                }
                field("Available Inventory"; SalesInfoPaneMgt.CalcAvailableInventory(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
                }
                field("Scheduled Receipt"; SalesInfoPaneMgt.CalcScheduledReceipt(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the assembly component are inbound on purchase orders, transfer orders, assembly orders, firm planned production orders, and released production orders.';
                }
                field("Reserved Receipt"; SalesInfoPaneMgt.CalcReservedRequirements(Rec))
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item on the sales line are reserved on incoming receipts.';
                }
                field("Gross Requirements"; SalesInfoPaneMgt.CalcGrossRequirements(Rec))
                {
                    ApplicationArea = Service;
                    Caption = 'Gross Requirements';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies, for the item on the sales line, dependent demand plus independent demand. Dependent demand comes production order components of all statuses, assembly order components, and planning lines. Independent demand comes from sales orders, transfer orders, service orders, project tasks, and demand forecasts.';
                }
                field("Reserved Requirements"; SalesInfoPaneMgt.CalcReservedDemand(Rec))
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved Requirements';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies, for the item on the sales line, how many are reserved on demand records.';
                }
                field("Reserved from Stock"; SalesInfoPaneMgt.GetQtyReservedFromStockState(Rec))
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved from stock';
                    Tooltip = 'Specifies what part of the sales line is reserved from inventory.';
                }
            }
            group(Item)
            {
                Caption = 'Item';
                field(UnitofMeasureCode; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit of Measure Code';
                    ToolTip = 'Specifies the unit of measure that is used to determine the value in the Unit Price field on the sales line.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. per Unit of Measure';
                    ToolTip = 'Specifies an auto-filled number if you have included Sales Unit of Measure on the item card and a quantity in the Qty. per Unit of Measure field.';
                }
                field(Substitutions; SalesInfoPaneMgt.CalcNoOfSubstitutions(Rec))
                {
                    ApplicationArea = Suite;
                    Caption = 'Substitutions';
                    DrillDown = true;
                    ToolTip = 'Specifies other items that are set up to be traded instead of the item in case it is not available.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord();
                        Rec.ShowItemSub();
                        CurrPage.Update(true);
                        if (Rec.Reserve = Rec.Reserve::Always) and (Rec."No." <> xRec."No.") then begin
                            Rec.AutoReserve();
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field(SalesPrices; SalesInfoPaneMgt.CalcNoOfSalesPrices(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    DrillDown = true;
                    ToolTip = 'Specifies special sales prices that you grant when certain conditions are met, such as customer, quantity, or ending date. The price agreements can be for individual customers, for a group of customers, for all customers or for a campaign.';

                    trigger OnDrillDown()
                    begin
                        Rec.PickPrice();
                        CurrPage.Update();
                    end;
                }
                field(SalesLineDiscounts; SalesInfoPaneMgt.CalcNoOfSalesLineDisc(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Line Discounts';
                    DrillDown = true;
                    ToolTip = 'Specifies how many special discounts you grant for the sales line. Choose the value to see the sales line discounts.';

                    trigger OnDrillDown()
                    begin
                        Rec.PickDiscount();
                        CurrPage.Update();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.ClearSalesHeader();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Reserved Quantity", "Attached Doc Count");
        SalesInfoPaneMgt.ResetItemNo();
    end;

    protected var
        SalesInfoPaneMgt: Codeunit "Sales Info-Pane Management";
#if not CLEAN25
        [Obsolete('Replaced by SalesAvailabilityMgt', '25.0')]
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
#else
        SalesAvailabilityMgt: Codeunit "Sales Availability Mgt.";
#endif

    local procedure ShowNo(): Code[20]
    begin
        if Rec.Type <> Rec.Type::Item then
            exit('');
        exit(Rec."No.");
    end;
}

