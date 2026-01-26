// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Service.History;

codeunit 12200 "Tax Invoice Renaming Subscr."
{

    trigger OnRun()
    begin
    end;

    var
        ThresholdAmount: Decimal;
        ServiceTaxInvoiceTxt: Label 'Service - Tax Invoice %1', Comment = '%1 is a placeholder for COPY token';
        TaxInvoiceTxt: Label 'Tax Invoice';
        PrepmtTaxInvoiceTxt: Label 'Prepayment Tax Invoice';

    [Scope('OnPrem')]
    procedure GetTaxInvoiceThreshold(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        ThresholdAmount := GeneralLedgerSetup."Tax Invoice Renaming Threshold";
        exit(ThresholdAmount > 0);
    end;

    local procedure IsSalesInvoiceAmountAboveThreshold(SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Posting Date", SalesInvoiceHeader."Posting Date");
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        if CustLedgerEntry.FindFirst() then begin
            CustLedgerEntry.CalcFields("Original Amt. (LCY)");
            exit(CustLedgerEntry."Original Amt. (LCY)" > ThresholdAmount);
        end;
    end;

    local procedure IsServiceInvoiceAmountAboveThreshold(ServiceInvoiceHeader: Record "Service Invoice Header"): Boolean
    begin
        ServiceInvoiceHeader.CalcFields("Amount Including VAT");
        exit(ServiceInvoiceHeader."Amount Including VAT" > ThresholdAmount);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Invoice", 'OnBeforeGetDocumentCaption', '', false, false)]
    local procedure OnBeforeGetStdSalesInvoiceCaption(SalesInvoiceHeader: Record "Sales Invoice Header"; var DocCaption: Text)
    begin
        if GetTaxInvoiceThreshold() then
            if IsSalesInvoiceAmountAboveThreshold(SalesInvoiceHeader) then
                if SalesInvoiceHeader."Prepayment Invoice" then
                    DocCaption := PrepmtTaxInvoiceTxt
                else
                    DocCaption := TaxInvoiceTxt;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Service - Invoice", 'OnBeforeGetDocumentCaption', '', false, false)]
    local procedure OnBeforeGetServiceInvoiceCaption(ServiceInvoiceHeader: Record "Service Invoice Header"; var DocCaption: Text)
    begin
        if GetTaxInvoiceThreshold() then
            if IsServiceInvoiceAmountAboveThreshold(ServiceInvoiceHeader) then
                DocCaption := ServiceTaxInvoiceTxt;
    end;
}

