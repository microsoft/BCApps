// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using System.Utilities;

report 708 "Inventory Order Details"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Order Details';
    DefaultRenderingLayout = Word;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description", "Assembly BOM", "Inventory Posting Group", "Statistics Group", "Bin Filter";
#if not CLEAN27
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
#endif
            column(ItemTableCaptItemFilter; ItemFilterText)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(StrSbStNoSalOdrLnSalLnFlt; SalesLineFilterText)
            {
            }
            column(SalesLineFilter; SalesLineFilter)
            {
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(OutstandingAmt_SalesLine; "Sales Line"."Outstanding Amount")
            {
                IncludeCaption = true;
            }
            column(InventoryPostingGroup_Item; "Inventory Posting Group")
            {
                IncludeCaption = true;
            }
            column(AssemblyBOM_Item; "Assembly BOM")
            {
                IncludeCaption = true;
            }
#if not CLEAN27
            column(VariantFilter_Item; "Variant Filter")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(LocationFilter_Item; "Location Filter")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(GlobalDim1Filter_Item; "Global Dimension 1 Filter")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(GlobalDim2Filter_Item; "Global Dimension 2 Filter")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(BinFilter_Item; "Bin Filter")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(InvntryOrderDetailCapt; InvntryOrderDetailCaptLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(SalesHeaderBilltoNameCapt; SalesHeaderBilltoNameCaptLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(SalesLineShipDateCaption; SalesLineShipDateCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(BackOrderQtyCaption; BackOrderQtyCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(SalesLineLineDiscCaption; SalesLineLineDiscCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(SalesLineInvDiscAmtCapt; SalesLineInvDiscAmtCaptLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(SalesLineOutstngAmtCapt; SalesLineOutstngAmtCaptLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(TotalCaption; TotalCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
#endif
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"), "Bin Code" = field("Bin Filter");
                DataItemTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date") where("Document Type" = const(Order), Type = const(Item), "Outstanding Quantity" = filter(<> 0));
                RequestFilterFields = "Shipment Date";
                RequestFilterHeading = 'Sales Order Line';
                column(SalesLineDocumentNo; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(SalesHeaderBilltoName; SalesHeader."Bill-to Name")
                {
                    IncludeCaption = true;
                }
                column(ShipmentDate_SalesLine; Format("Shipment Date"))
                {
                }
                column(Quantity_SalesLine; Quantity)
                {
                    IncludeCaption = true;
                }
                column(OutstandingQty_SalesLine; "Outstanding Quantity")
                {
                    IncludeCaption = true;
                }
                column(BackOrderQty; BackOrderQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(SalesLineUnitPrice; "Unit Price")
                {
                    IncludeCaption = true;
                }
                column(SalesLineLineDiscount; "Line Discount %")
                {
                    IncludeCaption = true;
                }
                column(InvDiscountAmt_SalesLine; "Inv. Discount Amount")
                {
                    IncludeCaption = true;
                }
                column(OutstandingAmt1_SalesLine; "Outstanding Amount")
                {
                    IncludeCaption = true;
                }
                column(SalesLineDescription; Description)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    SalesHeader.Get("Document Type", "Document No.");
                    if SalesHeader."Currency Factor" <> 0 then
                        "Outstanding Amount" :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              WorkDate(), SalesHeader."Currency Code", "Outstanding Amount",
                              SalesHeader."Currency Factor"));
                    if "Shipment Date" < WorkDate() then
                        BackOrderQty := "Outstanding Quantity"
                    else
                        BackOrderQty := 0;

                    SubtotalsOutstandingQty += "Outstanding Quantity";
                    SubtotalsBackOrderQty += BackOrderQty;
                    SubtotalsOutstandingAmt += "Outstanding Amount";
                    TotalsOutstandingAmt += "Outstanding Amount";

                    if not ReportHasData then
                        ReportHasData := true;
                end;
            }
            dataitem(SubTotals; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(SubTotals_OutstandingQty; SubtotalsOutstandingQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(SubTotals_BackOrderQty; SubtotalsBackOrderQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(SubTotals_OutstandingAmt; SubtotalsOutstandingAmt)
                {
                    DecimalPlaces = 2 : 2;
                }

                trigger OnPreDataItem()
                begin
                    if "Sales Line".IsEmpty() then
                        CurrReport.Break();
                end;
            }
            trigger OnAfterGetRecord()
            begin
                SubtotalsOutstandingQty := 0;
                SubtotalsBackOrderQty := 0;
                SubtotalsOutstandingAmt := 0;
            end;
        }
        dataitem(Totals; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Totals_OutstandingAmt; TotalsOutstandingAmt)
            {
                DecimalPlaces = 2 : 2;
            }
            column(Totals_Number; Number)
            {
            }

            trigger OnPreDataItem()
            begin
                if not ReportHasData then
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory Order Details';
        AboutText = 'Analyse your outstanding sales orders to understand your expected sales volume. Show all outstanding sales and highlight overdue sales lines for each item.';

        layout
        {
        }

        actions
        {
        }
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Inventory Order Details Excel';
            LayoutFile = '.\Inventory\Reports\InventoryOrderDetails.xlsx';
            Type = Excel;
        }
        layout(Word)
        {
            Caption = 'Inventory Order Details Word';
            LayoutFile = '.\Inventory\Reports\InventoryOrderDetails.docx';
            Type = Word;
        }
#if not CLEAN27
        layout(RDLC)
        {
            Caption = 'Inventory Order Details RDLC';
            LayoutFile = '.\Inventory\Reports\InventoryOrderDetails.rdlc';
            Type = RDLC;
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel and Word layouts and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }

    labels
    {
        DataRetrieved = 'Data retrieved:';
        InventoryOrderDetails = 'Inventory Order Details';
        InventoryOrderDetailsPrint = 'Inventory Order Details (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        InvOrderDetailsAnalysis = 'Inv. Order Details (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        PostingDateFilterLabel = 'Posting Date Filter:';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
        BackOrderQtyLabel = 'Quantity on Back Order';
        ShipmentDateLabel = 'Shipment Date';
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
        SalesLineFilter := "Sales Line".GetFilters();
        if ItemFilter <> '' then
            ItemFilterText := StrSubstNo(ItemFilterCaptLbl, ItemFilter);
        if SalesLineFilter <> '' then
            SalesLineFilterText := StrSubstNo(Text000, SalesLineFilter);
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        BackOrderQty: Decimal;
        ItemFilter: Text;
        ItemFilterText: Text;
        SalesLineFilter: Text;
        SalesLineFilterText: Text;
        SubtotalsOutstandingQty: Decimal;
        SubtotalsBackOrderQty: Decimal;
        SubtotalsOutstandingAmt: Decimal;
        TotalsOutstandingAmt: Decimal;
        ReportHasData: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Sales Order Line: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ItemFilterCaptLbl: Label 'Item: %1', Comment = '%1 - item filter';
#if not CLEAN27
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        TotalCaptionLbl: Label 'Total';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        InvntryOrderDetailCaptLbl: Label 'Inventory Order Details';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        CurrReportPageNoCaptionLbl: Label 'Page';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        SalesHeaderBilltoNameCaptLbl: Label 'Customer';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        SalesLineShipDateCaptionLbl: Label 'Shipment Date';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        BackOrderQtyCaptionLbl: Label 'Quantity on Back Order';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        SalesLineLineDiscCaptionLbl: Label 'Line Discount %';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        SalesLineInvDiscAmtCaptLbl: Label 'Invoice Discount Amount';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        SalesLineOutstngAmtCaptLbl: Label 'Amount on Order Inclusive VAT';
#endif
    protected var
        SalesHeader: Record "Sales Header";
}

