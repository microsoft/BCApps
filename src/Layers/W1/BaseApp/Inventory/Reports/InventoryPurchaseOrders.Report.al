// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using System.Utilities;

report 709 "Inventory Purchase Orders"
{
    ApplicationArea = Suite;
    Caption = 'Inventory Purchase Orders';
    DefaultRenderingLayout = Word;
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
            column(ItemTableCaptItemFilter; ItemFilterHeading)
            {
            }
            column(PurchaseLineFilter; PurchLineFilterHeading)
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
#if not CLEAN28
            column(PurchOrdLnPurchLnFilter; StrSubstNo(TableFilterTxt, PurchLineFilter))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemFilter; ItemFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PurchLineFilter; PurchLineFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InventoryPurchaseOrdersCaption; InventoryPurchaseOrdersCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PurchHeaderPaytoNameCaption; PurchHeaderPaytoNameCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PurchaseLineExpectedReceiptDateCaption; PurchaseLineExpectedReceiptDateCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(BackOrderQtyCaption; BackOrderQtyCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PurchaseLineLineDiscountCaption; PurchaseLineLineDiscountCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PurchaseLineInvDiscountAmountCaption; PurchaseLineInvDiscountAmountCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PurchaseLineOutstandingAmountCaption; PurchaseLineOutstandingAmountCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(TotalCaption; TotalCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
#endif
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

                    SubtotalsOutstandingQuantity += "Outstanding Quantity";
                    SubtotalsQtyOnBackOrder += BackOrderQty;
                    SubtotalsAmountOnOrder += "Outstanding Amount";

                    TotalsOutstandingAmount += "Outstanding Amount";
                end;
            }
            dataitem(Subtotals; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(Subtotals_OutstandingQuantity; SubtotalsOutstandingQuantity)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(Subtotals_QtyOnBackOrder; SubtotalsQtyOnBackOrder)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(Subtotals_AmountOnOrder; SubtotalsAmountOnOrder)
                {
                    AutoFormatType = 1;
                }

                trigger OnPreDataItem()
                begin
                    if "Purchase Line".IsEmpty() then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ItemDescription := Description;

                Clear(SubtotalsOutstandingQuantity);
                Clear(SubtotalsQtyOnBackOrder);
                Clear(SubtotalsAmountOnOrder);
            end;
        }
        dataitem(Totals; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(Totals_OutstandingAmount; TotalsOutstandingAmount)
            {
                AutoFormatType = 1;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory Purchase Orders';
        AboutText = 'Analyse your outstanding purchase orders to understand your expected purchase volume. Show all outstanding purchases and highlight overdue purchase lines for each item.';

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    // Used to set a report header across multiple languages
                    field(RequestItemFilterHeading; ItemFilterHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Item Filter';
                        ToolTip = 'Specifies the Item Filters applied to this report.';
                        Visible = false;
                    }
                    // Used to set a report header across multiple languages
                    field(RequestPurchLineFilterHeading; PurchLineFilterHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Purchase Line Filter';
                        ToolTip = 'Specifies the Purchase Line filters applied to this report.';
                        Visible = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnClosePage()
        begin
            UpdateRequestPageFilterValues();
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Inventory Purchase Orders Excel';
            Type = Excel;
            LayoutFile = './Inventory/Reports/InventoryPurchaseOrders.xlsx';
            Summary = 'Built in layout for the Inventory Purchase Orders Excel report.';
        }
        layout(Word)
        {
            Caption = 'Inventory Purchase Orders Word';
            Type = Word;
            LayoutFile = './Inventory/Reports/InventoryPurchaseOrders.docx';
            Summary = 'Built in layout for the Inventory Purchase Orders Word report.';
        }
#if not CLEAN28
        layout(RDLC)
        {
            Caption = 'Inventory Purchase Orders RDLC (Obsolete)';
            Type = RDLC;
            LayoutFile = './Inventory/Reports/InventoryPurchaseOrders.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel and Word layouts and will be removed in a future release.';
            ObsoleteTag = '28.0';
            Summary = 'Built in layout for the Inventory Purchase Orders RDLC (Obsolete) report.';
        }
#endif
    }

    labels
    {
        InventoryPurchOrdersLbl = 'Inventory Purchase Orders';
        InventoryPurchOrdersPrintLbl = 'Inventory Purch. Orders (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        InvPurchOrdersAnalysisLbl = 'Inv. Purch. Orders (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrievedLbl = 'Data retrieved:';
        ItemNoLbl = 'Item No.';
        ItemDescLbl = 'Item Description';
        VendorLbl = 'Vendor';
        ExpectedReceiptDateLbl = 'Expected Receipt Date';
        QtyOnBackOrderLbl = 'Qty. on Back Order';
        LineDiscountLbl = 'Line Disc. %';
        InvDiscountAmountLbl = 'Inv. Disc. Amount';
        AmtOnOrderInclVATLbl = 'Amount on Order Incl. VAT';
        TotalsLbl = 'Total';
        // About the report labels
        AboutTheReportLbl = 'About the report';
        EnvironmentLbl = 'Environment';
        CompanyLbl = 'Company';
        UserLbl = 'User';
        RunOnLbl = 'Run on';
        ReportNameLbl = 'Report name';
        DocumentationLbl = 'Documentation';
    }

    trigger OnPreReport()
    begin
        UpdateRequestPageFilterValues();
    end;

    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PurchaseHeader: Record "Purchase Header";
        ItemFilter: Text;
        PurchLineFilter: Text;
        ItemFilterHeading: Text;
        PurchLineFilterHeading: Text;
        BackOrderQty: Decimal;
        ItemDescription: Text[100];
        SubtotalsOutstandingQuantity: Decimal;
        SubtotalsQtyOnBackOrder: Decimal;
        SubtotalsAmountOnOrder: Decimal;
        TotalsOutstandingAmount: Decimal;
#if not CLEAN28
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
#endif

    // Ensures Layout Filter Headings are up to date
    local procedure UpdateRequestPageFilterValues()
    begin
        ItemFilter := Item.GetFilters();
        PurchLineFilter := "Purchase Line".GetFilters();

        ItemFilterHeading := '';
        PurchLineFilterHeading := '';
        if ItemFilter <> '' then
            ItemFilterHeading := Item.TableCaption + ': ' + ItemFilter;
        if PurchLineFilter <> '' then
            PurchLineFilterHeading := "Purchase Line".TableCaption + ': ' + PurchLineFilter;
    end;
}

