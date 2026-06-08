// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Utilities;

report 10041 "Cash Applied"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CashApplied.rdlc';
    Caption = 'Cash Applied';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date") where("Document Type" = const(Payment));
            PrintOnlyIfDetail = false;
            RequestFilterFields = "Posting Date", "Global Dimension 1 Code", "Global Dimension 2 Code", "Salesperson Code", "Customer No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(Time; Time)
            {
            }
            column(CompanyInfoName; CompanyInformation.Name)
            {
            }
            column(DocType_CustLedgEntry; "Cust. Ledger Entry"."Document Type")
            {
            }
            column(CustLedgerEntryFilterString; "Cust. Ledger Entry".TableName + ': ' + FilterString)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(GetTotalApplied; GetTotalApplied)
            {
            }
            column(GetTotalDiscounts; GetTotalDiscounts)
            {
            }
            column(TotalApplied; TotalApplied)
            {
            }
            column(CustNo_CustLedgerEntry; "Customer No.")
            {
            }
            column(CustomerName; Customer.Name)
            {
            }
            column(DocNo_CustLedgEntry; "Document No.")
            {
            }
            column(PostingDate_CustLedgEntry; "Posting Date")
            {
            }
            column(NegativeAmountLCY_CustLedgEntry; -"Amount (LCY)")
            {
            }
            column(NegativeAmtLCY_CustLedgEntry; -"Cust. Ledger Entry"."Amount (LCY)")
            {
            }
            column(TotalDiscounts; TotalDiscounts)
            {
            }
            column(TotalApplied_CustLedgEntry; -"Cust. Ledger Entry"."Amount (LCY)" - TotalApplied)
            {
            }
            column(TotalAmountt; TotalAmout)
            {
            }
            column(EntryNo_CustLedgEntry; "Entry No.")
            {
            }
            column(CashRecptAppliedCaption; CashRecptAppliedCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(PaymentCaption; PaymentCaptionLbl)
            {
            }
            column(AppliedToDocCaption; AppliedToDocCaptionLbl)
            {
            }
            column(DiscountDateCaption; DiscountDateCaptionLbl)
            {
            }
            column(DiscountTakenCaption; DiscountTakenCaptionLbl)
            {
            }
            column(AmountAppliedCaption; AmtAppliedCaptionLbl)
            {
            }
            column(AmtNotYetAppliedCaption; AmtNotYetAppliedCaptionLbl)
            {
            }
            column(NumberCaption; NumberCaptionLbl)
            {
            }
            column(PostDateCaption_CustLedgEntry; FieldCaption("Posting Date"))
            {
            }
            column(TypeCaption; TypeCaptionLbl)
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(AmountLCYCaption; AmountLCYCaptionLbl)
            {
            }
            column(CustomerCaption; CustomerCaptionLbl)
            {
            }
            column(ReportTotalsCaption; ReportTotalsCaptionLbl)
            {
            }
            dataitem(AppliedEntries; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(TempAppliedCustLedgEntryDocType; Format(TempAppliedCustLedgEntry."Document Type"))
                {
                }
                column(TempAppliedCustLedgEntryDocNo; TempAppliedCustLedgEntry."Document No.")
                {
                }
                column(TempAppliedCustLedgEntryDueDate; TempAppliedCustLedgEntry."Due Date")
                {
                }
                column(TempAppliedCustLedgEntryPmtDisDate; TempAppliedCustLedgEntry."Pmt. Discount Date")
                {
                }
                column(TempAppliedCustLedgEntryPmtDiscGivenLCY; TempAppliedCustLedgEntry."Pmt. Disc. Given (LCY)")
                {
                }
                column(TempAppliedCustLedgEntryAmttoApply; TempAppliedCustLedgEntry."Amount to Apply")
                {
                }
                column(CustLedgerEntryAmtLCYTotalApplied; -"Cust. Ledger Entry"."Amount (LCY)" - TotalApplied)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempAppliedCustLedgEntry.Find('-')
                    else
                        TempAppliedCustLedgEntry.Next();
                    TotalApplied := TotalApplied + TempAppliedCustLedgEntry."Amount to Apply";
                    TotalDiscounts := TotalDiscounts + TempAppliedCustLedgEntry."Pmt. Disc. Given (LCY)";

                    GetTotalApplied := GetTotalApplied + TempAppliedCustLedgEntry."Amount to Apply";
                    GetTotalDiscounts := GetTotalDiscounts + TempAppliedCustLedgEntry."Pmt. Disc. Given (LCY)";
                end;

                trigger OnPreDataItem()
                begin
                    TempAppliedCustLedgEntry.SetFilter("Salesperson Code", SalespersonFilterString);
                    SetRange(Number, 1, TempAppliedCustLedgEntry.Count);
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
            }

            trigger OnAfterGetRecord()
            begin
                TotalApplied := 0;
                TotalDiscounts := 0;
                CalcFields("Amount (LCY)");
                EntryAppMgt.GetAppliedCustEntries(TempAppliedCustLedgEntry, "Cust. Ledger Entry", true);

                if OldCustomerno <> "Customer No." then
                    if not Customer.Get("Customer No.") then
                        Clear(Customer)
                    else
                        OldCustomerno := "Customer No.";
                TotalAmout := TotalAmout + "Amount (LCY)";
            end;

            trigger OnPreDataItem()
            begin
                Clear(TotalApplied);
                Clear(TotalDiscounts);
                SetRange("Salesperson Code");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
        FilterString := "Cust. Ledger Entry".GetFilters();
        SalespersonFilterString := "Cust. Ledger Entry".GetFilter("Salesperson Code");
    end;

    var
        FilterString: Text;
        SalespersonFilterString: Text;
        TotalApplied: Decimal;
        TotalDiscounts: Decimal;
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        EntryAppMgt: Codeunit "Entry Application Management";
        OldCustomerno: Code[20];
        TotalAmout: Decimal;
        GetTotalApplied: Decimal;
        GetTotalDiscounts: Decimal;
        CashRecptAppliedCaptionLbl: Label 'Cash Receipts Applied';
        PageNoCaptionLbl: Label 'Page';
        PaymentCaptionLbl: Label 'Payment';
        AppliedToDocCaptionLbl: Label 'Applied-To Document';
        DiscountDateCaptionLbl: Label 'Discount Date';
        DiscountTakenCaptionLbl: Label 'Discount Taken';
        AmtAppliedCaptionLbl: Label 'Amount Applied';
        AmtNotYetAppliedCaptionLbl: Label 'Amount Not Yet Applied';
        NumberCaptionLbl: Label 'Number';
        TypeCaptionLbl: Label 'Type';
        DueDateCaptionLbl: Label 'Due Date';
        AmountLCYCaptionLbl: Label 'Payment Amount';
        CustomerCaptionLbl: Label 'Customer:';
        ReportTotalsCaptionLbl: Label 'Report Totals';
}

