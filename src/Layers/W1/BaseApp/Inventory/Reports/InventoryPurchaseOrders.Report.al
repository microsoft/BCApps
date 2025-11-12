// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;

report 709 "Inventory Purchase Orders"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventoryPurchaseOrders.rdlc';
    ApplicationArea = Suite;
    Caption = 'Inventory Purchase Orders';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description", "Assembly BOM", "Inventory Posting Group", "Statistics Group", "Bin Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTableCaptItemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(PurchOrdLnPurchLnFilter; StrSubstNo(TableFilterTxt, PurchLineFilter))
            {
            }
            column(PurchLineFilter; PurchLineFilter)
            {
            }
            column(ItemNo; "No.")
            {
            }
            column(Description_Item; Description)
            {
            }
            column(OutstandingAmt_PurchLine; "Purchase Line"."Outstanding Amount")
            {
            }
            column(VariantFilter_Item; "Variant Filter")
            {
            }
            column(LocationFilter_Item; "Location Filter")
            {
            }
            column(GlobalDim1Filter_Item; "Global Dimension 1 Filter")
            {
            }
            column(GlobalDim2Filter_Item; "Global Dimension 2 Filter")
            {
            }
            column(ItemBinFilter; "Bin Filter")
            {
            }
            column(InventoryPurchaseOrdersCaption; InventoryPurchaseOrdersCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(PurchHeaderPaytoNameCaption; PurchHeaderPaytoNameCaptionLbl)
            {
            }
            column(PurchaseLineExpectedReceiptDateCaption; PurchaseLineExpectedReceiptDateCaptionLbl)
            {
            }
            column(BackOrderQtyCaption; BackOrderQtyCaptionLbl)
            {
            }
            column(PurchaseLineLineDiscountCaption; PurchaseLineLineDiscountCaptionLbl)
            {
            }
            column(PurchaseLineInvDiscountAmountCaption; PurchaseLineInvDiscountAmountCaptionLbl)
            {
            }
            column(PurchaseLineOutstandingAmountCaption; PurchaseLineOutstandingAmountCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"), "Bin Code" = field("Bin Filter");
                DataItemTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Expected Receipt Date") where(Type = const(Item), "Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                RequestFilterFields = "Expected Receipt Date";
                RequestFilterHeading = 'Purchase Order Line';
                column(DocumentNo_PurchaseLine; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(PattoName_PurchaseLine; PurchaseHeader."Pay-to Name")
                {
                }
                column(ExpReceiptDt_PurchaseLine; Format("Expected Receipt Date"))
                {
                }
                column(Quantity_PurchaseLine; Quantity)
                {
                    IncludeCaption = true;
                }
                column(OutStandingQty_PurchLine; "Outstanding Quantity")
                {
                    IncludeCaption = true;
                }
                column(BackOrderQty; BackOrderQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(DirectUnitCost_PurchLine; "Direct Unit Cost")
                {
                    IncludeCaption = true;
                }
                column(LineDiscount_PurchaseLine; "Line Discount %")
                {
                }
                column(InvDiscountAmt_PurchLine; "Inv. Discount Amount")
                {
                }
                column(OutstandingAmt1_PurchLine; "Outstanding Amount")
                {
                }
                column(Description1_Item; ItemDescription)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PurchaseHeader.Get("Document Type", "Document No.");
                    if PurchaseHeader."Currency Factor" <> 0 then
                        "Outstanding Amount" :=
                          Round(
                            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                              WorkDate(), PurchaseHeader."Currency Code",
                              "Outstanding Amount", PurchaseHeader."Currency Factor"));
                    if "Expected Receipt Date" < WorkDate() then
                        BackOrderQty := "Outstanding Quantity"
                    else
                        BackOrderQty := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ItemDescription := Description;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory Purchase Orders';
        AboutText = 'Analyse your outstanding purchase orders to understand your expected purchase volume. Show all outstanding purchases and highlight overdue purchase lines for each item.';

        layout
        {
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
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PurchaseHeader: Record "Purchase Header";
        ItemFilter: Text;
        PurchLineFilter: Text;
        BackOrderQty: Decimal;
        ItemDescription: Text[100];

        TableFilterTxt: Label 'Purchase Order Line: %1', Comment = '%1 - table filters';
        InventoryPurchaseOrdersCaptionLbl: Label 'Inventory Purchase Orders';
        CurrReportPageNoCaptionLbl: Label 'Page';
        PurchHeaderPaytoNameCaptionLbl: Label 'Vendor';
        PurchaseLineExpectedReceiptDateCaptionLbl: Label 'Expected Receipt Date';
        BackOrderQtyCaptionLbl: Label 'Quantity on Back Order';
        PurchaseLineLineDiscountCaptionLbl: Label 'Line Disc. %';
        PurchaseLineInvDiscountAmountCaptionLbl: Label 'Inv. Discount Amount';
        PurchaseLineOutstandingAmountCaptionLbl: Label 'Amount on Order Incl. VAT';
        TotalCaptionLbl: Label 'Total';
}

