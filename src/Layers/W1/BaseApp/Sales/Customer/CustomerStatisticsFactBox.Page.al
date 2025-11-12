// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Foundation.Period;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;

page 9082 "Customer Statistics FactBox"
{
    Caption = 'Customer Statistics';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Customer No.';
                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field("Balance (LCY)"; Rec."Balance (LCY)")
            {
                ApplicationArea = Basic, Suite;
                trigger OnDrillDown()
                var
                    DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                    CustLedgEntry: Record "Cust. Ledger Entry";
                begin
                    DtldCustLedgEntry.SetRange("Customer No.", Rec."No.");
                    Rec.CopyFilter("Global Dimension 1 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 1");
                    Rec.CopyFilter("Global Dimension 2 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 2");
                    Rec.CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");
                    CustLedgEntry.DrillDownOnEntries(DtldCustLedgEntry);
                end;
            }
            field(BalanceAsVendor; BalanceAsVendor)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance (LCY) As Vendor';
                Editable = false;
                Enabled = BalanceAsVendorEnabled;
                ToolTip = 'Specifies the amount that you owe to this company. This is relevant when your customer is also your vendor. Customer and vendor are linked together through their contact record. Using customer''s contact record you can create linked vendor or link contact with existing vendor to enable calculation of Balance As Vendor amount.';

                trigger OnDrillDown()
                var
                    DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                    VendLedgEntry: Record "Vendor Ledger Entry";
                begin
                    if LinkedVendorNo = '' then
                        exit;
                    DtldVendLedgEntry.SetRange("Vendor No.", LinkedVendorNo);
                    Rec.CopyFilter("Global Dimension 1 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 1");
                    Rec.CopyFilter("Global Dimension 2 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 2");
                    Rec.CopyFilter("Currency Filter", DtldVendLedgEntry."Currency Code");
                    VendLedgEntry.DrillDownOnEntries(DtldVendLedgEntry);
                end;
            }
            group(Sales)
            {
                Caption = 'Sales';
                field("Outstanding Orders (LCY)"; Rec."Outstanding Orders (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Shipped Not Invoiced (LCY)"; Rec."Shipped Not Invoiced (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Outstanding Invoices (LCY)"; Rec."Outstanding Invoices (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                field("Payments (LCY)"; Rec."Payments (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        Clear(CustomerLedgerEntries);
                        SetFilterLastPaymentDateEntry(CustLedgerEntry);
                        if CustLedgerEntry.FindLast() then
                            CustomerLedgerEntries.SetRecord(CustLedgerEntry);
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
                    end;
                }
                field("Refunds (LCY)"; Rec."Refunds (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        Clear(CustomerLedgerEntries);
                        SetFilterRefundEntry(CustLedgerEntry);
                        if CustLedgerEntry.FindLast() then
                            CustomerLedgerEntries.SetRecord(CustLedgerEntry);
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
                    end;
                }
                field(LastPaymentReceiptDate; LastPaymentDate)
                {
                    AccessByPermission = TableData "Cust. Ledger Entry" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Payment Receipt Date';
                    ToolTip = 'Specifies the posting date of the last payment received from the customer.';

                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        Clear(CustomerLedgerEntries);
                        SetFilterLastPaymentDateEntry(CustLedgerEntry);
                        if CustLedgerEntry.FindLast() then
                            CustomerLedgerEntries.SetRecord(CustLedgerEntry);
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
                    end;
                }
            }
            field("Total (LCY)"; TotalAmountLCY)
            {
                AccessByPermission = TableData "Sales Line" = R;
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Total (LCY)';
                Importance = Promoted;
                Style = Strong;
                StyleExpr = true;
                ToolTip = 'Specifies the payment amount that the customer owes for completed sales plus sales that are still ongoing.';
            }
            field("Credit Limit (LCY)"; Rec."Credit Limit (LCY)")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Balance Due (LCY)"; OverdueBalance)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Text000;
                Caption = 'Balance Due (LCY)';

                trigger OnDrillDown()
                var
                    DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                    CustLedgEntry: Record "Cust. Ledger Entry";
                begin
                    DtldCustLedgEntry.SetFilter("Customer No.", Rec."No.");
                    Rec.CopyFilter("Global Dimension 1 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 1");
                    Rec.CopyFilter("Global Dimension 2 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 2");
                    Rec.CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");
                    CustLedgEntry.DrillDownOnOverdueEntries(DtldCustLedgEntry);
                end;
            }
            field("Sales (LCY)"; SalesLCY)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Total Sales (LCY)';
                ToolTip = 'Specifies your total sales turnover with the customer in the current fiscal year. It is calculated from amounts excluding VAT on all completed and open sales invoices and credit memos.';

                trigger OnDrillDown()
                var
                    CustLedgEntry: Record "Cust. Ledger Entry";
                    DateFilterCalc: Codeunit "DateFilter-Calc";
                    CustDateFilter: Text[30];
                    CustDateName: Text[30];
                begin
                    CustLedgEntry.Reset();
                    CustLedgEntry.SetRange("Customer No.", Rec."No.");
                    DateFilterCalc.CreateFiscalYearFilter(CustDateFilter, CustDateName, WorkDate(), 0);
                    CustLedgEntry.SetFilter("Posting Date", CustDateFilter);
                    PAGE.RunModal(PAGE::"Customer Ledger Entries", CustLedgEntry);
                end;
            }
            field(GetInvoicedPrepmtAmountLCY; InvoicedPrepmtAmountLCY)
            {
                AccessByPermission = TableData "Sales Line" = R;
                ApplicationArea = Prepayments;
                Caption = 'Invoiced Prepayment Amount (LCY)';
                ToolTip = 'Specifies your sales income from the customer, based on invoiced prepayments.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        CustomerNo: Code[20];
        CustomerNoFilter: Text;
    begin
        Rec.FilterGroup(4);
        // Get the customer number and set the current customer number
        CustomerNoFilter := Rec.GetFilter("No.");
        if (CustomerNoFilter = '') then begin
            Rec.FilterGroup(0);
            CustomerNoFilter := Rec.GetFilter("No.");
        end;

        CustomerNo := CopyStr(CustomerNoFilter, 1, MaxStrLen(CustomerNo));
        if CustomerNo <> CurrCustomerNo then begin
            CurrCustomerNo := CustomerNo;
            CalculateFieldValues(CurrCustomerNo);
        end;
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Overdue Amounts (LCY)';
#pragma warning restore AA0074
        TaskIdCalculateCue: Integer;
        CurrCustomerNo: Code[20];
        LinkedVendorNo: Code[20];
        BalanceAsVendorEnabled: Boolean;

    protected var
        LastPaymentDate: Date;
        TotalAmountLCY: Decimal;
        OverdueBalance: Decimal;
        SalesLCY: Decimal;
        InvoicedPrepmtAmountLCY: Decimal;
        BalanceAsVendor: Decimal;

    procedure CalculateFieldValues(CustomerNo: Code[20])
    var
        CalculateCustomerStats: Codeunit "Calculate Customer Stats.";
        Args: Dictionary of [Text, Text];
    begin
        if (TaskIdCalculateCue <> 0) then
            CurrPage.CancelBackgroundTask(TaskIdCalculateCue);

        Clear(LastPaymentDate);
        Clear(TotalAmountLCY);
        Clear(OverdueBalance);
        Clear(SalesLCY);
        Clear(InvoicedPrepmtAmountLCY);
        Clear(BalanceAsVendor);
        Clear(LinkedVendorNo);
        Clear(BalanceAsVendorEnabled);

        if CustomerNo = '' then
            exit;

        Args.Add(CalculateCustomerStats.GetCustomerNoLabel(), CustomerNo);
        CurrPage.EnqueueBackgroundTask(TaskIdCalculateCue, Codeunit::"Calculate Customer Stats.", Args);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CalculateCustomerStats: Codeunit "Calculate Customer Stats.";
        DictionaryValue: Text;
    begin
        if (TaskId = TaskIdCalculateCue) then begin
            if Results.Count() = 0 then
                exit;

            if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetLastPaymentDateLabel(), DictionaryValue) then
                Evaluate(LastPaymentDate, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetTotalAmountLCYLabel(), DictionaryValue) then
                Evaluate(TotalAmountLCY, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetOverdueBalanceLabel(), DictionaryValue) then
                Evaluate(OverdueBalance, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetSalesLCYLabel(), DictionaryValue) then
                Evaluate(SalesLCY, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetInvoicedPrepmtAmountLCYLabel(), DictionaryValue) then
                Evaluate(InvoicedPrepmtAmountLCY, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetLinkedVendorNoLabel(), DictionaryValue) then
                LinkedVendorNo := CopyStr(DictionaryValue, 1, MaxStrLen(LinkedVendorNo));
            BalanceAsVendorEnabled := LinkedVendorNo <> '';
            if BalanceAsVendorEnabled then
                if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetBalanceAsVendorLabel(), DictionaryValue) then
                    Evaluate(BalanceAsVendor, DictionaryValue);
        end;
    end;

    [TryFunction]
    local procedure TryGetDictionaryValueFromKey(var DictionaryToLookIn: Dictionary of [Text, Text]; KeyToSearchFor: Text; var ReturnValue: Text)
    begin
        ReturnValue := DictionaryToLookIn.Get(KeyToSearchFor);
    end;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Customer Card", Rec);
    end;

    local procedure SetFilterLastPaymentDateEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Currency Code");
        CustLedgerEntry.SetRange("Customer No.", Rec."No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange(Reversed, false);
    end;

    local procedure SetFilterRefundEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Currency Code");
        CustLedgerEntry.SetRange("Customer No.", Rec."No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Refund);
        CustLedgerEntry.SetRange(Reversed, false);
    end;
}
