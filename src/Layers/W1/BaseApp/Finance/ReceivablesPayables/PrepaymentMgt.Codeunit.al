// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Threading;

/// <summary>
/// Manages prepayment processing and validation for sales and purchase documents.
/// Handles prepayment amount validation, status management, and automatic order release processing.
/// </summary>
/// <remarks>
/// Core prepayment management engine providing validation and processing workflows for sales and purchase prepayments.
/// Integrates with job queue for automatic status updates and VAT calculation validation.
/// Supports multi-currency prepayments with currency-specific rounding and validation logic.
/// Provides extensibility through prepayment processing events and status change notifications.
/// </remarks>
codeunit 441 "Prepayment Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        JobQueueEntryHasStartedTxt: Label 'A job for changing the status from Pending Prepayment to Release has started with the frequency %1.', Comment = '%1 - job queue frequency';
        StatusOfSalesOrderIsChangedTxt: Label 'The status of the sales order %1 is changed from Pending Prepayment to Release.', Comment = '%1 - sales order no.';
        StatusOfPurchaseOrderIsChangedTxt: Label 'The status of the purchase order %1 is changed from Pending Prepayment to Release.', Comment = '%1 - purchase order no.';
        UpdateSalesOrderStatusTxt: Label 'Update sales order status.';
        UpdatePurchaseOrderStatusTxt: Label 'Update purchase order status.';
        PrepaymentAmountHigherThanTheOrderErr: Label 'The Prepayment account is assigned to a VAT product posting group where the VAT percentage is not equal to zero. This can cause posting errors when invoices have mixed VAT lines. To avoid errors, set the VAT percentage to zero for the account.\\Prepayment amount to be posted is %1. It differs from document amount %2 by %3 in related lines. If the difference is related to rounding, please adjust amounts in lines related to prepayments.', Comment = '%1 - prepayment amount; %2 = document amount; %3 = difference amount';
        PrepaymentInvoicesNotPaidErr: Label 'You cannot get lines until you have posted all related prepayment invoices to mark the prepayment as paid.';

    /// <summary>
    /// Validates that prepayment amount does not exceed the total document amount including VAT.
    /// Applies invoice rounding if configured and throws error if prepayment exceeds document total.
    /// </summary>
    /// <param name="DocumentTotalInclVAT">Total document amount including VAT</param>
    /// <param name="PrepmtTotalInclVAT">Total prepayment amount including VAT</param>
    /// <param name="CurrencyCode">Currency code for rounding calculations</param>
    /// <param name="InvoiceRoundingSetup">Whether invoice rounding is enabled</param>
    procedure AssertPrepmtAmountNotMoreThanDocAmount(DocumentTotalInclVAT: Decimal; PrepmtTotalInclVAT: Decimal; CurrencyCode: Code[10]; InvoiceRoundingSetup: Boolean)
    var
        CurrencyLcl: Record Currency;
    begin
        if InvoiceRoundingSetup then begin
            CurrencyLcl.Initialize(CurrencyCode);
            DocumentTotalInclVAT :=
              Round(DocumentTotalInclVAT, CurrencyLcl."Invoice Rounding Precision", CurrencyLcl.InvoiceRoundingDirection());
        end;
        if Abs(PrepmtTotalInclVAT) > Abs(DocumentTotalInclVAT) then
            Error(PrepaymentAmountHigherThanTheOrderErr, Abs(PrepmtTotalInclVAT), Abs(DocumentTotalInclVAT), Abs(PrepmtTotalInclVAT) - Abs(DocumentTotalInclVAT));
    end;

    /// <summary>
    /// Sets prepayment percentage on sales line based on customer and item prepayment configuration.
    /// Determines appropriate prepayment percentage from customer, item, or G/L account setup.
    /// </summary>
    /// <param name="SalesLine">Sales line to update with prepayment percentage</param>
    /// <param name="Date">Date for determining applicable prepayment setup</param>
    procedure SetSalesPrepaymentPct(var SalesLine: Record "Sales Line"; Date: Date)
    var
        Cust: Record Customer;
        SalesPrepaymentPct: Record "Sales Prepayment %";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSalesPrepaymentPct(SalesLine, Date, IsHandled);
        if IsHandled then
            exit;

        if (SalesLine.Type <> SalesLine.Type::Item) or (SalesLine."No." = '') or
           (SalesLine."Document Type" <> SalesLine."Document Type"::Order)
        then
            exit;
        SalesPrepaymentPct.SetFilter("Starting Date", '..%1', Date);
        SalesPrepaymentPct.SetFilter("Ending Date", '%1|>=%2', 0D, Date);
        SalesPrepaymentPct.SetRange("Item No.", SalesLine."No.");
        for SalesPrepaymentPct."Sales Type" := SalesPrepaymentPct."Sales Type"::Customer to SalesPrepaymentPct."Sales Type"::"All Customers" do begin
            SalesPrepaymentPct.SetRange("Sales Type", SalesPrepaymentPct."Sales Type");
            case SalesPrepaymentPct."Sales Type" of
                SalesPrepaymentPct."Sales Type"::Customer:
                    begin
                        SalesPrepaymentPct.SetRange("Sales Code", SalesLine."Bill-to Customer No.");
                        if ApplySalesPrepaymentPct(SalesLine, SalesPrepaymentPct) then
                            exit;
                    end;
                SalesPrepaymentPct."Sales Type"::"Customer Price Group":
                    begin
                        Cust.Get(SalesLine."Bill-to Customer No.");
                        if Cust."Customer Price Group" <> '' then
                            SalesPrepaymentPct.SetRange("Sales Code", Cust."Customer Price Group");
                        if ApplySalesPrepaymentPct(SalesLine, SalesPrepaymentPct) then
                            exit;
                    end;
                SalesPrepaymentPct."Sales Type"::"All Customers":
                    begin
                        SalesPrepaymentPct.SetRange("Sales Code");
                        if ApplySalesPrepaymentPct(SalesLine, SalesPrepaymentPct) then
                            exit;
                    end;
            end;
        end;
    end;

    local procedure ApplySalesPrepaymentPct(var SalesLine: Record "Sales Line"; var SalesPrepaymentPct: Record "Sales Prepayment %"): Boolean
    begin
        if SalesPrepaymentPct.FindLast() then begin
            SalesLine."Prepayment %" := SalesPrepaymentPct."Prepayment %";
            exit(true);
        end;
    end;

    /// <summary>
    /// Sets purchase prepayment percentage based on purchase prepayment setup.
    /// Updates purchase line prepayment percentage from purchase prepayment percentage configuration.
    /// </summary>
    /// <param name="PurchLine">Purchase line to update with prepayment percentage</param>
    /// <param name="Date">Date to use for prepayment percentage lookup</param>
    procedure SetPurchPrepaymentPct(var PurchLine: Record "Purchase Line"; Date: Date)
    var
        PurchPrepaymentPct: Record "Purchase Prepayment %";
    begin
        if (PurchLine.Type <> PurchLine.Type::Item) or (PurchLine."No." = '') or
           (PurchLine."Document Type" <> PurchLine."Document Type"::Order)
        then
            exit;
        PurchPrepaymentPct.SetFilter("Starting Date", '..%1', Date);
        PurchPrepaymentPct.SetFilter("Ending Date", '%1|>=%2', 0D, Date);
        PurchPrepaymentPct.SetRange("Item No.", PurchLine."No.");
        PurchPrepaymentPct.SetRange("Vendor No.", PurchLine."Pay-to Vendor No.");
        if ApplyPurchPrepaymentPct(PurchLine, PurchPrepaymentPct) then
            exit;
        // All Vendors
        PurchPrepaymentPct.SetRange("Vendor No.", '');
        if ApplyPurchPrepaymentPct(PurchLine, PurchPrepaymentPct) then
            exit;
    end;

    local procedure ApplyPurchPrepaymentPct(var PurchLine: Record "Purchase Line"; var PurchPrepaymentPct: Record "Purchase Prepayment %"): Boolean
    begin
        if PurchPrepaymentPct.FindLast() then begin
            PurchLine."Prepayment %" := PurchPrepaymentPct."Prepayment %";
            exit(true);
        end;
    end;

    /// <summary>
    /// Tests if sales document has prepayment requirements.
    /// Validates whether sales order contains prepayment percentages that require prepayment invoice processing.
    /// </summary>
    /// <param name="SalesHeader">Sales header to test for prepayment requirements</param>
    /// <returns>True if prepayment is required, false otherwise</returns>
    procedure TestSalesPrepayment(SalesHeader: Record "Sales Header"): Boolean
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
        TestResult: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesPrepayment(SalesHeader, TestResult, IsHandled);
        if IsHandled then
            exit(TestResult);

        if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then
            exit(false);

        SalesLine.SetLoadFields("Prepmt. Line Amount", "Prepmt. Amt. Inv.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                if SalesLine."Prepmt. Line Amount" <> 0 then
                    if SalesLine."Prepmt. Amt. Inv." <> SalesLine."Prepmt. Line Amount" then
                        exit(true);
            until SalesLine.Next() = 0;
    end;

    /// <summary>
    /// Tests if purchase document has prepayment requirements.
    /// Validates whether purchase order contains prepayment percentages that require prepayment invoice processing.
    /// </summary>
    /// <param name="PurchaseHeader">Purchase header to test for prepayment requirements</param>
    /// <returns>True if prepayment is required, false otherwise</returns>
    procedure TestPurchasePrepayment(PurchaseHeader: Record "Purchase Header"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
        TestResult: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchPrepayment(PurchaseHeader, TestResult, IsHandled);
        if IsHandled then
            exit(TestResult);

        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Quote then
            exit(false);

        PurchaseLine.SetLoadFields("Prepmt. Amt. Inv.", "Prepmt. Line Amount");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter("Prepmt. Line Amount", '<>%1', 0);
        if PurchaseLine.FindSet() then
            repeat
                if PurchaseLine."Prepmt. Amt. Inv." <> PurchaseLine."Prepmt. Line Amount" then
                    exit(true);
            until PurchaseLine.Next() = 0;
    end;

    /// <summary>
    /// Tests sales order line for compatibility with Get Shipment Lines function.
    /// Validates that sales line can be processed when using Get Shipment Lines with prepayment scenarios.
    /// </summary>
    /// <param name="SalesLine">Sales line to test for Get Shipment Lines compatibility</param>
    procedure TestSalesOrderLineForGetShptLines(SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesOrderLineForGetShptLines(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if SalesLine."Prepmt. Amt. Inv." <> SalesLine."Prepmt. Line Amount" then
            Error(PrepaymentInvoicesNotPaidErr);
    end;

    /// <summary>
    /// Tests purchase order line for compatibility with Get Receipt Lines function.
    /// Validates that purchase line can be processed when using Get Receipt Lines with prepayment scenarios.
    /// </summary>
    /// <param name="PurchaseLine">Purchase line to test for Get Receipt Lines compatibility</param>
    procedure TestPurchaseOrderLineForGetRcptLines(PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchaseOrderLineForGetRcptLines(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if PurchaseLine."Prepmt. Amt. Inv." <> PurchaseLine."Prepmt. Line Amount" then
            Error(PrepaymentInvoicesNotPaidErr);
    end;

    /// <summary>
    /// Tests if sales prepayment invoices are paid before posting.
    /// </summary>
    /// <param name="SalesHeader">Sales document header to test</param>
    /// <returns>True if prepayment is paid or check is disabled, false otherwise</returns>
    procedure TestSalesPayment(SalesHeader: Record "Sales Header") Result: Boolean
    var
        SalesSetup: Record "Sales & Receivables Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        IsHandled: Boolean;
    begin
        SalesSetup.Get();
        if not SalesSetup."Check Prepmt. when Posting" then
            exit(false);

        IsHandled := false;
        OnBeforeTestSalesPayment(SalesHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        SalesInvHeader.SetCurrentKey("Prepayment Order No.", "Prepayment Invoice");
        SalesInvHeader.SetLoadFields("No.");
        SalesInvHeader.SetRange("Prepayment Order No.", SalesHeader."No.");
        SalesInvHeader.SetRange("Prepayment Invoice", true);
        if SalesInvHeader.FindSet() then
            repeat
                OnTestSalesPaymentOnBeforeCustLedgerEntrySetFilter(CustLedgerEntry, SalesHeader, SalesInvHeader);
                CustLedgerEntry.SetCurrentKey("Document No.");
                CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
                CustLedgerEntry.SetRange("Document No.", SalesInvHeader."No.");
                CustLedgerEntry.SetFilter("Remaining Amt. (LCY)", '<>%1', 0);
                if not CustLedgerEntry.IsEmpty() then
                    exit(true);
            until SalesInvHeader.Next() = 0;

        exit(false);
    end;

    /// <summary>
    /// Tests if purchase prepayment invoices are paid before posting.
    /// </summary>
    /// <param name="PurchaseHeader">Purchase document header to test</param>
    /// <returns>True if prepayment is paid or check is disabled, false otherwise</returns>
    procedure TestPurchasePayment(PurchaseHeader: Record "Purchase Header") Result: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        IsHandled: Boolean;
    begin
        PurchasesPayablesSetup.Get();
        if not PurchasesPayablesSetup."Check Prepmt. when Posting" then
            exit(false);

        IsHandled := false;
        OnBeforeTestPurchasePayment(PurchaseHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        PurchInvHeader.SetCurrentKey("Prepayment Order No.", "Prepayment Invoice");
        PurchInvHeader.SetLoadFields("No.");
        PurchInvHeader.SetRange("Prepayment Order No.", PurchaseHeader."No.");
        PurchInvHeader.SetRange("Prepayment Invoice", true);
        if PurchInvHeader.FindSet() then
            repeat
                OnTestPurchasePaymentOnBeforeVendLedgerEntrySetFilter(VendLedgerEntry, PurchaseHeader, PurchInvHeader);
                VendLedgerEntry.SetCurrentKey("Document No.");
                VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Invoice);
                VendLedgerEntry.SetRange("Document No.", PurchInvHeader."No.");
                VendLedgerEntry.SetFilter("Remaining Amt. (LCY)", '<>%1', 0);
                if not VendLedgerEntry.IsEmpty() then
                    exit(true);
            until PurchInvHeader.Next() = 0;

        exit(false);
    end;

    /// <summary>
    /// Updates pending prepayment status for sales orders.
    /// </summary>
    procedure UpdatePendingPrepaymentSales()
    var
        SalesHeader: Record "Sales Header";
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::"Pending Prepayment");
        if SalesHeader.FindSet(true) then
            repeat
                if not PrepaymentMgt.TestSalesPayment(SalesHeader) then begin
                    CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader);
                    if SalesHeader.Status = SalesHeader.Status::Released then
                        Session.LogMessage('0000254', StrSubstNo(StatusOfSalesOrderIsChangedTxt, Format(SalesHeader."No.")), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', UpdateSalesOrderStatusTxt);
                end;
            until SalesHeader.Next() = 0;
    end;

    /// <summary>
    /// Updates pending prepayment status for purchase orders.
    /// </summary>
    procedure UpdatePendingPrepaymentPurchase()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange(Status, PurchaseHeader.Status::"Pending Prepayment");
        if PurchaseHeader.FindSet(true) then
            repeat
                if not PrepaymentMgt.TestPurchasePayment(PurchaseHeader) then begin
                    CODEUNIT.Run(CODEUNIT::"Release Purchase Document", PurchaseHeader);
                    if PurchaseHeader.Status = PurchaseHeader.Status::Released then
                        Session.LogMessage('0000255', StrSubstNo(StatusOfPurchaseOrderIsChangedTxt, Format(PurchaseHeader."No.")), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', UpdatePurchaseOrderStatusTxt);
                end;
            until PurchaseHeader.Next() = 0;
    end;

    /// <summary>
    /// Creates and starts job queue entry for updating pending prepayment sales orders.
    /// </summary>
    /// <param name="UpdateFrequency">Frequency of the automatic update</param>
    procedure CreateAndStartJobQueueEntrySales(UpdateFrequency: Option Never,Daily,Weekly)
    begin
        CreateAndStartJobQueueEntry(
          CODEUNIT::"Upd. Pending Prepmt. Sales", UpdateFrequency, UpdateSalesOrderStatusTxt);
    end;

    /// <summary>
    /// Creates and starts job queue entry for updating pending prepayment purchase orders.
    /// </summary>
    /// <param name="UpdateFrequency">Frequency of the automatic update</param>
    procedure CreateAndStartJobQueueEntryPurchase(UpdateFrequency: Option Never,Daily,Weekly)
    begin
        CreateAndStartJobQueueEntry(
          CODEUNIT::"Upd. Pending Prepmt. Purchase", UpdateFrequency, UpdatePurchaseOrderStatusTxt);
    end;

    /// <summary>
    /// Creates and starts a job queue entry for automatic prepayment processing.
    /// </summary>
    /// <param name="CodeunitID">Codeunit ID to run in the job queue</param>
    /// <param name="UpdateFrequency">Frequency of the automatic update</param>
    /// <param name="Category">Category description for the job queue entry</param>
    procedure CreateAndStartJobQueueEntry(CodeunitID: Integer; UpdateFrequency: Option Never,Daily,Weekly; Category: Text)
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Job Queue Management";
    begin
        JobQueueManagement.DeleteJobQueueEntries(JobQueueEntry."Object Type to Run"::Codeunit, CodeunitID);

        JobQueueEntry."No. of Minutes between Runs" := UpdateFrequencyToNoOfMinutes(UpdateFrequency);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CodeunitID;
        JobQueueManagement.CreateJobQueueEntry(JobQueueEntry);

        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        Session.LogMessage('0000256', StrSubstNo(JobQueueEntryHasStartedTxt, Format(UpdateFrequency)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', Category);
    end;

    local procedure UpdateFrequencyToNoOfMinutes(UpdateFrequency: Option Never,Daily,Weekly): Integer
    begin
        case UpdateFrequency of
            UpdateFrequency::Never:
                exit(0);
            UpdateFrequency::Daily:
                exit(60 * 24);
            UpdateFrequency::Weekly:
                exit(60 * 24 * 7);
        end;
    end;

    /// <summary>
    /// Integration event raised before testing sales prepayment requirements.
    /// </summary>
    /// <param name="SalesHeader">Sales document header to test</param>
    /// <param name="TestResult">Result of the prepayment test</param>
    /// <param name="IsHandled">Set to true to skip standard testing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesPrepayment(SalesHeader: Record "Sales Header"; var TestResult: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before testing purchase prepayment requirements.
    /// </summary>
    /// <param name="PurchHeader">Purchase document header to test</param>
    /// <param name="TestResult">Result of the prepayment test</param>
    /// <param name="IsHandled">Set to true to skip standard testing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchPrepayment(PurchHeader: Record "Purchase Header"; var TestResult: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before testing sales payment status.
    /// </summary>
    /// <param name="SalesHeader">Sales document header to test</param>
    /// <param name="Result">Result of the payment test</param>
    /// <param name="IsHandled">Set to true to skip standard testing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesPayment(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before testing purchase payment status.
    /// </summary>
    /// <param name="PurchaseHeader">Purchase document header to test</param>
    /// <param name="Result">Result of the payment test</param>
    /// <param name="IsHandled">Set to true to skip standard testing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchasePayment(PurchaseHeader: Record "Purchase Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before setting customer ledger entry filters in sales payment test.
    /// </summary>
    /// <param name="CustLedgerEntry">Customer ledger entry record</param>
    /// <param name="SalesHeader">Sales document header</param>
    /// <param name="SalesInvHeader">Sales invoice header</param>
    [IntegrationEvent(false, false)]
    local procedure OnTestSalesPaymentOnBeforeCustLedgerEntrySetFilter(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesHeader: Record "Sales Header"; SalesInvHeader: Record "Sales Invoice Header")
    begin
    end;

    /// <summary>
    /// Integration event raised before setting vendor ledger entry filters in purchase payment test.
    /// </summary>
    /// <param name="VendLedgerEntry">Vendor ledger entry record</param>
    /// <param name="PurchaseHeader">Purchase document header</param>
    /// <param name="PurchInvHeader">Purchase invoice header</param>
    [IntegrationEvent(false, false)]
    local procedure OnTestPurchasePaymentOnBeforeVendLedgerEntrySetFilter(var VendLedgerEntry: Record "Vendor Ledger Entry"; PurchaseHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    /// <summary>
    /// Integration event raised before setting sales prepayment percentage.
    /// </summary>
    /// <param name="SalesLine">Sales line to set prepayment percentage for</param>
    /// <param name="Date">Date for prepayment calculation</param>
    /// <param name="IsHandled">Set to true to skip standard processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalesPrepaymentPct(var SalesLine: Record "Sales Line"; Date: Date; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before testing sales order lines for get shipment lines operation.
    /// </summary>
    /// <param name="SalesLine">Sales line to test</param>
    /// <param name="IsHandled">Set to true to skip standard testing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesOrderLineForGetShptLines(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before testing purchase order lines for get receipt lines operation.
    /// </summary>
    /// <param name="PurchaseLine">Purchase line to test</param>
    /// <param name="IsHandled">Set to true to skip standard testing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchaseOrderLineForGetRcptLines(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;
}

