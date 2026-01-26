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

report 11568 "SR Cust. Paymt List Standard"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/SRCustPaymtListStandard.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Payments List Standard';
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
            column(LayoutStandard; Text006)
            {
            }
            column(Filters; Text004 + GetFilters)
            {
            }
            column(SortingTypeNo; SortingTypeNo)
            {
            }
            column(Name_Cust; Customer.Name)
            {
            }
            column(NoOfPmts; Format(NoOfPmts))
            {
            }
            column(TotalPmtDiscLCY; TotalPmtDiscLCY)
            {
            }
            column(TotalPaymentLCY; TotalPaymentLCY)
            {
            }
            column(TotalAmountLCY; TotalAmountLCY)
            {
            }
            column(AmtLCY_CustLedgerEntry; "Amount (LCY)")
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
            column(AccName; AccName)
            {
            }
            column(DocType_TempCustLedgerEntry; TempCustLedgerEntry."Document Type")
            {
            }
            column(DocNo_TempCustLedgerEntry; TempCustLedgerEntry."Document No.")
            {
            }
            column(PmtDiscLCY; PmtDiscLCY)
            {
                AutoFormatType = 1;
            }
            column(PaymentLCY; PaymentLCY)
            {
                AutoFormatType = 1;
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
            column(CustomerNoCaption; CustomerNoCaptionLbl)
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }
            column(DocCaption; DocCaptionLbl)
            {
            }
            column(AmtLCYCaption; AmtLCYCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(AppliesToDocNoCaption; AppliesToDocNoCaptionLbl)
            {
            }
            column(PaymentLCYCaption; PaymentLCYCaptionLbl)
            {
            }
            column(PmtDiscCurrDiffCaption; PmtDiscCurrDiffCaptionLbl)
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
                column(DocNo_TempCustLedgerEntry1; TempCustLedgerEntry."Document No.")
                {
                }
                column(DocType_TempCustLedgerEntry1; TempCustLedgerEntry."Document Type")
                {
                }

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

                PmtDiscLCY := "Amount (LCY)" - "Original Amt. (LCY)";
                PaymentLCY := "Original Amt. (LCY)";
                GetAppliedDocs();
                if TempCustLedgerEntry.Find('-') then begin
                    "Cust. Ledger Entry"."Applies-to Doc. Type" := TempCustLedgerEntry."Applies-to Doc. Type";
                    "Cust. Ledger Entry"."Applies-to Doc. No." := TempCustLedgerEntry."Applies-to Doc. No.";
                end;

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
                TotalPmtDiscLCY += "Amount (LCY)" - "Original Amt. (LCY)";
                TotalPaymentLCY += "Original Amt. (LCY)";
                TotalAmountLCY += "Amount (LCY)";
            end;

            trigger OnPreDataItem()
            begin
                if Sorting = Sorting::Chronological then
                    "Cust. Ledger Entry".SetCurrentKey("Entry No.");

                GlSetup.Get();
                Clear(PmtDiscLCY);
                Clear(PaymentLCY);
                Clear(NoOfRSPG);
                TotalPmtDiscLCY := 0;
                TotalPaymentLCY := 0;
                TotalAmountLCY := 0;
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
        Text004: Label 'Filter: ';
        Text005: Label 'Total Customer';
        GlSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        Sorting: Option Customer,Chronological;
        LinesPerGrp: Integer;
        NoOfPmts: Integer;
        AccNo: Code[20];
        AccName: Text[100];
        Text006: Label 'Layout Standard';
        PmtDiscLCY: Decimal;
        PaymentLCY: Decimal;
        SortingTypeNo: Integer;
        DetailedEntryProcessFlag: Boolean;
        NoOfRSPG: Decimal;
        TotalPmtDiscLCY: Decimal;
        TotalPaymentLCY: Decimal;
        TotalAmountLCY: Decimal;
        CustomerPaymentsListCaptionLbl: Label 'Customer Payments List';
        PageNoCaptionLbl: Label 'Page';
        CustomerNoCaptionLbl: Label 'Customer No.';
        DateCaptionLbl: Label 'Date';
        DocCaptionLbl: Label 'Doc.';
        AmtLCYCaptionLbl: Label 'Amt. LCY';
        NameCaptionLbl: Label 'Name';
        AppliesToDocNoCaptionLbl: Label 'Applies-to Doc. No.';
        PaymentLCYCaptionLbl: Label 'Payment LCY';
        PmtDiscCurrDiffCaptionLbl: Label 'Pmt. Disc.& Curr.Diff.';
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

    [Scope('OnPrem')]
    procedure GetAppliedDocs()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgerEntry: Record "Detailed Cust. Ledg. Entry";
        Counter: Integer;
        CustLedgerEntryNo: Integer;
        SumAmount: Decimal;
    begin
        TempCustLedgerEntry.DeleteAll();
        TempCustLedgerEntry.Init();
        Counter := 0;

        DetailedCustLedgerEntry.Reset();
        DetailedCustLedgerEntry.SetCurrentKey("Applied Cust. Ledger Entry No.");
        DetailedCustLedgerEntry.SetRange("Applied Cust. Ledger Entry No.", "Cust. Ledger Entry"."Entry No.");
        DetailedCustLedgerEntry.SetFilter("Cust. Ledger Entry No.", '<>%1&<>%2', 0, "Cust. Ledger Entry"."Entry No.");
        DetailedCustLedgerEntry.SetRange(Unapplied, false);
        SumAmount := 0;
        CustLedgerEntryNo := 0;
        if DetailedCustLedgerEntry.Find('-') then begin
            repeat
                if (CustLedgerEntryNo <> 0) and (CustLedgerEntryNo <> DetailedCustLedgerEntry."Cust. Ledger Entry No.") then begin
                    CustLedgerEntry.Get(CustLedgerEntryNo);
                    if SumAmount <> 0 then begin
                        Counter := Counter + 1;
                        TempCustLedgerEntry := CustLedgerEntry;
                        TempCustLedgerEntry."Entry No." := Counter;
                        TempCustLedgerEntry.Insert();
                        SumAmount := 0;
                    end;
                end;
                SumAmount := SumAmount + DetailedCustLedgerEntry."Amount (LCY)";
                CustLedgerEntryNo := DetailedCustLedgerEntry."Cust. Ledger Entry No.";
            until DetailedCustLedgerEntry.Next() = 0;
            CustLedgerEntry.Get(CustLedgerEntryNo);
            if SumAmount <> 0 then begin
                Counter := Counter + 1;
                TempCustLedgerEntry := CustLedgerEntry;
                TempCustLedgerEntry."Entry No." := Counter;
                TempCustLedgerEntry.Insert();
            end;
        end;

        DetailedCustLedgerEntry.Reset();
        DetailedCustLedgerEntry.SetCurrentKey("Cust. Ledger Entry No.");
        DetailedCustLedgerEntry.SetRange("Cust. Ledger Entry No.", "Cust. Ledger Entry"."Entry No.");
        DetailedCustLedgerEntry.SetFilter("Applied Cust. Ledger Entry No.", '<>%1&<>%2', 0, "Cust. Ledger Entry"."Entry No.");
        DetailedCustLedgerEntry.SetRange(Unapplied, false);
        SumAmount := 0;
        CustLedgerEntryNo := 0;
        if DetailedCustLedgerEntry.Find('-') then begin
            repeat
                if (CustLedgerEntryNo <> 0) and (CustLedgerEntryNo <> DetailedCustLedgerEntry."Applied Cust. Ledger Entry No.") then begin
                    CustLedgerEntry.Get(CustLedgerEntryNo);
                    if SumAmount <> 0 then begin
                        Counter := Counter + 1;
                        TempCustLedgerEntry := CustLedgerEntry;
                        TempCustLedgerEntry."Entry No." := Counter;
                        TempCustLedgerEntry.Insert();
                        SumAmount := 0;
                    end;
                end;
                SumAmount := SumAmount - DetailedCustLedgerEntry."Amount (LCY)";
                CustLedgerEntryNo := DetailedCustLedgerEntry."Applied Cust. Ledger Entry No.";
            until DetailedCustLedgerEntry.Next() = 0;
            CustLedgerEntry.Get(CustLedgerEntryNo);
            if SumAmount <> 0 then begin
                Counter := Counter + 1;
                TempCustLedgerEntry := CustLedgerEntry;
                TempCustLedgerEntry."Entry No." := Counter;
                TempCustLedgerEntry.Insert();
            end;
        end;
    end;
}

