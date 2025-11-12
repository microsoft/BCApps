// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

report 813 "Inventory Picking List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventoryPickingList.rdlc';
    AccessByPermission = TableData Location = R;
    ApplicationArea = Warehouse;
    Caption = 'Inventory Picking List';
    UsageCategory = ReportsAndAnalysis;

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
            }
            column(Description_Item; Description)
            {
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

                trigger OnAfterGetRecord()
                begin
                    Cust.Get("Sell-to Customer No.");
                    CalcFields("Reserved Qty. (Base)");

                    if GroupTotal then
                        if "Variant Code" <> '' then
                            ItemVariant.Get("No.", "Variant Code")
                        else
                            ItemVariant.Description := Item.Description;
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

    labels
    {
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
        ItemFilter: Text;
        SalesLineFilter: Text;
        GroupTotal: Boolean;
        GetSalesLineCurrentKey: Text[250];
        GetItemCurrentKey: Text[250];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Sales Order Line: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        InventoryPickingListCaptionLbl: Label 'Inventory Picking List';
        PageCaptionLbl: Label 'Page';
        CustomerCaptionLbl: Label 'Customer';
        ShipmentDateCaptionLbl: Label 'Shipment Date';
}

