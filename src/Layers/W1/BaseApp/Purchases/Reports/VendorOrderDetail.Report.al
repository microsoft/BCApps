// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;

report 308 "Vendor - Order Detail"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorOrderDetail.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Order Detail';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", Priority;
            column(ReceivingDatePeriodText; StrSubstNo(PeriodTxt, PeriodText))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintAmountsinLCY; PrintAmountsInLCYReq)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(VendFilterTableCaption; StrSubstNo(TableFilterTxt, TableCaption(), VendFilter))
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(PurchOrderLineFilter; StrSubstNo(PurchaseLineFilterTxt, PurchLineFilter))
            {
            }
            column(PurchLineFilter; PurchLineFilter)
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(GlobalDim1Filter_Vendor; "Global Dimension 1 Filter")
            {
            }
            column(GlobalDim2Filter_Vendor; "Global Dimension 2 Filter")
            {
            }
            column(VendorOrderDetailCaption; VendorOrderDetailCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(AllamountsareinLCYCaption; AllamountsareinLCYCaptionLbl)
            {
            }
            column(ExpectedDateCaption; ExpectedDateCaptionLbl)
            {
            }
            column(BackOrderQtyCaption; BackOrderQtyCaptionLbl)
            {
            }
            column(LineDiscountPercentageCaption; LineDiscountPercentageCaptionLbl)
            {
            }
            column(InvDiscountAmountCaption; InvDiscountAmountCaptionLbl)
            {
            }
            column(OutstandingOrdersCaption; OutstandingOrdersCaptionLbl)
            {
            }
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Pay-to Vendor No." = field("No."), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Document Type", "Pay-to Vendor No.", "Currency Code") where("Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                RequestFilterFields = "Expected Receipt Date";
                RequestFilterHeading = 'Purchase Order Line';
                column(PurchOrderHeaderNo; PurchOrderHeader."No.")
                {
                }
                column(PurchOrderHdrOrderDate; PurchOrderHeader."Order Date")
                {
                }
                column(ExpectedRectDt_PurchLine; Format("Expected Receipt Date"))
                {
                }
                column(Type_PurchaseLine; Type)
                {
                    IncludeCaption = true;
                }
                column(No_PurchaseLine; "No.")
                {
                    IncludeCaption = true;
                }
                column(Description_PurchaseLine; Description)
                {
                    IncludeCaption = true;
                }
                column(Quantity_PurchaseLine; Quantity)
                {
                    IncludeCaption = true;
                }
                column(OutstandingQty_PurchLine; "Outstanding Quantity")
                {
                    IncludeCaption = true;
                }
                column(BackOrderQty; BackOrderQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(DirectUnitCost_PurchLine; "Direct Unit Cost")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 2;
                    IncludeCaption = true;
                }
                column(LineDiscount_PurchaseLine; "Line Discount %")
                {
                }
                column(InvDiscountAmt_PurchLine; "Inv. Discount Amount")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    DecimalPlaces = 1 : 1;
                }
                column(PurchOrderAmount; PurchOrderAmount)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(PurchOrdHeaderCurrCode; PurchOrderHeader."Currency Code")
                {
                }
                column(OrderNoCaption; OrderNoCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    NewOrder := "Document No." <> PurchOrderHeader."No.";
                    if NewOrder then
                        PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, "Document No.");
                    if "Expected Receipt Date" <= WorkDate() then
                        BackOrderQty := "Outstanding Quantity"
                    else
                        BackOrderQty := 0;
                    Currency.InitRoundingPrecision();
                    if "VAT Calculation Type" in ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"] then
                        PurchOrderAmount :=
                          Round(
                            (Amount + "VAT Base Amount" * "VAT %" / 100) * "Outstanding Quantity" / Quantity / (1 + "VAT %" / 100),
                            Currency."Amount Rounding Precision")
                    else
                        PurchOrderAmount := Round("Outstanding Amount" / (1 + "VAT %" / 100), Currency."Amount Rounding Precision");
                    PurchOrderAmountLCY := PurchOrderAmount;
                    if "Currency Code" <> '' then begin
                        if PurchOrderHeader."Currency Factor" <> 0 then
                            PurchOrderAmountLCY :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  WorkDate(), PurchOrderHeader."Currency Code",
                                  PurchOrderAmountLCY, PurchOrderHeader."Currency Factor"));
                        if PrintAmountsInLCYReq then begin
                            "Direct Unit Cost" :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  WorkDate(), PurchOrderHeader."Currency Code",
                                  "Direct Unit Cost", PurchOrderHeader."Currency Factor"));
                            PurchOrderAmount := PurchOrderAmountLCY;
                        end;
                    end;
                    if PurchOrderHeader."Prices Including VAT" then begin
                        "Direct Unit Cost" := "Direct Unit Cost" / (1 + "VAT %" / 100);
                        "Inv. Discount Amount" := "Inv. Discount Amount" / (1 + "VAT %" / 100);
                    end;
                    "Inv. Discount Amount" := "Inv. Discount Amount" * "Outstanding Quantity" / Quantity;
                    CurrencyCode2 := PurchOrderHeader."Currency Code";
                    if PrintAmountsInLCYReq then
                        CurrencyCode2 := '';
                    TempCurrencyTotalBuffer.UpdateTotal(
                      CurrencyCode2,
                      PurchOrderAmount,
                      Counter1,
                      Counter1);
                end;

                trigger OnPreDataItem()
                begin
                    Clear(PurchOrderAmountLCY);
                    Clear(PurchOrderAmount);
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(TotalAmtCurrTotalBuffer; TempCurrencyTotalBuffer."Total Amount")
                {
                    AutoFormatExpression = TempCurrencyTotalBuffer."Currency Code";
                    AutoFormatType = 1;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        OK := TempCurrencyTotalBuffer.Find('-')
                    else
                        OK := TempCurrencyTotalBuffer.Next() <> 0;
                    if not OK then
                        CurrReport.Break();

                    TempCurrencyTotalBuffer2.UpdateTotal(
                      TempCurrencyTotalBuffer."Currency Code",
                      TempCurrencyTotalBuffer."Total Amount",
                      Counter1,
                      Counter1);
                end;

                trigger OnPostDataItem()
                begin
                    TempCurrencyTotalBuffer.DeleteAll();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if PrintOnlyOnePerPageReq then
                    PageGroupNo := PageGroupNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;

                Clear(PurchOrderAmountLCY);
            end;
        }
        dataitem(Integer2; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(TotalAmtCurrTotalBuffer2; TempCurrencyTotalBuffer2."Total Amount")
            {
                AutoFormatExpression = TempCurrencyTotalBuffer2."Currency Code";
                AutoFormatType = 1;
            }
            column(CurrTotalBuffer2CurrCode; TempCurrencyTotalBuffer2."Currency Code")
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    OK := TempCurrencyTotalBuffer2.Find('-')
                else
                    OK := TempCurrencyTotalBuffer2.Next() <> 0;
                if not OK then
                    CurrReport.Break();
            end;

            trigger OnPostDataItem()
            begin
                TempCurrencyTotalBuffer2.DeleteAll();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Vendor - Order Detail';
        AboutText = 'Analyse your outstanding purchase orders to understand your expected purchase volume. Show all outstanding purchases and highlight overdue purchase lines for each vendor.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintAmountsInLCY; PrintAmountsInLCYReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
                    }
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPageReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Vendor';
                        ToolTip = 'Specifies if each vendor''s information is printed on a new page if you have chosen two or more vendors to be included in the report.';
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
    var
        FormatDocument: Codeunit "Format Document";
    begin
        VendFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
        PurchLineFilter := "Purchase Line".GetFilters();
        PeriodText := "Purchase Line".GetFilter("Expected Receipt Date");
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        TempCurrencyTotalBuffer: Record "Currency Total Buffer" temporary;
        TempCurrencyTotalBuffer2: Record "Currency Total Buffer" temporary;
        PurchOrderHeader: Record "Purchase Header";
        Currency: Record Currency;
        PrintAmountsInLCYReq: Boolean;
        PeriodText: Text;
        PrintOnlyOnePerPageReq: Boolean;
        VendFilter: Text;
        PurchLineFilter: Text;
        BackOrderQty: Decimal;
        PurchOrderAmount: Decimal;
        PurchOrderAmountLCY: Decimal;
        NewOrder: Boolean;
        OK: Boolean;
        Counter1: Integer;
        CurrencyCode2: Code[10];
        PageGroupNo: Integer;
        VendorOrderDetailCaptionLbl: Label 'Vendor - Order Detail';
        PageCaptionLbl: Label 'Page';
        AllamountsareinLCYCaptionLbl: Label 'All amounts are in LCY.';
        ExpectedDateCaptionLbl: Label 'Expected Date';
        BackOrderQtyCaptionLbl: Label 'Quantity on Back Order';
        LineDiscountPercentageCaptionLbl: Label 'Line Disc. %';
        InvDiscountAmountCaptionLbl: Label 'Inv. Discount Amount';
        OutstandingOrdersCaptionLbl: Label 'Outstanding Orders';
        OrderNoCaptionLbl: Label 'Order No.';
        TotalCaptionLbl: Label 'Total';

        PeriodTxt: Label 'Receiving Date: %1', Comment = '%1 - date';
        PurchaseLineFilterTxt: Label 'Purchase Order Line: %1', Comment = '%1 - line no.';
        TableFilterTxt: Label '%1: %2', Locked = true;

    procedure InitializeRequest(NewPrintAmountsInLCY: Boolean; NewPrintOnlyOnePerPage: Boolean)
    begin
        PrintAmountsInLCYReq := NewPrintAmountsInLCY;
        PrintOnlyOnePerPageReq := NewPrintOnlyOnePerPage;
    end;
}

