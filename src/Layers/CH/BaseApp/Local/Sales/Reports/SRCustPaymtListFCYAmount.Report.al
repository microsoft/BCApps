// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 11569 "SR Cust. Paymt List FCY Amount"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/SRCustPaymtListFCYAmount.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Payments List FCY Amounts';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Customer No.", "Posting Date");
            RequestFilterFields = "Customer No.", "Posting Date", "Customer Posting Group", "Currency Code", Open, "Salesperson Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(LayoutFCYAmounts; Text006)
            {
            }
            column(Filters; Text004 + GetFilters)
            {
            }
            column(SortingTypeNo; SortingTypeNo)
            {
            }
            column(PmtDiscLCY; PmtDiscLCY)
            {
            }
            column(PaymentLCY; PaymentLCY)
            {
            }
            column(NoOfPmts; NoOfPmts)
            {
            }
            column(DocNo_CustLedgerEntry; "Document No.")
            {
            }
            column(DocType_CustLedgerEntry; CopyStr(Format("Document Type"), 1, 1))
            {
            }
            column(PostingDate_CustLedgerEntry; Format("Posting Date"))
            {
            }
            column(AccNo; AccNo)
            {
            }
            column(CurrencyCaption; CurrencyCaption)
            {
            }
            column(Amt_CustLedgerEntry; Amount)
            {
            }
            column(AmtLCY_CustLedgerEntry; "Amount (LCY)")
            {
            }
            column(Status; Status)
            {
            }
            column(Exrate; Exrate)
            {
            }
            column(Description_CustLedgerEntry; Description)
            {
            }
            column(OriginalAmt_CustLedgerEntry; "Original Amount")
            {
            }
            column(TotalCustomer; Text005 + ' ' + Customer."No." + ', ' + Customer.Name)
            {
            }
            column(CustomerPaymentsListCaption; CustomerPaymentsListCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(DocCaption; DocCaptionLbl)
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }
            column(CustomerNoCaption; CustomerNoCaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(ApplicLCYCaption; ApplicLCYCaptionLbl)
            {
            }
            column(StatusCaption; StatusCaptionLbl)
            {
            }
            column(ExrateCaption; ExrateCaptionLbl)
            {
            }
            column(TextCaption; TextCaptionLbl)
            {
            }
            column(PaymentCaption; PaymentCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(EntryNo_CustLedgerEntry; "Entry No.")
            {
            }
            column(CustNo_CustLedgerEntry; "Customer No.")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnAfterGetRecord()
                begin
                    if DetailedEntryProcessFlag then
                        TempCustLedgerEntry.Next()
                    else
                        DetailedEntryProcessFlag := true;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, TempCustLedgerEntry.Count);

                    DetailedEntryProcessFlag := false;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not ("Document Type" in ["Document Type"::Payment]) then
                    CurrReport.Skip();

                CalcFields("Original Amt. (LCY)");

                if "Currency Code" in ['', GlSetup."LCY Code"] then begin
                    Exrate := 0;
                    CurrencyCaption := GlSetup."LCY Code";
                end else begin
                    Exrate := CalcExrate("Original Amount", "Original Amt. (LCY)");
                    CurrencyCaption := "Currency Code";
                end;

                Status := Text000;
                if Open then
                    if "Remaining Amt. (LCY)" = "Amount (LCY)" then
                        Status := Text001
                    else
                        Status := Text002;

                AccNo := "Cust. Ledger Entry"."Customer No.";
                if Customer.Get("Customer No.") then
                    AccName := Customer.Name;

                if Sorting = Sorting::Customer then begin
                    LinesPerGrp := LinesPerGrp + 1;
                    if LinesPerGrp > 1 then begin
                        AccNo := '';
                        AccName := '';
                    end;
                end;

                NoOfPmts := NoOfPmts + 1;
                if NoOfRSPG = 0 then
                    NoOfRSPG := 1;
            end;

            trigger OnPreDataItem()
            begin
                if Sorting = Sorting::Chronological then
                    "Cust. Ledger Entry".SetCurrentKey("Entry No.");

                GlSetup.Get();
                Clear(PmtDiscLCY);
                Clear(PaymentLCY);
                Clear(NoOfRSPG);
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
                    field(Sorting; Sorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorting';
                        OptionCaption = 'Customer with Group Total,Chronological by Entry No.';
                        ToolTip = 'Specifies how the information is sorted.';
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
        SortingTypeNo := Sorting;
    end;

    var
        Text000: Label 'C', Locked = true;
        Text001: Label 'O', Locked = true;
        Text002: Label 'PP', Locked = true;
        Text005: Label 'Total Customer';
        GlSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        Sorting: Option Customer,Chronological;
        LinesPerGrp: Integer;
        NoOfPmts: Integer;
        AccNo: Code[20];
        AccName: Text[100];
        Status: Text[2];
        Exrate: Decimal;
        Text006: Label 'Layout FCY Amounts';
        PmtDiscLCY: Decimal;
        PaymentLCY: Decimal;
        SortingTypeNo: Integer;
        DetailedEntryProcessFlag: Boolean;
        CurrencyCaption: Text[30];
        Text004: Label 'Filter: ';
        NoOfRSPG: Decimal;
        CustomerPaymentsListCaptionLbl: Label 'Customer Payments List';
        PageNoCaptionLbl: Label 'Page';
        DocCaptionLbl: Label 'Doc.';
        DateCaptionLbl: Label 'Date';
        CustomerNoCaptionLbl: Label 'Customer No.';
        AmountCaptionLbl: Label 'Amount';
        ApplicLCYCaptionLbl: Label 'Applic. LCY';
        StatusCaptionLbl: Label 'Status';
        ExrateCaptionLbl: Label 'Exrate';
        TextCaptionLbl: Label 'Text';
        PaymentCaptionLbl: Label 'Payment';
        TotalCaptionLbl: Label 'Total';

    [Scope('OnPrem')]
    procedure CalcExrate(_FcyAmt: Decimal; _LcyAmt: Decimal) _ExRate: Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if (_FcyAmt <> 0) and (_FcyAmt <> _LcyAmt) then begin
            CurrExchRate.SetRange("Currency Code", "Cust. Ledger Entry"."Currency Code");
            CurrExchRate.SetFilter("Starting Date", '<=%1', "Cust. Ledger Entry"."Posting Date");
            if CurrExchRate.FindLast() then;
            _ExRate := Round(_LcyAmt * CurrExchRate."Exchange Rate Amount" / _FcyAmt, 0.001);
        end else
            _ExRate := 0;
    end;
}

