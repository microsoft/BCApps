// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

report 7322 "Inventory Put-away List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/Reports/InventoryPutawayList.rdlc';
    AccessByPermission = TableData Location = R;
    ApplicationArea = Warehouse;
    Caption = 'Inventory Put-away List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description", "Assembly BOM", "Inventory Posting Group", "Shelf No.", "Bin Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(PurchLineFilter; PurchLineFilter)
            {
            }
            column(GroupTotal; GroupTotal)
            {
            }
            column(ItemTableCaption; TableCaption + ': ' + ItemFilter)
            {
            }
            column(PurchOrderLineFilter; StrSubstNo(Text000, PurchLineFilter))
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
            column(InventoryPutawayListCptn; InventoryPutawayListCptnLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(VendorNameCaption; VendorNameCaptionLbl)
            {
            }
            column(PurchLineExpRcptDateCptn; PurchLineExpRcptDateCptnLbl)
            {
            }
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"), "Bin Code" = field("Bin Filter");
                DataItemTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Expected Receipt Date") where(Type = const(Item), "Document Type" = const(Order), "Qty. to Receive" = filter(<> 0));
                RequestFilterFields = "Expected Receipt Date", "Location Code";
                RequestFilterHeading = 'Purchase Order Line';
                column(UOMCode_PurchLine; "Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
                column(QtytoReceive_PurchLine; "Qty. to Receive")
                {
                    IncludeCaption = true;
                }
                column(ReservedQtyBase_PurchLine; "Reserved Qty. (Base)")
                {
                    IncludeCaption = true;
                }
                column(QtytoRecvBase_PurchLine; "Qty. to Receive (Base)")
                {
                    IncludeCaption = true;
                }
                column(ExpRcptDate_PurchLine; Format("Expected Receipt Date"))
                {
                }
                column(BinCode_PurchLine; "Bin Code")
                {
                    IncludeCaption = true;
                }
                column(LocationCode_PurchLine; "Location Code")
                {
                    IncludeCaption = true;
                }
                column(VariantCode_PurchLine; "Variant Code")
                {
                    IncludeCaption = true;
                }
                column(VendorName; Vendor.Name)
                {
                }
                column(DocumentNo_PurchLine; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(ItemVariantDescription; ItemVariant.Description)
                {
                }
                column(CurrReportTotalsCausedBy; TotalsCausedBy)
                {
                }
                column(BinCodeFieldNo_PurchLine; FieldNo("Bin Code"))
                {
                }
                column(No_PurchLine; "No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Vendor.Get("Buy-from Vendor No.");
                    CalcFields("Reserved Qty. (Base)");

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
                        ApplicationArea = Warehouse;
                        Caption = 'Print group totals';
                        ToolTip = 'Specifies if you would like the group totals to be printed on the report.';
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
        ItemFilter := Item.GetFilters();
        PurchLineFilter := "Purchase Line".GetFilters();
    end;

    var
        Vendor: Record Vendor;
        ItemVariant: Record "Item Variant";
        ItemFilter: Text;
        PurchLineFilter: Text;
        GroupTotal: Boolean;
        TotalsCausedBy: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Purchase Order Line: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        InventoryPutawayListCptnLbl: Label 'Inventory Put-away List';
        CurrReportPageNoCaptionLbl: Label 'Page';
        VendorNameCaptionLbl: Label 'Vendor';
        PurchLineExpRcptDateCptnLbl: Label 'Expected Receipt Date';
}

