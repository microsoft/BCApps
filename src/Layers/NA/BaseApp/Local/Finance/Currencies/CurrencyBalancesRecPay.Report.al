// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currencies;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Company;

report 10017 "Currency Balances - Rec./Pay."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/Currencies/CurrencyBalancesRecPay.rdlc';
    Caption = 'Currency Balances - Receivables/Payables';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Currency; Currency)
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(Time; Time)
            {
            }
            column(CompanyInfoName; CompanyInformation.Name)
            {
            }
            column(CurFilter; CurFilter)
            {
            }
            column(CurrTblCaptionCurFilter; Currency.TableCaption + ': ' + CurFilter)
            {
            }
            column(Currency_Code; Code)
            {
            }
            column(CurrExchAsOfDateCode; CurrencyExchRate.ExchangeRate(CurrExchAsOfDate, Code))
            {
                DecimalPlaces = 0 : 5;
            }
            column(CustBalance_Currency; "Customer Balance")
            {
                AutoFormatExpression = Code;
                AutoFormatType = 1;
            }
            column(CustBalanceLCY_Currency; "Customer Balance (LCY)")
            {
                AutoFormatType = 1;
            }
            column(CurValueReceivables; CurValueReceivables)
            {
                AutoFormatType = 1;
            }
            column(VendorBalance_Currency; "Vendor Balance")
            {
                AutoFormatExpression = Code;
                AutoFormatType = 1;
            }
            column(VendorBalanceLCY_Currency; "Vendor Balance (LCY)")
            {
                AutoFormatType = 1;
            }
            column(CurValuePayables; CurValuePayables)
            {
                AutoFormatType = 1;
            }
            column(Description_Currency; Description)
            {
            }
            column(ReceivableAndPayableCaption; ReceivableAndPayableCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(CodeCaption_Currency; FieldCaption(Code))
            {
            }
            column(CurrencyExchRateCaption; CurrencyExchRateCaptionLbl)
            {
            }
            column(CurrencyBalanceCaption; CurrencyBalanceCaptionLbl)
            {
            }
            column(CurrCustBalanceLCYCaption; CaptionClassTranslate('101,1,' + Text000))
            {
            }
            column(CurValueReceivablesCaption; CaptionClassTranslate('101,1,' + Text001))
            {
            }
            column(ReceivablesCustomersCaption; ReceivablesCustomersCaptionLbl)
            {
            }
            column(PayablesVendorsCaption; PayablesVendorsCaptionLbl)
            {
            }
            column(CurrVendBalanceLCYCaption; CaptionClassTranslate('101,1,' + Text000))
            {
            }
            column(CurValuePayablesCaption; CaptionClassTranslate('101,1,' + Text001))
            {
            }
            column(DescriptionCaption_Currency; FieldCaption(Description))
            {
            }
            column(ReportTotalCaption; ReportTotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Customer Balance", "Vendor Balance", "Customer Balance (LCY)", "Vendor Balance (LCY)");

                CurValueReceivables :=
                  Round(
                    CurrencyExchRate.ExchangeAmtFCYToFCY(CurrExchAsOfDate, Code, '', "Customer Balance"));
                CurValuePayables :=
                  Round(
                    CurrencyExchRate.ExchangeAmtFCYToFCY(CurrExchAsOfDate, Code, '', "Vendor Balance"));
            end;

            trigger OnPreDataItem()
            begin
                Clear(CurValueReceivables);
                Clear(CurValuePayables);
            end;
        }
    }

    requestpage
    {

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
        CompanyInformation.Get();
        CurFilter := Currency.GetFilters();

        if Currency.GetFilter("Date Filter") = '' then
            CurrExchAsOfDate := WorkDate()
        else
            CurrExchAsOfDate := Currency.GetRangeMax("Date Filter");
    end;

    var
        CompanyInformation: Record "Company Information";
        CurrencyExchRate: Record "Currency Exchange Rate";
        CurFilter: Text;
        CurrExchAsOfDate: Date;
        CurValueReceivables: Decimal;
        CurValuePayables: Decimal;
        Text000: Label 'In %1 (posted)';
        Text001: Label 'In %1 (at current rate)';
        ReceivableAndPayableCaptionLbl: Label 'Currency Balances in Receivables and Payables';
        PageNoCaptionLbl: Label 'Page';
        CurrencyExchRateCaptionLbl: Label 'Exchange Rate';
        CurrencyBalanceCaptionLbl: Label 'In Currency';
        ReceivablesCustomersCaptionLbl: Label 'Receivables (Customers)';
        PayablesVendorsCaptionLbl: Label 'Payables (Vendors)';
        ReportTotalCaptionLbl: Label 'Report Total';
}

