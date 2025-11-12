// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

report 307 "Vendor - Order Summary"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorOrderSummary.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Order Summary';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = Vendor;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", "Currency Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintAmountsInLCY; PrintAmountsInLCY)
            {
            }
            column(VenTableCaptionVendFilter; TableCaption + ': ' + VendFilter)
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(PeriodStartDate1; Format(PeriodStartDate[1]))
            {
            }
            column(PeriodStartDate2; Format(PeriodStartDate[2]))
            {
            }
            column(PeriodStartDate3; Format(PeriodStartDate[3]))
            {
            }
            column(PeriodStartDate21; Format(PeriodStartDate[2] - 1))
            {
            }
            column(PeriodStartDate31; Format(PeriodStartDate[3] - 1))
            {
            }
            column(PeriodStartDate41; Format(PeriodStartDate[4] - 1))
            {
            }
            column(PurchAmtOnOrderLCY1; PurchAmtOnOrderLCY[1])
            {
                AutoFormatType = 1;
            }
            column(PurchAmtOnOrderLCY2; PurchAmtOnOrderLCY[2])
            {
                AutoFormatType = 1;
            }
            column(PurchAmtOnOrderLCY3; PurchAmtOnOrderLCY[3])
            {
                AutoFormatType = 1;
            }
            column(PurchAmtOnOrderLCY4; PurchAmtOnOrderLCY[4])
            {
                AutoFormatType = 1;
            }
            column(PurchAmtOnOrderLCY5; PurchAmtOnOrderLCY[5])
            {
                AutoFormatType = 1;
            }
            column(PurchOrderAmountLCY; PurchOrderAmountLCY)
            {
                AutoFormatType = 1;
            }
            column(No_Vendor; "No.")
            {
                IncludeCaption = true;
            }
            column(VendorOrderSummaryCaption; VendorOrderSummaryCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(AllamountsareinLCYCaption; AllamountsareinLCYCaptionLbl)
            {
            }
            column(OutstandingOrdersCaption; OutstandingOrdersCaptionLbl)
            {
            }
            column(CustomerNoCaption; CustomerNoCapLbl)
            {
            }
            column(BeforeCaption; BeforeCaptionLbl)
            {
            }
            column(AfterCaption; AfterCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(TotalLCYCaption; TotalLCYCaptionLbl)
            {
            }
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Pay-to Vendor No." = field("No."), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"), "Currency Code" = field("Currency Filter");
                DataItemTableView = sorting("Document Type", "Pay-to Vendor No.", "Currency Code") where("Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                column(PurchOrderAmount; PurchOrderAmount)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(PurchAmtOnOrder5; PurchAmtOnOrder[5])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(PurchAmtOnOrder4; PurchAmtOnOrder[4])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(PurchAmtOnOrder3; PurchAmtOnOrder[3])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(PurchAmtOnOrder2; PurchAmtOnOrder[2])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(PurchAmtOnOrder1; PurchAmtOnOrder[1])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrencyCode_PurchaseLine; "Currency Code")
                {
                }
                column(Name_Vendor; Vendor.Name)
                {
                    IncludeCaption = true;
                }
                column(PurchaseLinePaytoNo_Vendor; "Pay-to Vendor No.")
                {
                }
                column(GroupNumber; GroupNumber)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PeriodNo := 1;
                    while "Expected Receipt Date" >= PeriodStartDate[PeriodNo] do
                        PeriodNo := PeriodNo + 1;

                    Currency.InitRoundingPrecision();
                    if "VAT Calculation Type" in ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"] then
                        PurchOrderAmount :=
                          Round(
                            (Amount + "VAT Base Amount" * "VAT %" / 100) * "Outstanding Quantity" / Quantity / (1 + "VAT %" / 100),
                            Currency."Amount Rounding Precision")
                    else
                        PurchOrderAmount :=
                          Round(
                            "Outstanding Amount" / (1 + "VAT %" / 100),
                            Currency."Amount Rounding Precision");
                    PurchOrderAmountLCY := PurchOrderAmount;

                    for i := 1 to ArrayLen(PurchAmtOnOrder) do begin
                        PurchAmtOnOrder[i] := 0;
                        PurchAmtOnOrderLCY[i] := 0;
                    end;

                    if "Currency Code" <> '' then begin
                        PurchOrderHeader.Get(1, "Document No.");
                        if PurchOrderHeader."Currency Factor" <> 0 then
                            PurchOrderAmountLCY :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  WorkDate(), PurchOrderHeader."Currency Code",
                                  PurchOrderAmount, PurchOrderHeader."Currency Factor"));
                    end;

                    PurchAmtOnOrder[PeriodNo] := PurchOrderAmount;
                    PurchAmtOnOrderLCY[PeriodNo] := PurchOrderAmountLCY;

                    if NewVendor then
                        GroupNumber += 1
                    else
                        if not PrintAmountsInLCY and ("Currency Code" <> LastCurrencyCode) then
                            GroupNumber += 1;
                    NewVendor := false;
                    LastCurrencyCode := "Currency Code";
                end;

                trigger OnPreDataItem()
                begin
                    Clear(PurchOrderAmount);
                    Clear(PurchOrderAmountLCY);
                    Clear(PurchAmtOnOrder);
                    Clear(PurchAmtOnOrderLCY);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                NewVendor := true;
            end;

            trigger OnPreDataItem()
            begin
                Clear(PurchOrderAmountLCY);
                Clear(PurchAmtOnOrderLCY);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Vendor - Order Summary';
        AboutText = 'Analyse your unreceived orders to understand your expected purchase volume. See order details with the quantity not yet received for each vendor in three periods of 30 days each, starting from the specified date.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; PeriodStartDate[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(AmountsinLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[1] = 0D then
                PeriodStartDate[1] := WorkDate();
        end;
    }

    labels
    {
        NameCaption = 'Name';
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        VendFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
        for i := 1 to 3 do
            PeriodStartDate[i + 1] := CalcDate('<1M>', PeriodStartDate[i]);
        PeriodStartDate[5] := DMY2Date(31, 12, 9999);
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        PurchOrderHeader: Record "Purchase Header";
        Currency: Record Currency;
        PurchOrderAmount: Decimal;
        PurchOrderAmountLCY: Decimal;
        PeriodStartDate: array[5] of Date;
        PrintAmountsInLCY: Boolean;
        PeriodNo: Integer;
        PurchAmtOnOrder: array[5] of Decimal;
        PurchAmtOnOrderLCY: array[5] of Decimal;
        i: Integer;
        VendorOrderSummaryCaptionLbl: Label 'Vendor - Order Summary';
        PageCaptionLbl: Label 'Page';
        AllamountsareinLCYCaptionLbl: Label 'All amounts are in LCY.';
        OutstandingOrdersCaptionLbl: Label 'Outstanding Orders';
        CustomerNoCapLbl: Label 'No.';
        BeforeCaptionLbl: Label '...Before';
        AfterCaptionLbl: Label 'After...';
        TotalCaptionLbl: Label 'Total';
        TotalLCYCaptionLbl: Label 'Total (LCY)';
        GroupNumber: Integer;
        NewVendor: Boolean;
        LastCurrencyCode: Code[10];

    protected var
        VendFilter: Text;

    procedure InitializeRequest(NewPeriodStartDate: Date; NewPrintAmountsInLCY: Boolean)
    begin
        PeriodStartDate[1] := NewPeriodStartDate;
        PrintAmountsInLCY := NewPrintAmountsInLCY;
    end;
}

