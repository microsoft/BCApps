// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;

report 11554 "SR Vendor Orders per Period"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/SRVendorOrdersperPeriod.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Orders per Period';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", "Currency Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VendFilter; Text003 + VendFilter)
            {
            }
            column(PeriodStartDate; Text004 + Format(PeriodStartDate[1]))
            {
            }
            column(AmtFilterTxt; AmtFilterTxt)
            {
            }
            column(ShowAmtInLCY; ShowAmtInLCY)
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
            column(PeriodStartDate3; Format(PeriodStartDate[3]))
            {
            }
            column(PeriodStartDate2; Format(PeriodStartDate[2]))
            {
            }
            column(PeriodStartDate1; Format(PeriodStartDate[1]))
            {
            }
            column(PurchAmtInOrderLCY1; PurchAmtInOrderLCY[1])
            {
                AutoFormatType = 1;
            }
            column(PurchAmtInOrderLCY2; PurchAmtInOrderLCY[2])
            {
                AutoFormatType = 1;
            }
            column(PurchAmtInOrderLCY3; PurchAmtInOrderLCY[3])
            {
                AutoFormatType = 1;
            }
            column(PurchAmtInOrderLCY4; PurchAmtInOrderLCY[4])
            {
                AutoFormatType = 1;
            }
            column(PurchAmtInOrderLCY5; PurchAmtInOrderLCY[5])
            {
                AutoFormatType = 1;
            }
            column(PurchOrderAmtLCY; PurchOrderAmtLCY)
            {
                AutoFormatType = 1;
            }
            column(VendOrdersperPeriodCaption; VendOrdersperPeriodCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
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
            column(VendorCaption; VendorCaptionLbl)
            {
            }
            column(NumberCaption; NumberCaptionLbl)
            {
            }
            column(TotalLCYCaption; TotalLCYCaptionLbl)
            {
            }
            column(No_Vend; "No.")
            {
            }
            column(GlobalDim2Filter_Vend; "Global Dimension 2 Filter")
            {
            }
            column(GlobalDim1Filter_Vend; "Global Dimension 1 Filter")
            {
            }
            column(CurrencyFilter_Vend; "Currency Filter")
            {
            }
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Pay-to Vendor No." = field("No."), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Currency Code" = field("Currency Filter");
                DataItemTableView = sorting("Document Type", "Pay-to Vendor No.", "Currency Code") where("Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                column(CurrencyCode_PurchLine; "Currency Code")
                {
                }
                column(PurchOrderAmount; PurchOrderAmount)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(PurchAmtInOrder5; PurchAmtInOrder[5])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(PurchAmtInOrder4; PurchAmtInOrder[4])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(PurchAmtInOrder3; PurchAmtInOrder[3])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(PurchAmtInOrder2; PurchAmtInOrder[2])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(PurchAmtInOrder1; PurchAmtInOrder[1])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(VendorName; Vendor.Name)
                {
                }
                column(DocType_PurchLine; "Document Type")
                {
                }
                column(DocNo_PurchLine; "Document No.")
                {
                }
                column(LineNo_PurchLine; "Line No.")
                {
                }
                column(PaytoVendNo_PurchLine; "Pay-to Vendor No.")
                {
                }
                column(ShortcutDim2Code_PurchLine; "Shortcut Dimension 2 Code")
                {
                }
                column(ShortcutDim1Code_PurchLine; "Shortcut Dimension 1 Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PeriodNo := 1;
                    while "Expected Receipt Date" >= PeriodStartDate[PeriodNo] do
                        PeriodNo := PeriodNo + 1;

                    PurchHeader.Get("Document Type", "Document No.");
                    if "Currency Code" <> '' then
                        Currency.Get("Currency Code")
                    else
                        Currency.InitRoundingPrecision();

                    PurchOrderAmount := "Line Amount" - GetInvDisc();
                    if PurchHeader."Prices Including VAT" then
                        PurchOrderAmount := Round(PurchOrderAmount / (100 + "Purchase Line"."VAT %") * 100,
                            Currency."Amount Rounding Precision");
                    PurchOrderAmount := Round(PurchOrderAmount * "Outstanding Quantity" / Quantity,
                        Currency."Amount Rounding Precision");
                    PurchOrderAmtLCY := PurchOrderAmount;

                    if "Currency Code" <> '' then
                        if PurchHeader."Currency Factor" <> 0 then
                            PurchOrderAmtLCY := Round(CurrExRate.ExchangeAmtFCYToLCY
                                (WorkDate(), "Currency Code", PurchOrderAmount, PurchHeader."Currency Factor"));

                    PurchAmtInOrder[PeriodNo] := PurchOrderAmount;
                    PurchAmtInOrderLCY[PeriodNo] := PurchOrderAmtLCY;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(PurchOrderAmtLCY);
                    Clear(PurchAmtInOrderLCY);
                    Clear(PurchOrderAmount);
                    Clear(PurchAmtInOrder);
                end;
            }

            trigger OnPreDataItem()
            begin
                Clear(PurchOrderAmtLCY);
                Clear(PurchAmtInOrderLCY);
            end;
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
                    field("Start Date"; PeriodStartDate[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field("Period Length"; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(ShowAmtInLCY; ShowAmtInLCY)
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

            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        VendFilter := Vendor.GetFilters();

        PurchSetup.Get();
        GLSetup.Get();

        if ShowAmtInLCY then
            AmtFilterTxt := Text000 + ' ' + GLSetup."LCY Code"
        else
            AmtFilterTxt := Text001;

        if Format(PeriodLength) = '' then
            Error(Text002);

        for i := 1 to 3 do
            PeriodStartDate[i + 1] := CalcDate(PeriodLength, PeriodStartDate[i]);
        PeriodStartDate[5] := 99991231D;
    end;

    var
        Text000: Label 'All amounts without VAT in';
        Text001: Label 'Amounts without VAT in Currency of Vendor';
        Text002: Label 'The period length is not defined.';
        Text003: Label 'Filter: ';
        Text004: Label 'Key Date: ';
        CurrExRate: Record "Currency Exchange Rate";
        PurchSetup: Record "Purchases & Payables Setup";
        GLSetup: Record "General Ledger Setup";
        PurchHeader: Record "Purchase Header";
        Currency: Record Currency;
        VendFilter: Text[250];
        PurchOrderAmount: Decimal;
        PurchOrderAmtLCY: Decimal;
        AmtFilterTxt: Text[100];
        PeriodLength: DateFormula;
        PeriodStartDate: array[5] of Date;
        PurchAmtInOrder: array[5] of Decimal;
        PurchAmtInOrderLCY: array[5] of Decimal;
        ShowAmtInLCY: Boolean;
        PeriodNo: Integer;
        i: Integer;
        VendOrdersperPeriodCaptionLbl: Label 'Vendor Orders per Period';
        PageNoCaptionLbl: Label 'Page';
        BeforeCaptionLbl: Label 'before';
        AfterCaptionLbl: Label 'after';
        TotalCaptionLbl: Label 'Total';
        VendorCaptionLbl: Label 'Vendor';
        NumberCaptionLbl: Label 'Number';
        TotalLCYCaptionLbl: Label 'Total LCY';

    [Scope('OnPrem')]
    procedure GetInvDisc(): Decimal
    var
        PurchLine2: Record "Purchase Line" temporary;
        PurchPost: Codeunit "Purch.-Post";
        PurchCalcDisc: Codeunit "Purch.-Calc.Discount";
    begin
        if "Purchase Line"."Allow Invoice Disc." and PurchSetup."Calc. Inv. Discount" then begin
            PurchPost.GetPurchLines(PurchHeader, PurchLine2, 0);
            PurchCalcDisc.CalculateInvoiceDiscount(PurchHeader, PurchLine2);
            PurchLine2.Get("Purchase Line"."Document Type", "Purchase Line"."Document No.", "Purchase Line"."Line No.");
            exit(PurchLine2."Inv. Discount Amount");
        end;
    end;
}

