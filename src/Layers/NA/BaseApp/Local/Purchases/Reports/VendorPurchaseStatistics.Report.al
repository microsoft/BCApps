// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 10107 "Vendor Purchase Statistics"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorPurchaseStatistics.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Purchase Statistics';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", "Currency Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Purchaser Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(PeriodStartingDate_2_; PeriodStartingDate[2])
            {
            }
            column(PeriodStartingDate_3_; PeriodStartingDate[3])
            {
            }
            column(PeriodStartingDate_4_; PeriodStartingDate[4])
            {
            }
            column(PeriodStartingDate_2__Control14; PeriodStartingDate[2])
            {
            }
            column(PeriodStartingDate_3__1; PeriodStartingDate[3] - 1)
            {
            }
            column(PeriodStartingDate_4__1; PeriodStartingDate[4] - 1)
            {
            }
            column(PeriodStartingDate_5__1; PeriodStartingDate[5] - 1)
            {
            }
            column(PeriodStartingDate_5__1_Control18; PeriodStartingDate[5] - 1)
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(Purchases___1_; "Purchases$"[1])
            {
            }
            column(Purchases___2_; "Purchases$"[2])
            {
            }
            column(Purchases___3_; "Purchases$"[3])
            {
            }
            column(Purchases___4_; "Purchases$"[4])
            {
            }
            column(Purchases___5_; "Purchases$"[5])
            {
            }
            column(Payments___1_; "Payments$"[1])
            {
            }
            column(Payments___2_; "Payments$"[2])
            {
            }
            column(Payments___3_; "Payments$"[3])
            {
            }
            column(Payments___4_; "Payments$"[4])
            {
            }
            column(Payments___5_; "Payments$"[5])
            {
            }
            column(FinanceCharges___1_; "FinanceCharges$"[1])
            {
            }
            column(FinanceCharges___2_; "FinanceCharges$"[2])
            {
            }
            column(FinanceCharges___3_; "FinanceCharges$"[3])
            {
            }
            column(FinanceCharges___4_; "FinanceCharges$"[4])
            {
            }
            column(FinanceCharges___5_; "FinanceCharges$"[5])
            {
            }
            column(InvoiceDiscounts___1_; "InvoiceDiscounts$"[1])
            {
            }
            column(InvoiceDiscounts___2_; "InvoiceDiscounts$"[2])
            {
            }
            column(InvoiceDiscounts___3_; "InvoiceDiscounts$"[3])
            {
            }
            column(InvoiceDiscounts___4_; "InvoiceDiscounts$"[4])
            {
            }
            column(InvoiceDiscounts___5_; "InvoiceDiscounts$"[5])
            {
            }
            column(VendorBalance___1_; "VendorBalance$"[1])
            {
            }
            column(VendorBalance___2_; "VendorBalance$"[2])
            {
            }
            column(VendorBalance___3_; "VendorBalance$"[3])
            {
            }
            column(VendorBalance___4_; "VendorBalance$"[4])
            {
            }
            column(VendorBalance___5_; "VendorBalance$"[5])
            {
            }
            column(DiscountsTaken___1_; -"DiscountsTaken$"[1])
            {
            }
            column(DiscountsTaken___2_; -"DiscountsTaken$"[2])
            {
            }
            column(DiscountsTaken___3_; -"DiscountsTaken$"[3])
            {
            }
            column(DiscountsTaken___4_; -"DiscountsTaken$"[4])
            {
            }
            column(DiscountsTaken___5_; -"DiscountsTaken$"[5])
            {
            }
            column(DiscountsLost___1_; -"DiscountsLost$"[1])
            {
            }
            column(DiscountsLost___2_; -"DiscountsLost$"[2])
            {
            }
            column(DiscountsLost___3_; -"DiscountsLost$"[3])
            {
            }
            column(DiscountsLost___4_; -"DiscountsLost$"[4])
            {
            }
            column(DiscountsLost___5_; -"DiscountsLost$"[5])
            {
            }
            column(Purchases___1__Control65; "Purchases$"[1])
            {
            }
            column(Purchases___2__Control66; "Purchases$"[2])
            {
            }
            column(Purchases___3__Control67; "Purchases$"[3])
            {
            }
            column(Purchases___4__Control68; "Purchases$"[4])
            {
            }
            column(Purchases___5__Control69; "Purchases$"[5])
            {
            }
            column(Payments___1__Control71; "Payments$"[1])
            {
            }
            column(Payments___2__Control72; "Payments$"[2])
            {
            }
            column(Payments___3__Control73; "Payments$"[3])
            {
            }
            column(Payments___4__Control74; "Payments$"[4])
            {
            }
            column(Payments___5__Control75; "Payments$"[5])
            {
            }
            column(FinanceCharges___1__Control77; "FinanceCharges$"[1])
            {
            }
            column(FinanceCharges___2__Control78; "FinanceCharges$"[2])
            {
            }
            column(FinanceCharges___3__Control79; "FinanceCharges$"[3])
            {
            }
            column(FinanceCharges___4__Control80; "FinanceCharges$"[4])
            {
            }
            column(FinanceCharges___5__Control81; "FinanceCharges$"[5])
            {
            }
            column(InvoiceDiscounts___1__Control83; "InvoiceDiscounts$"[1])
            {
            }
            column(InvoiceDiscounts___2__Control84; "InvoiceDiscounts$"[2])
            {
            }
            column(InvoiceDiscounts___3__Control85; "InvoiceDiscounts$"[3])
            {
            }
            column(InvoiceDiscounts___4__Control86; "InvoiceDiscounts$"[4])
            {
            }
            column(InvoiceDiscounts___5__Control87; "InvoiceDiscounts$"[5])
            {
            }
            column(VendorBalance___1__Control89; "VendorBalance$"[1])
            {
            }
            column(VendorBalance___2__Control90; "VendorBalance$"[2])
            {
            }
            column(VendorBalance___3__Control91; "VendorBalance$"[3])
            {
            }
            column(VendorBalance___4__Control92; "VendorBalance$"[4])
            {
            }
            column(VendorBalance___5__Control93; "VendorBalance$"[5])
            {
            }
            column(DiscountsTaken___1__Control95; -"DiscountsTaken$"[1])
            {
            }
            column(DiscountsTaken___2__Control96; -"DiscountsTaken$"[2])
            {
            }
            column(DiscountsTaken___3__Control97; -"DiscountsTaken$"[3])
            {
            }
            column(DiscountsTaken___4__Control98; -"DiscountsTaken$"[4])
            {
            }
            column(DiscountsTaken___5__Control99; -"DiscountsTaken$"[5])
            {
            }
            column(DiscountsLost___1__Control101; -"DiscountsLost$"[1])
            {
            }
            column(DiscountsLost___2__Control102; -"DiscountsLost$"[2])
            {
            }
            column(DiscountsLost___3__Control103; -"DiscountsLost$"[3])
            {
            }
            column(DiscountsLost___4__Control104; -"DiscountsLost$"[4])
            {
            }
            column(DiscountsLost___5__Control105; -"DiscountsLost$"[5])
            {
            }
            column(Vendor_Purchase_StatisticsCaption; Vendor_Purchase_StatisticsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(BeforeCaption; BeforeCaptionLbl)
            {
            }
            column(AfterCaption; AfterCaptionLbl)
            {
            }
            column(VendorCaption; VendorCaptionLbl)
            {
            }
            column(Vendor_NameCaption; FieldCaption(Name))
            {
            }
            column(PurchasesCaption; PurchasesCaptionLbl)
            {
            }
            column(PaymentsCaption; PaymentsCaptionLbl)
            {
            }
            column(Finance_ChargesCaption; Finance_ChargesCaptionLbl)
            {
            }
            column(Invoice_DiscountCaption; Invoice_DiscountCaptionLbl)
            {
            }
            column(Vendor_BalanceCaption; Vendor_BalanceCaptionLbl)
            {
            }
            column(Payment_Disc_TakenCaption; Payment_Disc_TakenCaptionLbl)
            {
            }
            column(Payment_Disc_LostCaption; Payment_Disc_LostCaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }
            column(PaymentsCaption_Control76; PaymentsCaption_Control76Lbl)
            {
            }
            column(Finance_ChargesCaption_Control82; Finance_ChargesCaption_Control82Lbl)
            {
            }
            column(Invoice_DiscountCaption_Control88; Invoice_DiscountCaption_Control88Lbl)
            {
            }
            column(Vendor_BalanceCaption_Control94; Vendor_BalanceCaption_Control94Lbl)
            {
            }
            column(Payment_Disc_TakenCaption_Control100; Payment_Disc_TakenCaption_Control100Lbl)
            {
            }
            column(Payment_Disc_LostCaption_Control106; Payment_Disc_LostCaption_Control106Lbl)
            {
            }
            column(PurchasesCaption_Control1; PurchasesCaption_Control1Lbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Clear("DiscountsTaken$");
                Clear("DiscountsLost$");

                for i := 1 to 5 do begin
                    SetRange("Date Filter", PeriodStartingDate[i], PeriodStartingDate[i + 1] - 1);
                    CalcFields("Purchases (LCY)", "Inv. Discounts (LCY)", "Fin. Charge Memo Amounts (LCY)", "Payments (LCY)", "Net Change (LCY)");
                    "Purchases$"[i] := "Purchases (LCY)";
                    "Payments$"[i] := "Payments (LCY)";
                    "FinanceCharges$"[i] := "Fin. Charge Memo Amounts (LCY)";
                    "InvoiceDiscounts$"[i] := "Inv. Discounts (LCY)";
                    if i = 1 then
                        "VendorBalance$"[i] := "Net Change (LCY)"
                    else
                        "VendorBalance$"[i] := "VendorBalance$"[i - 1] + "Net Change (LCY)";

                    VendLedgerEntry.SetRange("Vendor No.", "No.");
                    VendLedgerEntry.SetRange("Posting Date", PeriodStartingDate[i], PeriodStartingDate[i + 1] - 1);
                    VendLedgerEntry.SetCurrentKey("Vendor No.", "Posting Date");
                    if VendLedgerEntry.Find('-') then
                        repeat
                            VendLedgerEntry.CalcFields(Amount, "Amount (LCY)");
                            "DiscountsTaken$"[i] := "DiscountsTaken$"[i] + VendLedgerEntry."Pmt. Disc. Rcd.(LCY)";
                            if (VendLedgerEntry."Document Type" = VendLedgerEntry."Document Type"::Invoice) and
                               (not VendLedgerEntry.Open) and
                               (VendLedgerEntry.Amount <> 0)
                            then
                                "DiscountsLost$"[i] := "DiscountsLost$"[i] +
                                  (VendLedgerEntry."Original Pmt. Disc. Possible" * (VendLedgerEntry."Amount (LCY)" / VendLedgerEntry.Amount)) -
                                  VendLedgerEntry."Pmt. Disc. Rcd.(LCY)";
                        until VendLedgerEntry.Next() = 0;
                end;
                SetRange("Date Filter");
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
                    field(StartDate; PeriodStartingDate[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(LengthOfPeriods; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Length of Periods';
                        ToolTip = 'Specifies the interval used to compute statistics. The default is 1M, or one month. You can select any period you like, such as 4D for four days or 10W for 10 weeks, and so on.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartingDate[2] = 0D then
                PeriodStartingDate[2] := WorkDate();
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if Format(PeriodLength) = '' then
            Evaluate(PeriodLength, '<1M>');
        PeriodStartingDate[1] := 0D;
        for i := 2 to 4 do
            PeriodStartingDate[i + 1] := CalcDate(PeriodLength, PeriodStartingDate[i]);
        PeriodStartingDate[6] := 99991231D;
        CompanyInformation.Get();
        FilterString := Vendor.GetFilters();
    end;

    var
        FilterString: Text;
        PeriodStartingDate: array[6] of Date;
        PeriodLength: DateFormula;
        i: Integer;
        "DiscountsTaken$": array[5] of Decimal;
        "DiscountsLost$": array[5] of Decimal;
        "Purchases$": array[5] of Decimal;
        "Payments$": array[5] of Decimal;
        "FinanceCharges$": array[5] of Decimal;
        "InvoiceDiscounts$": array[5] of Decimal;
        "VendorBalance$": array[5] of Decimal;
        VendLedgerEntry: Record "Vendor Ledger Entry";
        CompanyInformation: Record "Company Information";
        Vendor_Purchase_StatisticsCaptionLbl: Label 'Vendor Purchase Statistics';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        BeforeCaptionLbl: Label 'Before';
        AfterCaptionLbl: Label 'After';
        VendorCaptionLbl: Label 'Vendor';
        PurchasesCaptionLbl: Label 'Purchases';
        PaymentsCaptionLbl: Label 'Payments';
        Finance_ChargesCaptionLbl: Label 'Finance Charges';
        Invoice_DiscountCaptionLbl: Label 'Invoice Discount';
        Vendor_BalanceCaptionLbl: Label 'Vendor Balance';
        Payment_Disc_TakenCaptionLbl: Label 'Payment Disc Taken';
        Payment_Disc_LostCaptionLbl: Label 'Payment Disc Lost';
        Report_TotalCaptionLbl: Label 'Report Total';
        PaymentsCaption_Control76Lbl: Label 'Payments';
        Finance_ChargesCaption_Control82Lbl: Label 'Finance Charges';
        Invoice_DiscountCaption_Control88Lbl: Label 'Invoice Discount';
        Vendor_BalanceCaption_Control94Lbl: Label 'Vendor Balance';
        Payment_Disc_TakenCaption_Control100Lbl: Label 'Payment Disc Taken';
        Payment_Disc_LostCaption_Control106Lbl: Label 'Payment Disc Lost';
        PurchasesCaption_Control1Lbl: Label 'Purchases';
}

