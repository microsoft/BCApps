// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Payment;
using Microsoft.Sales.Receivables;

/// <summary>
/// Prepares direct debit collection entry data for SEPA XML export by copying and organizing
/// eligible entries into a temporary structure for XMLPort processing.
/// </summary>
codeunit 1232 "SEPA DD-Prepare Source"
{
    TableNo = "Direct Debit Collection Entry";

    trigger OnRun()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.CopyFilters(Rec);
        CopyLines(DirectDebitCollectionEntry, Rec);
    end;

    /// <summary>
    /// Copies eligible direct debit collection entries to a temporary table for processing.
    /// Filters entries by status (New or File Created) and populates the target temporary table.
    /// </summary>
    /// <param name="FromDirectDebitCollectionEntry">Source direct debit collection entries with applied filters.</param>
    /// <param name="ToDirectDebitCollectionEntry">Target temporary table to receive the filtered entries.</param>
    local procedure CopyLines(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    begin
        if not FromDirectDebitCollectionEntry.IsEmpty() then begin
            FromDirectDebitCollectionEntry.SetFilter(Status, '%1|%2',
              FromDirectDebitCollectionEntry.Status::New, FromDirectDebitCollectionEntry.Status::"File Created");
            if FromDirectDebitCollectionEntry.FindSet() then
                repeat
                    ToDirectDebitCollectionEntry := FromDirectDebitCollectionEntry;
                    ToDirectDebitCollectionEntry.Insert();
                until FromDirectDebitCollectionEntry.Next() = 0
        end else
            CreateTempCollectionEntries(FromDirectDebitCollectionEntry, ToDirectDebitCollectionEntry);
    end;

    local procedure CopyFromCustBillHeader(var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry" temporary; DirectDebitCollection: Record "Direct Debit Collection")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerBillHeader: Record "Customer Bill Header";
        CustomerBillLine: Record "Customer Bill Line";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        CustomerBillHeader.Get(DirectDebitCollection.Identifier);
        CustomerBillHeader.TestField("Payment Method Code");
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillHeader."No.");
        if CustomerBillLine.FindSet() then
            repeat
                CustomerBillLine.TestField("Cumulative Bank Receipts", false);
                if SEPADirectDebitMandate.Get(CustomerBillLine."Direct Debit Mandate ID") then
                    CustomerBillLine.TestField("Customer Bank Acc. No.", SEPADirectDebitMandate."Customer Bank Account Code");
                CustLedgerEntry.Get(CustomerBillLine."Customer Entry No.");
                ToDirectDebitCollectionEntry.Init();
                ToDirectDebitCollectionEntry."Entry No." := CustomerBillLine."Line No.";
                ToDirectDebitCollectionEntry."Direct Debit Collection No." := DirectDebitCollection."No.";
                ToDirectDebitCollectionEntry.Validate("Customer No.", CustLedgerEntry."Customer No.");
                ToDirectDebitCollectionEntry.Validate("Applies-to Entry No.", CustLedgerEntry."Entry No.");
                ToDirectDebitCollectionEntry."Transfer Date" := CustomerBillLine."Due Date";
                ToDirectDebitCollectionEntry.Validate("Mandate ID", CustomerBillLine."Direct Debit Mandate ID");
                ToDirectDebitCollectionEntry.Insert();
            until CustomerBillLine.Next() = 0;
    end;

    local procedure CopyFromIssuedCustBillHeader(var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry" temporary; DirectDebitCollection: Record "Direct Debit Collection")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        IssuedCustomerBillHeader.Get(DirectDebitCollection.Identifier);
        IssuedCustomerBillHeader.TestField("Payment Method Code");
        IssuedCustomerBillLine.SetRange("Customer Bill No.", IssuedCustomerBillHeader."No.");
        if IssuedCustomerBillLine.FindSet() then
            repeat
                IssuedCustomerBillLine.TestField("Cumulative Bank Receipts", false);
                if SEPADirectDebitMandate.Get(IssuedCustomerBillLine."Direct Debit Mandate ID") then
                    IssuedCustomerBillLine.TestField("Customer Bank Acc. No.", SEPADirectDebitMandate."Customer Bank Account Code");
                CustLedgerEntry.Get(IssuedCustomerBillLine."Customer Entry No.");
                ToDirectDebitCollectionEntry.Init();
                ToDirectDebitCollectionEntry."Entry No." := IssuedCustomerBillLine."Line No.";
                ToDirectDebitCollectionEntry."Direct Debit Collection No." := DirectDebitCollection."No.";
                ToDirectDebitCollectionEntry.Validate("Customer No.", CustLedgerEntry."Customer No.");
                ToDirectDebitCollectionEntry.Validate("Applies-to Entry No.", CustLedgerEntry."Entry No.");
                ToDirectDebitCollectionEntry."Transfer Date" := IssuedCustomerBillLine."Due Date";
                ToDirectDebitCollectionEntry.Validate("Mandate ID", IssuedCustomerBillLine."Direct Debit Mandate ID");
                ToDirectDebitCollectionEntry.Insert();
            until IssuedCustomerBillLine.Next() = 0;
    end;

    /// <summary>
    /// Creates temporary collection entries when no source entries are found.
    /// Allows customization through integration events for alternative data population strategies.
    /// </summary>
    /// <param name="FromDirectDebitCollectionEntry">Source entry record used as template for temporary entries.</param>
    /// <param name="ToDirectDebitCollectionEntry">Target temporary table to populate with generated entries.</param>
    local procedure CreateTempCollectionEntries(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempCollectionEntries(FromDirectDebitCollectionEntry, ToDirectDebitCollectionEntry, IsHandled);
        if IsHandled then
            exit;

        ToDirectDebitCollectionEntry.Reset();
        DirectDebitCollection.Get(FromDirectDebitCollectionEntry.GetRangeMin("Direct Debit Collection No."));

        case DirectDebitCollection."Source Table ID" of
            DATABASE::"Customer Bill Header":
                CopyFromCustBillHeader(ToDirectDebitCollectionEntry, DirectDebitCollection);
            DATABASE::"Issued Customer Bill Header":
                CopyFromIssuedCustBillHeader(ToDirectDebitCollectionEntry, DirectDebitCollection);
        end;

        OnAfterCreateTempCollectionEntries(FromDirectDebitCollectionEntry, ToDirectDebitCollectionEntry);
    end;

    /// <summary>
    /// Integration event raised after creating temporary collection entries.
    /// Allows subscribers to modify or enhance the temporary entries after creation.
    /// </summary>
    /// <param name="FromDirectDebitCollectionEntry">Source entry record used as template.</param>
    /// <param name="ToDirectDebitCollectionEntry">Target temporary entry that was created.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempCollectionEntries(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before creating temporary collection entries.
    /// Allows subscribers to provide custom logic for temporary entry creation.
    /// </summary>
    /// <param name="FromDirectDebitCollectionEntry">Source entry record used as template.</param>
    /// <param name="ToDirectDebitCollectionEntry">Target temporary entry to be created.</param>
    /// <param name="isHandled">Set to true if the subscriber handles the entry creation completely.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempCollectionEntries(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var isHandled: Boolean)
    begin
    end;
}

