// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

page 9094 "Vendor Statistics FactBox"
{
    Caption = 'Vendor Statistics';
    PageType = CardPart;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Vendor No.';
                ToolTip = 'Specifies the number of the vendor. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field("Balance (LCY)"; Rec."Balance (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total value of your completed purchases from the vendor in the current fiscal year. It is calculated from amounts including VAT on all completed purchase invoices and credit memos.';

                trigger OnDrillDown()
                var
                    VendLedgEntry: Record "Vendor Ledger Entry";
                    DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                begin
                    DtldVendLedgEntry.SetRange("Vendor No.", Rec."No.");
                    Rec.CopyFilter("Global Dimension 1 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 1");
                    Rec.CopyFilter("Global Dimension 2 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 2");
                    Rec.CopyFilter("Currency Filter", DtldVendLedgEntry."Currency Code");
                    VendLedgEntry.DrillDownOnEntries(DtldVendLedgEntry);
                end;
            }
            field(BalanceAsCustomer; BalanceAsCustomer)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance (LCY) As Customer';
                Editable = false;
                Enabled = BalanceAsCustomerEnabled;
                ToolTip = 'Specifies the amount that this company owes you. This is relevant when your vendor is also your customer. Vendor and customer are linked together through their contact record. Using vendor''s contact record you can create linked customer or link contact with existing customer to enable calculation of Balance As Customer amount.';

                trigger OnDrillDown()
                var
                    DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                    CustLedgerEntry: Record "Cust. Ledger Entry";
                begin
                    if LinkedCustomerNo = '' then
                        exit;
                    DetailedCustLedgEntry.SetRange("Customer No.", LinkedCustomerNo);
                    Rec.CopyFilter("Global Dimension 1 Filter", DetailedCustLedgEntry."Initial Entry Global Dim. 1");
                    Rec.CopyFilter("Global Dimension 2 Filter", DetailedCustLedgEntry."Initial Entry Global Dim. 2");
                    Rec.CopyFilter("Currency Filter", DetailedCustLedgEntry."Currency Code");
                    CustLedgerEntry.DrillDownOnEntries(DetailedCustLedgEntry);
                end;
            }
            field("Outstanding Orders (LCY)"; Rec."Outstanding Orders (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sum of outstanding orders (in LCY) to this vendor.';
            }
            field("Amt. Rcd. Not Invoiced (LCY)"; Rec."Amt. Rcd. Not Invoiced (LCY)")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Amt. Rcd. Not Invd. (LCY)';
                ToolTip = 'Specifies the total invoice amount (in LCY) for the items you have received but not yet been invoiced for.';
            }
            field("Outstanding Invoices (LCY)"; Rec."Outstanding Invoices (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sum of the vendor''s outstanding purchase invoices in LCY.';
            }
            field(TotalAmountLCY; TotalAmountLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Total (LCY)';
                ToolTip = 'Specifies the payment amount that you owe the vendor for completed purchases plus purchases that are still ongoing.';
            }
            field("Balance Due (LCY)"; OverDueBalance)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Format(StrSubstNo(OverdueAmountsLCYTxt, Format(WorkDate())));
                Caption = 'Balance Due (LCY)';

                trigger OnDrillDown()
                var
                    VendLedgEntry: Record "Vendor Ledger Entry";
                    DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                begin
                    DtldVendLedgEntry.SetFilter("Vendor No.", Rec."No.");
                    Rec.CopyFilter("Global Dimension 1 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 1");
                    Rec.CopyFilter("Global Dimension 2 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 2");
                    Rec.CopyFilter("Currency Filter", DtldVendLedgEntry."Currency Code");
                    VendLedgEntry.DrillDownOnOverdueEntries(DtldVendLedgEntry);
                end;
            }
            field(GetInvoicedPrepmtAmountLCY; InvoicedPrepmtAmountLCY)
            {
                ApplicationArea = Prepayments;
                Caption = 'Invoiced Prepayment Amount (LCY)';
                ToolTip = 'Specifies your payments to the vendor, based on invoiced prepayments.';
            }
            field("Payments (LCY)"; Rec."Payments (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sum of payments paid to the vendor.';
                trigger OnDrillDown()
                var
                    VendorLedgerEntry: Record "Vendor Ledger Entry";
                    VendorLedgerEntries: Page "Vendor Ledger Entries";
                begin
                    Clear(VendorLedgerEntries);
                    SetFilterLastPaymentDateEntry(VendorLedgerEntry);
                    if VendorLedgerEntry.FindLast() then
                        VendorLedgerEntries.SetRecord(VendorLedgerEntry);
                    VendorLedgerEntries.SetTableView(VendorLedgerEntry);
                    VendorLedgerEntries.Run();
                end;
            }
            field("Refunds (LCY)"; Rec."Refunds (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sum of refunds paid to the vendor.';
                trigger OnDrillDown()
                var
                    VendorLedgerEntry: Record "Vendor Ledger Entry";
                    VendorLedgerEntries: Page "Vendor Ledger Entries";
                begin
                    Clear(VendorLedgerEntries);
                    SetFilterRefundEntry(VendorLedgerEntry);
                    if VendorLedgerEntry.FindLast() then
                        VendorLedgerEntries.SetRecord(VendorLedgerEntry);
                    VendorLedgerEntries.SetTableView(VendorLedgerEntry);
                    VendorLedgerEntries.Run();
                end;
            }
            field(LastPaymentDate; LastPaymentDate)
            {
                AccessByPermission = TableData "Vendor Ledger Entry" = R;
                ApplicationArea = Basic, Suite;
                Caption = 'Last Payment Date';
                ToolTip = 'Specifies the posting date of the last payment paid to the vendor.';

                trigger OnDrillDown()
                var
                    VendorLedgerEntry: Record "Vendor Ledger Entry";
                    VendorLedgerEntries: Page "Vendor Ledger Entries";
                begin
                    Clear(VendorLedgerEntries);
                    SetFilterLastPaymentDateEntry(VendorLedgerEntry);
                    if VendorLedgerEntry.FindLast() then
                        VendorLedgerEntries.SetRecord(VendorLedgerEntry);
                    VendorLedgerEntries.SetTableView(VendorLedgerEntry);
                    VendorLedgerEntries.Run();
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.SetAutoCalcFields("Balance (LCY)", "Outstanding Orders (LCY)", "Amt. Rcd. Not Invoiced (LCY)", "Outstanding Invoices (LCY)");
    end;

    trigger OnAfterGetRecord()
    var
        VendorNo: Code[20];
        VendorNoFilter: Text;
    begin
        TotalAmountLCY := Rec."Balance (LCY)" + Rec."Outstanding Orders (LCY)" + Rec."Amt. Rcd. Not Invoiced (LCY)" + Rec."Outstanding Invoices (LCY)";

        // Get the vendor number and set the current vendor number
        Rec.FilterGroup(4);
        VendorNoFilter := Rec.GetFilter("No.");
        if (VendorNoFilter = '') then begin
            Rec.FilterGroup(0);
            VendorNoFilter := Rec.GetFilter("No.");
        end;

        VendorNo := CopyStr(VendorNoFilter, 1, MaxStrLen(VendorNo));
        if VendorNo <> CurrVendorNo then begin
            CurrVendorNo := VendorNo;
            CalculateFieldValues(CurrVendorNo);
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        TotalAmountLCY := 0;

        exit(Rec.Find(Which));
    end;

    var
#pragma warning disable AA0470
        OverdueAmountsLCYTxt: Label 'Overdue Amounts (LCY) as of %1';
#pragma warning restore AA0470
        TaskIdCalculateCue: Integer;
        CurrVendorNo: Code[20];
        LinkedCustomerNo: Code[20];
        BalanceAsCustomerEnabled: Boolean;

    protected var
        TotalAmountLCY: Decimal;
        LastPaymentDate: Date;
        InvoicedPrepmtAmountLCY: Decimal;
        OverdueBalance: Decimal;
        BalanceAsCustomer: Decimal;

    procedure CalculateFieldValues(VendorNo: Code[20])
    var
        CalculateVendorStats: Codeunit "Calculate Vendor Stats.";
        Args: Dictionary of [Text, Text];
    begin
        if (TaskIdCalculateCue <> 0) then
            CurrPage.CancelBackgroundTask(TaskIdCalculateCue);

        Clear(LastPaymentDate);
        Clear(OverdueBalance);
        Clear(InvoicedPrepmtAmountLCY);
        Clear(LinkedCustomerNo);
        Clear(BalanceAsCustomer);
        Clear(BalanceAsCustomerEnabled);

        if VendorNo = '' then
            exit;

        Args.Add(CalculateVendorStats.GetVendorNoLabel(), VendorNo);
        CurrPage.EnqueueBackgroundTask(TaskIdCalculateCue, Codeunit::"Calculate Vendor Stats.", Args);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CalculateVendorStats: Codeunit "Calculate Vendor Stats.";
        DictionaryValue: Text;
    begin
        if (TaskId = TaskIdCalculateCue) then begin
            if Results.Count() = 0 then
                exit;

            if TryGetDictionaryValueFromKey(Results, CalculateVendorStats.GetLastPaymentDateLabel(), DictionaryValue) then
                Evaluate(LastPaymentDate, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateVendorStats.GetOverdueBalanceLabel(), DictionaryValue) then
                Evaluate(OverdueBalance, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateVendorStats.GetInvoicedPrepmtAmountLCYLabel(), DictionaryValue) then
                Evaluate(InvoicedPrepmtAmountLCY, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateVendorStats.GetLinkedCustomerNoLabel(), DictionaryValue) then
                LinkedCustomerNo := CopyStr(DictionaryValue, 1, MaxStrLen(LinkedCustomerNo));
            BalanceAsCustomerEnabled := LinkedCustomerNo <> '';
            if BalanceAsCustomerEnabled then
                if TryGetDictionaryValueFromKey(Results, CalculateVendorStats.GetBalanceAsCustomerLabel(), DictionaryValue) then
                    Evaluate(BalanceAsCustomer, DictionaryValue);
        end;
    end;

    [TryFunction]
    local procedure TryGetDictionaryValueFromKey(var DictionaryToLookIn: Dictionary of [Text, Text]; KeyToSearchFor: Text; var ReturnValue: Text)
    begin
        ReturnValue := DictionaryToLookIn.Get(KeyToSearchFor);
    end;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Vendor Card", Rec);
    end;

    local procedure SetFilterLastPaymentDateEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date", "Currency Code");
        VendorLedgerEntry.SetRange("Vendor No.", Rec."No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetRange(Reversed, false);
    end;

    local procedure SetFilterRefundEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date", "Currency Code");
        VendorLedgerEntry.SetRange("Vendor No.", Rec."No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Refund);
        VendorLedgerEntry.SetRange(Reversed, false);
    end;
}
