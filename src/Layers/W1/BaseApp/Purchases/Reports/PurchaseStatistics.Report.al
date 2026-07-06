// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

report 312 "Purchase Statistics"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/PurchaseStatistics.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Purchase Statistics';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", "Currency Code";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Vendor_TABLECAPTION__________VendFilter; TableCaption + ': ' + VendFilter)
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(PeriodStartDate_2_; Format(PeriodStartDate[2]))
            {
            }
            column(PeriodStartDate_3_; Format(PeriodStartDate[3]))
            {
            }
            column(PeriodStartDate_4_; Format(PeriodStartDate[4]))
            {
            }
            column(PeriodStartDate_3__1; Format(PeriodStartDate[3] - 1))
            {
            }
            column(PeriodStartDate_4__1; Format(PeriodStartDate[4] - 1))
            {
            }
            column(PeriodStartDate_5__1; Format(PeriodStartDate[5] - 1))
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(VendPurchLCY_1_; VendPurchLCY[1])
            {
                AutoFormatType = 1;
            }
            column(VendPurchLCY_2_; VendPurchLCY[2])
            {
                AutoFormatType = 1;
            }
            column(VendPurchLCY_3_; VendPurchLCY[3])
            {
                AutoFormatType = 1;
            }
            column(VendPurchLCY_4_; VendPurchLCY[4])
            {
                AutoFormatType = 1;
            }
            column(VendPurchLCY_5_; VendPurchLCY[5])
            {
                AutoFormatType = 1;
            }
            column(VendInvDiscAmountLCY_1_; VendInvDiscAmountLCY[1])
            {
                AutoFormatType = 1;
            }
            column(VendInvDiscAmountLCY_2_; VendInvDiscAmountLCY[2])
            {
                AutoFormatType = 1;
            }
            column(VendInvDiscAmountLCY_3_; VendInvDiscAmountLCY[3])
            {
                AutoFormatType = 1;
            }
            column(VendInvDiscAmountLCY_4_; VendInvDiscAmountLCY[4])
            {
                AutoFormatType = 1;
            }
            column(VendInvDiscAmountLCY_5_; VendInvDiscAmountLCY[5])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentDiscLCY_1_; VendPaymentDiscLCY[1])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentDiscLCY_2_; VendPaymentDiscLCY[2])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentDiscLCY_3_; VendPaymentDiscLCY[3])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentDiscLCY_4_; VendPaymentDiscLCY[4])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentDiscLCY_5_; VendPaymentDiscLCY[5])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentDiscTolLcy_1_; VendPaymentDiscTolLcy[1])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentDiscTolLcy_2_; VendPaymentDiscTolLcy[2])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentDiscTolLcy_3_; VendPaymentDiscTolLcy[3])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentDiscTolLcy_4_; VendPaymentDiscTolLcy[4])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentDiscTolLcy_5_; VendPaymentDiscTolLcy[5])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentTolLcy_5_; VendPaymentTolLcy[5])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentTolLcy_4_; VendPaymentTolLcy[4])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentTolLcy_3_; VendPaymentTolLcy[3])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentTolLcy_2_; VendPaymentTolLcy[2])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentTolLcy_1_; VendPaymentTolLcy[1])
            {
                AutoFormatType = 1;
            }
            column(VendPurchLCY_1__Control40; VendPurchLCY[1])
            {
                AutoFormatType = 1;
            }
            column(VendInvDiscAmountLCY_1__Control46; VendInvDiscAmountLCY[1])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentDiscLCY_1__Control52; VendPaymentDiscLCY[1])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentDiscTolLcy_1__Control77; VendPaymentDiscTolLcy[1])
            {
                AutoFormatType = 1;
            }
            column(VendPaymentTolLcy_1__Control78; VendPaymentTolLcy[1])
            {
                AutoFormatType = 1;
            }
            column(Purchase_StatisticsCaption; Purchase_StatisticsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor__No__Caption; FieldCaption("No."))
            {
            }
            column(Vendor_NameCaption; FieldCaption(Name))
            {
            }
            column(beforeCaption; beforeCaptionLbl)
            {
            }
            column(after___Caption; after___CaptionLbl)
            {
            }
            column(VendPurchLCY_1_Caption; VendPurchLCY_1_CaptionLbl)
            {
            }
            column(VendInvDiscAmountLCY_1_Caption; VendInvDiscAmountLCY_1_CaptionLbl)
            {
            }
            column(VendPaymentDiscLCY_1_Caption; VendPaymentDiscLCY_1_CaptionLbl)
            {
            }
            column(VendPaymentDiscTolLcy_1_Caption; VendPaymentDiscTolLcy_1_CaptionLbl)
            {
            }
            column(VendPaymentTolLcy_1_Caption; VendPaymentTolLcy_1_CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(VendPurchLCY_1__Control40Caption; VendPurchLCY_1__Control40CaptionLbl)
            {
            }
            column(VendInvDiscAmountLCY_1__Control46Caption; VendInvDiscAmountLCY_1__Control46CaptionLbl)
            {
            }
            column(VendPaymentDiscLCY_1__Control52Caption; VendPaymentDiscLCY_1__Control52CaptionLbl)
            {
            }
            column(VendPaymentDiscTolLcy_1__Control77Caption; VendPaymentDiscTolLcy_1__Control77CaptionLbl)
            {
            }
            column(VendPaymentTolLcy_1__Control78Caption; VendPaymentTolLcy_1__Control78CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                PrintVend := false;
                for i := 1 to 5 do begin
                    SetRange("Date Filter", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);
                    CalcFields("Purchases (LCY)", "Inv. Discounts (LCY)", "Pmt. Discounts (LCY)",
                      "Pmt. Disc. Tolerance (LCY)", "Pmt. Tolerance (LCY)");
                    VendPurchLCY[i] := "Purchases (LCY)";
                    VendInvDiscAmountLCY[i] := "Inv. Discounts (LCY)";
                    VendPaymentDiscLCY[i] := "Pmt. Discounts (LCY)";
                    VendPaymentDiscTolLcy[i] := "Pmt. Disc. Tolerance (LCY)";
                    VendPaymentTolLcy[i] := "Pmt. Tolerance (LCY)";
                    if (VendPurchLCY[i] <> 0) or (VendInvDiscAmountLCY[i] <> 0) or (VendPaymentDiscLCY[i] <> 0) then
                        PrintVend := true;
                end;
                if not PrintVend then
                    CurrReport.Skip();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Purchase Statistics';
        AboutText = 'Track vendor performance and ensure that your company gets the best value for money.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("PeriodStartDate[2]"; PeriodStartDate[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(PeriodLength; PeriodLengthReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[2] = 0D then
                PeriodStartDate[2] := WorkDate();
            if Format(PeriodLengthReq) = '' then
                Evaluate(PeriodLengthReq, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        VendFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
        for i := 2 to 4 do
            PeriodStartDate[i + 1] := CalcDate(PeriodLengthReq, PeriodStartDate[i]);
        PeriodStartDate[6] := DMY2Date(31, 12, 9999);
        PeriodStartDate[1] := DMY2Date(1, 1, 0);
    end;

    var
        PeriodLengthReq: DateFormula;
        VendFilter: Text;
        PeriodStartDate: array[6] of Date;
        VendPurchLCY: array[5] of Decimal;
        VendInvDiscAmountLCY: array[5] of Decimal;
        VendPaymentDiscLCY: array[5] of Decimal;
        VendPaymentDiscTolLcy: array[5] of Decimal;
        VendPaymentTolLcy: array[5] of Decimal;
        PrintVend: Boolean;
        i: Integer;
        Purchase_StatisticsCaptionLbl: Label 'Purchase Statistics';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        beforeCaptionLbl: Label '...Before';
        after___CaptionLbl: Label 'After...';
        VendPurchLCY_1_CaptionLbl: Label 'Purchases (LCY)';
        VendInvDiscAmountLCY_1_CaptionLbl: Label 'Inv. Discounts (LCY)';
        VendPaymentDiscLCY_1_CaptionLbl: Label 'Pmt. Discounts (LCY)';
        VendPaymentDiscTolLcy_1_CaptionLbl: Label 'Pmt. Disc. Tolerance (LCY)';
        VendPaymentTolLcy_1_CaptionLbl: Label 'Payment Tolerance (LCY)';
        TotalCaptionLbl: Label 'Total';
        VendPurchLCY_1__Control40CaptionLbl: Label 'Purchases (LCY)';
        VendInvDiscAmountLCY_1__Control46CaptionLbl: Label 'Inv. Discounts (LCY)';
        VendPaymentDiscLCY_1__Control52CaptionLbl: Label 'Pmt. Discounts (LCY)';
        VendPaymentDiscTolLcy_1__Control77CaptionLbl: Label 'Pmt. Disc. Tolerance (LCY)';
        VendPaymentTolLcy_1__Control78CaptionLbl: Label 'Payment Tolerance (LCY)';

    procedure InitializeRequest(NewPeriodLength: DateFormula; NewPeriodStartDate: Date)
    begin
        PeriodLengthReq := NewPeriodLength;
        PeriodStartDate[2] := CalcDate(PeriodLengthReq, NewPeriodStartDate);
    end;
}

