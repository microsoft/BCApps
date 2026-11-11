// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Purchases.History;
using Microsoft.Sales.History;

#pragma warning disable AS0088
tableextension 7000110 "VAT Entry ES" extends "VAT Entry"
{
    [Scope('OnPrem')]
    procedure IsCorrectiveCrMemoDiffPeriod(StartDateFormula: DateFormula; EndDateFormula: DateFormula): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Result: Boolean;
    begin
        if "Document Type" <> "Document Type"::"Credit Memo" then
            exit(false);

        case Type of
            Type::Sale:
                begin
                    if SalesCrMemoHeader.Get("Document No.") then
                        exit(IsCorrectiveSalesCrMemoDiffPeriod(SalesCrMemoHeader, StartDateFormula, EndDateFormula));
                    // Service processing moved to codeunit "Service Cr. Memo Header - Edit"
                    OnIsCorrectiveCrMemoDiffPeriodOnAfterCheckSales(Rec, StartDateFormula, EndDateFormula, Result);
                    exit(Result);
                end;
            Type::Purchase:
                exit(IsCorrectivePurchCrMemoDiffPeriod("Document No.", StartDateFormula, EndDateFormula));
        end;
    end;

    local procedure IsCorrectiveSalesCrMemoDiffPeriod(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; StartDateFormula: DateFormula; EndDateFormula: DateFormula): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if SalesCrMemoHeader."Corrected Invoice No." = '' then
            exit(false);
        SalesInvoiceHeader.Get(SalesCrMemoHeader."Corrected Invoice No.");
        exit(not (SalesInvoiceHeader."Posting Date" in [CalcDate(StartDateFormula, SalesCrMemoHeader."Posting Date") ..
                                                        CalcDate(EndDateFormula, SalesCrMemoHeader."Posting Date")]));
    end;

    local procedure IsCorrectivePurchCrMemoDiffPeriod(DocNo: Code[20]; StartDateFormula: DateFormula; EndDateFormula: DateFormula): Boolean
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchCrMemoHdr.Get(DocNo);
        if PurchCrMemoHdr."Corrected Invoice No." = '' then
            exit(false);
        PurchInvHeader.Get(PurchCrMemoHdr."Corrected Invoice No.");
        exit(not (PurchInvHeader."Posting Date" in [CalcDate(StartDateFormula, PurchCrMemoHdr."Posting Date") ..
                                                    CalcDate(EndDateFormula, PurchCrMemoHdr."Posting Date")]));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsCorrectiveCrMemoDiffPeriodOnAfterCheckSales(var VATEntry: Record "VAT Entry"; StartDateFormula: DateFormula; EndDateFormula: DateFormula; var Result: Boolean)
    begin
    end;
}
