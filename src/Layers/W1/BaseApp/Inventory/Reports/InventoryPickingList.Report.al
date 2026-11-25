// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.CRM.Team;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

report 813 "Inventory Picking List"
{
    AccessByPermission = TableData Location = R;
    ApplicationArea = Warehouse;
    Caption = 'Inventory Picking List';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = RDLCLayout;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description", "Assembly BOM", "Inventory Posting Group", "Shelf No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GetItemCurrentKey; GetItemCurrentKey)
            {
            }
            column(GetSalesLineCurrentKey; GetSalesLineCurrentKey)
            {
            }
            column(ItemTblCapItemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(SalesOrderLineSalesLine; StrSubstNo(Text000, SalesLineFilter))
            {
            }
            column(SalesLineFilter; SalesLineFilter)
            {
            }
            column(ShelfNo_Item; "Shelf No.")
            {
                IncludeCaption = true;
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(BaseUnitofMeasure_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(InventoryPickingListCaption; InventoryPickingListCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(CustomerCaption; CustomerCaptionLbl)
            {
            }
            column(ShipmentDateCaption; ShipmentDateCaptionLbl)
            {
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"), "Bin Code" = field("Bin Filter");
                DataItemTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date") where(Type = const(Item), "Document Type" = const(Order), "Qty. to Ship" = filter(<> 0));
                RequestFilterFields = "Shipment Date", "Location Code";
                RequestFilterHeading = 'Sales Order Line';
                column(DocumentNo_SalesLine; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(CustName; Cust.Name)
                {
                }
                column(ShipmentDate_SalesLine; Format("Shipment Date"))
                {
                }
                column(QtytoShipBase_SalesLine; "Qty. to Ship (Base)")
                {
                    IncludeCaption = true;
                }
                column(ReservedQtyBase_SalesLine; "Reserved Qty. (Base)")
                {
                    IncludeCaption = true;
                }
                column(BinCode_SalesLine; "Bin Code")
                {
                    IncludeCaption = true;
                }
                column(UnitofMeasure_SalesLIne; "Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
                column(QtytoShip_SalesLine; "Qty. to Ship")
                {
                    IncludeCaption = true;
                }
                column(VariantCode_SalesLine; "Variant Code")
                {
                    IncludeCaption = true;
                }
                column(LocationCode_SalesLine; "Location Code")
                {
                    IncludeCaption = true;
                }
                column(ItemVariantDescription; ItemVariant.Description)
                {
                }
                column(GroupTotal; GroupTotal)
                {
                }
                column(SellToCustomerNo_SalesLine; "Sell-to Customer No.")
                {
                    IncludeCaption = true;
                }
                column(ExternalDocumentNo_SalesHeader; SalesHeader."External Document No.")
                {
                    IncludeCaption = true;
                }
                column(YourReference_SalesHeader; SalesHeader."Your Reference")
                {
                    IncludeCaption = true;
                }
                column(DocumentDate_SalesHeader; Format(SalesHeader."Document Date"))
                {
                }
                column(DocumentDateCaption; SalesHeader.FieldCaption("Document Date"))
                {
                }
                column(SalespersonCode_SalesHeader; SalesHeader."Salesperson Code")
                {
                    IncludeCaption = true;
                }
                column(SalespersonName; SalespersonPurchaser.Name)
                {
                }
                column(ShippingAgentCode_SalesLine; "Shipping Agent Code")
                {
                    IncludeCaption = true;
                }
                column(ShippingAgentName; ShippingAgent.Name)
                {
                }
                column(NetWeight_SalesLine; "Net Weight")
                {
                    IncludeCaption = true;
                }
                column(GrossWeight_SalesLine; "Gross Weight")
                {
                    IncludeCaption = true;
                }
                column(ItemReferenceNo_SalesLine; "Item Reference No.")
                {
                    IncludeCaption = true;
                }
                column(ItemTrackingText; ItemTrackingText)
                {
                }
                column(OrderNo_SalesLine; "Document No.")
                {
                }
                column(LineNetWeight; LineNetWeight)
                {
                }
                column(LineGrossWeight; LineGrossWeight)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Cust.Get("Sell-to Customer No.");
                    CalcFields("Reserved Qty. (Base)");

                    if GroupTotal then
                        if "Variant Code" <> '' then
                            ItemVariant.Get("No.", "Variant Code")
                        else
                            ItemVariant.Description := Item.Description;

                    if not SalesHeader.Get("Document Type", "Document No.") then
                        Clear(SalesHeader);
                    if not SalespersonPurchaser.Get(SalesHeader."Salesperson Code") then
                        Clear(SalespersonPurchaser);
                    if not ShippingAgent.Get("Shipping Agent Code") then
                        Clear(ShippingAgent);
                    ItemTrackingText := GetItemTrackingText("Sales Line");
                    LineNetWeight := "Net Weight" * "Qty. to Ship";
                    LineGrossWeight := "Gross Weight" * "Qty. to Ship";
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory Picking List';
        AboutText = 'Explore sales orders that are covered when you pick items from inventory.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(GroupTotal; GroupTotal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print group totals';
                        ToolTip = 'Specifies if you want to include service orders in the cash flow forecast.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = './Inventory/Reports/InventoryPickingList.rdlc';
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
        }
        layout(WordBody)
        {
            Type = Word;
            Subtype = Body;
            LayoutFile = '.\Inventory\Reports\InventoryPickingListBody.docx';
            Caption = 'Body-only: Inventory Picking List Word';
            Summary = 'Shows the sales order lines to be picked for each item, with document number, customer, shipment date, location, bin, variant, quantity to ship, reserved quantity, and unit of measure.';
        }
    }

    labels
    {
        ItemTrackingLbl = 'Item Tracking';
        LotNoLbl = 'Lot No.';
        SerialNoLbl = 'Serial No.';
        OrderNoLbl = 'Order No.';
        SalespersonNameCaption = 'Salesperson Name';
        LineNetWeightLbl = 'Net Weight (Line)';
        LineGrossWeightLbl = 'Gross Weight (Line)';
        QtytoShipHelpTextLbl = 'Quantity to ship on the line, in the unit of measure of the line.';
        QtytoShipBaseHelpTextLbl = 'Quantity to ship on the line, in the base unit of measure of the item.';
        ReservedQtyBaseHelpTextLbl = 'Quantity already reserved for the line, in the base unit of measure of the item.';
    }

    trigger OnPreReport()
    begin
        GetItemCurrentKey := Item.CurrentKey;
        GetSalesLineCurrentKey := "Sales Line".CurrentKey;
        ItemFilter := Item.GetFilters();
        SalesLineFilter := "Sales Line".GetFilters();
    end;

    var
        Cust: Record Customer;
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ShippingAgent: Record "Shipping Agent";
        ItemFilter: Text;
        SalesLineFilter: Text;
        GroupTotal: Boolean;
        GetSalesLineCurrentKey: Text[250];
        GetItemCurrentKey: Text[250];
        ItemTrackingText: Text[250];
        LineNetWeight: Decimal;
        LineGrossWeight: Decimal;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Sales Order Line: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        InventoryPickingListCaptionLbl: Label 'Inventory Picking List';
        PageCaptionLbl: Label 'Page';
        CustomerCaptionLbl: Label 'Customer';
        ShipmentDateCaptionLbl: Label 'Shipment Date';

    local procedure GetItemTrackingText(SalesLine: Record "Sales Line"): Text[250]
    var
        ReservationEntry: Record "Reservation Entry";
        TrackingText: Text;
        TrackingEntryText: Text;
    begin
        if Item."Item Tracking Code" = '' then
            exit('');

        ReservationEntry.SetRange("Source Type", Database::"Sales Line");
        ReservationEntry.SetRange("Source Subtype", SalesLine."Document Type".AsInteger());
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        ReservationEntry.SetFilter("Item Tracking", '<>%1', ReservationEntry."Item Tracking"::None);
        if ReservationEntry.FindSet() then
            repeat
                TrackingEntryText := ReservationEntry."Serial No.";
                if ReservationEntry."Lot No." <> '' then begin
                    if TrackingEntryText <> '' then
                        TrackingEntryText := ReservationEntry."Lot No." + ' / ' + TrackingEntryText
                    else
                        TrackingEntryText := ReservationEntry."Lot No." + ' (' + Format(Abs(ReservationEntry."Quantity (Base)")) + ')';
                end;
                if TrackingText <> '' then
                    TrackingText += '; ';
                TrackingText += TrackingEntryText;
            until ReservationEntry.Next() = 0;

        exit(CopyStr(TrackingText, 1, 250));
    end;
}

